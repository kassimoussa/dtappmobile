// lib/screens/topup/topup_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/topup_api_service.dart';
import '../../exceptions/topup_exception.dart';

class TopUpTestScreen extends StatefulWidget {
  const TopUpTestScreen({super.key});

  @override
  State<TopUpTestScreen> createState() => _TopUpTestScreenState();
}

class _TopUpTestScreenState extends State<TopUpTestScreen> {
  final TextEditingController _msisdnController = TextEditingController(text: '77123456');
  final TextEditingController _isdnController = TextEditingController(text: '21123456');
  final TextEditingController _baseUrlController = TextEditingController(
    text: 'https://your-domain.com/api/topup'
  );
  
  bool _isLoading = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _msisdnController.dispose();
    _isdnController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _testGetBalances() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final response = await TopUpApi.instance.getBalances(
        msisdn: _msisdnController.text.trim(),
        isdn: _isdnController.text.trim(),
        useCache: false,
      );

      final resultText = '''
✅ SUCCÈS - Consultation des soldes

📱 Numéro mobile: ${response.mobileMsisdn}
📞 Numéro fixe: ${response.fixedIsdn}
💰 Total soldes: ${response.totalBalances}

📊 RÉSUMÉ:
• Argent: ${response.summary.moneyTotalFormatted}
• Données: ${response.summary.dataTotalFormatted}
• Voix: ${response.summary.voiceTotalFormatted}

📋 DÉTAILS:
${response.balances.map((balance) => '''
• ${balance.name}
  Valeur: ${balance.formattedValue}
  Type: ${balance.type}
  Statut: ${balance.expirationStatus.status}
  Message: ${balance.expirationStatus.message}
  Expire: ${balance.expireDateFormatted}
''').join('\n')}

🔧 INFORMATIONS TECHNIQUES:
• API Backend: ${response.details.backendApi}
• Heure requête: ${response.details.requestTime}
• Message: ${response.message}
      ''';

      setState(() {
        _result = resultText;
        _isLoading = false;
      });
    } catch (e) {
      String errorText = '❌ ERREUR\n\n';
      
      if (e is TopUpException) {
        errorText += '''
Type: ${e.error}
Message: ${e.message}
Code retour: ${e.returnCode ?? 'N/A'}
Status HTTP: ${e.statusCode}
Message utilisateur: ${e.userFriendlyMessage}

Détails:
• Erreur réseau: ${e.isNetworkError}
• Erreur validation: ${e.isValidationError}
• Erreur serveur: ${e.isServerError}
• Erreur auth: ${e.isAuthError}
• Numéro inexistant: ${e.isNumberNotFoundError}
• Numéro bloqué: ${e.isNumberBlockedError}
• Solde insuffisant: ${e.isInsufficientBalanceError}
        ''';
      } else {
        errorText += 'Erreur inattendue: $e';
      }

      setState(() {
        _error = errorText;
        _isLoading = false;
      });
    }
  }

  Future<void> _testValidation() async {
    final results = <String>[];
    
    // Test validation mobile
    final testMobiles = ['77123456', '25377123456', '78123456', '2537712345', '77'];
    for (final mobile in testMobiles) {
      final isValid = TopUpValidator.isValidMobile(mobile);
      results.add('📱 $mobile: ${isValid ? '✅' : '❌'}');
    }
    
    results.add('');
    
    // Test validation fixe
    final testFixed = ['21123456', '25321123456', '22123456', '2532112345', '21'];
    for (final fixed in testFixed) {
      final isValid = TopUpValidator.isValidFixed(fixed);
      results.add('📞 $fixed: ${isValid ? '✅' : '❌'}');
    }
    
    results.add('');
    
    // Test validation PIN
    final testPins = ['1234', '0000', '123', '12345', 'abcd'];
    for (final pin in testPins) {
      final isValid = TopUpValidator.isValidPin(pin);
      results.add('🔐 $pin: ${isValid ? '✅' : '❌'}');
    }
    
    results.add('');
    
    // Test génération transaction ID
    final transactionId = TopUpValidator.generateTransactionId();
    results.add('🆔 Transaction ID: $transactionId');
    
    setState(() {
      _result = '🧪 TESTS DE VALIDATION\n\n${results.join('\n')}';
      _error = null;
    });
  }

  Future<void> _testApiAvailability() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final isAvailable = await TopUpApi.instance.isApiAvailable();
      setState(() {
        _result = '''
🌐 TEST DE DISPONIBILITÉ API

URL: ${_baseUrlController.text}
Statut: ${isAvailable ? '✅ DISPONIBLE' : '❌ INDISPONIBLE'}

${isAvailable ? 'L\'API répond correctement' : 'L\'API ne répond pas ou est en erreur'}
        ''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '❌ Erreur lors du test de disponibilité: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    await TopUpApi.instance.clearCache();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache TopUp vidé avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copié dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Tests TopUp API',
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
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _clearCache,
            tooltip: 'Vider le cache',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfigurationCard(),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              _buildTestButtonsCard(),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              _buildResultsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
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
              '⚙️ Configuration',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de base API',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _msisdnController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile (MSISDN)',
                      prefixIcon: Icon(Icons.smartphone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                Expanded(
                  child: TextFormField(
                    controller: _isdnController,
                    decoration: const InputDecoration(
                      labelText: 'Fixe (ISDN)',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtonsCard() {
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
              '🧪 Tests disponibles',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testGetBalances,
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Test Soldes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dtBlue,
                      foregroundColor: AppTheme.dtYellow,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testValidation,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Validation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testApiAvailability,
                icon: const Icon(Icons.wifi_find),
                label: const Text('Test Disponibilité API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    if (_isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                Text(
                  'Test en cours...',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_result == null && _error == null) {
      return const SizedBox.shrink();
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📋 Résultats',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(_result ?? _error ?? ''),
                  tooltip: 'Copier',
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
              decoration: BoxDecoration(
                color: _error != null ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                border: Border.all(
                  color: _error != null ? Colors.red : Colors.green,
                  width: 1,
                ),
              ),
              child: Text(
                _result ?? _error ?? '',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(12),
                  fontFamily: 'monospace',
                  color: _error != null ? Colors.red[800] : Colors.green[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}