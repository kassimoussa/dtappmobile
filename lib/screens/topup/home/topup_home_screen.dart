// lib/screens/topup/topup_home_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../models/topup_balance.dart';
import '../../../exceptions/topup_exception.dart';
import '../../../providers/topup_provider.dart';
import '../../../providers/balance_provider.dart';
import '../../../routes/custom_route_transitions.dart';
import '../packages/topup_package_screen.dart';
import '../subscription/topup_subscription_screen.dart';
import '../recharge/topup_recharge_screen.dart';
import '../../../generated/l10n/app_localizations.dart';

class TopUpHomeScreen extends StatefulWidget {
  const TopUpHomeScreen({super.key});

  @override
  State<TopUpHomeScreen> createState() => _TopUpHomeScreenState();
}

class _TopUpHomeScreenState extends State<TopUpHomeScreen> {
  final TextEditingController _fixedNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialiser le provider TopUp
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopUpProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _fixedNumberController.dispose();
    super.dispose();
  }

  void _showSuspendedDialog(TopUpProvider provider) {
    if (provider.numberStatus == null) return;
    final l10n = AppLocalizations.of(context)!;

    final status = provider.numberStatus!['status'];
    final description = provider.numberStatus!['description'] ?? '';
    final rawDescription = status?['raw_description'] ?? description;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Text(
                l10n.numberSuspended,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rawDescription.isNotEmpty
                    ? rawDescription
                    : l10n.numberSuspendedInfo,
                style: TextStyle(fontSize: ResponsiveSize.getFontSize(16)),
              ),
              SizedBox(height: ResponsiveSize.getHeight(16)),
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveSize.getWidth(8),
                  ),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: ResponsiveSize.getWidth(8)),
                    Expanded(
                      child: Text(
                        l10n.balancesConsultableOnly,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(14),
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.understood,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _consultBalances() async {
    if (!_formKey.currentState!.validate()) return;

    final topUpProvider = context.read<TopUpProvider>();
    await topUpProvider.startSession(_fixedNumberController.text.trim());
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
    final topUpProvider = context.read<TopUpProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.logout),
            content: Text(l10n.logoutConfirmMessage(topUpProvider.fixedNumber!)),
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
      await topUpProvider.endSession();
      _fixedNumberController.clear();

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
    final topUpProvider = context.watch<TopUpProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueO08,
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: l10n.myLineTitle, showBack: false, actions: [if (topUpProvider.hasActiveSession) GlassAppBarAction(icon: Icons.logout_rounded, onTap: _disconnectTopUp)]),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              // Afficher les inputs seulement s'il n'y a pas de session active
              if (!topUpProvider.hasActiveSession) ...[
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                _buildInputForm(topUpProvider),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              ],

              // États de chargement et d'erreur
              if (topUpProvider.isLoading) _buildLoadingState(),
              if (topUpProvider.errorMessage != null) _buildErrorState(topUpProvider),

              // Résultats (toujours affichés s'ils existent)
              if (topUpProvider.balanceResponse != null) ...[
                _buildBalanceSummary(topUpProvider),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                _buildActionButtons(topUpProvider),
              ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }


  Widget _buildInputForm(TopUpProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusM),
          ),
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
                      borderRadius: BorderRadius.circular(
                        ResponsiveSize.getWidth(AppTheme.radiusS),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveSize.getWidth(AppTheme.radiusS),
                      ),
                      borderSide: const BorderSide(color: AppTheme.dtBlue, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                DtButton.primary(
                  label: l10n.consult,
                  loading: provider.isLoading,
                  onPressed: _consultBalances,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
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

  Widget _buildErrorState(TopUpProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
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
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            ElevatedButton.icon(
              onPressed: () => provider.refreshBalances(),
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

  String _getDataDisplay(TopUpProvider provider) {
    final response = provider.balanceResponse!;
    // Si données illimitées, afficher simplement "Illimité"
    if (provider.hasUnlimitedData) {
      return 'Illimité';
    }
    return response.summary.dataTotalFormatted;
  }

  Widget _buildBalanceSummary(TopUpProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final response = provider.balanceResponse!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
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
                        l10n.fixedLineNumberFormat(provider.fixedNumber ?? ''),
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
                  response.summary.moneyTotalCompact,
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildSummaryItem(
                  l10n.dataType,
                  _getDataDisplay(provider),
                  Icons.data_usage,
                  AppTheme.dtBlue,
                ),
                _buildSummaryItem(
                  l10n.voiceType,
                  response.summary.voiceTotalHoursMinutes,
                  Icons.phone,
                  Colors.orange,
                ),
              ],
            ),
            // Expiration en pied de carte, rattachée aux données
            ..._buildExpirationFooter(provider),
          ],
        ),
      ),
    );
  }

  /// Pied de carte « Expire le … » — liste vide si aucune date disponible
  List<Widget> _buildExpirationFooter(TopUpProvider provider) {
    final row = _buildExpirationInfo(provider);
    if (row == null) return const [];
    return [
      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
      Divider(height: 1, color: Colors.grey[200]),
      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
      Center(child: row),
    ];
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: ResponsiveSize.getFontSize(24)),
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

  Widget? _buildExpirationInfo(TopUpProvider provider) {
    final response = provider.balanceResponse!;

    // Chercher les données prépayées (type data)
    TopUpBalance? dataBalance;
    try {
      dataBalance = response.balances.firstWhere(
        (balance) => balance.isDataType,
      );
    } catch (e) {
      // Si aucune donnée trouvée, prendre le premier balance disponible
      dataBalance =
          response.balances.isNotEmpty ? response.balances.first : null;
    }

    if (dataBalance == null || dataBalance.expireDateFormatted.isEmpty) {
      return null;
    }

    // Vérifier si la date est expirée
    final isExpired = dataBalance.isExpired;
    final isExpiringSoon = dataBalance.isExpiringSoon;

    Color textColor = Colors.grey[600]!;
    Color? backgroundColor;

    if (isExpired) {
      textColor = Colors.red[700]!;
      backgroundColor = Colors.red[50];
    } else if (isExpiringSoon) {
      textColor = Colors.orange[700]!;
      backgroundColor = Colors.orange[50];
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(8),
        vertical: ResponsiveSize.getHeight(4),
      ),
      decoration:
          backgroundColor != null
              ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(4)),
                border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
              )
              : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExpired) ...[
            Icon(Icons.warning_amber, color: textColor, size: 14),
            SizedBox(width: ResponsiveSize.getWidth(4)),
          ] else if (isExpiringSoon) ...[
            Icon(Icons.schedule, color: textColor, size: 14),
            SizedBox(width: ResponsiveSize.getWidth(4)),
          ],
          Text(
            isExpired
                ? AppLocalizations.of(context)!.expiredOn(dataBalance.expireDateFormatted)
                : AppLocalizations.of(context)!.expiresOn(dataBalance.expireDateFormatted),
            style: TextStyle(
              color: textColor,
              fontSize: ResponsiveSize.getFontSize(12),
              fontWeight:
                  isExpired || isExpiringSoon
                      ? FontWeight.w600
                      : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TopUpProvider topUpProvider) {
    // Utiliser le BalanceProvider pour le solde mobile
    final balanceProvider = context.read<BalanceProvider>();
    final mobileSolde = balanceProvider.solde;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickActions,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionButton(
                icon: Icons.subscriptions,
                label: l10n.buySubscriptionBtn,
                onTap: () {
                  if (topUpProvider.isNumberSuspended) {
                    _showSuspendedDialog(topUpProvider);
                  } else {
                    Navigator.push(
                      context,
                      CustomRouteTransitions.slideRightRoute(
                        page: TopUpSubscriptionScreen(
                          fixedNumber: topUpProvider.fixedNumber!,
                          mobileNumber: topUpProvider.mobileNumber!,
                          soldeActuel: mobileSolde,
                        ),
                      ),
                    );
                  }
                },
              ),
              SizedBox(width: ResponsiveSize.getWidth(12)),
              _buildActionButton(
                icon: Icons.shopping_cart,
                label: l10n.buyPackagesBtn,
                onTap: () {
                  if (topUpProvider.isNumberSuspended) {
                    _showSuspendedDialog(topUpProvider);
                  } else {
                    Navigator.push(
                      context,
                      CustomRouteTransitions.slideRightRoute(
                        page: TopUpPackageScreen(
                          fixedNumber: topUpProvider.fixedNumber!,
                          mobileNumber: topUpProvider.mobileNumber!,
                          soldeActuel: mobileSolde,
                          hasUnlimitedData: topUpProvider.hasUnlimitedData,
                        ),
                      ),
                    );
                  }
                },
              ),
              SizedBox(width: ResponsiveSize.getWidth(12)),
              _buildActionButton(
                icon: Icons.account_balance_wallet,
                label: l10n.rechargeAccountBtn,
                onTap: () {
                  if (topUpProvider.isNumberSuspended) {
                    _showSuspendedDialog(topUpProvider);
                  } else {
                    Navigator.push(
                      context,
                      CustomRouteTransitions.slideRightRoute(
                        page: TopUpRechargeScreen(
                          fixedNumber: topUpProvider.fixedNumber!,
                          mobileNumber: topUpProvider.mobileNumber!,
                          soldeActuel: mobileSolde,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
              decoration: AppTheme.cardDecoration.copyWith(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppTheme.dtBlueDark,
                size: ResponsiveSize.getFontSize(24),
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(6)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: ResponsiveSize.getFontSize(12),
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
