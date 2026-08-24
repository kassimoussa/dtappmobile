// lib/screens/auth/otp_screen.dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:async';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';

import '../../routes/custom_route_transitions.dart';
import '../../providers/auth_provider.dart';
import '../core/main_screen.dart';
import 'pin/pin_setup_screen.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/user_session.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final bool isResettingPin;

  const OTPScreen({
    super.key,
    required this.phone,
    this.isResettingPin = false,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with CodeAutoFill {
  // MODIFIÉ
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  String? _errorMessage;

  // Compteur pour le délai de réenvoi
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _initSmsListener();
    _startTimer();
    _setupKeyHandlers();
  }

  // Gère le backspace sur un champ vide pour revenir au champ précédent
  void _setupKeyHandlers() {
    for (int i = 1; i < 6; i++) {
      final index = i;
      _focusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[index].text.isEmpty) {
          _focusNodes[index - 1].requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      };
    }
  }

  // Initialise l'écoute du SMS OTP.
  // On appelle listenForCode() DU MIXIN CodeAutoFill (avec parenthèses !) :
  // il s'abonne au flux `code` ET arme l'API SMS Retriever d'Android.
  // L'ancien `SmsAutoFill().listenForCode;` n'était qu'une référence de
  // méthode jamais appelée → l'écoute ne démarrait jamais.
  void _initSmsListener() async {
    try {
      listenForCode(smsCodeRegexPattern: r'\d{6}');
      debugPrint('Écoute des SMS activée');

      // Android (SMS Retriever) : le SMS OTP doit se terminer par la signature
      // d'app (hash de 11 caractères) sinon le SMS n'est jamais remis à l'app.
      // On loggue ce hash en debug pour le communiquer au backend.
      if (kDebugMode) {
        final signature = await SmsAutoFill().getAppSignature;
        debugPrint('🔑 App signature SMS (à inclure dans le SMS OTP): $signature');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de l\'auto-fill: $e');
    }
  }

  // AJOUT - Cette méthode est appelée automatiquement quand un code OTP est détecté
  @override
  void codeUpdated() {
    debugPrint('Code OTP détecté: $code');
    final detected = code;
    if (detected != null && detected.length == 6) {
      setState(() {
        // Remplir automatiquement les champs
        for (int i = 0; i < 6; i++) {
          _setField(i, detected[i]);
        }
      });

      // Vérifier automatiquement le code après un court délai
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _onOTPSubmit();
        }
      });
    }
  }

  // Écrit un chiffre dans une case. On passe par `value` (et non `text`) pour
  // laisser le curseur après le chiffre : sinon la saisie suivante s'insère
  // avant lui. L'affectation programmatique ne déclenche pas `onChanged`.
  void _setField(int index, String digit) {
    _controllers[index].value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
  }

  // Saisie utilisateur dans une case. Une valeur de plus d'un caractère vient
  // d'un collage (ou d'une suggestion du clavier) : on répartit les chiffres
  // sur les cases suivantes au lieu de n'en garder qu'un.
  void _onFieldChanged(int index, String value) {
    if (value.length > 1) {
      _distributeDigits(value, index);
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (index == 5 && value.isNotEmpty) {
      Future.microtask(() {
        if (mounted) _onOTPSubmit();
      });
    }
  }

  // Répartit une suite de chiffres à partir de `startIndex`. Un code complet
  // (6 chiffres ou plus) repart toujours de la première case, quelle que soit
  // celle dans laquelle il a été collé ; le surplus est ignoré.
  void _distributeDigits(String digits, int startIndex) {
    final start = digits.length >= 6 ? 0 : startIndex;
    var lastFilled = start - 1;

    for (var i = 0; i < digits.length && start + i < 6; i++) {
      _setField(start + i, digits[i]);
      lastFilled = start + i;
    }

    _focusNodes[(lastFilled + 1).clamp(0, 5)].requestFocus();

    if (_controllers.every((c) => c.text.isNotEmpty)) {
      Future.microtask(() {
        if (mounted) _onOTPSubmit();
      });
    }
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    cancel(); // annule l'abonnement au flux du mixin CodeAutoFill
    unregisterListener(); // arrête l'écoute native (SMS Retriever)
    super.dispose();
  }

  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    final authProvider = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final success = await authProvider.sendOtp(widget.phone);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.otpResentSuccess),
          backgroundColor: Colors.green,
        ),
      );
      _startTimer();
      _clearAllFields();
      // Ré-arme SMS Retriever pour le nouveau code (usage unique / expire
      // après 5 min). L'abonnement du mixin reste actif : inutile de rappeler
      // le listenForCode() du mixin (cela créerait un second abonnement).
      SmsAutoFill().listenForCode(smsCodeRegexPattern: r'\d{6}');
    } else {
      final message = _rateLimitMessage(authProvider, l10n)
          ?? authProvider.errorMessage
          ?? l10n.otpResentError;

      setState(() => _errorMessage = message);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: authProvider.rateLimitResult != null
              ? Colors.orange
              : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String? _rateLimitMessage(AuthProvider authProvider, AppLocalizations l10n) {
    final result = authProvider.rateLimitResult;
    if (result == null) return null;
    final wait = result.waitDuration!;
    if (result.windowExceeded) {
      return l10n.otpWindowExceeded(wait.inMinutes + 1);
    }
    return l10n.otpCooldown(wait.inSeconds + 1);
  }

  void _onOTPSubmit() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      final authProvider = context.read<AuthProvider>();

      // Si l'utilisateur est en train de réinitialiser son PIN
      if (widget.isResettingPin) {
        // NE PAS appeler verifyOtp() pour ne pas consommer l'OTP
        // L'endpoint /reset-pin fera la validation de l'OTP lui-même
        // Cela évite le problème de "OTP déjà utilisé"
        Navigator.of(context).pushAndRemoveUntil(
          CustomRouteTransitions.fadeScaleRoute(
            page: PinSetupScreen(
              isResetting: true,
              phoneNumber: widget.phone,
              otpCode: otp,
              onPinSet: () {
                // Après configuration du nouveau PIN, aller vers MainScreen
                Navigator.of(context).pushAndRemoveUntil(
                  CustomRouteTransitions.fadeScaleRoute(
                    page: const MainScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
          (route) => false,
        );
        return;
      }

      // Vérifier OTP via AuthProvider (crée la session et envoie FCM automatiquement)
      final success = await authProvider.verifyOtp(widget.phone, otp);

      if (!mounted) return;

      if (success) {
        // Succès

        // Vérifier aussi en local — l'API peut ne pas retourner has_pin
        final localHasPin = await UserSession.hasPin();

        if (!mounted) return;

        if (authProvider.hasPin || localHasPin) {
          // PIN déjà configuré => vers MainScreen
          Navigator.of(context).pushAndRemoveUntil(
            CustomRouteTransitions.fadeScaleRoute(page: const MainScreen()),
            (route) => false,
          );
        } else {
          // PIN non configuré => configuration obligatoire avant d'accéder à l'app
          Navigator.of(context).pushAndRemoveUntil(
            CustomRouteTransitions.fadeScaleRoute(
              page: PinSetupScreen(
                isMandatory: true,
                onPinSet: () {},
              ),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage =
              authProvider.errorMessage ??
              AppLocalizations.of(context)!.otpInvalid;
          _clearAllFields();
        });
      }
    }
  }

  String formatPhoneNumber(String phone) {
    if (phone.startsWith('+253')) {
      String clean = phone.substring(4);
      if (clean.length == 8) {
        return '+253 ${clean.substring(0, 2)} ${clean.substring(2, 5)} ${clean.substring(5)}';
      }
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final formattedPhone = formatPhoneNumber(widget.phone);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          // Fond cercle radial — identique au PIN screen
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
                  child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              Text(
                AppLocalizations.of(
                  context,
                )!.verificationCodeSentTo(formattedPhone),
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

              // Message d'erreur
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveSize.getWidth(AppTheme.spacingM),
                  ),
                  margin: EdgeInsets.only(
                    bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: ResponsiveSize.getFontSize(20),
                      ),
                      SizedBox(
                        width: ResponsiveSize.getWidth(AppTheme.spacingS),
                      ),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: ResponsiveSize.getFontSize(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: ResponsiveSize.getWidth(45),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autofocus: index == 0,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textAlignVertical:
                          TextAlignVertical.center, // AJOUT : Centrage vertical
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(24),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dtBlue,
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.grey[100],
                        filled: true,
                        // AJOUT : Réduire le padding pour éviter que le texte ne soit coupé
                        contentPadding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.getHeight(8),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveSize.getWidth(AppTheme.radiusS),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        counterText: '',
                      ),
                      // Pas de LengthLimitingTextInputFormatter(1) ici : il
                      // tronquerait un code collé à son premier chiffre avant
                      // même `onChanged`. C'est _onFieldChanged qui ramène
                      // chaque case à un seul chiffre.
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onFieldChanged(index, value),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
              DtButton.primary(
                label: AppLocalizations.of(context)!.verifyAction,
                loading: authProvider.isLoading,
                onPressed: _onOTPSubmit,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Réenvoi de code avec compteur
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed:
                        _canResend && !authProvider.isLoading
                            ? _resendOtp
                            : null,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _canResend ? Colors.grey[600] : Colors.grey[400],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        authProvider.isLoading
                            ? SizedBox(
                              width: ResponsiveSize.getWidth(16),
                              height: ResponsiveSize.getHeight(16),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey,
                                ),
                              ),
                            )
                            : Icon(
                              Icons.refresh,
                              size: ResponsiveSize.getFontSize(16),
                              color:
                                  _canResend
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                            ),
                        SizedBox(width: ResponsiveSize.getWidth(8)),
                        Text(
                          _canResend
                              ? AppLocalizations.of(context)!.resendCode
                              : AppLocalizations.of(
                                context,
                              )!.resendCodeTimer(_secondsRemaining),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(16),
                            decoration:
                                _canResend ? TextDecoration.underline : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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

}
