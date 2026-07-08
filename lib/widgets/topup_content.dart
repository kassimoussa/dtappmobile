// lib/widgets/topup_content.dart
import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/topup_balance.dart';
import '../services/topup_api_service.dart';
import '../services/user_session.dart';
import '../services/topup_session.dart';
import '../exceptions/topup_exception.dart';
import '../screens/topup/home/balance_inquiry_screen.dart';

class TopUpContent extends StatefulWidget {
  const TopUpContent({super.key});

  @override
  State<TopUpContent> createState() => _TopUpContentState();
}

class _TopUpContentState extends State<TopUpContent> {
  final TextEditingController _fixedNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TopUpBalanceResponse? _balanceResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userMobile;
  String? _currentFixedNumber;
  bool _hasActiveSession = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fixedNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Charger le numéro mobile de l'utilisateur
    final phoneNumber = await UserSession.getPhoneNumber();

    // Vérifier s'il y a une session TopUp active
    final hasSession = await TopUpSession.hasActiveSession();

    if (hasSession) {
      // Récupérer les données de session
      final sessionData = await TopUpSession.getSessionData();

      setState(() {
        _userMobile = phoneNumber;
        _hasActiveSession = true;
        _currentFixedNumber = sessionData['fixed'];
      });

      // Charger automatiquement les soldes
      if (_currentFixedNumber != null && _userMobile != null) {
        await _loadBalancesFromSession();
      }
    } else {
      setState(() {
        _userMobile = phoneNumber;
        _hasActiveSession = false;
      });
    }
  }

  Future<void> _loadBalancesFromSession() async {
    if (_userMobile == null || _currentFixedNumber == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TopUpApi.instance.getBalances(
        msisdn: _userMobile!,
        isdn: _currentFixedNumber!,
        useCache: true,
      );

      setState(() {
        _balanceResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e is TopUpException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = AppLocalizations.of(context)!.unexpectedError;
        }
      });
    }
  }

  Future<void> _consultBalances() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userMobile == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _balanceResponse = null;
    });

    try {
      final response = await TopUpApi.instance.getBalances(
        msisdn: _userMobile!,
        isdn: _fixedNumberController.text.trim(),
        useCache: true,
      );

      // Sauvegarder la session TopUp
      await TopUpSession.saveSession(
        mobileNumber: _userMobile!,
        fixedNumber: _fixedNumberController.text.trim(),
      );

      setState(() {
        _balanceResponse = response;
        _currentFixedNumber = _fixedNumberController.text.trim();
        _hasActiveSession = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e is TopUpException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = AppLocalizations.of(context)!.unexpectedError;
        }
      });
    }
  }

  String? _validateFixedNumber(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.fixedNumberRequired;
    }

    if (!TopUpValidator.isValidFixed(value.trim())) {
      return l10n.fixedNumberFormatError;
    }

    return null;
  }

  Future<void> _disconnectTopUp() async {
    final l10n = AppLocalizations.of(context)!;
    // Afficher confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutTopUp),
        content: Text(l10n.logoutConfirmMessage(_currentFixedNumber ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logoutAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Supprimer la session
      await TopUpSession.clearSession();

      // Réinitialiser l'état
      setState(() {
        _hasActiveSession = false;
        _currentFixedNumber = null;
        _balanceResponse = null;
        _errorMessage = null;
        _fixedNumberController.clear();
      });

      // Afficher confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.logoutTopUpSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header avec titre et actions
        Container(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          decoration: BoxDecoration(
            color: AppTheme.dtBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(ResponsiveSize.getWidth(AppTheme.radiusL)),
              bottomRight: Radius.circular(ResponsiveSize.getWidth(AppTheme.radiusL)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.topupFixedBalances,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_hasActiveSession) ...[
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _disconnectTopUp,
                    tooltip: l10n.logoutAction,
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BalanceInquiryScreen(),
                      ),
                    );
                  },
                  tooltip: l10n.detailedConsultation,
                ),
              ],
            ),
          ),
        ),

        // Contenu scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Afficher les inputs seulement s'il n'y a pas de session active
                if (!_hasActiveSession) ...[
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                  _buildInputForm(l10n),
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                ],

                // États de chargement et d'erreur
                if (_isLoading) _buildLoadingState(l10n),
                if (_errorMessage != null) _buildErrorState(l10n),

                // Résultats (toujours affichés s'ils existent)
                if (_balanceResponse != null) ...[
                  _buildBalanceSummary(l10n),
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildActionButtons(l10n),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputForm(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.checkFixedLine,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
              Text(
                l10n.enterFixedNumberInfo,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              TextFormField(
                controller: _fixedNumberController,
                keyboardType: TextInputType.phone,
                validator: _validateFixedNumber,
                decoration: InputDecoration(
                  labelText: l10n.fixedLineNumberKey,
                  hintText: l10n.fixedLineNumberHint,
                  prefixIcon: const Icon(Icons.phone, color: AppTheme.dtBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                    borderSide: const BorderSide(color: AppTheme.dtBlue, width: 2),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _consultBalances,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dtBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                    ),
                  ),
                  child: Text(
                    _isLoading ? l10n.consulting : l10n.consult,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            l10n.consultingInProgress,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveSize.getFontSize(48),
              color: Colors.red,
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              l10n.error,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            ElevatedButton.icon(
              onPressed: _consultBalances,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummary(AppLocalizations l10n) {
    final response = _balanceResponse!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.dtBlue,
                  size: ResponsiveSize.getFontSize(24),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.fixedBalances,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(18),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                      Text(
                        l10n.fixedLineNumberFormat(_currentFixedNumber ?? ''),
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(12),
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  l10n.money,
                  response.summary.moneyTotalFormatted,
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildSummaryItem(
                  l10n.dataType,
                  response.summary.dataTotalFormatted,
                  Icons.data_usage,
                  AppTheme.dtBlue,
                ),
                _buildSummaryItem(
                  l10n.voiceType,
                  response.summary.voiceTotalFormatted,
                  Icons.phone,
                  Colors.orange,
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            // Date d'expiration des données
            _buildDataExpirationInfo(response, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveSize.getFontSize(24),
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(12),
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDataExpirationInfo(TopUpBalanceResponse response, AppLocalizations l10n) {
    // Trouver la balance de type 'data' pour récupérer sa date d'expiration
    final dataBalance = response.balances.firstWhere(
      (balance) => balance.type == 'data',
      orElse: () => response.balances.first, // Fallback sur la première balance
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      decoration: BoxDecoration(
        color: AppTheme.dtBlueO10,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
        border: Border.all(
          color: AppTheme.dtBlueO30,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: ResponsiveSize.getFontSize(16),
            color: AppTheme.dtBlue,
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
          Text(
            l10n.dataExpireOn(dataBalance.expireDateFormatted),
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(12),
              color: AppTheme.dtBlue2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.topupActions,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              icon: Icons.add_box,
              label: l10n.topupRecharge,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoonMessage)),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.wifi,
              label: l10n.fixedPackage,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoonMessage)),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.swap_horiz,
              label: l10n.transferToFixed,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoonMessage)),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.history,
              label: l10n.topupHistory,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.comingSoonMessage)),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.dtBlue,
            radius: ResponsiveSize.getWidth(22),
            child: Icon(
              icon,
              color: AppTheme.dtYellow,
              size: ResponsiveSize.getFontSize(20),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(12),
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
