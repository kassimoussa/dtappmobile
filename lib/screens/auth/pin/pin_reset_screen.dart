// lib/screens/auth/pin/pin_reset_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/dt_button.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../routes/custom_route_transitions.dart';
import 'pin_reset_otp_screen.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// Écran de réinitialisation du PIN
/// Affiche les informations et permet d'envoyer un OTP pour réinitialiser le PIN
class PinResetScreen extends StatefulWidget {
  final String phoneNumber;

  const PinResetScreen({super.key, required this.phoneNumber});

  @override
  State<PinResetScreen> createState() => _PinResetScreenState();
}

class _PinResetScreenState extends State<PinResetScreen> {
  bool _isLoading = false;

  /// Envoie l'OTP pour la réinitialisation du PIN
  Future<void> _sendOtpForReset() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.sendOtp(widget.phoneNumber);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        // Naviguer vers l'écran dédié de vérification OTP pour réinitialisation
        Navigator.of(context).pushReplacement(
          CustomRouteTransitions.fadeScaleRoute(
            page: PinResetOtpScreen(phoneNumber: widget.phoneNumber),
          ),
        );
      } else {
        // Afficher l'erreur
        _showErrorDialog(
          authProvider.errorMessage ??
              AppLocalizations.of(context)!.otpSendError,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorDialog(AppLocalizations.of(context)!.genericError);
    }
  }

  /// Affiche un dialog d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.errorTitle),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dtBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

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
                GlassAppBar(title: AppLocalizations.of(context)!.resetPinTitle),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                            ResponsiveSize.getWidth(AppTheme.spacingL) * 2,
                      ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: ResponsiveSize.getHeight(AppTheme.spacingXL),
                  ),

                  // Icône
                  Icon(
                    Icons.lock_reset,
                    size: ResponsiveSize.getWidth(70),
                    color: AppTheme.dtBlue,
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

                  // Titre
                  Text(
                    AppLocalizations.of(context)!.forgotPin,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dtBlue,
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

                  // Numéro de téléphone
                  Text(
                    widget.phoneNumber,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(18),
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  SizedBox(
                    height: ResponsiveSize.getHeight(AppTheme.spacingXL),
                  ),

                  // Instructions
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveSize.getWidth(AppTheme.spacingM),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dtBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.dtBlue.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.howItWorks,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dtBlue,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveSize.getHeight(AppTheme.spacingM),
                        ),
                        _buildStep(
                          number: '1',
                          text: AppLocalizations.of(context)!.resetStep1,
                        ),
                        SizedBox(
                          height: ResponsiveSize.getHeight(AppTheme.spacingS),
                        ),
                        _buildStep(
                          number: '2',
                          text: AppLocalizations.of(context)!.resetStep2,
                        ),
                        SizedBox(
                          height: ResponsiveSize.getHeight(AppTheme.spacingS),
                        ),
                        _buildStep(
                          number: '3',
                          text: AppLocalizations.of(context)!.resetStep3,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

                  // Bouton d'envoi
                  DtButton.primary(
                    label: AppLocalizations.of(context)!.sendCode,
                    loading: _isLoading,
                    onPressed: _sendOtpForReset,
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

                  // Bouton annuler
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                ],
              ),
            ),
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


  /// Widget pour afficher une étape
  Widget _buildStep({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ResponsiveSize.getWidth(24),
          height: ResponsiveSize.getHeight(24),
          decoration: const BoxDecoration(
            color: AppTheme.dtBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(12),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtYellow,
            ),
          ),
        ),
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
