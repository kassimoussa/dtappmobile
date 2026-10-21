import 'dart:math' as math;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/remote_config_service.dart';

/// Ce que l'app doit faire de la version installée.
enum AppUpdateKind {
  /// À jour, ou rien d'exploitable dans la configuration.
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

  /// Nouveautés, dans la langue de l'utilisateur ; vide si non renseignées.
  final String notes;

  const AppUpdate({
    required this.kind,
    required this.latestVersion,
    required this.storeUrl,
    this.notes = '',
  });
}

/// Décide si l'utilisateur doit mettre l'app à jour, d'après Firebase Remote
/// Config : même canal que l'adresse du backend, donc ça fonctionne aussi
/// quand le backend est injoignable.
///
/// Paramètres à publier dans la console Firebase (un jeu par plateforme) :
///  - `min_app_version_android` / `min_app_version_ios` : version minimale.
///    En dessous, mise à jour **obligatoire** (dialogue bloquant).
///  - `latest_app_version_android` / `latest_app_version_ios` : dernière
///    version publiée sur le store. En dessous, mise à jour **proposée**.
///  - `update_notes_fr` / `update_notes_en` : nouveautés affichées (facultatif).
///
/// Versions au format `MAJEUR.MINEUR.CORRECTIF` (le numéro de build, après
/// `+`, est ignoré). Une valeur vide ou illisible est ignorée. Pour forcer tout
/// le monde à mettre à jour, il suffit que `min` soit égal à `latest`.
///
/// Règle « fail-open » : en cas de doute (Remote Config indisponible, valeur
/// invalide, aucun lien de store), on laisse passer plutôt que de bloquer.
class AppUpdateService {
  AppUpdateService._();

  static const String minVersionKey = 'min_app_version';
  static const String latestVersionKey = 'latest_app_version';
  static const String notesKey = 'update_notes';

  /// Une mise à jour proposée, repoussée, n'est pas redemandée avant ce délai
  /// (sauf si une version encore plus récente sort entre-temps).
  static const Duration reminderInterval = Duration(days: 3);

  /// Attente maximale du premier fetch Remote Config au démarrage.
  static const Duration readyTimeout = Duration(seconds: 3);

  static const String _dismissedVersionPref = 'app_update_dismissed_version';
  static const String _dismissedAtPref = 'app_update_dismissed_at';

  /// Lit la configuration et renvoie la mise à jour à présenter, ou `null`.
  /// Ne lève jamais.
  static Future<AppUpdate?> check({String languageCode = 'fr'}) async {
    try {
      final suffix = switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => null,
      };
      if (suffix == null) return null;

      // Le premier fetch peut ne pas être terminé au bout du splash ; on
      // l'attend un court instant, sinon on décide avec les valeurs déjà
      // activées lors d'un lancement précédent.
      await RemoteConfigService.ready.timeout(readyTimeout, onTimeout: () {});

      final remoteConfig = FirebaseRemoteConfig.instance;
      final notesLanguage = languageCode == 'en' ? 'en' : 'fr';
      var notes = remoteConfig.getString('${notesKey}_$notesLanguage');
      if (notes.trim().isEmpty) notes = remoteConfig.getString('${notesKey}_fr');

      final prefs = await SharedPreferences.getInstance();
      final dismissedAtMs = prefs.getInt(_dismissedAtPref);

      return evaluate(
        installed: (await PackageInfo.fromPlatform()).version,
        min: remoteConfig.getString('${minVersionKey}_$suffix'),
        latest: remoteConfig.getString('${latestVersionKey}_$suffix'),
        storeUrl: RemoteConfigService.storeUrl,
        notes: notes,
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

  /// Logique de décision, sans accès à Firebase ni au disque.
  @visibleForTesting
  static AppUpdate? evaluate({
    required String installed,
    required String? min,
    required String? latest,
    required String? storeUrl,
    String notes = '',
    String? dismissedVersion,
    DateTime? dismissedAt,
    required DateTime now,
  }) {
    // Sans lien de store (iOS tant que l'app n'y est pas publiée), un
    // dialogue bloquant n'enverrait l'utilisateur nulle part.
    if (storeUrl == null) return null;

    final kind = decide(installed: installed, min: min, latest: latest);
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
  }) {
    final current = parseVersion(installed);
    if (current == null) return AppUpdateKind.none;

    final minimum = parseVersion(min);
    if (minimum != null && _compare(current, minimum) < 0) {
      return AppUpdateKind.mandatory;
    }
    final newest = parseVersion(latest);
    if (newest != null && _compare(current, newest) < 0) {
      return AppUpdateKind.recommended;
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
