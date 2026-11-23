import 'dart:convert';

import 'package:dtservices/providers/topup_provider.dart';
import 'package:dtservices/services/fixed_line_pin_service.dart';
import 'package:dtservices/services/topup_session.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mobile = '25377000000';
const _fixed = '21364425';
const _goodPin = '1234';
const _badPin = '9999';

/// Faux backend, sans état : il sert aussi le client de TopUpApi, qui garde
/// celui de la première requête.
Future<http.Response> _backend(http.Request request) async {
  if (request.url.path.endsWith('/fix/pin/verify')) {
    final pin = (jsonDecode(request.body) as Map)['pin'];
    return pin == _goodPin
        ? http.Response('{"verified":true}', 200)
        : http.Response(
          '{"verified":false,"message":"Numéro ou PIN incorrect."}',
          401,
        );
  }
  // Les soldes ne sont pas l'objet de ces tests.
  return http.Response('{"message":"hors sujet"}', 400);
}

Future<FixedLinePinResult> _signIn(TopUpProvider provider, String pin) {
  return http.runWithClient(
    () => provider.signIn(fixedNumber: _fixed, pin: pin),
    () => MockClient(_backend),
  );
}

Future<void> _initialize(TopUpProvider provider) {
  return http.runWithClient(
    () => provider.initialize(),
    () => MockClient(_backend),
  );
}

Future<void> _startAppSession({Map<String, Object> disk = const {}}) async {
  SharedPreferences.setMockInitialValues({});
  await UserSession.clearSession();
  SharedPreferences.setMockInitialValues(disk);
  await UserSession.createSession(_mobile, sessionToken: 'tok-a');
}

/// Disque d'une ligne dont le PIN a été vérifié il y a [ago].
Map<String, Object> _verifiedLine(
  Duration ago, {
  String mobile = _mobile,
  bool inFuture = false,
}) {
  final at = inFuture ? DateTime.now().add(ago) : DateTime.now().subtract(ago);
  return {
    'topup_fixed_number': _fixed,
    'topup_mobile_number': mobile,
    'topup_verified_at': at.millisecondsSinceEpoch,
  };
}

Future<int?> _storedVerification() async =>
    (await SharedPreferences.getInstance()).getInt('topup_verified_at');

void main() {
  group('ouverture de « Ma ligne » par PIN', () {
    test(
      'une ligne enregistrée mais jamais vérifiée par PIN n\'est pas rouverte',
      () async {
        // Cas des utilisateurs d'une ancienne version : le PIN une fois.
        await _startAppSession(
          disk: {'topup_fixed_number': _fixed, 'topup_mobile_number': _mobile},
        );
        final provider = TopUpProvider();

        await _initialize(provider);

        expect(provider.hasActiveSession, isFalse);
        expect(provider.fixedNumber, isNull);
        expect(provider.balanceResponse, isNull);
        // Seul le numéro est gardé, pour préremplir le champ.
        expect(provider.savedFixedNumber, _fixed);
      },
    );

    test('un PIN faux n\'ouvre pas la ligne et ne mémorise rien', () async {
      await _startAppSession();
      final provider = TopUpProvider();

      final result = await _signIn(provider, _badPin);

      expect(result.status, FixedLinePinStatus.wrongPin);
      expect(provider.hasActiveSession, isFalse);
      expect(provider.fixedNumber, isNull);
      expect(provider.isLoading, isFalse);
      expect(await TopUpSession.getFixedNumber(), isNull);
      expect(await _storedVerification(), isNull);
    });

    test('un PIN correct ouvre la ligne et mémorise la vérification', () async {
      await _startAppSession();
      final provider = TopUpProvider();

      final result = await _signIn(provider, _goodPin);

      expect(result.isVerified, isTrue);
      expect(provider.hasActiveSession, isTrue);
      expect(provider.fixedNumber, _fixed);
      expect(await TopUpSession.getFixedNumber(), _fixed);
      expect(await TopUpSession.isLineVerifiedFor(_mobile), isTrue);
    });
  });

  group('lien avec la session de l\'app', () {
    test(
      'la ligne reste ouverte tant que la session de l\'app est la même',
      () async {
        await _startAppSession();
        final provider = TopUpProvider()..bindSession('tok-a');
        await _signIn(provider, _goodPin);

        provider.bindSession('tok-a');

        expect(provider.hasActiveSession, isTrue);
      },
    );

    test(
      'déconnexion ou expiration (plus de jeton) : la ligne se referme en mémoire',
      () async {
        await _startAppSession();
        final provider = TopUpProvider()..bindSession('tok-a');
        await _signIn(provider, _goodPin);

        provider.bindSession(null);

        expect(provider.hasActiveSession, isFalse);
        expect(provider.fixedNumber, isNull);
        expect(provider.balanceResponse, isNull);
        expect(provider.savedFixedNumber, _fixed);
      },
    );

    test(
      'une nouvelle session de l\'app (autre jeton) referme aussi la ligne',
      () async {
        await _startAppSession();
        final provider = TopUpProvider()..bindSession('tok-a');
        await _signIn(provider, _goodPin);

        provider.bindSession('tok-b');

        expect(provider.hasActiveSession, isFalse);
      },
    );

    test(
      'après une reconnexion, la ligne se rouvre sans PIN tant que la vérification est valable',
      () async {
        await _startAppSession();
        final provider = TopUpProvider()..bindSession('tok-a');
        await _signIn(provider, _goodPin);
        provider.bindSession(null);
        provider.bindSession('tok-b');

        await _initialize(provider);

        expect(provider.hasActiveSession, isTrue);
        expect(provider.fixedNumber, _fixed);
      },
    );

    test('la chute prévient les écrans qui écoutent', () async {
      await _startAppSession();
      final provider = TopUpProvider()..bindSession('tok-a');
      await _signIn(provider, _goodPin);
      var notified = 0;
      provider.addListener(() => notified++);

      provider.bindSession(null);
      await Future<void>.delayed(Duration.zero);

      expect(notified, 1);
    });
  });

  group('vérification mémorisée sur l\'appareil (30 jours)', () {
    test('vérifiée il y a 29 jours : la ligne s\'ouvre sans PIN', () async {
      await _startAppSession(disk: _verifiedLine(const Duration(days: 29)));
      final provider = TopUpProvider();

      await _initialize(provider);

      expect(provider.hasActiveSession, isTrue);
      expect(provider.fixedNumber, _fixed);
    });

    test('vérifiée il y a 31 jours : PIN redemandé, numéro gardé', () async {
      await _startAppSession(disk: _verifiedLine(const Duration(days: 31)));
      final provider = TopUpProvider();

      await _initialize(provider);

      expect(provider.hasActiveSession, isFalse);
      expect(provider.savedFixedNumber, _fixed);
      // La preuve périmée est effacée, pas laissée traîner.
      expect(await _storedVerification(), isNull);
    });

    test(
      'date de vérification dans le futur (horloge reculée) : refusée',
      () async {
        await _startAppSession(
          disk: _verifiedLine(const Duration(days: 2), inFuture: true),
        );
        final provider = TopUpProvider();

        await _initialize(provider);

        expect(provider.hasActiveSession, isFalse);
      },
    );

    test('vérifiée pour un autre compte mobile : refusée', () async {
      await _startAppSession(
        disk: _verifiedLine(const Duration(days: 1), mobile: '25377999999'),
      );
      final provider = TopUpProvider();

      await _initialize(provider);

      expect(provider.hasActiveSession, isFalse);
    });

    test(
      'le même mobile écrit avec ou sans 253 reste le même compte',
      () async {
        await _startAppSession(
          disk: _verifiedLine(const Duration(days: 1), mobile: '77000000'),
        );
        final provider = TopUpProvider();

        await _initialize(provider);

        expect(provider.hasActiveSession, isTrue);
      },
    );

    test(
      'session de l\'app terminée : rien n\'est rouvert, mais la vérification est conservée',
      () async {
        await _startAppSession(disk: _verifiedLine(const Duration(days: 1)));
        final provider = TopUpProvider();
        await UserSession.clearSession();

        await _initialize(provider);

        expect(provider.hasActiveSession, isFalse);
        expect(await _storedVerification(), isNotNull);

        // Reconnexion du même compte : la ligne se rouvre.
        await UserSession.createSession(_mobile, sessionToken: 'tok-b');
        await _initialize(provider);

        expect(provider.hasActiveSession, isTrue);
      },
    );
  });

  group('déconnexion volontaire de la ligne', () {
    test(
      'le numéro et la vérification sont oubliés, le PIN est redemandé',
      () async {
        await _startAppSession();
        final provider = TopUpProvider()..bindSession('tok-a');
        await _signIn(provider, _goodPin);

        await provider.endSession();

        expect(provider.hasActiveSession, isFalse);
        expect(provider.savedFixedNumber, isNull);
        expect(await TopUpSession.getFixedNumber(), isNull);
        expect(await _storedVerification(), isNull);

        await _initialize(provider);
        expect(provider.hasActiveSession, isFalse);
      },
    );
  });

  group('TopUpSession', () {
    setUp(() => _startAppSession(disk: _verifiedLine(const Duration(days: 1))));

    test('enregistrer une ligne retire la vérification précédente', () async {
      await TopUpSession.saveSession(
        mobileNumber: _mobile,
        fixedNumber: '27111111',
      );

      expect(await TopUpSession.isLineVerifiedFor(_mobile), isFalse);
    });

    test(
      'changer seulement le numéro fixe retire aussi la vérification',
      () async {
        await TopUpSession.updateFixedNumber('27111111');

        expect(await TopUpSession.isLineVerifiedFor(_mobile), isFalse);
      },
    );

    test('oublier la vérification garde la ligne', () async {
      await TopUpSession.clearVerification();

      expect(await TopUpSession.isLineVerifiedFor(_mobile), isFalse);
      expect(await TopUpSession.getFixedNumber(), _fixed);
    });

    test('effacer la session retire tout', () async {
      await TopUpSession.clearSession();

      expect(await TopUpSession.getFixedNumber(), isNull);
      expect(await _storedVerification(), isNull);
    });

    test('limite : valable jusqu\'à 30 jours exclus', () async {
      final at = DateTime(2026, 11, 1, 12);
      await TopUpSession.markVerified(now: at);

      expect(
        await TopUpSession.isLineVerifiedFor(
          _mobile,
          now: at.add(const Duration(days: 29, hours: 23)),
        ),
        isTrue,
      );
      expect(
        await TopUpSession.isLineVerifiedFor(
          _mobile,
          now: at.add(const Duration(days: 30)),
        ),
        isFalse,
      );
    });
  });
}
