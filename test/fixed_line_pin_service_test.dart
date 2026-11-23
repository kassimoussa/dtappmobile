import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dtservices/services/fixed_line_pin_service.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phone = '25377000000';
const _token = 'tok-1234567890';

Future<void> _startAppSession() async {
  SharedPreferences.setMockInitialValues({});
  await UserSession.clearSession();
  await UserSession.createSession(_phone, sessionToken: _token);
}

Future<FixedLinePinResult> _verify(
  MockClientHandler handler, {
  String cli = '21364425',
  String pin = '1234',
}) {
  return http.runWithClient(
    () => FixedLinePinService.verify(cli: cli, pin: pin),
    () => MockClient(handler),
  );
}

http.Response _json(
  int status,
  Map<String, Object?> body, {
  Map<String, String> headers = const {},
}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json', ...headers},
);

void main() {
  setUp(_startAppSession);

  group('requête', () {
    test(
      'POST /fix/pin/verify, PIN et numéro en chaînes dans le corps',
      () async {
        late http.Request sent;
        final result = await _verify(
          (request) async {
            sent = request;
            return _json(200, {'verified': true});
          },
          cli: '21 36 44 25',
          pin: '0123',
        );

        expect(result.status, FixedLinePinStatus.verified);
        expect(sent.method, 'POST');
        expect(sent.url.path, endsWith('/api/fix/pin/verify'));
        // Le PIN ne doit jamais être dans l'URL.
        expect(sent.url.toString(), isNot(contains('0123')));
        expect(sent.url.query, isEmpty);
        expect(sent.headers['Authorization'], 'Bearer $_token');
        final body = jsonDecode(sent.body) as Map<String, dynamic>;
        // Chaînes, pour ne pas perdre le zéro de tête ; numéro réduit aux chiffres.
        expect(body, {'cli': '21364425', 'pin': '0123'});
      },
    );
  });

  group('réponses', () {
    test(
      '401 portant « verified » : mauvais PIN, la session est conservée',
      () async {
        final result = await _verify(
          (_) async => _json(401, {
            'verified': false,
            'message': 'Numéro ou PIN incorrect.',
          }),
        );

        expect(result.status, FixedLinePinStatus.wrongPin);
        // Un mauvais PIN ne doit surtout pas déconnecter l'utilisateur.
        expect(await UserSession.getSessionToken(), _token);
      },
    );

    test('401 sans « verified » : session expirée, elle est effacée', () async {
      final result = await _verify(
        (_) async => _json(401, {
          'status': 'error',
          'message': 'Session invalide ou expirée',
        }),
      );

      expect(result.status, FixedLinePinStatus.sessionExpired);
      expect(await UserSession.getSessionToken(), isNull);
    });

    test('422 : format refusé', () async {
      final result = await _verify(
        (_) async => _json(422, {
          'verified': false,
          'message': 'Format du numéro ou du PIN invalide.',
        }),
      );
      expect(result.status, FixedLinePinStatus.invalidFormat);
    });

    test('429 avec « verified » : verrou, avec le délai', () async {
      final result = await _verify(
        (_) async => _json(429, {
          'verified': false,
          'message': 'Trop de tentatives. Réessayez plus tard.',
          'retry_after': 840,
        }),
      );

      expect(result.status, FixedLinePinStatus.locked);
      expect(result.retryAfterSeconds, 840);
      expect(await UserSession.getSessionToken(), _token);
    });

    test(
      '429 sans « verified » : limite par IP, délai lu dans Retry-After',
      () async {
        final result = await _verify(
          (_) async => _json(
            429,
            {'message': 'Too Many Requests'},
            headers: {'retry-after': '30'},
          ),
        );

        expect(result.status, FixedLinePinStatus.tooManyRequests);
        expect(result.retryAfterSeconds, 30);
      },
    );

    test('503 : indisponible, jamais présenté comme un PIN faux', () async {
      final result = await _verify(
        (_) async => _json(503, {
          'verified': false,
          'message': 'Service momentanément indisponible. Réessayez.',
        }),
      );
      expect(result.status, FixedLinePinStatus.unavailable);
    });

    test(
      'corps illisible (page d\'erreur d\'un proxy) : indisponible',
      () async {
        final result = await _verify(
          (_) async => http.Response('<html>Bad gateway</html>', 502),
        );
        expect(result.status, FixedLinePinStatus.unavailable);
      },
    );

    test('200 sans « verified: true » n\'ouvre rien', () async {
      final result = await _verify((_) async => _json(200, {'ok': true}));
      expect(result.status, FixedLinePinStatus.unavailable);
    });
  });

  group('pannes réseau', () {
    test('réseau coupé : indisponible', () async {
      final result = await _verify(
        (_) async => throw const SocketException('pas de réseau'),
      );
      expect(result.status, FixedLinePinStatus.unavailable);
    });

    test('délai dépassé : indisponible', () async {
      final result = await _verify(
        (_) async => throw TimeoutException('trop long'),
      );
      expect(result.status, FixedLinePinStatus.unavailable);
    });
  });

  group('format du PIN', () {
    test('de 3 à 12 chiffres, rien d\'autre', () {
      for (final pin in ['123', '0000', '123456789012']) {
        expect(FixedLinePinService.isValidPinFormat(pin), isTrue, reason: pin);
      }
      for (final pin in ['', '12', '1234567890123', '12a4', '12 34', '-123']) {
        expect(FixedLinePinService.isValidPinFormat(pin), isFalse, reason: pin);
      }
    });
  });
}
