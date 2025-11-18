// lib/screens/otp_screen.dart
// VERSION MIGRÉE AVEC PROVIDER

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:async';

import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../routes/custom_route_transitions.dart';
import '../providers/user_session_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/forfait_provider.dart';
import 'main_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phone;

  const OTPScreen({
    super.key,
    required this.phone,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with CodeAutoFill {
  // Contrôleurs pour les 6 champs OTP
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  // État local pour le timer de réenvoi
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _initSmsListener();
    _startTimer();
  }

  @override
  void dispose() {
    // Nettoyer les ressources
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    cancel(); // Arrêter l'écoute SMS
    super.dispose();
  }

  /// Initialise l'écoute automatique des SMS pour l'OTP
  void _initSmsListener() async {
    try {
      SmsAutoFill().listenForCode;
      debugPrint('✅ Écoute des SMS activée pour auto-fill OTP');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'initialisation de l\'auto-fill: $e');
    }
  }

  /// Appelé automatiquement quand un code OTP est détecté dans un SMS
  @override
  void codeUpdated() {
    debugPrint('📱 Code OTP détecté: $code');
    if (code != null && code!.length == 6) {
      setState(() {
        // Remplir automatiquement les 6 champs
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = code![i];
        }
      });

      // Vérifier automatiquement après un court délai
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _onOTPSubmit();
        }
      });
    }
  }

  /// Démarre le compte à rebours pour le réenvoi (60 secondes)
  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

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

  /// Soumet le code OTP pour vérification
  /// UTILISE LE PROVIDER au lieu d'appels directs
  Future<void> _onOTPSubmit() async {
    // Récupérer le code des 6 champs
    final otpCode = _controllers.map((c) => c.text).join();

    if (otpCode.length != 6) {
      _showError('Veuillez entrer le code à 6 chiffres');
      return;
    }

    // ✅ UTILISER LE PROVIDER pour la connexion
    final sessionProvider = Provider.of<UserSessionProvider>(context, listen: false);

    // Le provider gère isLoading automatiquement
    final success = await sessionProvider.login(widget.phone, otpCode);

    if (!mounted) return;

    if (success) {
      // ✅ Connexion réussie !
      debugPrint('✅ Connexion réussie via Provider');

      // Précharger les données pour accélérer l'affichage
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      final forfaitProvider = Provider.of<ForfaitProvider>(context, listen: false);

      // Charger en parallèle (optionnel, l'écran peut aussi le faire)
      Future.wait([
        balanceProvider.fetchBalance(),
        forfaitProvider.fetchForfaits(),
      ]);

      // Naviguer vers l'écran principal
      Navigator.of(context).pushAndRemoveUntil(
        CustomRouteTransitions.fadeScaleRoute(page: const MainScreen()),
        (route) => false,
      );
    } else {
      // ❌ Erreur de connexion
      // L'erreur est déjà dans sessionProvider.error
      _showError(sessionProvider.error ?? 'Code OTP invalide');
    }
  }

  /// Renvoie un nouveau code OTP
  Future<void> _onResendOTP() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
    });

    try {
      // TODO: Appeler le service de réenvoi d'OTP
      // await OtpService.sendOtp(widget.phone);

      debugPrint('📨 Nouveau code OTP envoyé');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un nouveau code a été envoyé'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _startTimer(); // Redémarrer le timer
    } catch (e) {
      debugPrint('❌ Erreur lors du réenvoi: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du réenvoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _canResend = true;
      });
    }
  }

  /// Affiche un message d'erreur
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Gère l'entrée de texte dans un champ OTP
  void _onOTPFieldChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Passer au champ suivant
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Dernier champ, soumettre automatiquement
        _focusNodes[index].unfocus();
        _onOTPSubmit();
      }
    }
  }

  /// Gère la touche de suppression
  void _onOTPFieldKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Si le champ est vide et qu'on appuie sur backspace,
          // revenir au champ précédent
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveSize.width(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveSize.height(20)),

              // Titre
              Text(
                'Vérification',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSize(28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              SizedBox(height: ResponsiveSize.height(12)),

              // Description
              Text(
                'Entrez le code à 6 chiffres envoyé au\n${widget.phone}',
                style: TextStyle(
                  fontSize: ResponsiveSize.fontSize(16),
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),

              SizedBox(height: ResponsiveSize.height(40)),

              // Champs OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return _buildOTPField(index);
                }),
              ),

              SizedBox(height: ResponsiveSize.height(24)),

              // Bouton de réenvoi
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _onResendOTP,
                        child: Text(
                          'Renvoyer le code',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontSize(16),
                            color: AppTheme.dtBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Text(
                        'Renvoyer dans $_secondsRemaining s',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSize(14),
                          color: AppTheme.textSecondary,
                        ),
                      ),
              ),

              SizedBox(height: ResponsiveSize.height(32)),

              // ✅ CONSUMER pour afficher l'état de chargement du provider
              Consumer<UserSessionProvider>(
                builder: (context, sessionProvider, child) {
                  if (sessionProvider.isLoading) {
                    return Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: ResponsiveSize.height(16)),
                          Text(
                            'Vérification en cours...',
                            style: TextStyle(
                              fontSize: ResponsiveSize.fontSize(14),
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              SizedBox(height: ResponsiveSize.height(24)),

              // Bouton de vérification manuelle
              SizedBox(
                width: double.infinity,
                height: ResponsiveSize.height(56),
                child: Consumer<UserSessionProvider>(
                  builder: (context, sessionProvider, child) {
                    return ElevatedButton(
                      onPressed: sessionProvider.isLoading
                          ? null
                          : _onOTPSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dtBlue,
                        disabledBackgroundColor: AppTheme.dtBlue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        sessionProvider.isLoading ? 'Vérification...' : 'Vérifier',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un champ individuel pour un chiffre de l'OTP
  Widget _buildOTPField(int index) {
    return Container(
      width: ResponsiveSize.width(48),
      height: ResponsiveSize.height(56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusS),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? AppTheme.dtBlue
              : AppTheme.textSecondary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onOTPFieldKeyPressed(event, index),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: TextStyle(
            fontSize: ResponsiveSize.fontSize(24),
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          onChanged: (value) => _onOTPFieldChanged(value, index),
        ),
      ),
    );
  }
}
