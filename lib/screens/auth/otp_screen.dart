// lib/screens/auth/otp_screen.dart
import 'package:flutter/material.dart';
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

  // AJOUT - Initialiser l'écoute des SMS
  void _initSmsListener() async {
    try {
      SmsAutoFill().listenForCode;
      debugPrint('Écoute des SMS activée');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de l\'auto-fill: $e');
    }
  }

  // AJOUT - Cette méthode est appelée automatiquement quand un code OTP est détecté
  @override
  void codeUpdated() {
    debugPrint('Code OTP détecté: $code');
    if (code != null && code!.length == 6) {
      setState(() {
        // Remplir automatiquement les champs
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = code![i];
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
    SmsAutoFill().unregisterListener(); // AJOUT - Arrêter l'écoute des SMS
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
      SmsAutoFill().listenForCode;
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

  void _showPinSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusM),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppTheme.dtBlue,
                size: ResponsiveSize.getFontSize(28),
              ),
              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.setupPinTitle,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.setupPinMessage,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save preference: Don't ask again
                await UserSession.setSkipPinSetup(true);

                if (!context.mounted) return;
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.of(context).pushAndRemoveUntil(
                  CustomRouteTransitions.fadeScaleRoute(
                    page: const MainScreen(),
                  ),
                  (route) => false,
                );
              },
              child: Text(
                AppLocalizations.of(context)!.later,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: ResponsiveSize.getFontSize(16),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer le dialog
                Navigator.of(context).push(
                  CustomRouteTransitions.fadeScaleRoute(
                    page: PinSetupScreen(
                      onPinSet: () {
                        // Après configuration du PIN, aller vers MainScreen
                        Navigator.of(context).pushAndRemoveUntil(
                          CustomRouteTransitions.fadeScaleRoute(
                            page: const MainScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                  vertical: ResponsiveSize.getHeight(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveSize.getWidth(AppTheme.radiusM),
                  ),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.setup,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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

        final shouldSkip = await UserSession.shouldSkipPinSetup();
        // Vérifier aussi en local — l'API peut ne pas retourner has_pin
        final localHasPin = await UserSession.hasPin();

        if (authProvider.hasPin || localHasPin || shouldSkip) {
          // PIN déjà configuré OU ignoré => vers MainScreen
          Navigator.of(context).pushAndRemoveUntil(
            CustomRouteTransitions.fadeScaleRoute(page: const MainScreen()),
            (route) => false,
          );
        } else {
          // PIN non configuré => proposer configuration
          _showPinSetupDialog();
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
                _buildGlassAppBar(context),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      onChanged: (value) {
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
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _onOTPSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dtBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveSize.getHeight(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
                  ),
                ),
                child:
                    authProvider.isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          AppLocalizations.of(context)!.verifyAction,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                              child: CircularProgressIndicator(
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

  Widget _buildGlassAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Text(
                  l10n.verificationTitle,
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
}
