import 'package:dtservices/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base pilotée à distance (Firebase Remote Config → AppConfig) et mémoire de
/// l'hôte joignable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.resetForTest();
  });

  test('sans valeur distante, l\'app part sur le domaine en HTTPS', () {
    expect(AppConfig.host, AppConfig.domainHost);
    expect(AppConfig.baseUrl, 'https://${AppConfig.domainHost}/api');
    expect(AppConfig.appliedRemoteBase, isNull);
  });

  test('une base publiée change l\'hôte', () async {
    final changed = await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj');

    expect(changed, isTrue);
    expect(AppConfig.baseUrl, 'https://api.djiboutitelecom.dj/api');
    expect(AppConfig.isBackend(Uri.parse('https://api.djiboutitelecom.dj/x')), isTrue);
  });

  test('port explicite et préfixe de chemin conservés', () async {
    await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj:8443/dt');

    expect(AppConfig.baseUrl, 'https://api.djiboutitelecom.dj:8443/dt/api');
  });

  test('un suffixe /api publié par erreur n\'est pas dupliqué', () async {
    await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj/api');

    expect(AppConfig.baseUrl, 'https://api.djiboutitelecom.dj/api');
  });

  test('une valeur invalide est ignorée, la config précédente survit',
      () async {
    await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj');

    for (final invalide in ['', '   ', 'pas une url', 'ftp://api.djiboutitelecom.dj']) {
      expect(await AppConfig.applyRemoteBase(invalide), isFalse,
          reason: 'devrait rejeter "$invalide"');
      expect(AppConfig.baseUrl, 'https://api.djiboutitelecom.dj/api');
    }
  });

  test('republier la même valeur ne change rien', () async {
    expect(await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj'), isTrue);
    expect(await AppConfig.applyRemoteBase('  https://api.djiboutitelecom.dj  '), isFalse);
  });

  test('publier du HTTP reste possible — la soupape de panne', () async {
    // Aucun mécanisme automatique ne dégrade le chiffrement ; seule une
    // publication délibérée le peut.
    await AppConfig.applyRemoteBase('http://${AppConfig.ipHost}');

    expect(AppConfig.scheme, AppConfig.httpScheme);
    expect(AppConfig.baseUrl, 'http://${AppConfig.ipHost}/api');
  });

  test('l\'hôte appris est restauré au lancement suivant, hors ligne',
      () async {
    // Le failover a basculé sur l'IP lors d'une session précédente.
    await AppConfig.setActiveHost(AppConfig.ipHost);

    AppConfig.resetForTest();
    await AppConfig.loadPersistedForTest();

    expect(AppConfig.host, AppConfig.ipHost);
    expect(AppConfig.baseUrl, 'https://${AppConfig.ipHost}/api');
  });

  test('la base publiée est restaurée au lancement suivant, hors ligne',
      () async {
    await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj');

    AppConfig.resetForTest();
    await AppConfig.loadPersistedForTest();

    expect(AppConfig.baseUrl, 'https://api.djiboutitelecom.dj/api');
    expect(AppConfig.appliedRemoteBase, 'https://api.djiboutitelecom.dj');
  });

  test('une nouvelle base publiée annule l\'hôte appris', () async {
    await AppConfig.setActiveHost(AppConfig.ipHost);
    await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj');

    AppConfig.resetForTest();
    await AppConfig.loadPersistedForTest();

    // L'hôte publié fait autorité, l'IP apprise ne le réécrit pas.
    expect(AppConfig.host, 'api.djiboutitelecom.dj');
  });

  test('les hôtes connus restent reconnus après un changement de base',
      () async {
    await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj');

    // URLs absolues encore renvoyées par l'API (images de bannières…).
    expect(AppConfig.isBackend(Uri.parse('http://${AppConfig.ipHost}/img.png')),
        isTrue);
    expect(AppConfig.isBackend(Uri.parse('https://speed.cloudflare.com/x')),
        isFalse);
  });

  test('le secours n\'existe qu\'entre les deux hôtes connus', () async {
    expect(AppConfig.fallbackHost, AppConfig.ipHost);

    await AppConfig.setActiveHost(AppConfig.ipHost);
    expect(AppConfig.fallbackHost, AppConfig.domainHost);

    await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj');
    expect(AppConfig.fallbackHost, isNull);
    expect(AppConfig.fallbackBase, isNull);
  });

  // Une publication Remote Config ne doit jamais pouvoir envoyer les jetons,
  // OTP et PIN des utilisateurs vers un hôte étranger.
  group('hôtes autorisés', () {
    const defaultBase = 'https://mydtapp.djiboutitelecom.dj/api';

    test('les hôtes de l\'opérateur sont acceptés', () async {
      final acceptes = {
        'https://mydtapp.djiboutitelecom.dj': 'mydtapp.djiboutitelecom.dj',
        'https://196.201.193.252': '196.201.193.252',
        'https://api.djiboutitelecom.dj': 'api.djiboutitelecom.dj',
        'https://a.b.djiboutitelecom.dj:8443/dt': 'a.b.djiboutitelecom.dj',
        // Soupape de panne du 443 : le clair, mais seulement vers l'IP.
        'http://196.201.193.252': '196.201.193.252',
      };

      for (final entry in acceptes.entries) {
        AppConfig.resetForTest();

        expect(
          await AppConfig.applyRemoteBase(entry.key),
          isTrue,
          reason: 'devrait accepter "${entry.key}"',
        );
        expect(AppConfig.host, entry.value);
      }
    });

    test('un hôte étranger ou imitant le domaine est refusé', () async {
      const refuses = [
        'https://evil.com',
        'http://evil.com',
        // Imitations du domaine de l'opérateur.
        'https://evil-djiboutitelecom.dj',
        'https://djiboutitelecom.dj.evil.com',
        'https://mydtapp.djiboutitelecom.dj.evil.com',
        'https://api.djiboutitelecom.dj.',
        // Le domaine nu est le site de l'opérateur, pas une API.
        'https://djiboutitelecom.dj',
        // Identifiants dans l'adresse : l'hôte réel est après le @.
        'https://mydtapp.djiboutitelecom.dj@evil.com',
        'https://user:pw@api.djiboutitelecom.dj',
        r'https://evil.com\@api.djiboutitelecom.dj',
        // Une autre IP que celle du backend.
        'https://203.0.113.9',
        'https://196.201.193.253',
        // Le clair n'est toléré que vers l'IP de la soupape.
        'http://api.djiboutitelecom.dj',
        'http://mydtapp.djiboutitelecom.dj',
      ];

      for (final value in refuses) {
        expect(
          await AppConfig.applyRemoteBase(value),
          isFalse,
          reason: 'devrait refuser "$value"',
        );
        expect(
          AppConfig.baseUrl,
          defaultBase,
          reason: '"$value" ne doit pas changer l\'hôte actif',
        );
        expect(AppConfig.appliedRemoteBase, isNull);
      }
    });

    test(
      'une valeur refusée ne remplace pas la configuration en place',
      () async {
        await AppConfig.applyRemoteBase('https://api.djiboutitelecom.dj');

        expect(await AppConfig.applyRemoteBase('https://evil.com'), isFalse);

        expect(AppConfig.baseUrl, 'https://api.djiboutitelecom.dj/api');
        expect(AppConfig.appliedRemoteBase, 'https://api.djiboutitelecom.dj');
      },
    );

    test('une valeur refusée n\'est pas mémorisée sur l\'appareil', () async {
      await AppConfig.applyRemoteBase('https://evil.com');

      AppConfig.resetForTest();
      await AppConfig.loadPersistedForTest();

      expect(AppConfig.baseUrl, defaultBase);
      expect(
        (await SharedPreferences.getInstance()).getString('api_remote_base'),
        isNull,
      );
    });

    test(
      'une base déjà mémorisée par un tiers est ignorée puis oubliée',
      () async {
        // Cas d'une valeur arrivée avant la liste d'hôtes autorisés, ou écrite
        // sur un appareil modifié.
        SharedPreferences.setMockInitialValues({
          'api_remote_base': 'https://evil.com',
        });

        await AppConfig.loadPersistedForTest();

        expect(AppConfig.baseUrl, defaultBase);
        expect(AppConfig.appliedRemoteBase, isNull);
        expect(
          (await SharedPreferences.getInstance()).getString('api_remote_base'),
          isNull,
        );
      },
    );

    test('une base mémorisée valide est toujours restaurée', () async {
      SharedPreferences.setMockInitialValues({
        'api_remote_base': 'https://api.djiboutitelecom.dj',
      });

      await AppConfig.loadPersistedForTest();

      expect(AppConfig.baseUrl, 'https://api.djiboutitelecom.dj/api');
    });

    test('isAllowedBackendHost : la liste blanche, hôte par hôte', () {
      expect(
        AppConfig.isAllowedBackendHost('mydtapp.djiboutitelecom.dj'),
        isTrue,
      );
      expect(AppConfig.isAllowedBackendHost('196.201.193.252'), isTrue);
      expect(AppConfig.isAllowedBackendHost('x.djiboutitelecom.dj'), isTrue);

      expect(AppConfig.isAllowedBackendHost('djiboutitelecom.dj'), isFalse);
      expect(
        AppConfig.isAllowedBackendHost('evil-djiboutitelecom.dj'),
        isFalse,
      );
      expect(
        AppConfig.isAllowedBackendHost('djiboutitelecom.dj.evil.com'),
        isFalse,
      );
      expect(AppConfig.isAllowedBackendHost(''), isFalse);
    });
  });
}
