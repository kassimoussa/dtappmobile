// lib/services/seasonal_event_service.dart
import 'dart:convert';

import 'package:dtservices/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/seasonal_event.dart';

/// Animations de fêtes et d'événements, pilotées par le backend
/// (`GET /api/seasonal-event`, contrat : seasonal-event-endpoint.md).
///
/// Comme pour les bannières et le popup : appel public au démarrage, jamais
/// bloquant, et tout échec est silencieux (aucune animation, aucune erreur).
class SeasonalEventService {
  static String get baseUrl => AppConfig.baseUrl;

  /// Jeu d'essai local, pour voir les cinq emplacements sans événement actif
  /// côté serveur : `flutter run --dart-define=SEASONAL_FIXTURE=true`.
  /// Sans effet hors mode debug.
  static const bool _useFixture = bool.fromEnvironment('SEASONAL_FIXTURE');

  /// Événement actif, null s'il n'y en a pas (ou pas encore reçu). N'est
  /// publié qu'une fois les fichiers Lottie chargés : un emplacement ne réserve
  /// donc jamais de place pour une animation qui ne s'affichera pas.
  static final ValueNotifier<SeasonalEvent?> active = ValueNotifier(null);

  static Future<void>? _loading;
  static bool _fetching = false;

  /// Un seul appel par session, sans attente multiple : à lancer depuis le
  /// splash, en parallèle des bannières.
  static Future<void> load() => _loading ??= _fetch();

  /// Relit l'événement (tirer pour rafraîchir) : une fête qui commence ou se
  /// termine pendant que l'app reste ouverte est prise en compte. Un appel déjà
  /// en cours est réutilisé. Ne lève jamais.
  static Future<void> refresh() {
    if (_fetching) return _loading!;
    return _loading = _fetch();
  }

  static bool has(SeasonalPlacement placement) =>
      active.value?.animationsFor(placement).isNotEmpty ?? false;

  static Future<void> _fetch() async {
    _fetching = true;
    try {
      final event =
          (kDebugMode && _useFixture) ? _fixture : await _fetchFromBackend();
      if (event == null) {
        debugPrint('🎉 SeasonalEvent: aucun événement actif');
        // Réponse valide sans événement : il a pris fin, ou n'a jamais existé.
        active.value = null;
        return;
      }

      final loadable = await _keepLoadable(event);
      debugPrint(
        '🎉 SeasonalEvent: "${event.name}" — '
        '${loadable.animations.length}/${event.animations.length} '
        'animation(s) chargée(s)',
      );
      active.value = loadable.animations.isEmpty ? null : loadable;
    } catch (e) {
      // Réseau coupé ou réponse illisible : on garde ce qui est déjà affiché,
      // une erreur ne doit jamais faire disparaître un événement en cours.
      debugPrint('🎉 SeasonalEvent: ignoré ($e)');
    } finally {
      _fetching = false;
    }
  }

  /// Lève une exception si le serveur ne répond pas correctement ; renvoie null
  /// seulement quand il répond explicitement qu'il n'y a pas d'événement.
  static Future<SeasonalEvent?> _fetchFromBackend() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/seasonal-event'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    if (json is! Map || json['success'] != true) {
      throw const FormatException('réponse inattendue');
    }

    final data = json['data'];
    if (data == null) return null;

    final event = SeasonalEvent.tryParse(data);
    if (event == null) throw const FormatException('événement illisible');
    return event;
  }

  /// Charge chaque fichier Lottie (ce qui le met en cache) et écarte ceux qui
  /// échouent. Un fichier introuvable ne doit pas priver les autres de leur
  /// animation.
  static Future<SeasonalEvent> _keepLoadable(SeasonalEvent event) async {
    final results = await Future.wait(
      event.animations.map((spec) async {
        try {
          await spec.provider.load().timeout(const Duration(seconds: 10));
          return spec;
        } catch (e) {
          debugPrint('🎉 SeasonalEvent: animation ${spec.id} ignorée ($e)');
          return null;
        }
      }),
    );
    return event.withAnimations([
      for (final spec in results)
        if (spec != null) spec,
    ]);
  }

  // --- « Une fois par utilisateur et par événement » ---------------------

  static const String _seenKey = 'seasonal_once_seen';

  static String _seenEntry(SeasonalEvent event, SeasonalAnimationSpec spec) =>
      '${event.id}:${spec.id}';

  /// Une animation `infinite` se joue toujours ; une animation `once` une seule
  /// fois par événement, mémorisée sur l'appareil.
  static Future<bool> shouldPlay(
    SeasonalEvent event,
    SeasonalAnimationSpec spec,
  ) async {
    if (spec.loop == SeasonalLoop.infinite) return true;
    // Jeu d'essai : rejouable à chaque lancement.
    if (kDebugMode && _useFixture) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_seenKey) ?? const [];
      return !seen.contains(_seenEntry(event, spec));
    } catch (_) {
      // Mémoire illisible : mieux vaut rejouer que de ne jamais montrer.
      return true;
    }
  }

  static Future<void> markPlayed(
    SeasonalEvent event,
    SeasonalAnimationSpec spec,
  ) async {
    if (spec.loop == SeasonalLoop.infinite) return;
    if (kDebugMode && _useFixture) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getStringList(_seenKey) ?? <String>[];
      final entry = _seenEntry(event, spec);
      if (!seen.contains(entry)) {
        await prefs.setStringList(_seenKey, [...seen, entry]);
      }
    } catch (_) {
      // Sans conséquence : l'animation sera simplement rejouée.
    }
  }

  // --- Jeu d'essai ---------------------------------------------------------

  /// Les deux animations de l'Aïd embarquées, posées aux cinq emplacements.
  static final SeasonalEvent _fixture = SeasonalEvent(
    id: 0,
    name: 'Jeu d\'essai',
    animations: [
      _fixtureAnimation(
        1,
        SeasonalPlacement.headerStrip,
        'dt-aid-croissant',
        SeasonalPosition.topLeft,
        0.2,
      ),
      _fixtureAnimation(
        2,
        SeasonalPlacement.headerStrip,
        'dt-aid-lanterne',
        SeasonalPosition.topRight,
        0.18,
      ),
      _fixtureAnimation(
        3,
        SeasonalPlacement.cardCorner,
        'dt-aid-croissant',
        SeasonalPosition.bottomRight,
        0.27,
      ),
      _fixtureAnimation(
        4,
        SeasonalPlacement.bannerStrip,
        'dt-aid-lanterne',
        SeasonalPosition.centerLeft,
        0.2,
        title: const {'fr': 'Aïd Moubarak !', 'en': 'Eid Mubarak!'},
      ),
      _fixtureAnimation(
        5,
        SeasonalPlacement.overlay,
        'dt-aid-croissant',
        SeasonalPosition.center,
        0.6,
        loop: SeasonalLoop.once,
      ),
      _fixtureAnimation(
        6,
        SeasonalPlacement.splash,
        'dt-aid-lanterne',
        SeasonalPosition.topRight,
        0.3,
        loop: SeasonalLoop.once,
      ),
    ],
  );

  static SeasonalAnimationSpec _fixtureAnimation(
    int id,
    SeasonalPlacement placement,
    String file,
    SeasonalPosition position,
    double widthFraction, {
    SeasonalLoop loop = SeasonalLoop.infinite,
    Map<String, String>? title,
  }) => SeasonalAnimationSpec(
    id: id,
    placement: placement,
    animationUrl:
        '${SeasonalAnimationSpec.assetScheme}assets/lottie/$file.json',
    position: position,
    widthFraction: widthFraction,
    loop: loop,
    title: title,
  );
}
