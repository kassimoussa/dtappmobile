import 'package:dtservices/firebase/notification_service.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:dtservices/services/fcm_token_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'utils/responsive_size.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Initialiser les notifications en arrière-plan sans bloquer le démarrage
    NotificationService().initNotifications().catchError((error) {
      debugPrint('⚠️ Erreur lors de l\'initialisation des notifications: $error');
    });

    // Écouter les rafraîchissements de token FCM
    FCMTokenService.listenToTokenRefresh();
    debugPrint('🔔 Écoute des rafraîchissements de token FCM activée');
  } catch (e) {
    debugPrint('⚠️ Erreur lors de l\'initialisation de Firebase: $e');
  }

  // Forcer l'orientation portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Personnaliser la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
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
    UserSession.appResumed();
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

    // Gérer les changements d'état du cycle de vie de l'application
    switch (state) {
      case AppLifecycleState.resumed:
        // L'application est revenue au premier plan
        UserSession.appResumed();
        debugPrint('Application revenue au premier plan');
        break;
      case AppLifecycleState.paused:
        // L'application est mise en pause (en arrière-plan)
        UserSession.appPaused();
        debugPrint('Application passée en arrière-plan');
        break;
      case AppLifecycleState.detached:
        // L'application est fermée
        UserSession.appTerminated();
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
    // Mettre à jour l'activité utilisateur à chaque construction du widget racine
    UserSession.updateActivity();

    return MaterialApp(
      title: 'DTServices',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(
        primaryColor: const Color(0xFF002464),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: Builder(
        builder: (context) {
          // Initialiser le responsive size
          ResponsiveSize.init(context);
          return const SplashScreen();
        },
      ),
    );
  }
}
