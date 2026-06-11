// lib/screens/topup/topup_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../services/topup_api_service.dart';
import '../../../exceptions/topup_exception.dart';

class TopUpDebugScreen extends StatefulWidget {
  const TopUpDebugScreen({super.key});

  @override
  State<TopUpDebugScreen> createState() => _TopUpDebugScreenState();
}

class _TopUpDebugScreenState extends State<TopUpDebugScreen> {
  final TextEditingController _msisdnController = TextEditingController(text: '77001011');
  final TextEditingController _isdnController = TextEditingController(text: '21250999');
  
  final List<Map<String, String>> _testCases = [
    // Cas de test pour validation
    {'mobile': '77001011', 'fixed': '21250999', 'description': 'Numéros valides standards'},
    {'mobile': '77123456', 'fixed': '21123456', 'description': 'Numéros de test documentation'},
    {'mobile': '25377001011', 'fixed': '25321250999', 'description': 'Formats internationaux'},
    {'mobile': '77000000', 'fixed': '21000000', 'description': 'Numéros avec zéros'},
    {'mobile': '77999999', 'fixed': '21999999', 'description': 'Numéros max range'},
    
    // Cas d'erreur attendus
    {'mobile': '78123456', 'fixed': '21123456', 'description': 'Mobile invalide (78)'},
    {'mobile': '77123456', 'fixed': '22123456', 'description': 'Fixe invalide (22)'},
    {'mobile': '7712345', 'fixed': '21123456', 'description': 'Mobile trop court'},
    {'mobile': '77123456', 'fixed': '2112345', 'description': 'Fixe trop court'},
  ];
  
  bool _isLoading = false;
  String? _result;
  String? _error;
  final List<Map<String, dynamic>> _batchResults = [];

  @override
  void dispose() {
    _msisdnController.dispose();
    _isdnController.dispose();
    super.dispose();
  }

  Future<void> _testSingleNumber() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    final mobile = _msisdnController.text.trim();
    final fixed = _isdnController.text.trim();

    try {
      // Test de validation d'abord
      final validationResult = _validateNumbers(mobile, fixed);
      if (validationResult != null) {
        setState(() {
          _error = validationResult;
          _isLoading = false;
        });
        return;
      }

      // Test de l'API
      final response = await TopUpApi.instance.getBalances(
        msisdn: mobile,
        isdn: fixed,
        useCache: false,
      );

      final resultText = '''
✅ SUCCÈS - $mobile → $fixed

📊 RÉSUMÉ:
• Total soldes: ${response.totalBalances}
• Argent: ${response.summary.moneyTotalFormatted}
• Données: ${response.summary.dataTotalFormatted}
• Voix: ${response.summary.voiceTotalFormatted}

📋 DÉTAILS DES SOLDES:
${response.balances.map((balance) => '''
• ${balance.name}: ${balance.formattedValue}
  Statut: ${balance.expirationStatus.status}
  Expire: ${balance.expireDateFormatted}''').join('\n')}

🔧 INFORMATIONS TECHNIQUES:
• Backend: ${response.details.backendApi}
• Timestamp: ${response.details.requestTime}
• Message: ${response.message}
      ''';

      setState(() {
        _result = resultText;
        _isLoading = false;
      });
    } catch (e) {
      String errorText = _formatError(e, mobile, fixed);
      
      setState(() {
        _error = errorText;
        _isLoading = false;
      });
    }
  }

  String? _validateNumbers(String mobile, String fixed) {
    final errors = <String>[];
    
    // Validation mobile
    if (!TopUpValidator.isValidMobile(mobile)) {
      errors.add('Mobile invalide: $mobile');
      errors.add('  Format attendu: 77XXXXXX ou 25377XXXXXX');
    }
    
    // Validation fixe
    if (!TopUpValidator.isValidFixed(fixed)) {
      errors.add('Fixe invalide: $fixed');
      errors.add('  Format attendu: 21XXXXXX ou 25321XXXXXX');
    }
    
    if (errors.isNotEmpty) {
      return '❌ ERREURS DE VALIDATION:\n\n${errors.join('\n')}';
    }
    
    return null;
  }

  String _formatError(dynamic error, String mobile, String fixed) {
    String errorText = '❌ ERREUR - $mobile → $fixed\n\n';
    
    if (error is TopUpException) {
      errorText += '''
🔍 ANALYSE DE L'ERREUR:
• Type: ${error.error}
• Message: ${error.message}
• Code HTTP: ${error.statusCode}
• Code retour: ${error.returnCode ?? 'N/A'}

📊 CLASSIFICATION:
• Erreur réseau: ${error.isNetworkError ? '✅' : '❌'}
• Erreur validation: ${error.isValidationError ? '✅' : '❌'}
• Erreur serveur: ${error.isServerError ? '✅' : '❌'}
• Erreur auth: ${error.isAuthError ? '✅' : '❌'}

🎯 DIAGNOSTIC SPÉCIFIQUE:
• Numéro inexistant: ${error.isNumberNotFoundError ? '✅' : '❌'}
• Numéro bloqué: ${error.isNumberBlockedError ? '✅' : '❌'}
• Numéro postpaid: ${error.isPostpaidError ? '✅' : '❌'}
• Numéro expiré: ${error.isNumberExpiredError ? '✅' : '❌'}
• Solde insuffisant: ${error.isInsufficientBalanceError ? '✅' : '❌'}

💬 MESSAGE UTILISATEUR:
${error.userFriendlyMessage}
      ''';
      
      // Ajouter des suggestions basées sur le type d'erreur
      if (error.isNumberNotFoundError) {
        errorText += '\n🔧 SUGGESTION: Vérifiez que le numéro fixe existe dans le système.';
      } else if (error.isNumberBlockedError) {
        errorText += '\n🔧 SUGGESTION: Le numéro est suspendu, contactez le service client.';
      } else if (error.isPostpaidError) {
        errorText += '\n🔧 SUGGESTION: Les numéros postpaid ne sont pas supportés par TopUp.';
      } else if (error.isNetworkError) {
        errorText += '\n🔧 SUGGESTION: Vérifiez votre connexion internet et réessayez.';
      } else if (error.isServerError) {
        errorText += '\n🔧 SUGGESTION: Problème serveur temporaire, réessayez plus tard.';
      }
      
    } else {
      errorText += 'Erreur inattendue: $error';
    }
    
    return errorText;
  }

  Future<void> _runBatchTests() async {
    setState(() {
      _isLoading = true;
      _batchResults.clear();
      _result = null;
      _error = null;
    });

    for (int i = 0; i < _testCases.length; i++) {
      final testCase = _testCases[i];
      final mobile = testCase['mobile']!;
      final fixed = testCase['fixed']!;
      final description = testCase['description']!;

      try {
        final response = await TopUpApi.instance.getBalances(
          msisdn: mobile,
          isdn: fixed,
          useCache: false,
        );

        _batchResults.add({
          'success': true,
          'mobile': mobile,
          'fixed': fixed,
          'description': description,
          'totalBalances': response.totalBalances,
          'moneyTotal': response.summary.moneyTotalFormatted,
          'message': response.message,
        });
      } catch (e) {
        _batchResults.add({
          'success': false,
          'mobile': mobile,
          'fixed': fixed,
          'description': description,
          'error': e is TopUpException ? e.error : 'Erreur inattendue',
          'errorCode': e is TopUpException ? e.returnCode : null,
          'statusCode': e is TopUpException ? e.statusCode : 0,
          'userMessage': e is TopUpException ? e.userFriendlyMessage : e.toString(),
        });
      }

      // Pause pour éviter de surcharger l'API
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isLoading = false;
    });
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
          'Debug TopUp API',
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputCard(),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              _buildTestButtonsCard(),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              if (_isLoading) _buildLoadingCard(),
              if (_result != null || _error != null) _buildResultCard(),
              if (_batchResults.isNotEmpty) _buildBatchResultsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
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
              '🔧 Test Manuel',
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
                  child: TextFormField(
                    controller: _msisdnController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile (MSISDN)',
                      prefixIcon: Icon(Icons.smartphone),
                      border: OutlineInputBorder(),
                      hintText: '77001011',
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
                      hintText: '21250999',
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
              '🧪 Tests Disponibles',
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
                    onPressed: _isLoading ? null : _testSingleNumber,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Manuel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dtBlue,
                      foregroundColor: AppTheme.dtYellow,
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runBatchTests,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Tests Batch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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

  Widget _buildLoadingCard() {
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
                _batchResults.isEmpty ? 'Test en cours...' : 'Tests batch en cours... (${_batchResults.length}/${_testCases.length})',
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

  Widget _buildResultCard() {
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
                  '📋 Résultat du Test',
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
                color: _error != null ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                border: Border.all(
                  color: _error != null ? Colors.red : Colors.green,
                  width: 1,
                ),
              ),
              child: Text(
                _result ?? _error ?? '',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(11),
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

  Widget _buildBatchResultsCard() {
    final successCount = _batchResults.where((r) => r['success'] == true).length;
    final errorCount = _batchResults.length - successCount;

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
                  '📊 Résultats Tests Batch',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                Text(
                  '✅ $successCount  ❌ $errorCount',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            ..._batchResults.map((result) => _buildBatchResultItem(result)),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchResultItem(Map<String, dynamic> result) {
    final isSuccess = result['success'] == true;
    
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingS)),
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: ResponsiveSize.getFontSize(16),
              ),
              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
              Expanded(
                child: Text(
                  '${result['mobile']} → ${result['fixed']}',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            result['description'],
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(10),
              color: AppTheme.textSecondary,
            ),
          ),
          if (isSuccess) ...[
            Text(
              'Soldes: ${result['totalBalances']}, Argent: ${result['moneyTotal']}',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(10),
                color: Colors.green[700],
              ),
            ),
          ] else ...[
            Text(
              'Erreur: ${result['error']} (${result['statusCode']})',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(10),
                color: Colors.red[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}