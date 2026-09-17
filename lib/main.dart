import 'dart:async';
import 'package:dtservices/config/api_client.dart';
import 'package:dtservices/config/app_config.dart';
import 'package:dtservices/config/failover_http_client.dart';
import 'package:dtservices/config/remote_config_service.dart';
import 'package:dtservices/firebase/notification_service.dart';
import 'package:dtservices/services/fcm_token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/connectivity_banner.dart';
import 'utils/responsive_size.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/balance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/topup_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/language_provider.dart';
import 'services/user_session.dart';
import 'package:dtservices/constants/app_theme.dart';

Future<void> main() async {
  // Tous les appels HTTP de l'app (ApiClient comme http.get/post directs)
  // passent par le client à bascule : si le domaine devient injoignable, les
  // requêtes repartent sur l'IP du même backend, toujours en HTTPS.
  await http.runWithClient(_startApp, () => BackendFailoverClient());
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restaure l'adresse du backend (base publiée par Remote Config lors d'un
  // lancement précédent + dernier hôte joignable) et relance une sonde en
  // arrière-plan. Purement local : marche hors ligne.
  await AppConfig.init();

  // Corrige une faille de sécurité : purge le flag biométrique global
  // hérité et les PIN mis en cache par erreur (voir user_session.dart)
  await UserSession.migrateLegacyBiometricScope();

  // Brancher le navigatorKey partagé pour l'intercepteur 401
  ApiClient.navigatorKey = NotificationService.navigatorKey;

  // Version d'app et plateforme envoyées en en-tête : le backend s'en sert
  // pour qualifier les consentements sans faire confiance au corps.
  unawaited(ApiClient.initClientHeaders());

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BalanceProvider()),
        ChangeNotifierProvider(create: (_) => TopUpProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Firebase initialisé après le premier rendu — notifications uniquement, non bloquant
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // App Check atteste que les requêtes Firebase (FCM, Remote Config)
    // viennent d'une installation authentique de l'app. Les clés du projet
    // sont publiques par nature — elles partent dans l'APK et l'IPA — donc
    // c'est cette attestation, et non leur secret, qui protège le projet.
    //
    // Try séparé : tant que la contrainte n'est pas activée dans la console
    // Firebase, un échec d'attestation ne bloque aucun appel, et il ne doit
    // surtout pas empêcher les notifications et Remote Config de démarrer.
    try {
      await FirebaseAppCheck.instance.activate(
        // En debug : un jeton s'affiche dans les logs au premier lancement,
        // à enregistrer dans la console pour tester l'attestation.
        providerAndroid:
            kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
        providerApple:
            kDebugMode
                ? const AppleDebugProvider()
                : const AppleAppAttestProvider(),
      );
    } catch (e) {
      debugPrint('⚠️ App Check indisponible: $e');
    }

    NotificationService().initNotifications().catchError((error) {
      debugPrint('⚠️ Erreur notifications: $error');
    });
    FCMTokenService.listenToTokenRefresh();

    // Adresse du backend pilotée depuis la console Firebase : permet de
    // déplacer le serveur sans republier l'app. Non bloquant — l'app tourne
    // déjà sur la base restaurée par AppConfig.init().
    unawaited(
      RemoteConfigService.init(
        // Nouvelle adresse : on resonde, l'hôte appris précédemment ne vaut
        // plus pour cette base.
        onBaseChanged: () => unawaited(AppConfig.probe()),
      ),
    );
  } catch (e) {
    debugPrint('⚠️ Erreur Firebase: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    _requestPermissions();

    // Ajouter l'observateur pour le cycle de vie de l'application
    WidgetsBinding.instance.addObserver(this);

    // Indiquer que l'application est au premier plan au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().appResumed();
    });
  }

  @override
  void dispose() {
    // Supprimer l'observateur quand le widget est détruit
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Gérer les changements d'état du cycle de vie de l'application via AuthProvider
    final authProvider = context.read<AuthProvider>();

    switch (state) {
      case AppLifecycleState.resumed:
        // L'application est revenue au premier plan
        authProvider.appResumed().then((_) {
          if (authProvider.sessionExpiredWhileAway) {
            authProvider.clearSessionExpiredFlag();
            debugPrint('Session expirée — redirection vers login');
            NotificationService.navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        });
        break;
      case AppLifecycleState.paused:
        // L'application est mise en pause (en arrière-plan)
        authProvider.appPaused();
        debugPrint('Application passée en arrière-plan');
        break;
      case AppLifecycleState.detached:
        // L'application est fermée
        authProvider.appTerminated();
        debugPrint('Application fermée');
        break;
      default:
        break;
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.phone, Permission.sms].request();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return ConnectivityBanner(
      child: MaterialApp(
        title: 'DJIBTEL',
        debugShowCheckedModeBanner: false,
        navigatorKey: NotificationService.navigatorKey,
        routes: {'/login': (_) => const LoginScreen()},
        // Ferme le clavier dès qu'on tape en dehors d'un champ de saisie.
        // Placé ici plutôt que dans chaque écran : le builder enveloppe toute
        // l'app, y compris les routes poussées et les bottom sheets.
        // translucent laisse passer les taps vers les widgets en dessous, donc
        // boutons, listes et défilement continuent de fonctionner normalement.
        builder:
            (context, child) => GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: child,
            ),
        theme: ThemeData(
          primaryColor: AppTheme.dtBlue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.dtBlue,
            primary: AppTheme.dtBlue,
            secondary: AppTheme.dtYellow,
          ),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: 'Inter',
        ),
        locale: languageProvider.currentLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            // Initialiser le responsive size
            ResponsiveSize.init(context);
            return const SplashScreen();
          },
        ),
      ),
    );
  }
}
