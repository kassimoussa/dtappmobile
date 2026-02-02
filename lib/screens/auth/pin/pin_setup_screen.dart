// lib/screens/auth/pin/pin_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/pin_keyboard.dart';
import '../../../widgets/pin_dots.dart';
import '../../../services/pin_service.dart';

/// Écran de configuration initiale du code PIN
///
/// Affiché après une première connexion OTP réussie
/// Permet à l'utilisateur de créer un PIN pour les connexions futures
class PinSetupScreen extends StatefulWidget {
  final VoidCallback onPinSet;
  final VoidCallback? onSkip;
  final bool isResetting;
  final String? phoneNumber;
  final String? otpCode;

  const PinSetupScreen({
    super.key,
    required this.onPinSet,
    this.onSkip,
    this.isResetting = false,
    this.phoneNumber,
    this.otpCode,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmingPin = false;
  String? _weakPinWarning;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.dtBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.onSkip != null)
            TextButton(
              onPressed: authProvider.isLoading ? null : widget.onSkip,
              child: Text(
                'Passer',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: AppTheme.dtBlue,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                ),
                child: Column(
                  children: [
                    SizedBox(height: ResponsiveSize.getHeight(20)),

                    // Icône
                    Container(
                      padding: EdgeInsets.all(ResponsiveSize.getWidth(20)),
                      decoration: BoxDecoration(
                        color: AppTheme.dtBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: ResponsiveSize.getWidth(60),
                        color: AppTheme.dtBlue,
                      ),
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(24)),

                    // Titre
                    Text(
                      _isConfirmingPin
                          ? 'Confirmez votre code PIN'
                          : 'Créez un code PIN',
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(24),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(8)),

                    // Description
                    Text(
                      _isConfirmingPin
                          ? 'Entrez votre PIN une seconde fois'
                          : 'Créez un code à 4 chiffres pour vous connecter rapidement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(14),
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    // Avertissement pour réinitialisation
                    if (widget.isResetting && !_isConfirmingPin) ...[
                      SizedBox(height: ResponsiveSize.getHeight(16)),
                      Container(
                        padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: Colors.orange.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: ResponsiveSize.getFontSize(18),
                            ),
                            SizedBox(width: ResponsiveSize.getWidth(8)),
                            Expanded(
                              child: Text(
                                'Le code OTP expire dans quelques minutes. Configurez votre PIN rapidement.',
                                style: TextStyle(
                                  fontSize: ResponsiveSize.getFontSize(12),
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: ResponsiveSize.getHeight(40)),

                    // Affichage PIN (4 cercles)
                    PinDots(
                      pinLength:
                          _isConfirmingPin ? _confirmPin.length : _pin.length,
                      maxLength: 4,
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(16)),

                    // Avertissement PIN faible
                    if (_weakPinWarning != null && !_isConfirmingPin)
                      _buildWeakPinWarning(),

                    // Message d'erreur
                    if (authProvider.errorMessage != null)
                      _buildErrorMessage(authProvider.errorMessage!),

                    const Spacer(),

                    // Clavier numérique
                    PinKeyboard(
                      onNumberPressed: (number) {
                        if (_isConfirmingPin) {
                          if (_confirmPin.length < 4) {
                            setState(() {
                              _confirmPin += number;
                            });

                            if (_confirmPin.length == 4) {
                              _submitPin();
                            }
                          }
                        } else {
                          if (_pin.length < 4) {
                            setState(() {
                              _pin += number;
                              _weakPinWarning = null;
                            });

                            if (_pin.length == 4) {
                              _checkWeakPin();
                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () {
                                  if (mounted) {
                                    setState(() {
                                      _isConfirmingPin = true;
                                    });
                                  }
                                },
                              );
                            }
                          }
                        }
                      },
                      onDeletePressed: () {
                        if (_isConfirmingPin) {
                          if (_confirmPin.isNotEmpty) {
                            setState(() {
                              _confirmPin = _confirmPin.substring(
                                0,
                                _confirmPin.length - 1,
                              );
                            });
                          } else {
                            // Retour à la saisie du PIN
                            setState(() {
                              _isConfirmingPin = false;
                              _pin = '';
                              _weakPinWarning = null;
                            });
                          }
                        } else {
                          if (_pin.isNotEmpty) {
                            setState(() {
                              _pin = _pin.substring(0, _pin.length - 1);
                              _weakPinWarning = null;
                            });
                          }
                        }
                      },
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeakPinWarning() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      margin: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(16)),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: Colors.orange[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange[700],
            size: ResponsiveSize.getWidth(24),
          ),
          SizedBox(width: ResponsiveSize.getWidth(12)),
          Expanded(
            child: Text(
              _weakPinWarning!,
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: ResponsiveSize.getFontSize(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      margin: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(16)),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: ResponsiveSize.getWidth(24),
          ),
          SizedBox(width: ResponsiveSize.getWidth(12)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: ResponsiveSize.getFontSize(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkWeakPin() {
    final warning = PinService.getWeakPinWarning(_pin);
    if (warning != null) {
      setState(() {
        _weakPinWarning = warning;
      });
    }
  }

  Future<void> _submitPin() async {
    // Vérifier que les PINs correspondent
    if (_pin != _confirmPin) {
      setState(() {
        _confirmPin = '';
      });

      context.read<AuthProvider>().clearError();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Les codes PIN ne correspondent pas'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    bool success;

    if (widget.isResetting) {
      // Mode réinitialisation : utiliser resetPin avec OTP
      if (widget.phoneNumber == null || widget.otpCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur: informations manquantes pour la réinitialisation'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
      success = await authProvider.resetPin(
        widget.phoneNumber!,
        widget.otpCode!,
        _pin,
        _confirmPin,
      );
    } else {
      // Mode configuration initiale : utiliser setPin
      success = await authProvider.setPin(_pin, _confirmPin);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isResetting
            ? 'Code PIN réinitialisé avec succès !'
            : 'Code PIN configuré avec succès !'),
          backgroundColor: Colors.green[700],
        ),
      );

      widget.onPinSet();
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      // Gestion spécifique pour OTP expiré en mode réinitialisation
      if (widget.isResetting && authProvider.errorMessage != null &&
          (authProvider.errorMessage!.toLowerCase().contains('expiré') ||
           authProvider.errorMessage!.toLowerCase().contains('invalide') ||
           authProvider.errorMessage!.toLowerCase().contains('expired'))) {

        // Afficher dialog avec option de renvoyer OTP
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Code OTP expiré'),
            content: const Text(
              'Le code OTP a expiré. Vous devez obtenir un nouveau code pour réinitialiser votre PIN.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer dialog
                  Navigator.of(context).pop(); // Retour à PinResetScreen
                },
                child: const Text('Obtenir un nouveau code'),
              ),
            ],
          ),
        );
      }

      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirmingPin = false;
        _weakPinWarning = null;
      });
    }
  }

  @override
  void dispose() {
    _pin = '';
    _confirmPin = '';
    super.dispose();
  }
}
