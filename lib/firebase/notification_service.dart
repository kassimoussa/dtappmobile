import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

// Handler pour les notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Message reçu en arrière-plan : ${message.notification?.title}');
}

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // GlobalKey pour la navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initNotifications() async {
    // 1. Demander la permission (surtout crucial pour iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('🔔 User granted permission: ${settings.authorizationStatus}');

    // 2. Obtenir le Token FCM
    String? token = await _firebaseMessaging.getToken();
    debugPrint("🔑 FCM Token: $token");
    if (kDebugMode) {
      print("========================================");
      print("FCM TOKEN:");
      print(token);
      print("========================================");
    }

    // TRÈS IMPORTANT : Stockez ce token dans votre base de données (Firestore, Realtime DB, ou votre serveur backend)
    // pour pouvoir envoyer des notifications ciblées à cet utilisateur.

    // 3. Initialiser les notifications locales
    await _initLocalNotifications();

    // 4. Configurer le handler pour les messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Gérer les messages au premier plan (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Message reçu au premier plan : ${message.notification?.title}');
      debugPrint('📦 Données: ${message.data}');

      // Afficher la notification locale avec les données
      if (message.notification != null) {
        _showLocalNotification(message.notification!, message.data);
      }
    });

    // 6. Gérer l'ouverture de l'application depuis la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification cliquée!');
      debugPrint('📦 Données: ${message.data}');
      _handleNotificationNavigation(message.data);
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification locale cliquée');
        if (details.payload != null) {
          try {
            final data = json.decode(details.payload!);
            _handleNotificationNavigation(data);
          } catch (e) {
            debugPrint('❌ Erreur décodage payload: $e');
          }
        }
      },
    );
  }

  Future<void> _showLocalNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Notifications',
      channelDescription: 'Canal de notifications par défaut',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convertir les données en JSON pour le payload
    final payload = json.encode(data);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Gère la navigation contextuelle selon le type de notification
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('❌ Context de navigation non disponible');
      return;
    }

    final type = data['type'];
    debugPrint('🎯 Navigation vers type: $type');

    switch (type) {
      case 'offer_purchase':
        _navigateToOffers(context, data);
        break;
      case 'credit_transfer':
        _navigateToBalance(context, data);
        break;
      case 'voucher_refill':
        _navigateToBalance(context, data);
        break;
      case 'offer_gift':
        _navigateToOffers(context, data);
        break;
      default:
        debugPrint('⚠️ Type de notification inconnu: $type');
        _navigateToHome(context);
    }
  }

  /// Navigation vers l'écran des offres/forfaits
  void _navigateToOffers(BuildContext context, Map<String, dynamic> data) {
    debugPrint('📱 Navigation vers écran des forfaits');
    // L'utilisateur peut voir ses forfaits actifs
    Navigator.of(context).pushNamed('/forfaits_actifs');
  }

  /// Navigation vers l'écran de solde/accueil
  void _navigateToBalance(BuildContext context, Map<String, dynamic> data) {
    debugPrint('💰 Navigation vers écran d\'accueil (solde)');
    // L'écran d'accueil affiche le solde
    Navigator.of(context).pushNamed('/home');
  }

  /// Navigation vers l'écran d'accueil par défaut
  void _navigateToHome(BuildContext context) {
    debugPrint('🏠 Navigation vers écran d\'accueil');
    Navigator.of(context).pushNamed('/home');
  }
}

