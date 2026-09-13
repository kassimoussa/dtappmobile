import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration globale de l'application.
///
/// L'adresse du backend est résolue **à l'exécution**, jamais figée à la
/// compilation. Trois niveaux, du plus prioritaire au plus faible :
///
///  1. **Firebase Remote Config** (`api_base_url`) : permet de déplacer le
///     backend sans republier l'app (voir remote_config_service.dart). La
///     valeur reçue est mémorisée localement, donc elle survit à un démarrage
///     hors ligne.
///  2. **Hôte appris** : sondé au démarrage et corrigé à chaud par le client à
///     bascule (failover_http_client.dart), qui bascule entre [domainHost] et
///     [ipHost] — les deux servent le même backend et présentent chacun un
///     certificat valide. La bascule reste **toujours en HTTPS** : elle
///     contourne une panne DNS, jamais le chiffrement.
///  3. **Valeurs compilées** ci-dessous.
///
/// ⚠️ Deux échéances côté exploitation, critiques depuis que l'app valide
/// réellement les certificats (le contournement `_TrustAllCerts` a été retiré
/// de main.dart) :
///  - [domainHost] : certificat ZeroSSL valable jusqu'au **30/01/2027** ;
///  - [ipHost] : certificat Let's Encrypt **de 6 jours**, donc entièrement
///    dépendant de son renouvellement automatique. À surveiller, sans quoi le
///    filet de secours disparaît silencieusement.
///
/// Le HTTP en clair n'est plus emprunté par aucun chemin de code. L'exception
/// cleartext vers [ipHost] reste ouverte côté plateformes (Android
/// network_security_config.xml, iOS NSAppTransportSecurity) uniquement comme
/// soupape manuelle : publier `http://196.201.193.252` dans Remote Config un
/// jour de panne du 443. À retirer une fois le réseau mobile stable dans la
/// durée.
class AppConfig {
  // ─── Valeurs compilées ────────────────────────────────────────────────────

  /// Domaine du backend — cible par défaut.
  static const String domainHost = 'mydtapp.djiboutitelecom.dj';

  /// IP publique du même backend — secours en cas de panne DNS.
  static const String ipHost = '196.201.193.252';

  /// Hôte compilé par défaut.
  static const String serverHost = domainHost;

  static const String domainBase = 'https://$domainHost';
  static const String ipBase = 'https://$ipHost';

  /// Base compilée par défaut — sert aussi de valeur par défaut Remote Config.
  static const String compiledBase = domainBase;

  // ─── Schéma ───────────────────────────────────────────────────────────────

  static const String httpScheme = 'http';
  static const String httpsScheme = 'https';

  /// Schéma par défaut. Seule une publication Remote Config explicite peut le
  /// faire retomber en HTTP ; aucun mécanisme automatique ne le dégrade.
  static const String preferredScheme = httpsScheme;

  /// En-tête interne : marque une requête de sonde, que le client HTTP doit
  /// laisser passer telle quelle (ni réécriture, ni bascule).
  static const String probeHeader = 'x-dt-scheme-probe';

  /// Route publique et légère utilisée pour tester la joignabilité.
  static const String probePath = '/api/banners';

  static const String _hostKey = 'api_active_host';
  static const String _remoteBaseKey = 'api_remote_base';

  // ─── État courant ─────────────────────────────────────────────────────────

  static String _scheme = preferredScheme;
  static String _host = serverHost;
  static int? _port;
  static String _pathPrefix = '';

  /// Dernière valeur brute reçue de Remote Config et effectivement appliquée.
  static String? _appliedRemoteBase;

  /// Schéma actuellement actif.
  static String get scheme => _scheme;

  /// Hôte actuellement actif.
  static String get host => _host;

  /// Base serveur active, ex. `https://mydtapp.djiboutitelecom.dj`.
  static String get serverBase => _originFor(_host);

  /// Base API active, ex. `https://mydtapp.djiboutitelecom.dj/api`.
  static String get baseUrl => '$serverBase$_pathPrefix/api';

  /// Base distante appliquée, `null` si l'app tourne sur les valeurs compilées.
  static String? get appliedRemoteBase => _appliedRemoteBase;

  static String _originFor(String host) =>
      _port == null ? '$_scheme://$host' : '$_scheme://$host:$_port';

  /// Hôte de secours pour l'hôte actif, ou `null` s'il n'y en a pas : un hôte
  /// publié sur mesure n'a pas de secours devinable.
  static String? get fallbackHost {
    if (_host == domainHost) return ipHost;
    if (_host == ipHost) return domainHost;
    return null;
  }

  /// Base de secours, ou `null`. Même schéma que la base active.
  static String? get fallbackBase {
    final other = fallbackHost;
    return other == null ? null : _originFor(other);
  }

  static bool isKnownHost(String host) => host == domainHost || host == ipHost;

  // ─── Démarrage ────────────────────────────────────────────────────────────

  /// À appeler au démarrage, avant tout appel réseau : restaure la dernière
  /// base distante connue et le dernier hôte joignable, puis lance une sonde en
  /// arrière-plan. Ne dépend ni du réseau ni de Firebase.
  static Future<void> init() async {
    await _loadPersisted();
    unawaited(probe());
  }

  static Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final base = prefs.getString(_remoteBaseKey);
      if (base != null && base.isNotEmpty && _applyBase(base)) {
        _appliedRemoteBase = base;
        debugPrint('🌐 AppConfig: base distante restaurée → $base');
      }

      // L'hôte appris ne s'applique qu'entre les deux hôtes connus : une base
      // publiée sur mesure fait autorité et n'est pas réécrite.
      final saved = prefs.getString(_hostKey);
      if (saved != null && isKnownHost(saved) && isKnownHost(_host)) {
        _host = saved;
        debugPrint('🌐 AppConfig: hôte restauré → $_host');
      }
    } catch (e) {
      debugPrint('⚠️ AppConfig: lecture de la configuration impossible ($e)');
    }
  }

  // ─── Base distante (Firebase Remote Config) ──────────────────────────────

  /// Applique une base publiée à distance, ex. `https://mydtapp.djiboutitelecom.dj`.
  ///
  /// La valeur attendue est l'origine du backend **sans** `/api` (un `/api`
  /// final est toléré et retiré). Une valeur invalide est ignorée : l'app
  /// continue sur la configuration précédente plutôt que de se retrouver sans
  /// backend. Renvoie `true` si la configuration active a changé.
  static Future<bool> applyRemoteBase(String? raw) async {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return false;
    if (value == _appliedRemoteBase) return false;

    if (!_applyBase(value)) {
      debugPrint('⚠️ AppConfig: base distante invalide, ignorée → "$value"');
      return false;
    }

    _appliedRemoteBase = value;
    debugPrint('🌐 AppConfig: base distante appliquée → $baseUrl');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_remoteBaseKey, value);
      // L'hôte appris précédemment ne vaut plus pour cette nouvelle base.
      await prefs.remove(_hostKey);
    } catch (e) {
      debugPrint('⚠️ AppConfig: écriture de la base distante impossible ($e)');
    }
    return true;
  }

  /// Parse et installe une base. Renvoie `false` si la valeur est inutilisable.
  static bool _applyBase(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return false;
    if (uri.scheme != httpScheme && uri.scheme != httpsScheme) return false;
    if (uri.host.isEmpty) return false;

    var prefix = uri.path.replaceAll(RegExp(r'/+$'), '');
    // Tolère une valeur publiée avec le suffixe /api : la base attendue est
    // l'origine, le /api est ajouté par [baseUrl].
    if (prefix.endsWith('/api')) {
      prefix = prefix.substring(0, prefix.length - 4);
    }

    _scheme = uri.scheme;
    _host = uri.host;
    _port = uri.hasPort ? uri.port : null;
    _pathPrefix = prefix;
    return true;
  }

  // ─── Hôte actif ───────────────────────────────────────────────────────────

  /// Fixe l'hôte actif parmi les hôtes connus et le mémorise pour les
  /// prochains lancements.
  static Future<void> setActiveHost(String value) async {
    if (!isKnownHost(value) || _host == value) return;
    _host = value;
    debugPrint('🌐 AppConfig: bascule sur $_host');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_hostKey, value);
    } catch (e) {
      debugPrint('⚠️ AppConfig: écriture de l\'hôte impossible ($e)');
    }
  }

  /// Vérifie que l'hôte actif répond ; sinon bascule sur l'hôte de secours.
  /// Sans effet si aucun des deux ne répond : la configuration est conservée.
  static Future<void> probe({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (await _isReachable(serverBase, timeout)) return;

    final other = fallbackHost;
    final otherBase = fallbackBase;
    if (other == null || otherBase == null) return;

    if (await _isReachable(otherBase, timeout)) {
      await setActiveHost(other);
    } else {
      debugPrint('⚠️ AppConfig: backend injoignable sur les deux hôtes');
    }
  }

  static Future<bool> _isReachable(String origin, Duration timeout) async {
    try {
      final response = await http.get(
        Uri.parse('$origin$_pathPrefix$probePath'),
        headers: const {probeHeader: '1'},
      ).timeout(timeout);
      // Tout code < 500 prouve que le serveur répond (401/404 inclus) ; seul un
      // échec réseau disqualifie l'hôte.
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  // ─── Utilitaires d'URL ────────────────────────────────────────────────────

  /// Vrai si l'URL vise le backend DT (et non un service tiers). Les deux
  /// hôtes connus restent reconnus quel que soit l'hôte actif : des URLs
  /// absolues renvoyées par l'API peuvent référencer l'un ou l'autre.
  static bool isBackend(Uri uri) => uri.host == _host || isKnownHost(uri.host);

  /// Aligne [uri] sur l'origine active (schéma, hôte, port). Laisse intactes
  /// les URLs des services tiers. C'est ce qui fait qu'une URL absolue encore
  /// écrite en `http://196.201.193.252` dans une réponse de l'API part malgré
  /// tout en HTTPS sur l'hôte actif.
  static Uri normalize(Uri uri) {
    if (!isBackend(uri)) return uri;
    final aligned = uri.replace(scheme: _scheme, host: _host);
    return _port == null ? aligned : aligned.replace(port: _port);
  }

  /// Renvoie [uri] portée sur l'hôte de secours, ou `null` s'il n'y en a pas.
  /// Le schéma est conservé : la bascule ne dégrade jamais le chiffrement.
  static Uri? withFallbackHost(Uri uri) {
    final other = fallbackHost;
    if (other == null || !isBackend(uri)) return null;
    return uri.replace(host: other);
  }

  /// Relit la configuration persistée — tests uniquement ([init] le fait déjà
  /// au démarrage, mais en déclenchant aussi la sonde réseau).
  @visibleForTesting
  static Future<void> loadPersistedForTest() => _loadPersisted();

  /// Réinitialise l'état en mémoire — tests uniquement.
  @visibleForTesting
  static void resetForTest() {
    _scheme = preferredScheme;
    _host = serverHost;
    _port = null;
    _pathPrefix = '';
    _appliedRemoteBase = null;
  }
}
