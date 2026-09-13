import 'dart:io';

import 'package:dtservices/config/app_config.dart';
import 'package:dtservices/config/failover_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bascule d'hôte du client HTTP (domaine ↔ IP), toujours en HTTPS.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.resetForTest();
  });

  test('aligne les URLs backend sur l\'origine active', () async {
    final vues = <Uri>[];
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        vues.add(request.url);
        return http.Response('{}', 200);
      }),
    );

    // URL absolue héritée, écrite en clair sur l'IP (image renvoyée par l'API).
    await client.get(Uri.parse('http://${AppConfig.ipHost}/storage/img.png'));

    expect(vues.single.scheme, 'https');
    expect(vues.single.host, AppConfig.domainHost);
    expect(vues.single.path, '/storage/img.png');
  });

  test('laisse intactes les URLs des services tiers', () async {
    final vues = <Uri>[];
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        vues.add(request.url);
        return http.Response('{}', 200);
      }),
    );

    await client.get(Uri.parse('https://speed.cloudflare.com/__down'));

    expect(vues.single.toString(), 'https://speed.cloudflare.com/__down');
  });

  test('bascule sur l\'IP quand le domaine échoue, corps préservé', () async {
    final vues = <Uri>[];
    final corps = <String?>[];
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        vues.add(request.url);
        corps.add(request.body);
        if (request.url.host == AppConfig.domainHost) {
          throw const SocketException('résolution DNS impossible');
        }
        return http.Response('{"ok":true}', 200);
      }),
    );

    final response = await client.post(
      Uri.parse('${AppConfig.baseUrl}/sms/otp/send'),
      body: '{"phone":"25377000000"}',
      headers: {'Content-Type': 'application/json'},
    );

    expect(response.statusCode, 200);
    expect(vues.map((u) => u.host).toList(),
        [AppConfig.domainHost, AppConfig.ipHost]);
    expect(corps, ['{"phone":"25377000000"}', '{"phone":"25377000000"}']);
    // L'hôte qui a fonctionné devient l'hôte actif.
    expect(AppConfig.host, AppConfig.ipHost);
    expect(AppConfig.baseUrl, 'https://${AppConfig.ipHost}/api');
  });

  test('la bascule ne dégrade jamais le chiffrement', () async {
    final vues = <Uri>[];
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        vues.add(request.url);
        if (request.url.host == AppConfig.domainHost) {
          throw const SocketException('injoignable');
        }
        return http.Response('{}', 200);
      }),
    );

    await client.get(Uri.parse('${AppConfig.baseUrl}/banners'));

    // Les deux tentatives restent en HTTPS : aucun repli en clair.
    expect(vues.map((u) => u.scheme).toSet(), {'https'});
  });

  test('ne bascule pas sur une erreur applicative (500)', () async {
    var appels = 0;
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        appels++;
        return http.Response('erreur serveur', 500);
      }),
    );

    final response = await client.get(Uri.parse('${AppConfig.baseUrl}/banners'));

    expect(response.statusCode, 500);
    expect(appels, 1);
    expect(AppConfig.host, AppConfig.domainHost);
  });

  test('les sondes ne sont ni réécrites ni rejouées', () async {
    final vues = <Uri>[];
    final entetes = <Map<String, String>>[];
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        vues.add(request.url);
        entetes.add(request.headers);
        return http.Response('{}', 200);
      }),
    );

    // Hôte actif = domaine, sonde explicite sur l'IP : elle doit y rester.
    await client.get(
      Uri.parse('https://${AppConfig.ipHost}${AppConfig.probePath}'),
      headers: {AppConfig.probeHeader: '1'},
    );

    expect(vues.single.host, AppConfig.ipHost);
    expect(entetes.single.containsKey(AppConfig.probeHeader), isFalse);
  });

  test('remonte l\'erreur si les deux hôtes échouent', () async {
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        throw const SocketException('injoignable');
      }),
    );

    await expectLater(
      client.get(Uri.parse('${AppConfig.baseUrl}/banners')),
      throwsA(isA<SocketException>()),
    );
  });

  test('une base publiée sur mesure n\'a pas de secours deviné', () async {
    await AppConfig.applyRemoteBase('https://backup.dj');
    var appels = 0;
    final client = BackendFailoverClient(
      inner: MockClient((request) async {
        appels++;
        throw const SocketException('injoignable');
      }),
    );

    await expectLater(
      client.get(Uri.parse('${AppConfig.baseUrl}/banners')),
      throwsA(isA<SocketException>()),
    );
    expect(appels, 1, reason: 'aucune seconde tentative à deviner');
  });
}
