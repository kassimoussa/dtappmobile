// lib/screens/auth/pin/pin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/pin_keyboard.dart';
import '../../../widgets/pin_dots.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../services/user_session.dart';
import '../../core/main_screen.dart';
import 'pin_reset_screen.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// Écran de connexion par code PIN
///
/// Alternative à l'authentification OTP
/// Affiche un clavier numérique pour saisir le PIN à 4 chiffres
class PinLoginScreen extends StatefulWidget {
  final String phoneNumber;

  const PinLoginScreen({super.key, required this.phoneNumber});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _pin = '';
  bool _isProcessing = false;
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
              decoration: BoxDecoration(
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
                _buildGlassAppBar(context, AppLocalizations.of(context)!.pinLoginTitle),
                Expanded(
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

                    SizedBox(height: ResponsiveSize.getHeight(8)),

                    // Numéro de téléphone
                    Text(
                      widget.phoneNumber,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(40)),

                    // Affichage PIN (4 cercles)
                    PinDots(
                      pinLength: _pin.length,
                      maxLength: 4,
                      activeColor: _success ? Colors.green : AppTheme.dtBlue,
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(16)),

                    // Message d'erreur
                    if (authProvider.errorMessage != null)
                      _buildErrorMessage(authProvider),

                    const Spacer(),

                    // Clavier numérique
                    PinKeyboard(
                      onNumberPressed: (number) {
                        if (_pin.length < 4) {
                          setState(() {
                            _pin += number;
                          });

                          // Auto-submit quand 4 chiffres sont saisis
                          if (_pin.length == 4) {
                            _submitPin();
                          }
                        }
                      },
                      onDeletePressed: () {
                        if (_pin.isNotEmpty) {
                          setState(() {
                            _pin = _pin.substring(0, _pin.length - 1);
                          });
                        }
                      },
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(24)),

                    // Lien "PIN oublié"
                    TextButton(
                      onPressed:
                          _isProcessing
                              ? null
                              : () {
                                // Naviguer vers écran de réinitialisation PIN
                                Navigator.of(context).push(
                                  CustomRouteTransitions.slideRightRoute(
                                    page: PinResetScreen(
                                      phoneNumber: widget.phoneNumber,
                                    ),
                                  ),
                                );
                              },
                      child: Text(
                        AppLocalizations.of(context)!.forgotPin,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(16),
                          color: AppTheme.dtBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveSize.getHeight(40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, String title) {
    return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(
            color: AppTheme.white95,
            border: Border(bottom: BorderSide(color: AppTheme.dtBlueO10, width: 0.5)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.white50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildErrorMessage(AuthProvider authProvider) {
    String errorText = authProvider.errorMessage ?? '';

    // Afficher les tentatives restantes si disponibles
    if (authProvider.errorCode == 'invalid_pin' &&
        authProvider.remainingAttempts != null) {
      errorText +=
          '\n${AppLocalizations.of(context)!.remainingAttempts(authProvider.remainingAttempts!)}';
    }

    // Afficher le temps de verrouillage si disponible
    if (authProvider.errorCode == 'account_locked' &&
        authProvider.remainingSeconds != null) {
      final minutes = (authProvider.remainingSeconds! / 60).floor();
      final seconds = authProvider.remainingSeconds! % 60;
      errorText +=
          '\n${AppLocalizations.of(context)!.retryIn(minutes, seconds)}';
    }

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
              errorText,
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

  Future<void> _submitPin() async {
    if (_isProcessing || _pin.length != 4) return;

    setState(() {
      _isProcessing = true;
    });

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.loginWithPin(widget.phoneNumber, _pin);

    if (success) {
      final isBiometricEnabled = await UserSession.isBiometricEnabled();
      if (isBiometricEnabled) {
        await UserSession.saveSecurePin(widget.phoneNumber, _pin);
      }

      if (!mounted) return;

      // Points verts pendant 500ms avant de naviguer
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        CustomRouteTransitions.fadeScaleRoute(page: const MainScreen()),
        (route) => false,
      );
    } else if (!success && mounted) {
      // Reset PIN si erreur
      setState(() {
        _pin = '';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _pin = '';
    super.dispose();
  }
}
