import 'dart:convert';
import 'package:dtservices/models/app_notification.dart';
import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/services/notification_store.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:dtservices/widgets/in_app_notification_banner.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/core/main_screen.dart';

// ─── Canaux Android ──────────────────────────────────────────────────────────

const _chTransactionsId = 'dtservices_transactions';
const _chPromotionsId = 'dtservices_promotions';
const _chSecurityId = 'dtservices_security';

const _chTransactions = AndroidNotificationChannel(
  _chTransactionsId,
  'Transactions',
  description: 'Transferts, recharges et achats',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

const _chPromotions = AndroidNotificationChannel(
  _chPromotionsId,
  'Promotions',
  description: 'Offres et forfaits',
  importance: Importance.defaultImportance,
  playSound: false,
  enableVibration: false,
);

const _chSecurity = AndroidNotificationChannel(
  _chSecurityId,
  'Sécurité',
  description: 'OTP et alertes de sécurité',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// ─── Background handler (top-level, obligatoire) ─────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Message reçu en arrière-plan : ${message.notification?.title}');
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> initNotifications() async {
    final supported = await _fcm.isSupported();
    if (!supported) {
      debugPrint('⚠️ FCM non supporté sur cet appareil');
      return;
    }

    NotificationSettings settings;
    try {
      settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 Permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('⚠️ Impossible de demander la permission FCM: $e');
      return;
    }

    try {
      final token = await _fcm.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (kDebugMode) {
        debugPrint('========================================');
        debugPrint('FCM TOKEN: $token');
        debugPrint('========================================');
      }
    } catch (e) {
      debugPrint('⚠️ Token FCM indisponible: $e');
    }

    await _initLocalNotifications();
    await NotificationStore().load();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground → bannière in-app + stockage
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground: ${message.notification?.title}');
      if (message.notification != null) {
        _handleIncoming(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          data: message.data,
          foreground: true,
        );
      }
    });

    // Background → tap sur la notif
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Tap depuis arrière-plan: ${message.data}');
      _handleNavigation(message.data);
    });

    // App fermée → tap sur la notif
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 Tap depuis app fermée: ${initialMessage.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(initialMessage.data);
      });
    }
  }

  // ─── Canaux locaux ────────────────────────────────────────────────────────

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
            final data =
                jsonDecode(details.payload!) as Map<String, dynamic>;
            _handleNavigation(data);
          } catch (e) {
            debugPrint('❌ Erreur décodage payload: $e');
          }
        }
      },
    );

    // Créer les canaux Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_chTransactions);
    await androidPlugin?.createNotificationChannel(_chPromotions);
    await androidPlugin?.createNotificationChannel(_chSecurity);
  }

  // ─── Réception unifiée ────────────────────────────────────────────────────

  Future<void> _handleIncoming({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    bool foreground = false,
  }) async {
    final type = data['type'] as String?;
    final channel = AppNotification.channelFromType(type);
    // Bannière in-app affichée AVANT tout await (pas de gap async)
    if (foreground) {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay != null) {
        InAppNotificationBanner.show(
          overlay: overlay,
          title: title,
          body: body,
          channel: channel,
          onTap: () => _handleNavigation(data),
        );
      }
    }

    // Persistance et notif système en async
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      channel: channel,
      receivedAt: DateTime.now(),
      data: data,
    );
    await NotificationStore().add(notif);

    if (!foreground) {
      await _showSystemNotification(
        title: title,
        body: body,
        channel: channel,
        data: data,
      );
    }
  }

  Future<void> _showSystemNotification({
    required String title,
    required String body,
    required NotificationChannel channel,
    required Map<String, dynamic> data,
  }) async {
    final badgeCount = NotificationStore().badgeCount;

    final (channelId, importance, priority) = switch (channel) {
      NotificationChannel.transactions => (
          _chTransactionsId,
          Importance.high,
          Priority.high
        ),
      NotificationChannel.security => (
          _chSecurityId,
          Importance.max,
          Priority.max
        ),
      NotificationChannel.promotions => (
          _chPromotionsId,
          Importance.defaultImportance,
          Priority.defaultPriority
        ),
    };

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channel.name,
      importance: importance,
      priority: priority,
      showWhen: true,
      number: badgeCount,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: channel != NotificationChannel.promotions,
        badgeNumber: badgeCount,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
  }

  // ─── Notification solde bas (locale, sans serveur) ────────────────────────

  Future<void> checkAndNotifyLowBalance(double balance,
      {double threshold = 500}) async {
    if (balance >= threshold) return;

    const title = 'Solde faible';
    final body =
        'Votre solde est de ${balance.toStringAsFixed(0)} DJF. Pensez à recharger.';
    const data = <String, dynamic>{'type': 'low_balance'};

    await _handleIncoming(
      title: title,
      body: body,
      data: data,
      foreground: navigatorKey.currentState?.overlay != null,
    );
  }

  // ─── Deep linking ─────────────────────────────────────────────────────────

  void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    debugPrint('🎯 Deep link type: $type');

    switch (type) {
      case 'offer_purchase':
      case 'offer_gift':
        _goTo(_buildForfaitsActifsRoute);
      case 'buy_offer':
        _goTo(_buildBuyOfferRoute);
      case 'credit_transfer':
        _goTo(_buildTransferRoute);
      case 'voucher_refill':
        _goTo(_buildRefillRoute);
      default:
        debugPrint('⚠️ Type inconnu ($type) → accueil');
        _goToHome();
    }
  }

  void _goTo(Future<Widget?> Function() screenBuilder) async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint('❌ Navigator non disponible');
      return;
    }
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
    final screen = await screenBuilder();
    if (screen == null) return;
    nav.push(MaterialPageRoute(builder: (_) => screen));
  }

  void _goToHome() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  // ─── Constructeurs d'écrans ───────────────────────────────────────────────

  Future<Widget?> _buildForfaitsActifsRoute() async =>
      const ForfaitsActifsScreen();

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
