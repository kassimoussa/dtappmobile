import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/screens/home_screen.dart';
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:dtapp3/widgets/appbar_widget.dart';
import 'package:dtapp3/services/refill_service.dart';
import 'package:dtapp3/models/refill_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RefillCodeScreen extends StatefulWidget {
  final String phoneNumber; 
  final VoidCallback? onRefreshSolde;
  final bool isGift; // Pour savoir si c'est un cadeau ou pour soi-même

  const RefillCodeScreen({
    super.key,
    required this.phoneNumber, 
    this.onRefreshSolde,
    this.isGift = false,
  });

  @override
  State<RefillCodeScreen> createState() => _RefillCodeScreenState();
}

class _RefillCodeScreenState extends State<RefillCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _codeError;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: "Recharge de crédit", 
        showAction: true,  
        showCancelToHome: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // Titre principal
                Text(
                  widget.isGift 
                    ? 'Recharge cadeau'
                    : 'Recharger mon crédit',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Sous-titre avec numéro
                Text(
                  widget.isGift 
                    ? 'Destinataire : ${widget.phoneNumber}'
                    : 'Mon numéro : ${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Champ code de recharge
                _buildRefillCodeField(),
                
                // Erreur code
                if (_codeError != null) ...[
                  const SizedBox(height: 8),
                  _buildErrorMessage(_codeError!),
                ],
                
                const SizedBox(height: 24),
                
                // Information importante
                _buildInfoBox(),
                
                const SizedBox(height: 32),
                
                // Bouton de confirmation
                _buildConfirmButton(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget pour le champ code de recharge
  Widget _buildRefillCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code de recharge',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: _codeError != null 
              ? Border.all(color: Colors.red[300]!, width: 1.5)
              : null,
          ),
          child: TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: '123456789012',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                letterSpacing: 2,
              ),
              prefixIcon: Icon(
                Icons.qr_code,
                color: AppTheme.dtBlue,
              ),
              suffixIcon: _codeController.text.length == 14
                ? Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              // Formater le code avec des espaces pour la lisibilité
              TextInputFormatter.withFunction((oldValue, newValue) {
                String newText = newValue.text.replaceAll(' ', '');
                if (newText.length <= 12) {
                  // Ajouter des espaces tous les 4 chiffres
                  String formatted = '';
                  for (int i = 0; i < newText.length; i += 4) {
                    if (i > 0) formatted += ' ';
                    formatted += newText.substring(
                      i, 
                      i + 4 > newText.length ? newText.length : i + 4
                    );
                  }
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
                return oldValue;
              }),
            ],
            onChanged: (value) {
              _validateCode(value);
            },
          ),
        ),
      ],
    );
  }

  // Widget pour les messages d'erreur
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la boîte d'information
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dtBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dtBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.dtBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Comment utiliser votre code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Grattez la carte pour révéler le code à 12 chiffres\n'
            '• Saisissez le code complet sans espaces ni tirets\n'
            '• Le crédit sera ajouté immédiatement après validation\n'
            '• Chaque code ne peut être utilisé qu\'une seule fois',
            style: TextStyle(
              color: AppTheme.dtBlue,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le bouton de confirmation
  Widget _buildConfirmButton() {
    final cleanCode = _codeController.text.replaceAll(' ', '');
    bool isFormValid = _codeError == null && cleanCode.length == 12;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid && !_isLoading ? _validateAndProcessRefill : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFormValid ? AppTheme.dtBlue2 : Colors.grey[400],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: ResponsiveSize.getFontSize(18),
                ),
                SizedBox(width: ResponsiveSize.getWidth(8)),
                Text(
                  'Confirmer la recharge',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // Validation du code en temps réel
  void _validateCode(String value) {
    final cleanCode = value.replaceAll(' ', '');
    
    setState(() {
      if (cleanCode.isEmpty) {
        _codeError = null;
        return;
      }

      if (cleanCode.length < 12) {
        _codeError = 'Le code doit contenir exactement 12 chiffres';
        return;
      }

      if (!RegExp(r'^\d{12}$').hasMatch(cleanCode)) {
        _codeError = 'Le code ne doit contenir que des chiffres';
        return;
      }

      _codeError = null;
    });
  }

  void _validateAndProcessRefill() async {
    final cleanCode = _codeController.text.replaceAll(' ', '');
    
    if (cleanCode.length != 12) {
      setState(() {
        _codeError = 'Le code doit contenir exactement 12 chiffres';
      });
      return;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(cleanCode)) {
      setState(() {
        _codeError = 'Le code ne doit contenir que des chiffres';
      });
      return;
    }

    // Commencer le chargement
    setState(() {
      _isLoading = true;
      _codeError = null;
    });

    try {
      // Appel API réel
      final response = await RefillService.processRefillCode(
        phoneNumber: widget.phoneNumber,
        voucherCode: cleanCode,
      );
      
      // Si succès, afficher le dialog de réussite
      _showSuccessDialog(response);
      
    } on RefillException catch (e) {
      // Gérer les erreurs spécifiques de recharge
      print('RefillException: ${e.toString()}');
      setState(() {
        _codeError = e.userFriendlyMessage;
      });
    } catch (e, stackTrace) {
      // Gérer les autres erreurs avec plus de détails
      print('Erreur inattendue: $e');
      print('StackTrace: $stackTrace');
      setState(() {
        _codeError = 'Une erreur inattendue est survenue: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(RefillResponse response) {
    // Extraire les informations de la réponse
    final newBalance = RefillService.getNewBalanceFromResponse(response);
    final refillAmount = RefillService.getRefillAmountFromResponse(response);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green[600],
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recharge réussie !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isGift 
                  ? 'La recharge a été effectuée avec succès pour ${widget.phoneNumber}'
                  : 'Votre crédit a été rechargé avec succès',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (refillAmount != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Montant rechargé',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${refillAmount.toStringAsFixed(0)} DJF',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                      if (newBalance != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Nouveau solde : ${newBalance.toStringAsFixed(2)} DJF',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Fermer le dialog et revenir à l'écran principal
                Navigator.of(context).pop(); // Fermer le dialog
                widget.onRefreshSolde?.call(); // Rafraîchir le solde
                Navigator.of(context).pushNamedAndRemoveUntil(
                  HomeScreen as String,
                  (route) => false,
                ); // Retourner à l'écran précédent
              },
              child: Text(
                'Fermer',
                style: TextStyle(
                  color: AppTheme.dtBlue2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}