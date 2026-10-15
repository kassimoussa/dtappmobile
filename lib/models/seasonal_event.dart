// lib/models/seasonal_event.dart
import 'package:dtservices/config/app_config.dart';
import 'package:flutter/painting.dart';
import 'package:lottie/lottie.dart';

/// Emplacements d'animation que l'application sait dessiner. Une valeur
/// inconnue envoyée par le backend est ignorée (voir [fromWire]) : c'est ce qui
/// permet à une ancienne version de ne jamais casser.
///
/// Contrat complet : seasonal-event-endpoint.md.
enum SeasonalPlacement {
  headerStrip(
    'header_strip',
    SeasonalPosition.topRight,
    0.2,
    SeasonalLoop.infinite,
  ),
  overlay('overlay', SeasonalPosition.center, 1.0, SeasonalLoop.once),
  cardCorner(
    'card_corner',
    SeasonalPosition.bottomRight,
    0.27,
    SeasonalLoop.infinite,
  ),
  bannerStrip(
    'banner_strip',
    SeasonalPosition.centerLeft,
    0.2,
    SeasonalLoop.infinite,
  ),
  splash('splash', SeasonalPosition.center, 1.0, SeasonalLoop.once);

  const SeasonalPlacement(
    this.wire,
    this.defaultPosition,
    this.defaultWidthFraction,
    this.defaultLoop,
  );

  /// Valeur échangée avec le backend.
  final String wire;

  /// Valeurs utilisées quand le backend n'en envoie pas.
  final SeasonalPosition defaultPosition;
  final double defaultWidthFraction;
  final SeasonalLoop defaultLoop;

  static SeasonalPlacement? fromWire(Object? value) {
    for (final placement in values) {
      if (placement.wire == value) return placement;
    }
    return null;
  }
}

/// Position dans la zone d'un emplacement : grille de 3 × 3, les quatre coins,
/// les quatre milieux de côté et le centre.
enum SeasonalPosition {
  topLeft('top_left', Alignment.topLeft),
  topCenter('top_center', Alignment.topCenter),
  topRight('top_right', Alignment.topRight),
  centerLeft('center_left', Alignment.centerLeft),
  center('center', Alignment.center),
  centerRight('center_right', Alignment.centerRight),
  bottomLeft('bottom_left', Alignment.bottomLeft),
  bottomCenter('bottom_center', Alignment.bottomCenter),
  bottomRight('bottom_right', Alignment.bottomRight);

  const SeasonalPosition(this.wire, this.alignment);

  final String wire;
  final Alignment alignment;

  static SeasonalPosition? fromWire(Object? value) {
    for (final position in values) {
      if (position.wire == value) return position;
    }
    return null;
  }
}

enum SeasonalLoop {
  once,
  infinite;

  static SeasonalLoop? fromWire(Object? value) {
    for (final loop in values) {
      if (loop.name == value) return loop;
    }
    return null;
  }
}

/// Une animation Lottie à poser à un emplacement.
class SeasonalAnimationSpec {
  /// Préfixe réservé au jeu d'essai local (animations embarquées dans l'app) :
  /// le backend n'envoie jamais ce schéma.
  static const String assetScheme = 'asset:';

  final int id;
  final SeasonalPlacement placement;
  final String animationUrl;
  final SeasonalPosition position;

  /// Largeur de l'animation, en fraction de la largeur de la zone (]0, 1]).
  final double widthFraction;
  final SeasonalLoop loop;
  final Duration delay;

  /// Textes par langue (`fr`, `en`), affichés seulement par `banner_strip`.
  final Map<String, String>? title;

  const SeasonalAnimationSpec({
    required this.id,
    required this.placement,
    required this.animationUrl,
    required this.position,
    required this.widthFraction,
    required this.loop,
    this.delay = Duration.zero,
    this.title,
  });

  /// Retourne null si l'animation est inutilisable (identifiant ou fichier
  /// manquant, emplacement inconnu) : elle est alors simplement ignorée, sans
  /// jamais faire échouer le reste de l'événement.
  static SeasonalAnimationSpec? tryParse(Object? json) {
    if (json is! Map) return null;

    final id = json['id'];
    final url = json['animation_url'];
    final placement = SeasonalPlacement.fromWire(json['placement']);
    if (id is! int || url is! String || url.isEmpty || placement == null) {
      return null;
    }

    final fraction = json['width_fraction'];
    final delay = json['delay_ms'];
    final rawTitle = json['title'];

    return SeasonalAnimationSpec(
      id: id,
      placement: placement,
      animationUrl: url,
      position:
          SeasonalPosition.fromWire(json['position']) ??
          placement.defaultPosition,
      widthFraction:
          (fraction is num && fraction > 0 && fraction <= 1)
              ? fraction.toDouble()
              : placement.defaultWidthFraction,
      loop: SeasonalLoop.fromWire(json['loop']) ?? placement.defaultLoop,
      delay:
          (delay is int && delay > 0)
              ? Duration(milliseconds: delay)
              : Duration.zero,
      title: _parseTitle(rawTitle),
    );
  }

  static Map<String, String>? _parseTitle(Object? raw) {
    if (raw is! Map) return null;
    final title = <String, String>{
      for (final entry in raw.entries)
        if (entry.key is String &&
            entry.value is String &&
            (entry.value as String).trim().isNotEmpty)
          entry.key as String: entry.value as String,
    };
    return title.isEmpty ? null : title;
  }

  /// Texte dans la langue demandée, à défaut en français, à défaut le premier.
  String? titleFor(String languageCode) {
    final title = this.title;
    if (title == null) return null;
    return title[languageCode] ?? title['fr'] ?? title.values.first;
  }

  bool get isAsset => animationUrl.startsWith(assetScheme);

  /// Un chemin relatif (`/storage/...`) est résolu sur l'origine du serveur,
  /// sans `/api`, comme `image_url` des bannières.
  String get resolvedUrl {
    if (animationUrl.startsWith('http://') ||
        animationUrl.startsWith('https://')) {
      return animationUrl;
    }
    final base = AppConfig.serverBase;
    return '$base${animationUrl.startsWith('/') ? '' : '/'}$animationUrl';
  }

  /// Source du fichier Lottie. Le chargement passe par le cache de Lottie :
  /// une animation préchargée au splash s'affiche instantanément ensuite.
  LottieProvider get provider =>
      isAsset
          ? AssetLottie(animationUrl.substring(assetScheme.length))
          : NetworkLottie(resolvedUrl);
}

/// L'événement saisonnier actif renvoyé par `GET /api/seasonal-event`.
class SeasonalEvent {
  final int id;
  final String name;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<SeasonalAnimationSpec> animations;

  const SeasonalEvent({
    required this.id,
    required this.name,
    this.startsAt,
    this.endsAt,
    required this.animations,
  });

  /// Retourne null si [json] n'est pas un événement exploitable.
  static SeasonalEvent? tryParse(Object? json) {
    if (json is! Map) return null;

    final id = json['id'];
    if (id is! int) return null;

    final rawAnimations = json['animations'];
    final animations = <SeasonalAnimationSpec>[
      if (rawAnimations is List)
        for (final raw in rawAnimations)
          if (SeasonalAnimationSpec.tryParse(raw) case final spec?) spec,
    ];

    return SeasonalEvent(
      id: id,
      name: json['name'] is String ? json['name'] as String : '',
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
      animations: animations,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  List<SeasonalAnimationSpec> animationsFor(SeasonalPlacement placement) => [
    for (final spec in animations)
      if (spec.placement == placement) spec,
  ];

  /// Même événement réduit aux animations [kept] (celles dont le fichier a pu
  /// être chargé).
  SeasonalEvent withAnimations(List<SeasonalAnimationSpec> kept) =>
      SeasonalEvent(
        id: id,
        name: name,
        startsAt: startsAt,
        endsAt: endsAt,
        animations: kept,
      );
}
