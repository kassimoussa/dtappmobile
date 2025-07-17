// lib/screens/otp_screen.dart (modifié avec auto-fill SEULEMENT)
import 'package:dtapp3/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart'; // AJOUT
import 'dart:async';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../routes/custom_route_transitions.dart';
import '../services/otp_service.dart';
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

class _OTPScreenState extends State<OTPScreen> with CodeAutoFill { // MODIFIÉ
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  
  // Compteur pour le délai de réenvoi
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _initSmsListener(); // AJOUT
    _startTimer();
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

  final _otpService = OtpService();

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final result = await _otpService.sendOtp(widget.phone);
      debugPrint('Résultat du réenvoi OTP: $result');
      
      if (result.containsKey('status')) {
        if (result['status'] == 'success') {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Un nouveau code a été envoyé'),
              backgroundColor: Colors.green,
            ),
          );
          
          _startTimer();
          _clearAllFields();
          
          // AJOUT - Réactiver l'écoute SMS après réenvoi
          SmsAutoFill().listenForCode;
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Erreur lors de l\'envoi du code';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Réponse inattendue du serveur';
        });
        debugPrint('Format de réponse inattendu lors du réenvoi: $result');
      }
    } catch (e) {
      debugPrint('Erreur lors du réenvoi du code: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erreur lors du réenvoi du code';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _onOTPSubmit() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      setState(() {
        _isVerifying = true;
        _errorMessage = null;
      });

      try {
        final result = await _otpService.verifyOtp(widget.phone, otp);
        debugPrint('Résultat de la vérification OTP: $result');
        
        if (result.containsKey('status')) {
          if (result['status'] == 'success') {
            await UserSession.createSession(widget.phone);
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              CustomRouteTransitions.fadeScaleRoute(
                page: const MainScreen(),
              ),
              (route) => false,
            );
          } else {
            setState(() {
              _errorMessage = result['message'] ?? 'Code OTP incorrect';
              _clearAllFields();
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Réponse inattendue du serveur';
            _clearAllFields();
          });
          debugPrint('Format de réponse inattendu lors de la vérification: $result');
        }
      } catch (e) {
        debugPrint('Erreur lors de la vérification: $e');
        if (!mounted) return;
        
        setState(() {
          _errorMessage = 'Une erreur est survenue lors de la vérification';
          _clearAllFields();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
        }
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
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: AppTheme.dtBlue,
            size: ResponsiveSize.getFontSize(24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vérification',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              Text(
                'Un code a été envoyé au $formattedPhone',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
              
              // Message d'erreur
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                  margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingM)),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: ResponsiveSize.getFontSize(20),
                      ),
                      SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
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
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(24),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dtBlue,
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
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
                          _onOTPSubmit();
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
              ElevatedButton(
                onPressed: _isVerifying ? null : _onOTPSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dtBlue,
                  foregroundColor: AppTheme.dtYellow,
                  padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                  ),
                ),
                child: _isVerifying
                    ? SizedBox(
                        width: ResponsiveSize.getWidth(24),
                        height: ResponsiveSize.getHeight(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
                        ),
                      )
                    : Text(
                        'Vérifier',
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
                    onPressed: _canResend && !_isResending ? _resendOtp : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _canResend ? Colors.grey[600] : Colors.grey[400],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isResending 
                          ? SizedBox(
                              width: ResponsiveSize.getWidth(16),
                              height: ResponsiveSize.getHeight(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            )
                          : Icon(
                              Icons.refresh,
                              size: ResponsiveSize.getFontSize(16),
                              color: _canResend ? Colors.grey[600] : Colors.grey[400],
                            ),
                        SizedBox(width: ResponsiveSize.getWidth(8)),
                        Text(
                          _canResend 
                            ? 'Renvoyer le code' 
                            : 'Renvoyer le code (${_secondsRemaining}s)',
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(16),
                            decoration: _canResend ? TextDecoration.underline : null,
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
    );
  }
}