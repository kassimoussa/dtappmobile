import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

/// Persiste l'historique des notifications et le compteur de badge,
/// scopés par numéro de téléphone pour éviter le mélange entre comptes.
class NotificationStore extends ChangeNotifier {
  static const int _maxStored = 50;

  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  String _phoneNumber = '';
  List<AppNotification> _notifications = [];
  int _badgeCount = 0;

  // Clés dynamiques selon le numéro connecté
  String get _keyNotifications => 'notif_history_$_phoneNumber';
  String get _keyBadgeCount => 'notif_badge_count_$_phoneNumber';

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get badgeCount => _badgeCount;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Appelé à chaque connexion/déconnexion pour charger les notifs du bon compte.
  Future<void> switchUser(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    _notifications = [];
    _badgeCount = 0;
    if (phoneNumber.isNotEmpty) {
      await load();
    } else {
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (_phoneNumber.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyNotifications) ?? [];
    _notifications = raw
        .map((s) {
          try {
            return AppNotification.fromJsonString(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<AppNotification>()
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    _badgeCount = prefs.getInt(_keyBadgeCount) ?? 0;
    notifyListeners();
  }

  Future<void> add(AppNotification notif) async {
    if (_phoneNumber.isEmpty) return;
    _notifications.insert(0, notif);
    if (_notifications.length > _maxStored) {
      _notifications = _notifications.sublist(0, _maxStored);
    }
    _badgeCount++;
    await _persist();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _badgeCount = 0;
    await _persist();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final notif = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => _notifications.first,
    );
    if (!notif.isRead) {
      notif.isRead = true;
      if (_badgeCount > 0) _badgeCount--;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _badgeCount = 0;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_phoneNumber.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyNotifications,
      _notifications.map((n) => n.toJsonString()).toList(),
    );
    await prefs.setInt(_keyBadgeCount, _badgeCount);
  }
}
