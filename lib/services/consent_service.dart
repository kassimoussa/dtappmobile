import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_client.dart';

/// Consentement versionné aux documents juridiques.
///
/// Remplace l'ancien booléen `privacy_policy_accepted`, qui ne permettait ni de
/// savoir quelle version un utilisateur avait acceptée, ni de le re-solliciter
/// après une révision : le booléen restait vrai à vie.
///
/// Trois principes :
///  1. **La version acceptée est mémorisée localement**, document par document.
///     Une révision côté serveur rend le consentement caduc et l'écran
///     d'acceptation réapparaît.
///  2. **L'app ne dépend jamais du réseau pour afficher l'écran.** L'acceptation
///     précède la connexion ; si `/api/legal/versions` est injoignable, on
///     retombe sur le cache puis sur [bundledVersions], compilé dans le binaire.
///  3. **La preuve part au serveur dès que possible.** Le consentement donné
///     avant authentification est tamponné, puis transmis à la première
///     connexion réussie — d'où [flushPending].
class ConsentService {
  ConsentService._();

  static const String privacyDoc = 'privacy_policy';
  static const String termsDoc = 'terms_of_service';
  static const List<String> documents = [privacyDoc, termsDoc];

  /// Versions embarquées : filet de sécurité quand le serveur est injoignable.
  /// À mettre à jour en même temps que le texte des écrans juridiques.
  static const Map<String, String> bundledVersions = {
    privacyDoc: '2026-08-02',
    termsDoc: '2026-08-02',
  };

  static const String actionAccepted = 'accepted';
  static const String actionDeclined = 'declined';

  static const String _acceptedKey = 'consent_accepted_versions';
  static const String _pendingKey = 'consent_pending_uploads';
  static const String _requiredKey = 'consent_required_versions';

  /// Documents que le serveur déclare en attente (bloc `legal.pending` des
  /// réponses de connexion et de profil). Vaut par-dessus la comparaison
  /// locale : le serveur sait ce qu'il a réellement enregistré.
  static Set<String> _serverPending = {};

  // ─── Versions en vigueur ──────────────────────────────────────────────────

  /// Mémorisation pour la durée de la session : évite de rappeler le serveur à
  /// chaque question, sans jamais figer les versions d'un lancement à l'autre.
  /// Seul un appel réussi est mémorisé — un repli hors ligne doit pouvoir être
  /// retenté plus tard dans la même session.
  static Map<String, RequiredVersion>? _memo;

  /// Versions exigées, par document, avec l'indication de re-consentement.
  ///
  /// Interroge `/api/legal/versions` (route publique, donc utilisable avant
  /// connexion) et met le résultat en cache. En cas d'échec : dernier cache
  /// connu, sinon [bundledVersions].
  ///
  /// Le réseau est interrogé en premier, le cache n'est qu'un filet : le lire
  /// en priorité rendrait l'app aveugle à toute révision publiée.
  static Future<Map<String, RequiredVersion>> requiredVersions({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _memo != null) return _memo!;

    try {
      // Délai court et volontaire : cet appel conditionne l'affichage de
      // l'écran de connexion. Mieux vaut retomber sur les versions connues que
      // faire patienter l'utilisateur derrière un endpoint qui traîne.
      final response = await ApiClient.getPublic('/legal/versions')
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'success' && body['data'] is Map) {
          final parsed = <String, RequiredVersion>{};
          (body['data'] as Map).forEach((key, value) {
            if (value is Map && value['version'] is String) {
              parsed[key as String] = RequiredVersion(
                version: value['version'] as String,
                requiresReacceptance: value['requires_reacceptance'] == true,
              );
            }
          });
          if (parsed.isNotEmpty) {
            _memo = parsed;
            await _cacheRequired(parsed);
            return parsed;
          }
        }
      }
      debugPrint('⚠️ Consent: /legal/versions inattendu (${response.statusCode})');
    } catch (e) {
      debugPrint('⚠️ Consent: /legal/versions injoignable ($e)');
    }

    return await _readCachedRequired() ?? _bundledAsRequired();
  }

  static Map<String, RequiredVersion> _bundledAsRequired() =>
      bundledVersions.map((doc, version) => MapEntry(
            doc,
            RequiredVersion(version: version, requiresReacceptance: true),
          ));

  static Future<Map<String, RequiredVersion>?> _readCachedRequired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_requiredKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = <String, RequiredVersion>{};
      map.forEach((key, value) {
        parsed[key] = RequiredVersion(
          version: value['version'] as String,
          requiresReacceptance: value['requires_reacceptance'] == true,
        );
      });
      return parsed.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _cacheRequired(Map<String, RequiredVersion> v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _requiredKey,
        jsonEncode(v.map((doc, r) => MapEntry(doc, {
              'version': r.version,
              'requires_reacceptance': r.requiresReacceptance,
            }))),
      );
    } catch (e) {
      debugPrint('⚠️ Consent: cache des versions impossible ($e)');
    }
  }

  // ─── Décision de l'utilisateur ────────────────────────────────────────────

  /// Documents restant à faire accepter. Vide = rien à demander.
  ///
  /// Un document n'est demandé que s'il est marqué `requires_reacceptance` :
  /// une correction de forme publiée côté serveur ne dérange personne.
  ///
  /// [refresh] réinterroge le serveur au lieu de se fier aux versions déjà
  /// connues pour cette session. À utiliser au moment où la décision compte —
  /// à la connexion — pour qu'une révision publiée pendant que l'app tournait
  /// soit prise en compte immédiatement.
  static Future<List<String>> pendingDocuments({bool refresh = false}) async {
    final required = await requiredVersions(forceRefresh: refresh);
    final accepted = await acceptedVersions();

    return documents.where((doc) {
      final req = required[doc];
      if (req == null) return false;
      if (_serverPending.contains(doc)) return true;
      if (!req.requiresReacceptance) return false;
      return accepted[doc] != req.version;
    }).toList();
  }

  /// Enregistre la décision de l'utilisateur sur [docs] : mémorisation locale
  /// (acceptation seulement) et mise en file pour transmission au serveur.
  static Future<void> record({
    required List<String> docs,
    required String action,
    required String locale,
  }) async {
    if (docs.isEmpty) return;
    final required = await requiredVersions();
    final now = DateTime.now().toUtc().toIso8601String();

    final entries = <Map<String, dynamic>>[];
    final accepted = await acceptedVersions();

    for (final doc in docs) {
      final version = required[doc]?.version ?? bundledVersions[doc];
      if (version == null) continue;
      entries.add({
        'document': doc,
        'version': version,
        'action': action,
        'accepted_at': now,
        'locale': locale,
      });
      if (action == actionAccepted) {
        accepted[doc] = version;
      } else {
        // Un refus annule le consentement précédent : le document redevient
        // à demander tant que l'utilisateur n'a pas accepté la version en cours.
        accepted.remove(doc);
      }
    }

    await _writeAccepted(accepted);
    await _queue(entries);
    _serverPending.removeAll(docs);

    // Transmission immédiate si une session existe déjà ; sinon la file part
    // à la prochaine connexion réussie.
    await flushPending();
  }

  static Future<Map<String, String>> acceptedVersions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_acceptedKey);
      if (raw == null) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeAccepted(Map<String, String> accepted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_acceptedKey, jsonEncode(accepted));
    } catch (e) {
      debugPrint('⚠️ Consent: écriture des acceptations impossible ($e)');
    }
  }

  // ─── Transmission au serveur ──────────────────────────────────────────────

  static Future<void> _queue(List<Map<String, dynamic>> entries) async {
    if (entries.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = _decodeQueue(prefs.getString(_pendingKey));
      current.addAll(entries);
      await prefs.setString(_pendingKey, jsonEncode(current));
    } catch (e) {
      debugPrint('⚠️ Consent: mise en file impossible ($e)');
    }
  }

  static List<Map<String, dynamic>> _decodeQueue(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Transmet les consentements en attente. À appeler après chaque
  /// authentification réussie : le consentement donné avant connexion n'a pas
  /// de session pour partir au moment où il est donné.
  ///
  /// Sans session, l'appel est sans effet et la file est conservée.
  static Future<void> flushPending() async {
    List<Map<String, dynamic>> queued;
    try {
      final prefs = await SharedPreferences.getInstance();
      queued = _decodeQueue(prefs.getString(_pendingKey));
    } catch (_) {
      return;
    }
    if (queued.isEmpty) return;

    final sent = await _post(queued);
    if (!sent) {
      // Horodatage refusé (horloge du téléphone faussée) : on rejoue une fois
      // en laissant le serveur dater, sinon le consentement ne serait jamais
      // enregistré et l'utilisateur serait re-sollicité à chaque connexion.
      final withoutDate = queued
          .map((e) => Map<String, dynamic>.from(e)..remove('accepted_at'))
          .toList();
      if (!await _post(withoutDate)) return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingKey);
    } catch (_) {}
  }

  static Future<bool> _post(List<Map<String, dynamic>> consents) async {
    try {
      final response =
          await ApiClient.post('/mobile/consents', {'consents': consents});
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Consent: ${consents.length} consentement(s) enregistré(s)');
        return true;
      }
      debugPrint('⚠️ Consent: envoi refusé (${response.statusCode})');
      return false;
    } catch (e) {
      debugPrint('⚠️ Consent: envoi impossible ($e)');
      return false;
    }
  }

  /// Applique le bloc `legal.pending` d'une réponse de connexion ou de profil.
  /// Le serveur fait autorité : il sait ce qu'il a réellement enregistré, y
  /// compris pour un consentement donné depuis un autre appareil.
  static void applyServerPending(dynamic legalBlock) {
    if (legalBlock is! Map) return;
    final pending = legalBlock['pending'];
    if (pending is! List) return;
    _serverPending = pending.whereType<String>().toSet();
    if (_serverPending.isNotEmpty) {
      debugPrint('📄 Consent: le serveur réclame $_serverPending');
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _serverPending = {};
    _memo = null;
  }
}

/// Version exigée pour un document, telle que publiée par le serveur.
class RequiredVersion {
  final String version;
  final bool requiresReacceptance;

  const RequiredVersion({
    required this.version,
    required this.requiresReacceptance,
  });
}
