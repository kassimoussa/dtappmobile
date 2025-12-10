import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/appbar_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/pin_keyboard.dart';
import '../../../widgets/pin_dots.dart';
import '../../../services/pin_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  // Stages: 0 = Old PIN, 1 = New PIN, 2 = Confirm New PIN
  int _stage = 0;

  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';

  String? _weakPinWarning;

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final authProvider = context.watch<AuthProvider>();

    String title;
    String description;
    String currentPin;

    switch (_stage) {
      case 0:
        title = 'Ancien code PIN';
        description = 'Entrez votre code PIN actuel';
        currentPin = _oldPin;
        break;
      case 1:
        title = 'Nouveau code PIN';
        description = 'Créez un nouveau code à 4 chiffres';
        currentPin = _newPin;
        break;
      case 2:
        title = 'Confirmez le code PIN';
        description = 'Entrez votre nouveau PIN une seconde fois';
        currentPin = _confirmPin;
        break;
      default:
        title = '';
        description = '';
        currentPin = '';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWidget(
        title: 'Modifier le code PIN',
        showAction: false,
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

                    // Titre de l'étape
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(24),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(8)),

                    // Description
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(14),
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(40)),

                    // Affichage PIN (4 cercles)
                    PinDots(pinLength: currentPin.length, maxLength: 4),

                    SizedBox(height: ResponsiveSize.getHeight(16)),

                    // Avertissement PIN faible (seulement pour le nouveau PIN)
                    if (_weakPinWarning != null && _stage == 1)
                      _buildWeakPinWarning(),

                    // Message d'erreur
                    if (authProvider.errorMessage != null)
                      _buildErrorMessage(authProvider.errorMessage!),

                    const Spacer(),

                    // Clavier numérique
                    PinKeyboard(
                      onNumberPressed: (number) {
                        _handleNumberPressed(number);
                      },
                      onDeletePressed: () {
                        _handleDeletePressed();
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

  void _handleNumberPressed(String number) {
    String currentPin = _getCurrentPin();

    if (currentPin.length < 4) {
      setState(() {
        _appendToCurrentPin(number);
      });

      // Nouvelle longueur après ajout
      if (_getCurrentPin().length == 4) {
        _handlePinSubmission();
      }
    }
  }

  void _handleDeletePressed() {
    String currentPin = _getCurrentPin();

    if (currentPin.isNotEmpty) {
      setState(() {
        _removeLastCharFromCurrentPin();
        _weakPinWarning = null;
        context.read<AuthProvider>().clearError();
      });
    } else if (_stage > 0) {
      // Retour à l'étape précédente
      setState(() {
        _stage--;
        _weakPinWarning = null;
        context.read<AuthProvider>().clearError();
        if (_stage == 1) {
          _newPin = '';
        } else if (_stage == 0) {
          _oldPin = '';
        }
      });
    }
  }

  String _getCurrentPin() {
    switch (_stage) {
      case 0:
        return _oldPin;
      case 1:
        return _newPin;
      case 2:
        return _confirmPin;
      default:
        return '';
    }
  }

  void _appendToCurrentPin(String number) {
    switch (_stage) {
      case 0:
        _oldPin += number;
        break;
      case 1:
        _newPin += number;
        if (_newPin.length == 4) _checkWeakPin();
        break;
      case 2:
        _confirmPin += number;
        break;
    }
  }

  void _removeLastCharFromCurrentPin() {
    switch (_stage) {
      case 0:
        _oldPin = _oldPin.substring(0, _oldPin.length - 1);
        break;
      case 1:
        _newPin = _newPin.substring(0, _newPin.length - 1);
        break;
      case 2:
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        break;
    }
  }

  void _handlePinSubmission() {
    if (_stage == 0) {
      // Transition Ancien -> Nouveau
      // On pourrait vérifier l'ancien PIN ici via une API si nécessaire,
      // mais souvent l'API fait le check global à la fin.
      // Pour l'instant, passons simplement à l'étape suivante.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _stage = 1;
          });
        }
      });
    } else if (_stage == 1) {
      // Transition Nouveau -> Confirmation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _stage = 2;
          });
        }
      });
    } else if (_stage == 2) {
      // Validation finale
      _submitChangePin();
    }
  }

  void _checkWeakPin() {
    final warning = PinService.getWeakPinWarning(_newPin);
    if (warning != null) {
      setState(() {
        _weakPinWarning = warning;
      });
    }
  }

  Future<void> _submitChangePin() async {
    // Vérifier que les nouveaux PINs correspondent
    if (_newPin != _confirmPin) {
      setState(() {
        _confirmPin = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Les nouveaux codes PIN ne correspondent pas'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    // Check if new PIN is same as old PIN (optional, but good practice)
    if (_oldPin == _newPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Le nouveau PIN doit être différent de l\'ancien',
          ),
          backgroundColor: Colors.orange[700],
        ),
      );
      setState(() {
        _newPin = '';
        _confirmPin = '';
        _stage = 1;
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.changePin(_oldPin, _newPin, _confirmPin);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code PIN modifié avec succès !'),
          backgroundColor: Colors.green[700],
        ),
      );

      Navigator.of(context).pop();
    } else if (!success && mounted) {
      // Gestion des erreurs
      if (authProvider.errorCode == 'invalid_old_pin' ||
          authProvider.errorMessage?.contains('ancien') == true) {
        // Si l'ancien PIN est incorrect, on reset tout ou juste l'ancien ?
        // UX: Reset juste l'ancien PIN et retour étape 0
        setState(() {
          _oldPin = '';
          _stage = 0; // Retour au début
          _newPin = '';
          _confirmPin = '';
        });
      } else {
        // Autre erreur
        setState(() {
          _confirmPin = '';
          // Reste sur l'étape de confirmation ou retour stage 2
        });
      }
    }
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
}
