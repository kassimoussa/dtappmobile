import 'dart:io';

import 'package:dtservices/services/speedtest_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Choix du serveur de mesure : c'est lui qui détermine le chiffre affiché,
/// bien plus que la méthode de mesure.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SpeedTestService.setTargetForTest(null);
    SpeedTestService.primaryTarget = SpeedTestService.djiboutiTelecom;
    // flutter_test remplace HttpClient par un bouchon qui répond 400 à tout :
    // sans ça, la sonde ne pourrait jamais joindre le serveur local du test et
    // ces cas ne vérifieraient rien.
    HttpOverrides.global = null;
  });

  tearDown(() {
    SpeedTestService.setTargetForTest(null);
    SpeedTestService.primaryTarget = SpeedTestService.djiboutiTelecom;
  });

  test('la forme des URLs suit le serveur visé', () {
    // OoklaServer attend `size`, Cloudflare attend `bytes` : confondre les deux
    // renvoie une réponse vide et un débit nul.
    expect(
      SpeedTestService.djiboutiTelecom.downloadFor(50000000).toString(),
      'http://ookla.djiboutitelecom.dj:8080/download?size=50000000',
    );
    expect(
      SpeedTestService.cloudflare.downloadFor(50000000).toString(),
      'https://speed.cloudflare.com/__down?bytes=50000000',
    );
  });

  test('un serveur local joignable est préféré', () async {
    final serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((req) async {
      req.response.write('hello');
      await req.response.close();
    });
    addTearDown(() => serveur.close(force: true));

    SpeedTestService.primaryTarget = SpeedTestTarget(
      name: 'local',
      downloadUrl: 'http://127.0.0.1:${serveur.port}/download',
      uploadUrl: 'http://127.0.0.1:${serveur.port}/upload',
      latencyUrl: 'http://127.0.0.1:${serveur.port}/hello',
      sizeParam: 'size',
    );

    // La sonde doit réellement joindre ce serveur et le retenir.
    expect((await SpeedTestService.resolveTarget()).name, 'local');
  });

  test('serveur local injoignable : repli sur Cloudflare', () async {
    // On ouvre puis referme un port pour être certain que rien n'écoute.
    final mort = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = mort.port;
    await mort.close(force: true);

    SpeedTestService.primaryTarget = SpeedTestTarget(
      name: 'injoignable',
      downloadUrl: 'http://127.0.0.1:$port/download',
      uploadUrl: 'http://127.0.0.1:$port/upload',
      latencyUrl: 'http://127.0.0.1:$port/hello',
      sizeParam: 'size',
    );

    final chosen = await SpeedTestService.resolveTarget();

    // La mesure doit basculer sur le repli international, jamais échouer.
    expect(chosen.name, SpeedTestService.cloudflare.name);
    expect(chosen.sizeParam, 'bytes');
  });

  test('la cible est mémorisée pour la session', () async {
    final premier = await SpeedTestService.resolveTarget();
    final second = await SpeedTestService.resolveTarget();
    expect(identical(premier, second), isTrue);
  });
}
