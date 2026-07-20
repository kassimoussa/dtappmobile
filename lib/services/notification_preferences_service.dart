import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_client.dart';

/// Préférences de notification de l'utilisateur.
///
/// Source de vérité : le serveur (`/mobile/notification-preferences`), qui
/// filtre réellement les push envoyés. Une copie locale (SharedPreferences) sert
/// de repli hors-ligne et d'affichage instantané.
class NotificationPreferences {
  final bool transactions;
  final bool offers;
  final bool balance;
  final bool security;

  const NotificationPreferences({
    this.transactions = true,
    this.offers = true,
    this.balance = true,
    this.security = true,
  });

  NotificationPreferences copyWith({
    bool? transactions,
    bool? offers,
    bool? balance,
    bool? security,
  }) {
    return NotificationPreferences(
      transactions: transactions ?? this.transactions,
      offers: offers ?? this.offers,
      balance: balance ?? this.balance,
      security: security ?? this.security,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      transactions: _asBool(json['transactions']),
      offers: _asBool(json['offers']),
      balance: _asBool(json['balance']),
      security: _asBool(json['security']),
    );
  }

  Map<String, bool> toJson() => {
        'transactions': transactions,
        'offers': offers,
        'balance': balance,
        'security': security,
      };

  /// Tolère bool / 0-1 / "true"/"1" (les back-ends sérialisent parfois en int).
  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return true; // défaut : activé
  }
}

class NotificationPreferencesService {
  static const String _endpoint = '/mobile/notification-preferences';
  static const String _prefix = 'notif_pref_';

  /// Charge depuis le serveur ; repli sur le cache local en cas d'erreur.
  static Future<NotificationPreferences> load() async {
    try {
      final res = await ApiClient.get(_endpoint);
      debugPrint('NotifPrefs load: GET ${res.statusCode} — ${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final prefs = NotificationPreferences.fromJson(data);
          await _cacheLocal(prefs);
          return prefs;
        }
      }
    } catch (e) {
      debugPrint('NotifPrefs load: erreur $e → repli cache local');
    }
    return _loadLocal();
  }

  /// Écrit en local (optimiste) puis synchronise avec le serveur.
  /// Renvoie true si la synchro serveur a réussi.
  static Future<bool> save(NotificationPreferences prefs) async {
    await _cacheLocal(prefs);
    try {
      final res = await ApiClient.put(_endpoint, prefs.toJson());
      debugPrint('NotifPrefs save: PUT ${res.statusCode} — ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('NotifPrefs save: erreur $e');
      return false;
    }
  }

  static Future<NotificationPreferences> _loadLocal() async {
    final p = await SharedPreferences.getInstance();
    return NotificationPreferences(
      transactions: p.getBool('${_prefix}transactions') ?? true,
      offers: p.getBool('${_prefix}offers') ?? true,
      balance: p.getBool('${_prefix}balance') ?? true,
      security: p.getBool('${_prefix}security') ?? true,
    );
  }

  static Future<void> _cacheLocal(NotificationPreferences prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('${_prefix}transactions', prefs.transactions);
    await p.setBool('${_prefix}offers', prefs.offers);
    await p.setBool('${_prefix}balance', prefs.balance);
    await p.setBool('${_prefix}security', prefs.security);
  }
}
