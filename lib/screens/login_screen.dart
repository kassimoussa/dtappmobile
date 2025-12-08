// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';
import '../routes/custom_route_transitions.dart';
import '../extensions/color_extensions.dart';
import 'otp_screen.dart';
import '../generated/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _savedPhoneNumber;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Vérifier s'il y a un numéro enregistré
    _checkSavedPhoneNumber();

    // Démarrer l'animation après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  Future<void> _checkSavedPhoneNumber() async {
    try {
      final phoneNumber = await UserService.getPhoneNumber();
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        if (mounted) {
          setState(() {
            _savedPhoneNumber = phoneNumber;
            _phoneController.text = phoneNumber;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du numéro sauvegardé: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = _phoneController.text;
    final authProvider = context.read<AuthProvider>();

    // Enregistrer le numéro de téléphone pour pré-remplissage
    await UserService.savePhoneNumber(phoneNumber);

    // Appeler AuthProvider pour envoyer l'OTP
    final success = await authProvider.sendOtp(phoneNumber);

    if (!mounted) return;

    if (success) {
      // Naviguer vers l'écran OTP
      Navigator.push(
        context,
        CustomRouteTransitions.fadeScaleRoute(
          page: OTPScreen(phone: phoneNumber),
        ),
      );
    } else {
      // Afficher erreur via SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
              Expanded(
                child: Text(
                  authProvider.errorMessage ??
                      AppLocalizations.of(context)!.otpSendError,
                  style: TextStyle(fontSize: ResponsiveSize.getFontSize(14)),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusS),
            ),
          ),
          margin: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    // Utiliser AuthProvider pour l'état
    final authProvider = context.watch<AuthProvider>();

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
        },
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: ResponsiveSize.getHeight(
          MediaQuery.of(context).size.height * 0.25,
        ),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusXL),
            ),
            bottomRight: Radius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusXL),
            ),
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
                  AppLocalizations.of(context)!.welcome,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveSize.getFontSize(28),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
                Text(
                  AppLocalizations.of(context)!.loginPrompt,
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
    final authProvider = context.watch<AuthProvider>();

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
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingM),
                ),
                margin: EdgeInsets.only(
                  bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.dtYellow.withOpacityValue(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveSize.getWidth(AppTheme.radiusM),
                  ),
                  border: Border.all(
                    color: AppTheme.dtYellow.withOpacityValue(0.3),
                  ),
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
                        AppLocalizations.of(context)!.savedPhoneNumber,
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
            if (authProvider.errorMessage != null)
              Container(
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingM),
                ),
                margin: EdgeInsets.only(
                  bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveSize.getWidth(AppTheme.radiusM),
                  ),
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
                        authProvider.errorMessage!,
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
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
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
                      borderRadius: BorderRadius.circular(
                        ResponsiveSize.getWidth(AppTheme.radiusS),
                      ),
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
                    return AppLocalizations.of(context)!.phoneValidationError;
                  }
                  if (value.length != 8) {
                    return AppLocalizations.of(context)!.phoneLengthError;
                  }
                  if (!value.startsWith('77')) {
                    return AppLocalizations.of(context)!.phoneStartError;
                  }
                  return null;
                },
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),

            // Bouton de connexion
            ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: AppTheme.dtYellow,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveSize.getHeight(18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveSize.getWidth(AppTheme.radiusM),
                  ),
                ),
                elevation: 2,
              ),
              child:
                  authProvider.isLoading
                      ? SizedBox(
                        width: ResponsiveSize.getWidth(24),
                        height: ResponsiveSize.getHeight(24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.dtYellow,
                          ),
                        ),
                      )
                      : Text(
                        AppLocalizations.of(context)!.continueAction,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

            // Message d'information
            Container(
              padding: EdgeInsets.all(
                ResponsiveSize.getWidth(AppTheme.spacingM),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
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
                      AppLocalizations.of(context)!.smsVerificationMessage,
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
