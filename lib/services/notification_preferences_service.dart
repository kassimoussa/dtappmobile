import 'package:shared_preferences/shared_preferences.dart';

/// Préférences de notification de l'utilisateur.
///
/// Persistées localement (SharedPreferences). ⚠️ Pour que ces choix filtrent
/// RÉELLEMENT les push envoyés, ils doivent être synchronisés côté serveur :
/// voir [NotificationPreferencesService.save] (TODO backend) et l'endpoint
/// `/mobile/notification-preferences`.
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

  Map<String, bool> toJson() => {
        'transactions': transactions,
        'offers': offers,
        'balance': balance,
        'security': security,
      };
}

class NotificationPreferencesService {
  static const String _prefix = 'notif_pref_';

  static Future<NotificationPreferences> load() async {
    final p = await SharedPreferences.getInstance();
    return NotificationPreferences(
      transactions: p.getBool('${_prefix}transactions') ?? true,
      offers: p.getBool('${_prefix}offers') ?? true,
      balance: p.getBool('${_prefix}balance') ?? true,
      security: p.getBool('${_prefix}security') ?? true,
    );
  }

  static Future<void> save(NotificationPreferences prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('${_prefix}transactions', prefs.transactions);
    await p.setBool('${_prefix}offers', prefs.offers);
    await p.setBool('${_prefix}balance', prefs.balance);
    await p.setBool('${_prefix}security', prefs.security);

    // TODO(backend): pousser prefs.toJson() vers
    //   PUT {baseUrl}/mobile/notification-preferences (avec le session token)
    // afin que le serveur filtre réellement les notifications envoyées.
  }
}
