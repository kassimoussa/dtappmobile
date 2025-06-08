// lib/screens/login_screen.dart (modifié)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../services/user_service.dart';
import '../services/otp_service.dart'; // Importez le nouveau service OTP
import '../routes/custom_route_transitions.dart';
import '../extensions/color_extensions.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _savedPhoneNumber;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Configuration des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Vérifier s'il y a un numéro enregistré
    _checkSavedPhoneNumber();
    
    // Démarrer l'animation après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  Future<void> _checkSavedPhoneNumber() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = await UserService.getPhoneNumber();
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        setState(() {
          _savedPhoneNumber = phoneNumber;
          _phoneController.text = phoneNumber;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du numéro sauvegardé: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final _otpService = OtpService();

// Puis modifiez la méthode _handleLogin comme suit :
// Méthode _handleLogin corrigée pour login_screen.dart
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  final phoneNumber = _phoneController.text;
  // Ajouter le préfixe +253 s'il n'est pas déjà présent
  final fullPhoneNumber = phoneNumber;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Enregistrer le numéro de téléphone
    await UserService.savePhoneNumber(phoneNumber);

    // Appel à l'API pour envoyer l'OTP - utiliser l'instance
    final result = await _otpService.sendOtp(phoneNumber);
    
    debugPrint('Résultat complet de sendOtp: $result');
    
    // Vérifier que result est bien un Map et contient la clé 'status'
    if (result.containsKey('status')) {
      if (result['status'] == 'success') {
        // Naviguer vers l'écran OTP
        if (!mounted) return;
        Navigator.push(
          context,
          CustomRouteTransitions.fadeScaleRoute(
            page: OTPScreen(phone: fullPhoneNumber),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors de l\'envoi du code';
        });
      }
    } else {
      // Cas où la réponse n'a pas le format attendu
      setState(() {
        _errorMessage = 'Réponse inattendue du serveur';
      });
      debugPrint('Format de réponse inattendu: $result');
    }
  } catch (e) {
    debugPrint('Erreur lors de la connexion: $e');
    if (!mounted) return;
    
    setState(() {
      _errorMessage = 'Une erreur est survenue. Veuillez réessayer.';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
            Expanded(
              child: Text(
                'Erreur: ${e.toString()}',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
        ),
        margin: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Column(
            children: [
              // En-tête avec dégradé
              _buildHeader(),
              
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              
              // Formulaire
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildForm(),
                  ),
                ),
              ),
               
            ],
          );
        }
      ),
    );
  }
  
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: ResponsiveSize.getHeight(MediaQuery.of(context).size.height * 0.25),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(ResponsiveSize.getWidth(AppTheme.radiusXL)),
            bottomRight: Radius.circular(ResponsiveSize.getWidth(AppTheme.radiusXL)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.dtBlue.withOpacityValue(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bienvenue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveSize.getFontSize(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
                Text(
                  'Connectez-vous avec votre numéro',
                  style: TextStyle(
                    color: Colors.white.withOpacityValue(0.9),
                    fontSize: ResponsiveSize.getFontSize(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Si un numéro est enregistré, afficher un message
            if (_savedPhoneNumber != null && _savedPhoneNumber!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingM)),
                decoration: BoxDecoration(
                  color: AppTheme.dtYellow.withOpacityValue(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                  border: Border.all(color: AppTheme.dtYellow.withOpacityValue(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.dtYellow,
                      size: ResponsiveSize.getFontSize(20),
                    ),
                    SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                    Expanded(
                      child: Text(
                        'Numéro de téléphone sauvegardé',
                        style: TextStyle(
                          color: AppTheme.dtBlue,
                          fontSize: ResponsiveSize.getFontSize(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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

            // Champ de numéro de téléphone
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacityValue(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(18),
                  color: AppTheme.dtBlue,
                ),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.getWidth(15),
                      vertical: ResponsiveSize.getHeight(6),
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveSize.getWidth(8),
                      vertical: ResponsiveSize.getHeight(8),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                    ),
                    child: Text(
                      '+253',
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dtBlue,
                      ),
                    ),
                  ),
                  border: InputBorder.none,
                  hintText: '77 XX XX XX',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: ResponsiveSize.getFontSize(16),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                    horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre numéro';
                  }
                  if (value.length != 8) {
                    return 'Le numéro doit contenir 8 chiffres';
                  }
                  if (!value.startsWith('77')) {
                    return 'Le numéro doit commencer par 77';
                  }
                  return null;
                },
              ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
            
            // Bouton de connexion
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: AppTheme.dtYellow,
                padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(18)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: ResponsiveSize.getWidth(24),
                      height: ResponsiveSize.getHeight(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
                      ),
                    )
                  : Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            
            // Message d'information
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sms_outlined,
                    color: AppTheme.dtBlue.withOpacityValue(0.7),
                    size: ResponsiveSize.getFontSize(20),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                  Expanded(
                    child: Text(
                      'Un code de vérification vous sera envoyé par SMS',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: ResponsiveSize.getFontSize(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}