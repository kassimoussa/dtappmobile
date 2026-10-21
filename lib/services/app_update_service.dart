import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_client.dart';
import '../config/remote_config_service.dart';

/// Ce que l'app doit faire de la version installée.
enum AppUpdateKind {
  /// À jour, ou rien d'exploitable dans la réponse du serveur.
  none,

  /// Une version plus récente existe : on la propose, l'utilisateur peut
  /// remettre à plus tard.
  recommended,

  /// Version trop ancienne : dialogue bloquant, l'app n'est pas utilisable.
  mandatory,
}

/// Mise à jour à présenter à l'utilisateur.
class AppUpdate {
  final AppUpdateKind kind;

  /// Dernière version publiée (sert à ne pas redemander une même version).
  final String latestVersion;

  /// Fiche de l'app sur le store de la plateforme.
  final String storeUrl;

  /// Nouveautés (`release_notes`) ; vide si non renseignées.
  final String notes;

  const AppUpdate({
    required this.kind,
    required this.latestVersion,
    required this.storeUrl,
    this.notes = '',
  });
}

/// Décide si l'utilisateur doit mettre l'app à jour, d'après
/// `GET /api/mobile/app-version?platform=android|ios` (public, appelé avant la
/// connexion ; contrat dans BACKEND_PROMPTS.md).
///
/// Réponse : `latest_version`, `min_version`, `force_update`, `store_url`,
/// `release_notes`. Versions au format `MAJEUR.MINEUR.CORRECTIF` (le numéro de
/// build, après `+`, est ignoré).
///
///  - installée < `min_version` → mise à jour **obligatoire** (bloquante) ;
///  - installée < `latest_version` → **proposée**, ou obligatoire si
///    `force_update` est vrai (interrupteur pour forcer sans toucher au
///    minimum). Une version déjà à jour n'est jamais bloquée : elle n'aurait
///    aucune mise à jour à installer.
///
/// Règle « fail-open » : en cas de doute (serveur injoignable, réponse
/// invalide, aucun lien de store utilisable), on laisse passer plutôt que de
/// bloquer l'utilisateur.
class AppUpdateService {
  AppUpdateService._();

  static const String _path = '/mobile/app-version';

  /// Une mise à jour proposée, repoussée, n'est pas redemandée avant ce délai
  /// (sauf si une version encore plus récente sort entre-temps).
  static const Duration reminderInterval = Duration(days: 3);

  /// Le Splash est déjà long : sans réponse à temps, on laisse passer.
  static const Duration requestTimeout = Duration(seconds: 4);

  static const String _dismissedVersionPref = 'app_update_dismissed_version';
  static const String _dismissedAtPref = 'app_update_dismissed_at';

  /// Interroge le serveur et renvoie la mise à jour à présenter, ou `null`.
  /// Ne lève jamais.
  static Future<AppUpdate?> check() async {
    try {
      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => null,
      };
      if (platform == null) return null;

      final response = await ApiClient.getPublic(
        '$_path?platform=$platform',
      ).timeout(requestTimeout);
      if (response.statusCode != 200) {
        debugPrint('⚠️ AppUpdate: HTTP ${response.statusCode}');
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final dismissedAtMs = prefs.getInt(_dismissedAtPref);

      return parseResponse(
        jsonDecode(utf8.decode(response.bodyBytes)),
        installed: (await PackageInfo.fromPlatform()).version,
        fallbackStoreUrl: RemoteConfigService.storeUrl,
        dismissedVersion: prefs.getString(_dismissedVersionPref),
        dismissedAt:
            dismissedAtMs == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(dismissedAtMs),
        now: DateTime.now(),
      );
    } catch (e) {
      debugPrint('⚠️ AppUpdate: vérification impossible ($e)');
      return null;
    }
  }

  /// Mémorise que l'utilisateur a repoussé cette version proposée.
  static Future<void> markDismissed(AppUpdate update) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedVersionPref, update.latestVersion);
      await prefs.setInt(
        _dismissedAtPref,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('⚠️ AppUpdate: report non mémorisé ($e)');
    }
  }

  /// Lit la réponse JSON du serveur, sans accès au réseau ni au disque. Toute
  /// forme inattendue donne `null` (fail-open).
  ///
  /// [fallbackStoreUrl] sert quand `store_url` est absent ou inutilisable.
  @visibleForTesting
  static AppUpdate? parseResponse(
    Object? decoded, {
    required String installed,
    required String? fallbackStoreUrl,
    String? dismissedVersion,
    DateTime? dismissedAt,
    required DateTime now,
  }) {
    if (decoded is! Map || decoded['success'] != true) return null;
    final data = decoded['data'];
    if (data is! Map) return null;

    String? text(String key) {
      final value = data[key];
      return value is String ? value : null;
    }

    return evaluate(
      installed: installed,
      min: text('min_version'),
      latest: text('latest_version'),
      force: data['force_update'] == true,
      storeUrl: usableStoreUrl(text('store_url')) ?? fallbackStoreUrl,
      notes: text('release_notes') ?? '',
      dismissedVersion: dismissedVersion,
      dismissedAt: dismissedAt,
      now: now,
    );
  }

  /// Le lien tel qu'il est publié par le serveur, s'il est exploitable : une
  /// URL `https` avec un hôte, et pas le gabarit « id000000000 » que le
  /// serveur renvoie pour l'App Store tant que l'app n'y est pas publiée (il
  /// ouvrirait une page inexistante).
  @visibleForTesting
  static String? usableStoreUrl(String? raw) {
    final url = (raw ?? '').trim();
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    if (RegExp(r'/id0+/?$').hasMatch(uri.path)) return null;
    return url;
  }

  /// Logique de décision et de report, sur des valeurs déjà lues.
  @visibleForTesting
  static AppUpdate? evaluate({
    required String installed,
    required String? min,
    required String? latest,
    bool force = false,
    required String? storeUrl,
    String notes = '',
    String? dismissedVersion,
    DateTime? dismissedAt,
    required DateTime now,
  }) {
    // Sans lien de store (iOS tant que l'app n'y est pas publiée), un
    // dialogue bloquant n'enverrait l'utilisateur nulle part.
    if (storeUrl == null) return null;

    final kind = decide(
      installed: installed,
      min: min,
      latest: latest,
      force: force,
    );
    if (kind == AppUpdateKind.none) return null;

    final latestVersion = (latest ?? '').trim();
    if (kind == AppUpdateKind.recommended &&
        dismissedVersion == latestVersion &&
        dismissedAt != null &&
        now.difference(dismissedAt) < reminderInterval) {
      return null;
    }

    return AppUpdate(
      kind: kind,
      latestVersion: latestVersion,
      storeUrl: storeUrl,
      notes: notes.trim(),
    );
  }

  /// Compare la version installée au minimum puis à la dernière version.
  @visibleForTesting
  static AppUpdateKind decide({
    required String installed,
    required String? min,
    required String? latest,
    bool force = false,
  }) {
    final current = parseVersion(installed);
    if (current == null) return AppUpdateKind.none;

    final minimum = parseVersion(min);
    if (minimum != null && _compare(current, minimum) < 0) {
      return AppUpdateKind.mandatory;
    }
    final newest = parseVersion(latest);
    if (newest != null && _compare(current, newest) < 0) {
      return force ? AppUpdateKind.mandatory : AppUpdateKind.recommended;
    }
    return AppUpdateKind.none;
  }

  /// `1.2.3`, `1.2.3+4`, `v1.2` → `[1, 2, 3]`, `[1, 2, 3]`, `[1, 2]` ;
  /// `null` si la valeur n'est pas une version.
  @visibleForTesting
  static List<int>? parseVersion(String? raw) {
    var core = (raw ?? '').trim();
    if (core.startsWith('v') || core.startsWith('V')) core = core.substring(1);
    core = core.split(RegExp(r'[+-]')).first;
    if (core.isEmpty) return null;

    final numbers = <int>[];
    for (final part in core.split('.')) {
      // Que des chiffres : int.tryParse accepterait aussi « -1 » ou « +1 ».
      if (!RegExp(r'^\d+$').hasMatch(part)) return null;
      numbers.add(int.parse(part));
    }
    return numbers;
  }

  /// Négatif si [a] < [b], nul si égales, positif sinon ; une partie absente
  /// vaut 0 (`1.2` = `1.2.0`).
  static int _compare(List<int> a, List<int> b) {
    for (var i = 0; i < math.max(a.length, b.length); i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
