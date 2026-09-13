import 'dart:convert';

import 'package:dtservices/services/consent_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Consentement versionné : c'est ce qui remplace l'ancien booléen à vie.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConsentService.resetForTest();
  });

  /// Réponse type de `GET /api/legal/versions`.
  String versionsBody({
    String privacy = '2026-08-02',
    String terms = '2026-08-02',
    bool privacyRequires = true,
    bool termsRequires = true,
  }) =>
      jsonEncode({
        'status': 'success',
        'data': {
          'privacy_policy': {
            'version': privacy,
            'updated_at': '${privacy}T00:00:00Z',
            'requires_reacceptance': privacyRequires,
          },
          'terms_of_service': {
            'version': terms,
            'updated_at': '${terms}T00:00:00Z',
            'requires_reacceptance': termsRequires,
          },
        },
      });

  /// Exécute [body] avec un client HTTP simulé, comme le fait `main.dart`
  /// avec le client à bascule.
  Future<T> withServer<T>(
    Future<T> Function() body, {
    required Future<http.Response> Function(http.Request) handler,
  }) =>
      http.runWithClient(body, () => MockClient(handler));

  group('versions en vigueur', () {
    test('lues depuis le serveur puis mises en cache', () async {
      var appels = 0;
      await withServer(
        () async {
          final v = await ConsentService.requiredVersions();
          expect(v[ConsentService.privacyDoc]!.version, '2026-08-02');
          // Deuxième lecture : servie par le cache, pas de nouvel appel.
          await ConsentService.requiredVersions();
        },
        handler: (request) async {
          appels++;
          return http.Response(versionsBody(), 200);
        },
      );
      expect(appels, 1);
    });

    test('repli sur les versions compilées si le serveur est injoignable',
        () async {
      await withServer(
        () async {
          final v = await ConsentService.requiredVersions();
          expect(v[ConsentService.privacyDoc]!.version,
              ConsentService.bundledVersions[ConsentService.privacyDoc]);
        },
        handler: (_) async => http.Response('erreur', 500),
      );
    });
  });

  group('documents à faire accepter', () {
    test('les deux au premier lancement', () async {
      await withServer(
        () async {
          expect(await ConsentService.pendingDocuments(),
              [ConsentService.privacyDoc, ConsentService.termsDoc]);
        },
        handler: (_) async => http.Response(versionsBody(), 200),
      );
    });

    test('plus rien après acceptation de la version en cours', () async {
      await withServer(
        () async {
          await ConsentService.record(
            docs: ConsentService.documents,
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
          expect(await ConsentService.pendingDocuments(), isEmpty);
        },
        handler: (request) async => request.url.path.endsWith('/legal/versions')
            ? http.Response(versionsBody(), 200)
            : http.Response('{"status":"success"}', 200),
      );
    });

    test('une nouvelle version rend le consentement caduc', () async {
      // Session 1 : l'utilisateur accepte la version d'août.
      await withServer(
        () async {
          await ConsentService.record(
            docs: ConsentService.documents,
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
        },
        handler: (request) async => request.url.path.endsWith('/legal/versions')
            ? http.Response(versionsBody(), 200)
            : http.Response('{"status":"success"}', 200),
      );

      // Session 2 : le juridique publie une révision de la confidentialité.
      // `refresh` reproduit la vérification faite à chaque connexion.
      await withServer(
        () async {
          final pending =
              await ConsentService.pendingDocuments(refresh: true);
          expect(pending, [ConsentService.privacyDoc]);
        },
        handler: (_) async =>
            http.Response(versionsBody(privacy: '2027-01-15'), 200),
      );
    });

    test('une correction de forme ne redemande rien', () async {
      await withServer(
        () async {
          await ConsentService.record(
            docs: ConsentService.documents,
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
        },
        handler: (request) async => request.url.path.endsWith('/legal/versions')
            ? http.Response(versionsBody(), 200)
            : http.Response('{"status":"success"}', 200),
      );

      await withServer(
        () async {
          expect(await ConsentService.pendingDocuments(refresh: true), isEmpty);
        },
        // Version différente, mais requires_reacceptance à false.
        handler: (_) async => http.Response(
            versionsBody(privacy: '2027-01-15', privacyRequires: false), 200),
      );
    });

    test('le serveur peut forcer une re-sollicitation', () async {
      await withServer(
        () async {
          await ConsentService.record(
            docs: ConsentService.documents,
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
          expect(await ConsentService.pendingDocuments(), isEmpty);

          // Bloc `legal` d'une réponse de connexion : le serveur n'a aucune
          // trace de ce consentement (envoi perdu, autre appareil…).
          ConsentService.applyServerPending({
            'pending': [ConsentService.privacyDoc]
          });
          expect(await ConsentService.pendingDocuments(),
              [ConsentService.privacyDoc]);
        },
        handler: (request) async => request.url.path.endsWith('/legal/versions')
            ? http.Response(versionsBody(), 200)
            : http.Response('{"status":"success"}', 200),
      );
    });

    test('un refus annule le consentement précédent', () async {
      await withServer(
        () async {
          await ConsentService.record(
            docs: ConsentService.documents,
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
          await ConsentService.record(
            docs: [ConsentService.privacyDoc],
            action: ConsentService.actionDeclined,
            locale: 'fr',
          );
          expect(await ConsentService.pendingDocuments(),
              [ConsentService.privacyDoc]);
        },
        handler: (request) async => request.url.path.endsWith('/legal/versions')
            ? http.Response(versionsBody(), 200)
            : http.Response('{"status":"success"}', 200),
      );
    });
  });

  group('transmission au serveur', () {
    test('les deux documents partent dans un seul appel', () async {
      Map<String, dynamic>? envoye;
      await withServer(
        () async {
          await ConsentService.record(
            docs: ConsentService.documents,
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
        },
        handler: (request) async {
          if (request.url.path.endsWith('/legal/versions')) {
            return http.Response(versionsBody(), 200);
          }
          expect(request.url.path, endsWith('/mobile/consents'));
          envoye = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"status":"success"}', 200);
        },
      );

      final consents = envoye!['consents'] as List;
      expect(consents.length, 2);
      expect(consents.map((c) => c['document']).toList(),
          [ConsentService.privacyDoc, ConsentService.termsDoc]);
      expect(consents.first['action'], 'accepted');
      expect(consents.first['locale'], 'fr');
      expect(consents.first['accepted_at'], isNotNull);
      // Les métadonnées sensibles sont déduites côté serveur, pas envoyées ici.
      expect(consents.first.containsKey('app_version'), isFalse);
      expect(consents.first.containsKey('platform'), isFalse);
    });

    test('sans session, le consentement est conservé et rejoué plus tard',
        () async {
      // Consentement donné avant connexion : l'envoi échoue.
      await withServer(
        () async {
          await ConsentService.record(
            docs: ConsentService.documents,
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
        },
        handler: (request) async => request.url.path.endsWith('/legal/versions')
            ? http.Response(versionsBody(), 200)
            : http.Response('{"status":"error"}', 503),
      );

      // Après authentification : la file part enfin.
      var recus = 0;
      await withServer(
        () async => ConsentService.flushPending(),
        handler: (request) async {
          recus = (jsonDecode(request.body)['consents'] as List).length;
          return http.Response('{"status":"success"}', 200);
        },
      );
      expect(recus, 2);

      // Et la file est bien vidée : pas de second envoi.
      var rappels = 0;
      await withServer(
        () async => ConsentService.flushPending(),
        handler: (_) async {
          rappels++;
          return http.Response('{"status":"success"}', 200);
        },
      );
      expect(rappels, 0);
    });

    test('un horodatage refusé est rejoué sans date, pas perdu', () async {
      // Horloge du téléphone faussée : le serveur refuse accepted_at. Sans
      // rejeu, le consentement ne serait jamais enregistré et l'utilisateur
      // serait re-sollicité à chaque connexion.
      final corps = <Map<String, dynamic>>[];
      await withServer(
        () async {
          await ConsentService.record(
            docs: [ConsentService.privacyDoc],
            action: ConsentService.actionAccepted,
            locale: 'fr',
          );
        },
        handler: (request) async {
          if (request.url.path.endsWith('/legal/versions')) {
            return http.Response(versionsBody(), 200);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          corps.add(body);
          final premier = (body['consents'] as List).first;
          return premier.containsKey('accepted_at')
              ? http.Response('{"status":"error"}', 422)
              : http.Response('{"status":"success"}', 200);
        },
      );

      expect(corps.length, 2, reason: 'un envoi daté puis un rejeu sans date');
      expect((corps.last['consents'] as List).first.containsKey('accepted_at'),
          isFalse);

      // Le rejeu ayant réussi, la file est vide.
      var rappels = 0;
      await withServer(
        () async => ConsentService.flushPending(),
        handler: (_) async {
          rappels++;
          return http.Response('{"status":"success"}', 200);
        },
      );
      expect(rappels, 0);
    });
  });
}
