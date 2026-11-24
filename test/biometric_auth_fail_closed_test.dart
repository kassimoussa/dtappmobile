import 'package:dtservices/services/biometric_auth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Faux plugin d'authentification système : le résultat est choisi par le test.
class _FakeLocalAuth extends Fake implements LocalAuthentication {
  _FakeLocalAuth(this._outcome, {this.supported = true});

  final Future<bool> Function() _outcome;
  final bool supported;
  int authenticateCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => supported;

  // `authenticate` prend un type (AuthMessages) que local_auth n'exporte pas :
  // on l'intercepte plutôt que de recopier sa signature.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #authenticate) {
      authenticateCalls++;
      return _outcome();
    }
    return super.noSuchMethod(invocation);
  }
}

/// Les deux écrans qui engagent de l'argent : achat de forfait et transfert.
final _flows = <String, Future<BiometricAuthResult> Function()>{
  'achat':
      () => BiometricAuthService.authenticateForPurchase(
        itemName: 'Forfait 1 Go',
        amount: 500,
        currency: 'DJF',
      ),
  'transfert':
      () => BiometricAuthService.authenticateForTransfer(
        amount: 500,
        currency: 'DJF',
        recipient: '77000000',
      ),
};

_FakeLocalAuth _install(
  Future<bool> Function() outcome, {
  bool supported = true,
}) {
  final fake = _FakeLocalAuth(outcome, supported: supported);
  BiometricAuthService.localAuthForTest = fake;
  return fake;
}

void main() {
  for (final flow in _flows.entries) {
    group(
      '${flow.key} : l\'authentification échoue → l\'opération est refusée',
      () {
        final run = flow.value;

        test('succès de l\'authentification : autorisé', () async {
          _install(() async => true);

          final result = await run();

          expect(result.success, isTrue);
        });

        test('refus ou annulation de l\'utilisateur : refusé', () async {
          _install(() async => false);

          final result = await run();

          expect(result.success, isFalse);
          expect(result.errorType, BiometricAuthErrorType.userCancel);
        });

        // Ces trois cas étaient autrefois AUTORISÉS (« contournement » pour
        // erreur de canal) : une panne du plugin ouvrait le paiement.
        test('erreur de canal du plugin : refusé, jamais autorisé', () async {
          _install(() async => throw PlatformException(code: 'channel-error'));

          final result = await run();

          expect(result.success, isFalse);
          expect(result.errorType, BiometricAuthErrorType.unknown);
          expect(result.errorMessage, isNotEmpty);
        });

        test('code d\'erreur contenant « channel » : refusé', () async {
          _install(
            () async => throw PlatformException(code: 'some-channel-problem'),
          );

          final result = await run();

          expect(result.success, isFalse);
        });

        test('message d\'erreur contenant « channel » : refusé', () async {
          _install(
            () async =>
                throw PlatformException(
                  code: 'autre',
                  message: 'Unable to establish connection on channel',
                ),
          );

          final result = await run();

          expect(result.success, isFalse);
        });

        test('exception inattendue : refusé', () async {
          _install(() async => throw StateError('boom'));

          final result = await run();

          expect(result.success, isFalse);
          expect(result.errorType, BiometricAuthErrorType.unknown);
        });

        test(
          'appareil sans authentification : refusé, rien n\'est demandé',
          () async {
            final fake = _install(() async => true, supported: false);

            final result = await run();

            expect(result.success, isFalse);
            expect(result.errorType, BiometricAuthErrorType.notAvailable);
            expect(fake.authenticateCalls, 0);
          },
        );

        test(
          'erreurs connues de la plateforme : refusé, avec leur type',
          () async {
            final cases = {
              auth_error.notAvailable: BiometricAuthErrorType.notAvailable,
              auth_error.notEnrolled: BiometricAuthErrorType.notEnrolled,
              auth_error.lockedOut: BiometricAuthErrorType.lockedOut,
              auth_error.permanentlyLockedOut:
                  BiometricAuthErrorType.permanentlyLockedOut,
            };

            for (final entry in cases.entries) {
              _install(() async => throw PlatformException(code: entry.key));

              final result = await run();

              expect(result.success, isFalse, reason: entry.key);
              expect(result.errorType, entry.value, reason: entry.key);
            }
          },
        );
      },
    );
  }
}
