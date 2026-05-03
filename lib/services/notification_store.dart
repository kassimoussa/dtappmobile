import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

/// Persiste l'historique des notifications et le compteur de badge.
class NotificationStore extends ChangeNotifier {
  static const _keyNotifications = 'notif_history';
  static const _keyBadgeCount = 'notif_badge_count';
  static const int _maxStored = 50;

  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  List<AppNotification> _notifications = [];
  int _badgeCount = 0;

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);
  int get badgeCount => _badgeCount;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyNotifications,
      _notifications.map((n) => n.toJsonString()).toList(),
    );
    await prefs.setInt(_keyBadgeCount, _badgeCount);
  }
}
