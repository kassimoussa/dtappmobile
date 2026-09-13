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
    final changed = await AppConfig.applyRemoteBase('https://backup.dj');

    expect(changed, isTrue);
    expect(AppConfig.baseUrl, 'https://backup.dj/api');
    expect(AppConfig.isBackend(Uri.parse('https://backup.dj/x')), isTrue);
  });

  test('port explicite et préfixe de chemin conservés', () async {
    await AppConfig.applyRemoteBase('https://backup.dj:8443/dt');

    expect(AppConfig.baseUrl, 'https://backup.dj:8443/dt/api');
  });

  test('un suffixe /api publié par erreur n\'est pas dupliqué', () async {
    await AppConfig.applyRemoteBase('https://backup.dj/api');

    expect(AppConfig.baseUrl, 'https://backup.dj/api');
  });

  test('une valeur invalide est ignorée, la config précédente survit',
      () async {
    await AppConfig.applyRemoteBase('https://backup.dj');

    for (final invalide in ['', '   ', 'pas une url', 'ftp://backup.dj']) {
      expect(await AppConfig.applyRemoteBase(invalide), isFalse,
          reason: 'devrait rejeter "$invalide"');
      expect(AppConfig.baseUrl, 'https://backup.dj/api');
    }
  });

  test('republier la même valeur ne change rien', () async {
    expect(await AppConfig.applyRemoteBase('https://backup.dj'), isTrue);
    expect(await AppConfig.applyRemoteBase('  https://backup.dj  '), isFalse);
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
    await AppConfig.applyRemoteBase('https://backup.dj');

    AppConfig.resetForTest();
    await AppConfig.loadPersistedForTest();

    expect(AppConfig.baseUrl, 'https://backup.dj/api');
    expect(AppConfig.appliedRemoteBase, 'https://backup.dj');
  });

  test('une nouvelle base publiée annule l\'hôte appris', () async {
    await AppConfig.setActiveHost(AppConfig.ipHost);
    await AppConfig.applyRemoteBase('https://backup.dj');

    AppConfig.resetForTest();
    await AppConfig.loadPersistedForTest();

    // L'hôte publié fait autorité, l'IP apprise ne le réécrit pas.
    expect(AppConfig.host, 'backup.dj');
  });

  test('les hôtes connus restent reconnus après un changement de base',
      () async {
    await AppConfig.applyRemoteBase('https://backup.dj');

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

    await AppConfig.applyRemoteBase('https://backup.dj');
    expect(AppConfig.fallbackHost, isNull);
    expect(AppConfig.fallbackBase, isNull);
  });
}
