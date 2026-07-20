import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../routes/custom_route_transitions.dart';
import '../../../providers/auth_provider.dart';
import 'pin_setup_screen.dart';
import '../../../../generated/l10n/app_localizations.dart';

class PinResetOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const PinResetOtpScreen({super.key, required this.phoneNumber});

  @override
  State<PinResetOtpScreen> createState() => _PinResetOtpScreenState();
}

class _PinResetOtpScreenState extends State<PinResetOtpScreen>
    with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();
  bool _isProcessing = false;
  String _otpCode = "";

  @override
  void initState() {
    super.initState();
    _initSmsListener();
  }

  void _initSmsListener() async {
    try {
      // listenForCode() DU MIXIN (avec parenthèses) : s'abonne au flux `code`
      // et arme SMS Retriever. L'ancienne référence sans () ne démarrait rien.
      listenForCode(smsCodeRegexPattern: r'\d{6}');
      debugPrint('Écoute des SMS activée (PinResetOtpScreen)');
    } catch (e) {
      debugPrint('Erreur init SMS listener: $e');
    }
  }

  @override
  void dispose() {
    cancel(); // annule l'abonnement au flux du mixin CodeAutoFill
    unregisterListener(); // arrête l'écoute native (SMS Retriever)
    _otpController.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    debugPrint('Code OTP détecté: $code');
    if (code != null && code!.length == 6) {
      setState(() {
        _otpCode = code!;
        _otpController.text = code!;
      });
      _verifyAndProceed();
    }
  }

  Future<void> _verifyAndProceed() async {
    if (_otpCode.length != 6) return;

    setState(() => _isProcessing = true);

    // Vérifier l'OTP via AuthProvider (sans créer de session)
    final isValid = await context.read<AuthProvider>().verifyOtpForReset(
      widget.phoneNumber,
      _otpCode,
    );

    if (mounted) {
      setState(() => _isProcessing = false);

      if (isValid) {
        // Navigation vers l'écran de configuration du PIN
        // On n'a plus besoin de passer l'OTP code car il a déjà été vérifié
        Navigator.of(context).push(
          CustomRouteTransitions.fadeScaleRoute(
            page: PinSetupScreen(
              onPinSet: () {
                // Callback non utilisé ici
              },
              isResetting: true,
              phoneNumber: widget.phoneNumber,
              // otpCode: _otpCode, // Plus nécessaire
            ),
          ),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isProcessing = true);

    try {
      final success = await context.read<AuthProvider>().sendOtp(
        widget.phoneNumber,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppLocalizations.of(context)!.codeResentSuccess
                  : AppLocalizations.of(context)!.otpSendError,
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      // Ignorer erreur
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
                GlassAppBar(title: AppLocalizations.of(context)!.verificationTitle),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

              Text(
                AppLocalizations.of(context)!.enterReceivedCode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

              Text(
                AppLocalizations.of(context)!.codeSentTo(widget.phoneNumber),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),

              SizedBox(height: ResponsiveSize.getHeight(40)),

              // Champ OTP stylisé
              PinFieldAutoFill(
                controller: _otpController,
                codeLength: 6,
                autoFocus: true,
                decoration: BoxLooseDecoration(
                  strokeColorBuilder: PinListenColorBuilder(
                    AppTheme.dtBlue,
                    Colors.grey.shade300,
                  ),
                  bgColorBuilder: FixedColorBuilder(Colors.grey.shade50),
                  radius: const Radius.circular(AppTheme.radiusM),
                  gapSpace: ResponsiveSize.getWidth(10),
                ),
                currentCode: _otpCode,
                onCodeSubmitted: (code) {
                  setState(() => _otpCode = code);
                  _verifyAndProceed();
                },
                onCodeChanged: (code) {
                  if (code != null) {
                    setState(() => _otpCode = code);
                    if (code.length == 6) {
                      _verifyAndProceed();
                    }
                  }
                },
              ),

              const Spacer(),

              // Bouton Renvoyer
              Center(
                child: TextButton(
                  onPressed: _isProcessing ? null : _resendCode,
                  child: Text(
                    AppLocalizations.of(context)!.resendCode,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: _isProcessing ? Colors.grey : AppTheme.dtBlue,
                    ),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveSize.getHeight(20)),

              // Bouton Continuer
              DtButton.primary(
                label: AppLocalizations.of(context)!.continueText,
                loading: _isProcessing,
                onPressed:
                    _otpCode.length == 6 ? _verifyAndProceed : null,
              ),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
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

}
