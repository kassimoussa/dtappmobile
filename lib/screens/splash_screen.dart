// lib/screens/splash_screen.dart
import 'package:dtapp3/screens/home_screen.dart';
import 'package:dtapp3/services/user_session.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../extensions/color_extensions.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configuration de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Démarrage de l'animation
    _animationController.forward();
    
    // Vérification et navigation
    //_checkAuthentication();

    _navigateAfterSplash();
  }

  // Méthode pour afficher le splash puis vérifier la session et naviguer
Future<void> _navigateAfterSplash() async {
  // Affiche le splash screen pendant 2 secondes, quelle que soit la validité de la session
  await Future.delayed(const Duration(seconds: 2));

  // Vérifie si l'utilisateur est authentifié après l'affichage du splash
  final isAuthenticated = await UserSession.isAuthenticated();
  final phoneNumber = await UserSession.getPhoneNumber();

  // Navigation vers la page appropriée
  if (!mounted) return; // Vérifie si le widget est toujours monté
  
  if (isAuthenticated && phoneNumber != null) {
    // Utilisateur authentifié, rediriger vers l'écran principal
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(), // Ajustez selon votre écran
      ),
    );
  } else {
    // Utilisateur non authentifié, rediriger vers l'écran de connexion
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(), // Ajustez selon votre écran
      ),
    );
  }
}
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialisation des dimensions responsives
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: AppTheme.dtBlue,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withOpacityValue(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(AppTheme.spacingXL),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animé
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Image.asset(
                            'assets/dtlogo3.webp',
                            width: ResponsiveSize.getWidth(300),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                      
                      // Indicateur de chargement animé
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: ResponsiveSize.getWidth(40),
                          height: ResponsiveSize.getHeight(40),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
                            strokeWidth: ResponsiveSize.isTablet ? 3.5 : 2.5,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                      
                      // Texte de chargement optionnel
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Chargement en cours...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: ResponsiveSize.getFontSize(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}