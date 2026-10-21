import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// Pilote l'adresse du backend depuis la console Firebase Remote Config.
///
/// Permet de déplacer le backend **sans republier l'application** : il suffit
/// de modifier le paramètre [apiBaseKey] dans la console et de publier.
///
/// Contrat du paramètre :
///  - clé : `api_base_url`
///  - valeur : l'origine du backend, **sans** `/api`
///    (ex. `https://mydtapp.djiboutitelecom.dj`, ou `http://196.201.193.252`,
///    un port explicite est accepté : `https://host:8443`)
///  - une valeur vide ou invalide est ignorée : l'app garde sa configuration
///    précédente plutôt que de se retrouver sans backend.
///
/// Remote Config passe par les serveurs Google, pas par le backend DT : même
/// backend injoignable, une nouvelle adresse peut donc toujours être poussée.
///
/// Sert aussi les liens de la fiche de l'app sur les stores ([storeUrl]), que
/// l'on ne connaît parfois qu'une fois l'app publiée :
///  - clés : `store_url_android` et `store_url_ios`
///  - valeur : URL `https` complète de la fiche (ex.
///    `https://apps.apple.com/app/id<APP_ID>`) ; vide tant que non publiée.
class RemoteConfigService {
  RemoteConfigService._();

  /// Clé du paramètre dans la console Firebase.
  static const String apiBaseKey = 'api_base_url';

  static const String storeUrlAndroidKey = 'store_url_android';
  static const String storeUrlIosKey = 'store_url_ios';

  /// Fiche Play Store, connue d'avance : repli Android quand Remote Config ne
  /// fournit rien d'exploitable.
  static const String compiledPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.djiboutitelecom.dtappmobile';

  /// Lien de la fiche de l'app sur le store de la plateforme courante, ou
  /// `null` si l'app n'y est pas (encore) publiée : l'appelant masque alors
  /// les actions « Partager » et « Noter ».
  static String? get storeUrl {
    String? remote;
    try {
      remote = FirebaseRemoteConfig.instance.getString(_storeKey());
    } catch (_) {
      // Firebase non initialisé : on retombe sur la valeur compilée.
    }
    return resolveStoreUrl(defaultTargetPlatform, remote);
  }

  /// [storeUrl] pointant directement sur l'écran d'avis quand le store le
  /// permet (iOS) ; identique à [storeUrl] sinon.
  static String? get reviewUrl {
    final url = storeUrl;
    return url == null ? null : reviewUrlFor(defaultTargetPlatform, url);
  }

  static String _storeKey() =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? storeUrlIosKey
          : storeUrlAndroidKey;

  /// Valeur Remote Config valide (URL `https`, hôte renseigné) si elle existe,
  /// sinon le repli compilé sur Android, sinon `null`.
  @visibleForTesting
  static String? resolveStoreUrl(TargetPlatform platform, String? remote) {
    final trimmed = remote?.trim() ?? '';
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      return trimmed;
    }
    return platform == TargetPlatform.android ? compiledPlayStoreUrl : null;
  }

  /// Sur iOS, `action=write-review` ouvre directement l'écran d'avis de
  /// l'App Store. Le Play Store n'a pas d'équivalent : lien inchangé.
  @visibleForTesting
  static String reviewUrlFor(TargetPlatform platform, String storeUrl) {
    if (platform != TargetPlatform.iOS) return storeUrl;
    final uri = Uri.parse(storeUrl);
    return uri
        .replace(
          queryParameters: {...uri.queryParameters, 'action': 'write-review'},
        )
        .toString();
  }

  /// En production on ne retélécharge pas plus d'une fois par heure (quota
  /// Firebase) ; en debug, aucune limite pour pouvoir tester immédiatement.
  static Duration get _minimumFetchInterval =>
      kDebugMode ? Duration.zero : const Duration(hours: 1);

  static StreamSubscription<RemoteConfigUpdate>? _updates;

  /// À appeler une fois Firebase initialisé. Ne lève jamais : un échec laisse
  /// l'app sur sa configuration locale.
  ///
  /// [onBaseChanged] est appelé quand l'adresse du backend change réellement
  /// (au fetch initial comme sur une mise à jour temps réel).
  static Future<void> init({VoidCallback? onBaseChanged}) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: _minimumFetchInterval,
        ),
      );
      // Valeur de repli si le paramètre n'existe pas encore côté console.
      await remoteConfig.setDefaults(const {
        apiBaseKey: AppConfig.compiledBase,
        storeUrlAndroidKey: compiledPlayStoreUrl,
        storeUrlIosKey: '',
      });

      await _applyFrom(remoteConfig, onBaseChanged);
      _listenForUpdates(remoteConfig, onBaseChanged);
    } catch (e) {
      debugPrint('⚠️ RemoteConfig: initialisation impossible ($e)');
    }
  }

  static Future<void> _applyFrom(
    FirebaseRemoteConfig remoteConfig,
    VoidCallback? onBaseChanged,
  ) async {
    try {
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      // Hors ligne, quota atteint, projet mal configuré… on continue avec les
      // valeurs déjà activées localement.
      debugPrint('⚠️ RemoteConfig: fetch impossible ($e)');
    }

    final value = remoteConfig.getValue(apiBaseKey);
    // `source` est le seul moyen de distinguer une valeur réellement reçue de
    // la console (valueRemote) du repli local (valueDefault) : les deux
    // peuvent porter exactement la même chaîne.
    debugPrint(
      '🌐 RemoteConfig: fetch=${remoteConfig.lastFetchStatus.name}, '
      'source=${value.source.name}, $apiBaseKey="${value.asString()}"',
    );
    if (value.source != ValueSource.valueRemote) {
      debugPrint(
        '⚠️ RemoteConfig: valeur non reçue de la console — vérifier que le '
        'paramètre $apiBaseKey est publié (modèle client) et que l\'appareil '
        'a du réseau.',
      );
    }

    final changed = await AppConfig.applyRemoteBase(value.asString());
    if (changed) onBaseChanged?.call();
  }

  /// Mises à jour temps réel (Android/iOS) : une publication depuis la console
  /// est appliquée sans attendre le prochain lancement.
  static void _listenForUpdates(
    FirebaseRemoteConfig remoteConfig,
    VoidCallback? onBaseChanged,
  ) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      _updates?.cancel();
      _updates = remoteConfig.onConfigUpdated.listen(
        (update) async {
          final keys = update.updatedKeys;
          final baseUpdated = keys.contains(apiBaseKey);
          final storeUpdated =
              keys.contains(storeUrlAndroidKey) ||
              keys.contains(storeUrlIosKey);
          if (!baseUpdated && !storeUpdated) return;
          try {
            await remoteConfig.activate();
            // Les liens de store sont lus à la demande : l'activation suffit.
            if (!baseUpdated) return;
            final changed = await AppConfig.applyRemoteBase(
              remoteConfig.getString(apiBaseKey),
            );
            if (changed) onBaseChanged?.call();
          } catch (e) {
            debugPrint('⚠️ RemoteConfig: activation impossible ($e)');
          }
        },
        onError:
            (Object e) =>
                debugPrint('⚠️ RemoteConfig: flux temps réel interrompu ($e)'),
      );
    } catch (e) {
      debugPrint('⚠️ RemoteConfig: temps réel indisponible ($e)');
    }
  }

  static Future<void> dispose() async {
    await _updates?.cancel();
    _updates = null;
  }
}
