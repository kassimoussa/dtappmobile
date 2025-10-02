import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler pour les notifications en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Message reçu en arrière-plan : ${message.notification?.title}');
}

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

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

      // Afficher la notification locale
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });

    // 6. Gérer l'ouverture de l'application depuis la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification cliquée! Naviguer vers un écran spécifique.');
      // Ajoutez ici la logique de navigation (Deep Linking)
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
        debugPrint('🔔 Notification locale cliquée: ${details.payload}');
        // Gérer le clic sur la notification
      },
    );
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
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

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
    );
  }
}

