// lib/screens/topup/balance_inquiry_screen.dart
import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../models/topup_balance.dart';
import '../../services/topup_api_service.dart';
import '../../services/user_session.dart';
import '../../exceptions/topup_exception.dart';
import 'topup_debug_screen.dart';

class BalanceInquiryScreen extends StatefulWidget {
  const BalanceInquiryScreen({super.key});

  @override
  State<BalanceInquiryScreen> createState() => _BalanceInquiryScreenState();
}

class _BalanceInquiryScreenState extends State<BalanceInquiryScreen> {
  final TextEditingController _fixedNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  TopUpBalanceResponse? _balanceResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userMobile;

  @override
  void initState() {
    super.initState();
    _loadUserMobile();
  }

  @override
  void dispose() {
    _fixedNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMobile() async {
    final phoneNumber = await UserSession.getPhoneNumber();
    setState(() {
      _userMobile = phoneNumber;
    });
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
          _errorMessage = 'Une erreur inattendue est survenue';
        }
      });
    }
  }

  String? _validateFixedNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un numéro de téléphone fixe';
    }
    
    if (!TopUpValidator.isValidFixed(value.trim())) {
      return 'Le numéro doit commencer par 21 ou 25321 et contenir 8 ou 11 chiffres';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Consultation des Soldes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
                  ),
              actions: [         
                IconButton(
                  icon: const Icon(Icons.bug_report, color: Colors.white),
                  onPressed: () {             
                    Navigator.push(               
                      context,               
                      MaterialPageRoute(
                        builder: (context) => const TopUpDebugScreen(),
                      ),            
                    );            
                  },            
                  tooltip: 'Debug',          
                ),
              ]
        ), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoCard(),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              _buildInputForm(),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              if (_isLoading) _buildLoadingState(),
              if (_errorMessage != null) _buildErrorState(),
              if (_balanceResponse != null) _buildBalanceResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
              decoration: BoxDecoration(
                color: AppTheme.dtBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.dtBlue,
                size: ResponsiveSize.getFontSize(24),
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numéro initiateur',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(12),
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    _userMobile ?? 'Chargement...',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dtBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
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
                'Numéro de ligne fixe',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              TextFormField(
                controller: _fixedNumberController,
                keyboardType: TextInputType.phone,
                validator: _validateFixedNumber,
                decoration: InputDecoration(
                  hintText: 'Ex: 21123456 ou 25321123456',
                  prefixIcon: Icon(Icons.phone, color: AppTheme.dtBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                    borderSide: BorderSide(color: AppTheme.dtBlue, width: 2),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _consultBalances,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dtBlue,
                    foregroundColor: AppTheme.dtYellow,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                    ),
                  ),
                  child: Text(
                    _isLoading ? 'Consultation...' : 'Consulter les soldes',
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            'Consultation des soldes en cours...',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              'Erreur',
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
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: AppTheme.dtYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceResults() {
    final response = _balanceResponse!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultsHeader(response),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
        _buildSummaryCard(response.summary),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
        _buildBalancesList(response.balances),
      ],
    );
  }

  Widget _buildResultsHeader(TopUpBalanceResponse response) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: ResponsiveSize.getFontSize(24),
            ),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consultation réussie',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Numéro: ${response.fixedIsdn}',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(14),
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${response.totalBalances} solde${response.totalBalances > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TopUpBalanceSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé des soldes',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Argent',
                  summary.moneyTotalFormatted,
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Données',
                  summary.dataTotalFormatted,
                  Icons.data_usage,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Voix',
                  summary.voiceTotalFormatted,
                  Icons.phone,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveSize.getFontSize(20),
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(12),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(10),
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBalancesList(List<TopUpBalance> balances) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails des soldes',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        ...balances.map((balance) => _buildBalanceCard(balance)),
      ],
    );
  }

  Widget _buildBalanceCard(TopUpBalance balance) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingS)),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      balance.name,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.getWidth(AppTheme.spacingXS),
                      vertical: ResponsiveSize.getHeight(2),
                    ),
                    decoration: BoxDecoration(
                      color: balance.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusXS)),
                    ),
                    child: Text(
                      balance.expirationStatus.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(10),
                        fontWeight: FontWeight.bold,
                        color: balance.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
              Text(
                balance.formattedValue,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: ResponsiveSize.getFontSize(14),
                    color: balance.statusColor,
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
                  Text(
                    balance.expirationStatus.message,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(12),
                      color: balance.statusColor,
                    ),
                  ),
                ],
              ),
              Text(
                'Expire le ${balance.expireDateFormatted}',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(10),
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}