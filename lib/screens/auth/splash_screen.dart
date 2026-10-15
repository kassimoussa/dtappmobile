// lib/screens/auth/splash_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dtservices/screens/core/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../extensions/color_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../models/banner.dart';
import '../../models/popup.dart';
import '../../services/banner_service.dart';
import '../../models/seasonal_event.dart';
import '../../services/popup_service.dart';
import '../../services/seasonal_event_service.dart';
import '../../widgets/seasonal_animation.dart';
import '../../widgets/staggered_text.dart';
import 'login_screen.dart';
import '../../generated/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Durée minimale du splash, comptée à partir du premier frame.
  static const Duration _splashDuration = Duration(seconds: 5);

  /// Pause avant le début du mouvement : le temps que l'écran se pose et que
  /// le gros du démarrage à froid (premiers frames) soit passé.
  static const Duration _settleDelay = Duration(milliseconds: 800);

  /// Durée de l'animation d'intro (logo, nom, « Chargement »), pilotée par un
  /// seul contrôleur pour que tout reste synchronisé. Elle se joue à la vitesse
  /// normale du Lottie (dt-logo-reveal.json dure 4 s ; seules ses 1,8 premières
  /// secondes servent, les carrés étant en place dès ~1,7 s).
  static const Duration _introDuration = Duration(milliseconds: 1800);

  /// Temps pendant lequel le logo complet reste à l'écran après l'intro.
  static const Duration _holdAfterIntro = Duration(milliseconds: 800);

  static const String _logoAsset = 'assets/lottie/dt-logo-reveal.json';

  /// Bleu des carrés du logo (dt-logo-reveal.json), distinct d'AppTheme.dtBlue.
  static const Color _logoBlue = Color(0xFF284B8D);

  /// Taille de l'animation du logo, et part de sa largeur réellement occupée
  /// par les carrés (de x=48 à x=442 sur le canevas de 500 de
  /// dt-logo-reveal.json). Le nom de l'opérateur est calé sur cette largeur.
  static const double _logoSize = 240;
  static const double _logoContentRatio = 394 / 500;

  /// Part de l'intro pendant laquelle les lettres du nom apparaissent : de
  /// ~0,8 s à la fin, pendant que le logo termine de se construire.
  static const Interval _wordmarkInterval = Interval(0.45, 1.0);

  /// « Chargement » n'apparaît qu'à la fin, une fois le logo et le nom en place.
  static const Interval _loadingInterval = Interval(
    0.75,
    1.0,
    curve: Curves.easeIn,
  );

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// Fichier Lottie chargé en mémoire avant de lancer l'intro, pour que ses
  /// premières images ne paient pas le coût de lecture du fichier.
  LottieComposition? _composition;
  Animation<double>? _lottieProgress;

  @override
  void initState() {
    super.initState();

    // Un seul contrôleur pilote tout le mouvement ; il ne démarre qu'une fois
    // l'écran posé et le fichier Lottie chargé (voir _runSplash).
    _animationController = AnimationController(
      vsync: this,
      duration: _introDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: _loadingInterval),
    );

    _runSplash();
  }

  Future<void> _runSplash() async {
    // Charger le Lottie pendant que l'écran se pose. Un échec (très improbable,
    // le fichier est dans l'application) ne doit pas bloquer le splash.
    final compositionFuture = AssetLottie(_logoAsset)
        .load()
        .then<LottieComposition?>((composition) => composition)
        .catchError((_) => null);

    // Attendre que le premier frame soit réellement dessiné avant de compter
    // le délai : au cold start sur appareil réel le premier rendu peut prendre
    // plusieurs secondes, et le timer expirait avant que le splash soit visible.
    await WidgetsBinding.instance.endOfFrame;
    final minimumDuration = Future<void>.delayed(_splashDuration);

    // Laisser l'œil se poser sur l'écran avant tout mouvement.
    await Future<void>.delayed(_settleDelay);
    final composition = await compositionFuture;
    if (!mounted) return;

    // Précharger bannières/popup en arrière-plan, SANS bloquer l'affichage :
    // l'accueil sait les afficher quand elles arrivent. Lancé après les premiers
    // frames pour ne pas les concurrencer.
    _preloadImages();
    // Animations d'événement : appel en parallèle, jamais bloquant. Si la
    // réponse arrive pendant le splash, l'emplacement `splash` s'anime.
    SeasonalEventService.load();

    setState(() {
      _composition = composition;
      if (composition != null) {
        // Lecture à la vitesse normale : 1,8 s sur les 4 s du fichier.
        final end =
            _introDuration.inMicroseconds / composition.duration.inMicroseconds;
        _lottieProgress = _animationController.drive(
          Tween<double>(begin: 0, end: end.clamp(0.0, 1.0)),
        );
      }
    });

    await _animationController.forward();
    await Future<void>.delayed(_holdAfterIntro);
    // Sur un appareil lent l'intro démarre plus tard : on ne coupe jamais
    // l'animation, la durée de 5 s est un minimum.
    await minimumDuration;

    _goNext();
  }

  void _goNext() {
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
                      // Logo animé (Lottie, une seule lecture : les carrés se
                      // construisent en ~1,7 s puis le logo reste affiché).
                      // L'emplacement est réservé dès le départ : rien ne
                      // bouge quand l'animation démarre.
                      SizedBox.square(
                        dimension: ResponsiveSize.getWidth(_logoSize),
                        child: Stack(
                          children: [
                            if (_composition != null)
                              Positioned.fill(
                                child: Lottie(
                                  composition: _composition,
                                  controller: _lottieProgress,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            // Emplacement `splash` : décor d'événement posé sur
                            // le logo, même canevas que le logo.
                            const Positioned.fill(
                              child: SeasonalSlot(SeasonalPlacement.splash),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingS),
                      ),

                      // Nom de l'opérateur, lettre par lettre, de la même
                      // largeur que les carrés du logo (le FittedBox ajuste la
                      // taille de police : 24 n'est qu'une taille de référence).
                      SizedBox(
                        width: ResponsiveSize.getWidth(
                          _logoSize * _logoContentRatio,
                        ),
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: StaggeredText(
                            text: 'DJIBOUTI TELECOM',
                            progress: _wordmarkInterval.transform(
                              _animationController.value,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              color: _logoBlue,
                              fontSize: 24,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingL),
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
