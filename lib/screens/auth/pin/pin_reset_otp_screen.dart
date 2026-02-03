import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/appbar_widget.dart';
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
      await SmsAutoFill().listenForCode;
      debugPrint('Écoute des SMS activée (PinResetOtpScreen)');
    } catch (e) {
      debugPrint('Erreur init SMS listener: $e');
    }
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
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
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: AppLocalizations.of(context)!.verificationTitle,
        showAction: false,
      ),
      body: SafeArea(
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
                  radius: Radius.circular(AppTheme.radiusM),
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
              SizedBox(
                height: ResponsiveSize.getHeight(52),
                child: ElevatedButton(
                  onPressed:
                      _otpCode.length == 6 && !_isProcessing
                          ? _verifyAndProceed
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dtBlue,
                    foregroundColor: AppTheme.dtYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isProcessing
                          ? SizedBox(
                            height: ResponsiveSize.getHeight(24),
                            width: ResponsiveSize.getWidth(24),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.dtYellow,
                              ),
                            ),
                          )
                          : Text(
                            AppLocalizations.of(context)!.continueText,
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            ],
          ),
        ),
      ),
    );
  }
}
