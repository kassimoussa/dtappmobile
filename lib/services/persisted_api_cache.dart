// lib/services/persisted_api_cache.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Réponses d'API gardées dans SharedPreferences pour tenir quand le serveur
/// tarde ou ne répond pas : forfaits actifs, soldes et packages TopUp.
///
/// Les clés portent le numéro de la ligne (`topup_cache_balances_<mobile>_<fixe>`)
/// et les valeurs des soldes ou des forfaits : rien de cela ne doit survivre à
/// la session de l'utilisateur. [clear] est appelé par `UserSession` à chaque
/// fin de session, quelle qu'en soit la cause.
///
/// Les services d'écriture lisent leurs préfixes ici : un préfixe ajouté ailleurs
/// échapperait au nettoyage, un préfixe ajouté ici est nettoyé d'office.
class PersistedApiCache {
  PersistedApiCache._();

  /// `TopUpApiService` : soldes et packages d'une ligne fixe.
  static const String topUpData = 'topup_cache_';
  static const String topUpTtl = 'topup_ttl_';

  /// `ForfaitActifService` : forfaits actifs, repli quand l'API est en délai.
  static const String forfaitData = 'api_cache_';
  static const String forfaitTtl = 'api_ttl_';

  static const List<String> _prefixes = [
    topUpData,
    topUpTtl,
    forfaitData,
    forfaitTtl,
  ];

  /// Efface toutes les réponses gardées (données et échéances) ; les autres
  /// clés ne sont pas touchées. [prefs] évite de rouvrir le stockage quand
  /// l'appelant l'a déjà.
  static Future<void> clear([SharedPreferences? prefs]) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    final stale = store.getKeys().where(
      (key) => _prefixes.any(key.startsWith),
    );
    for (final key in stale.toList()) {
      await store.remove(key);
    }
  }
}
