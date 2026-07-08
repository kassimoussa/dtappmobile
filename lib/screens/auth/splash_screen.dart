// lib/screens/auth/splash_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dtservices/screens/core/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../extensions/color_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../models/banner.dart';
import '../../models/popup.dart';
import '../../services/banner_service.dart';
import '../../services/popup_service.dart';
import 'login_screen.dart';
import '../../generated/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
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

  Future<void> _navigateAfterSplash() async {
    // Précharger bannières/popup en arrière-plan, SANS bloquer l'affichage :
    // l'accueil sait les afficher quand elles arrivent. On ne fait donc
    // attendre l'utilisateur que le temps d'une courte animation fixe.
    _preloadImages();

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && authProvider.phoneNumber != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  /// Pré-charge les données bannières/popup et met leurs images en cache
  Future<void> _preloadImages() async {
    try {
      // Lancer les deux requêtes API en parallèle
      final results = await Future.wait<dynamic>([
        BannerService.getBanners().catchError((_) => <PromoBanner>[]),
        PopupService.getPopup().catchError((_) => null),
      ]);

      if (!mounted) return;

      final banners = results[0] as List<PromoBanner>;
      final popup = results[1] as PromoPopup?;

      // Pré-cacher toutes les images dans le cache disque
      final precacheFutures = <Future>[];
      for (final banner in banners) {
        precacheFutures.add(
          precacheImage(CachedNetworkImageProvider(banner.imageUrl), context)
              .catchError((_) {}),
        );
      }
      if (popup != null) {
        precacheFutures.add(
          precacheImage(CachedNetworkImageProvider(popup.imageUrl), context)
              .catchError((_) {}),
        );
      }

      await Future.wait(precacheFutures);
    } catch (_) {
      // Silencieux - les images se chargeront normalement plus tard
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
            colors: [Colors.white, Colors.white.withOpacityValue(0.9)],
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
                            'assets/logos/dtlogo-img-wbg.png',
                            width: ResponsiveSize.getWidth(300),
                            cacheWidth: 600,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingL),
                      ),

                      // Indicateur de chargement animé
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SizedBox(
                          width: ResponsiveSize.getWidth(40),
                          height: ResponsiveSize.getHeight(40),
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.dtBlue,
                            ),
                            strokeWidth: ResponsiveSize.isTablet ? 3.5 : 2.5,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingM),
                      ),

                      // Texte de chargement optionnel
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          AppLocalizations.of(context)!.loading,
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
            },
          ),
        ),
      ),
    );
  }
}
