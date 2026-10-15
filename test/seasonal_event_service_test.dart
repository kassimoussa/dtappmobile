import 'dart:convert';

import 'package:dtservices/services/seasonal_event_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _croissant = 'asset:assets/lottie/dt-aid-croissant.json';
const _missing = 'asset:assets/lottie/n-existe-pas.json';

Map<String, dynamic> _animation(int id, String url) => {
  'id': id,
  'placement': 'header_strip',
  'animation_url': url,
};

http.Response _event(int id, List<Map<String, dynamic>> animations) =>
    http.Response(
      jsonEncode({
        'success': true,
        'data': {'id': id, 'name': 'Fête $id', 'animations': animations},
      }),
      200,
    );

final _noEvent = http.Response('{"success":true,"data":null}', 200);

/// Lance une relecture avec un serveur simulé.
Future<void> _refresh(Future<http.Response> Function() reply) =>
    http.runWithClient(
      SeasonalEventService.refresh,
      () => MockClient((_) => reply()),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => SeasonalEventService.active.value = null);

  test('publie l\'événement reçu', () async {
    await _refresh(() async => _event(5, [_animation(1, _croissant)]));

    expect(SeasonalEventService.active.value?.id, 5);
    expect(SeasonalEventService.active.value?.animations, hasLength(1));
  });

  test('un nouvel événement remplace le précédent', () async {
    await _refresh(() async => _event(5, [_animation(1, _croissant)]));
    await _refresh(() async => _event(6, [_animation(1, _croissant)]));

    expect(SeasonalEventService.active.value?.id, 6);
  });

  test(
    'réponse « aucun événement » : l\'événement affiché disparaît',
    () async {
      await _refresh(() async => _event(5, [_animation(1, _croissant)]));
      expect(SeasonalEventService.active.value, isNotNull);

      await _refresh(() async => _noEvent);

      expect(SeasonalEventService.active.value, isNull);
    },
  );

  group('une erreur ne fait jamais disparaître l\'événement affiché', () {
    setUp(() async {
      await _refresh(() async => _event(5, [_animation(1, _croissant)]));
      expect(SeasonalEventService.active.value?.id, 5);
    });

    test('erreur serveur (500)', () async {
      await _refresh(() async => http.Response('oups', 500));
      expect(SeasonalEventService.active.value?.id, 5);
    });

    test('réseau coupé', () async {
      await _refresh(() async => throw http.ClientException('hors ligne'));
      expect(SeasonalEventService.active.value?.id, 5);
    });

    test('réponse illisible', () async {
      await _refresh(
        () async => http.Response('<html>pas du json</html>', 200),
      );
      expect(SeasonalEventService.active.value?.id, 5);
    });

    test('succès à false', () async {
      await _refresh(
        () async => http.Response('{"success":false,"data":null}', 200),
      );
      expect(SeasonalEventService.active.value?.id, 5);
    });

    test('événement sans identifiant', () async {
      await _refresh(
        () async => http.Response('{"success":true,"data":{"name":"x"}}', 200),
      );
      expect(SeasonalEventService.active.value?.id, 5);
    });
  });

  group('fichiers Lottie introuvables', () {
    test('seule l\'animation défaillante est écartée', () async {
      await _refresh(
        () async =>
            _event(5, [_animation(1, _croissant), _animation(2, _missing)]),
      );

      final animations = SeasonalEventService.active.value!.animations;
      expect(animations.map((a) => a.id), [1]);
    });

    test(
      'toutes défaillantes : aucun événement, donc aucune place réservée',
      () async {
        await _refresh(() async => _event(5, [_animation(1, _missing)]));

        expect(SeasonalEventService.active.value, isNull);
      },
    );
  });
}
