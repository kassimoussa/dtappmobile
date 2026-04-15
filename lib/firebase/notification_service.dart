import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

import '../screens/core/main_screen.dart';

// Handler pour les notifications en arrière-plan (top-level, obligatoire)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Message reçu en arrière-plan : ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _firebaseMessaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// GlobalKey branché sur MaterialApp.navigatorKey
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> initNotifications() async {
    // 1. Demander la permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permission: ${settings.authorizationStatus}');

    // 2. Log du token FCM
    final token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('FCM TOKEN: $token');
      debugPrint('========================================');
    }

    // 3. Initialiser les notifications locales
    await _initLocalNotifications();

    // 4. Handler arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Notification reçue quand l'app est au premier plan → afficher une notif locale
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground: ${message.notification?.title}');
      if (message.notification != null) {
        _showLocalNotification(message.notification!, message.data);
      }
    });

    // 6. App en arrière-plan → utilisateur tape la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Tap depuis arrière-plan: ${message.data}');
      _handleNavigation(message.data);
    });

    // 7. App fermée (terminated) → utilisateur tape la notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 Tap depuis app fermée: ${initialMessage.data}');
      // Attendre que le navigator soit prêt
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(initialMessage.data);
      });
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = json.decode(details.payload!) as Map<String, dynamic>;
            _handleNavigation(data);
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
      'dtservices_channel',
      'DTServices Notifications',
      channelDescription: 'Notifications DTServices',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: json.encode(data),
    );
  }

  // ─────────────────────────────────────────────
  // Deep linking
  // ─────────────────────────────────────────────

  /// Point d'entrée unique pour toute navigation depuis une notification.
  void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    debugPrint('🎯 Deep link type: $type');

    switch (type) {
      case 'offer_purchase':
      case 'offer_gift':
        _goTo(_buildForfaitsActifsRoute);
        break;
      case 'buy_offer':
        _goTo(_buildBuyOfferRoute);
        break;
      case 'credit_transfer':
        _goTo(_buildTransferRoute);
        break;
      case 'voucher_refill':
        _goTo(_buildRefillRoute);
        break;
      default:
        debugPrint('⚠️ Type inconnu ($type) → accueil');
        _goToHome();
    }
  }

  /// Navigue vers MainScreen puis empile l'écran cible par-dessus.
  void _goTo(Future<Widget?> Function() screenBuilder) async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint('❌ Navigator non disponible');
      return;
    }

    // 1. Aller sur MainScreen en vidant la pile
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );

    // 2. Construire l'écran cible (peut nécessiter des données async)
    final screen = await screenBuilder();
    if (screen == null) return;

    // 3. Empiler l'écran cible
    nav.push(MaterialPageRoute(builder: (_) => screen));
  }

  void _goToHome() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  // ─── Constructeurs d'écrans ───────────────────

  Future<Widget?> _buildForfaitsActifsRoute() async {
    return const ForfaitsActifsScreen();
  }

  Future<Widget?> _buildBuyOfferRoute() async {
    final phone = await UserSession.getPhoneNumber();
    return ForfaitRecipientScreen(phoneNumber: phone);
  }

  Future<Widget?> _buildTransferRoute() async {
    final phone = await UserSession.getPhoneNumber();
    if (phone == null || phone.isEmpty) return null;
    return TransferInputScreen(phoneNumber: phone);
  }

  Future<Widget?> _buildRefillRoute() async {
    final phone = await UserSession.getPhoneNumber();
    return RefillRecipientScreen(phoneNumber: phone);
  }
}
