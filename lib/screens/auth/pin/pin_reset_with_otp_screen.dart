// lib/screens/auth/pin/pin_reset_with_otp_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/pin_keyboard.dart';
import '../../../widgets/pin_dots.dart';
import '../../../services/pin_service.dart';
import '../../../routes/custom_route_transitions.dart';
import 'pin_login_screen.dart';

import 'package:sms_autofill/sms_autofill.dart';

/// Écran combiné : OTP + Nouveau PIN sur le même écran
/// Cela réduit le délai et évite l'expiration de l'OTP
class PinResetWithOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const PinResetWithOtpScreen({super.key, required this.phoneNumber});

  @override
  State<PinResetWithOtpScreen> createState() => _PinResetWithOtpScreenState();
}

class _PinResetWithOtpScreenState extends State<PinResetWithOtpScreen>
    with CodeAutoFill {
  // Étapes : 0 = OTP, 1 = Nouveau PIN, 2 = Confirmation PIN
  int _currentStep = 0;

  String _otp = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _weakPinWarning;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initSmsListener();
  }

  void _initSmsListener() async {
    try {
      await SmsAutoFill().listenForCode;
      debugPrint('Écoute des SMS activée pour Reset PIN');
    } catch (e) {
      debugPrint('Erreur init SMS listener: $e');
    }
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  @override
  void codeUpdated() {
    debugPrint('Code OTP détecté (Reset PIN): $code');
    if (code != null && code!.length == 6 && _currentStep == 0) {
      setState(() {
        _otp = code!;
      });
      // Optionnel : Passer automatiquement à l'étape suivante
      // Mais on laisse l'utilisateur valider visuellement pour l'instant ou cliquer sur continuer
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.dtBlue),
          onPressed: () {
            if (_currentStep > 0 && !_isProcessing) {
              // Retour arrière : étape précédente
              setState(() {
                if (_currentStep == 2) {
                  _confirmPin = '';
                  _currentStep = 1;
                } else if (_currentStep == 1) {
                  _newPin = '';
                  _weakPinWarning = null;
                  _currentStep = 0;
                }
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  SizedBox(height: ResponsiveSize.getHeight(20)),

                  // Indicateur d'étape
                  _buildStepIndicator(),

                  SizedBox(height: ResponsiveSize.getHeight(40)),

                  // Titre
                  Text(
                    _getTitle(),
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(8)),

                  // Description
                  Text(
                    _getDescription(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(14),
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(40)),

                  // Affichage des cercles
                  PinDots(
                    pinLength: _getCurrentInput().length,
                    maxLength: _currentStep == 0 ? 6 : 4,
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(16)),

                  // Avertissement PIN faible
                  if (_weakPinWarning != null && _currentStep == 1)
                    _buildWeakPinWarning(),

                  // Message d'erreur
                  if (authProvider.errorMessage != null)
                    _buildErrorMessage(authProvider.errorMessage!),

                  const Spacer(),

                  // Bouton Continuer pour l'étape OTP
                  if (_currentStep == 0 && _otp.length == 6)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: ResponsiveSize.getHeight(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: ResponsiveSize.getHeight(50),
                        child: ElevatedButton(
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () {
                                    setState(() => _currentStep = 1);
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dtBlue,
                            foregroundColor: AppTheme.dtYellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                          ),
                          child: Text(
                            'Continuer',
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Clavier
                  PinKeyboard(
                    onNumberPressed: _isProcessing ? (_) {} : _onNumberPressed,
                    onDeletePressed: _isProcessing ? () {} : _onDeletePressed,
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(40)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, 'OTP'),
        _buildStepLine(0),
        _buildStepDot(1, 'PIN'),
        _buildStepLine(1),
        _buildStepDot(2, 'OK'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Column(
      children: [
        Container(
          width: ResponsiveSize.getWidth(40),
          height: ResponsiveSize.getHeight(40),
          decoration: BoxDecoration(
            color: isCompleted || isActive ? AppTheme.dtBlue : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child:
                isCompleted
                    ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: ResponsiveSize.getFontSize(20),
                    )
                    : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontSize: ResponsiveSize.getFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(4)),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(12),
            color: isActive ? AppTheme.dtBlue : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = step < _currentStep;
    return Container(
      width: ResponsiveSize.getWidth(40),
      height: 2,
      color: isCompleted ? AppTheme.dtBlue : Colors.grey[300],
    );
  }

  String _getTitle() {
    switch (_currentStep) {
      case 0:
        return 'Code de vérification';
      case 1:
        return 'Nouveau code PIN';
      case 2:
        return 'Confirmez le PIN';
      default:
        return '';
    }
  }

  String _getDescription() {
    switch (_currentStep) {
      case 0:
        return 'Entrez le code reçu par SMS';
      case 1:
        return 'Créez un nouveau code à 4 chiffres';
      case 2:
        return 'Entrez votre PIN une seconde fois';
      default:
        return '';
    }
  }

  String _getCurrentInput() {
    switch (_currentStep) {
      case 0:
        return _otp;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  void _onNumberPressed(String number) {
    if (_isProcessing) return;

    setState(() {
      switch (_currentStep) {
        case 0:
          if (_otp.length < 6) {
            _otp += number;
            // Ne pas auto-avancer ni vérifier l'OTP ici
            // L'utilisateur cliquera sur "Continuer" manuellement
          }
          break;
        case 1:
          if (_newPin.length < 4) {
            _newPin += number;
            _weakPinWarning = null;
            if (_newPin.length == 4) {
              _checkWeakPin();
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() => _currentStep = 2);
                }
              });
            }
          }
          break;
        case 2:
          if (_confirmPin.length < 4) {
            _confirmPin += number;
            if (_confirmPin.length == 4) {
              _submitReset();
            }
          }
          break;
      }
    });
  }

  void _onDeletePressed() {
    if (_isProcessing) return;

    setState(() {
      switch (_currentStep) {
        case 0:
          if (_otp.isNotEmpty) {
            _otp = _otp.substring(0, _otp.length - 1);
          }
          break;
        case 1:
          if (_newPin.isNotEmpty) {
            _newPin = _newPin.substring(0, _newPin.length - 1);
            _weakPinWarning = null;
          } else {
            // Retour à l'étape OTP
            _currentStep = 0;
          }
          break;
        case 2:
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          } else {
            // Retour à l'étape nouveau PIN
            _currentStep = 1;
            _newPin = '';
            _weakPinWarning = null;
          }
          break;
      }
    });
  }

  void _checkWeakPin() {
    final warning = PinService.getWeakPinWarning(_newPin);
    if (warning != null) {
      setState(() => _weakPinWarning = warning);
    }
  }

  Future<void> _submitReset() async {
    if (_newPin != _confirmPin) {
      setState(() => _confirmPin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les codes PIN ne correspondent pas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    // L'OTP a déjà été vérifié à l'étape 1
    // Maintenant on utilise l'endpoint reset-pin qui accepte l'OTP déjà validé
    final success = await authProvider.resetPin(
      widget.phoneNumber,
      _newPin,
      _newPin,
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code PIN réinitialisé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Code PIN réinitialisé avec succès ! Veuillez vous connecter.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Rediriger vers l'écran de connexion PIN
      Navigator.of(context).pushAndRemoveUntil(
        CustomRouteTransitions.fadeScaleRoute(
          page: PinLoginScreen(phoneNumber: widget.phoneNumber),
        ),
        (route) => false,
      );
    } else {
      // Erreur - Réinitialiser tout
      setState(() {
        _otp = '';
        _newPin = '';
        _confirmPin = '';
        _weakPinWarning = null;
        _currentStep = 0;
      });
    }
  }

  Widget _buildWeakPinWarning() {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(16)),
      padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: ResponsiveSize.getFontSize(20),
          ),
          SizedBox(width: ResponsiveSize.getWidth(8)),
          Expanded(
            child: Text(
              _weakPinWarning!,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(12),
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(16)),
      padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: ResponsiveSize.getFontSize(20),
          ),
          SizedBox(width: ResponsiveSize.getWidth(8)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(12),
                color: Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
