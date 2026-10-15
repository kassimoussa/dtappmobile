import 'package:dtservices/config/app_config.dart';
import 'package:dtservices/models/seasonal_event.dart';
import 'package:dtservices/services/seasonal_event_service.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exemple du contrat (seasonal-event-endpoint.md).
Map<String, dynamic> _contractExample() => {
  'id': 12,
  'name': 'Aïd Moubarak',
  'starts_at': '2027-03-09T00:00:00+03:00',
  'ends_at': '2027-03-12T23:59:59+03:00',
  'animations': <Object?>[
    {
      'id': 31,
      'placement': 'header_strip',
      'animation_url': '/storage/uploads/events/croissant.json',
      'position': 'top_left',
      'width_fraction': 0.2,
      'loop': 'infinite',
      'delay_ms': 0,
      'title': null,
    },
    {
      'id': 33,
      'placement': 'banner_strip',
      'animation_url': 'https://cdn.example.dj/aid.json',
      'position': 'center_left',
      'width_fraction': 0.2,
      'loop': 'infinite',
      'delay_ms': 250,
      'title': {'fr': 'Aïd Moubarak !', 'en': 'Eid Mubarak!'},
    },
  ],
};

void main() {
  group('SeasonalEvent.tryParse', () {
    test('lit l\'exemple du contrat', () {
      final event = SeasonalEvent.tryParse(_contractExample())!;

      expect(event.id, 12);
      expect(event.name, 'Aïd Moubarak');
      expect(event.startsAt, DateTime.parse('2027-03-09T00:00:00+03:00'));
      expect(event.animations, hasLength(2));

      final strip = event.animations.first;
      expect(strip.placement, SeasonalPlacement.headerStrip);
      expect(strip.position, SeasonalPosition.topLeft);
      expect(strip.position.alignment, Alignment.topLeft);
      expect(strip.widthFraction, 0.2);
      expect(strip.loop, SeasonalLoop.infinite);
      expect(strip.title, isNull);

      expect(event.animations.last.delay, const Duration(milliseconds: 250));
    });

    test('ignore un emplacement inconnu sans perdre les autres animations', () {
      final json = _contractExample();
      (json['animations'] as List).add({
        'id': 99,
        'placement': 'footer_wave', // pas connu de cette version de l'app
        'animation_url': '/x.json',
      });

      final event = SeasonalEvent.tryParse(json)!;

      expect(event.animations.map((a) => a.id), [31, 33]);
    });

    test('ignore une animation inutilisable', () {
      final json = _contractExample();
      (json['animations'] as List).addAll([
        'pas un objet',
        {'id': 1, 'placement': 'overlay'}, // sans fichier
        {'placement': 'overlay', 'animation_url': '/x.json'}, // sans id
        {'id': 2, 'placement': 'overlay', 'animation_url': ''},
      ]);

      expect(SeasonalEvent.tryParse(json)!.animations, hasLength(2));
    });

    test('valeurs absentes ou hors bornes : défauts de l\'emplacement', () {
      final event =
          SeasonalEvent.tryParse({
            'id': 1,
            'animations': <Object?>[
              {'id': 1, 'placement': 'overlay', 'animation_url': '/o.json'},
              {
                'id': 2,
                'placement': 'card_corner',
                'animation_url': '/c.json',
                'position': 'sideways',
                'width_fraction': 4,
                'loop': 'forever',
                'delay_ms': -10,
              },
            ],
          })!;

      final overlay = event.animations.first;
      expect(overlay.position, SeasonalPosition.center);
      expect(overlay.widthFraction, 1.0);
      expect(overlay.loop, SeasonalLoop.once);
      expect(overlay.delay, Duration.zero);

      final corner = event.animations.last;
      expect(corner.position, SeasonalPosition.bottomRight);
      expect(corner.widthFraction, 0.27);
      expect(corner.loop, SeasonalLoop.infinite);
      expect(corner.delay, Duration.zero);
    });

    test('rejette ce qui n\'est pas un événement', () {
      expect(SeasonalEvent.tryParse(null), isNull);
      expect(SeasonalEvent.tryParse('texte'), isNull);
      expect(SeasonalEvent.tryParse({'name': 'sans id'}), isNull);
    });

    test('animations absentes : événement valide mais vide', () {
      expect(SeasonalEvent.tryParse({'id': 3})!.animations, isEmpty);
    });
  });

  group('SeasonalAnimationSpec', () {
    SeasonalAnimationSpec spec(Map<String, dynamic> overrides) =>
        SeasonalAnimationSpec.tryParse({
          'id': 1,
          'placement': 'banner_strip',
          'animation_url': '/a.json',
          ...overrides,
        })!;

    test('titleFor : langue demandée, sinon français, sinon le premier', () {
      final both = spec({
        'title': {'fr': 'Bonjour', 'en': 'Hello'},
      });
      expect(both.titleFor('en'), 'Hello');
      expect(both.titleFor('ar'), 'Bonjour');
      expect(
        spec({
          'title': {'en': 'Only English'},
        }).titleFor('fr'),
        'Only English',
      );
      expect(spec({}).titleFor('fr'), isNull);
    });

    test('titre vide ou mal formé : pas de titre', () {
      expect(
        spec({
          'title': {'fr': '  ', 'en': 3},
        }).title,
        isNull,
      );
      expect(spec({'title': 'texte'}).title, isNull);
    });

    test('résout un chemin relatif sur l\'origine du serveur, sans /api', () {
      expect(
        spec({'animation_url': '/storage/a.json'}).resolvedUrl,
        '${AppConfig.serverBase}/storage/a.json',
      );
      expect(
        spec({'animation_url': 'storage/a.json'}).resolvedUrl,
        '${AppConfig.serverBase}/storage/a.json',
      );
      expect(
        spec({'animation_url': 'https://cdn.example.dj/a.json'}).resolvedUrl,
        'https://cdn.example.dj/a.json',
      );
    });
  });

  group('SeasonalEventService.has', () {
    tearDown(() => SeasonalEventService.active.value = null);

    test('vrai seulement pour les emplacements de l\'événement actif', () {
      expect(SeasonalEventService.has(SeasonalPlacement.headerStrip), isFalse);

      SeasonalEventService.active.value = SeasonalEvent.tryParse(
        _contractExample(),
      );

      expect(SeasonalEventService.has(SeasonalPlacement.headerStrip), isTrue);
      expect(SeasonalEventService.has(SeasonalPlacement.bannerStrip), isTrue);
      expect(SeasonalEventService.has(SeasonalPlacement.overlay), isFalse);
    });
  });
}
