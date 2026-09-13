import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Cible de mesure : un serveur et la forme de ses URLs.
class SpeedTestTarget {
  const SpeedTestTarget({
    required this.name,
    required this.downloadUrl,
    required this.uploadUrl,
    required this.latencyUrl,
    required this.sizeParam,
  });

  final String name;
  final String downloadUrl;
  final String uploadUrl;
  final String latencyUrl;

  /// Nom du paramètre de taille : `size` chez OoklaServer, `bytes` chez
  /// Cloudflare.
  final String sizeParam;

  Uri downloadFor(int bytes) => Uri.parse('$downloadUrl?$sizeParam=$bytes');
}

/// Service de mesure de débit réseau (download / upload / latence).
///
/// **Le choix du serveur détermine le résultat**, bien plus que la méthode.
/// Mesurer vers Cloudflare depuis Djibouti donnait ~38 Mbps pour 117 ms de
/// RTT, là où Speedtest Ookla affichait 189 Mbps à 6 ms : le premier chiffre
/// mesure le transit international, le second la ligne de l'abonné. Un test
/// d'opérateur doit parler de la ligne.
///
/// On vise donc en priorité le serveur de test hébergé par Djibouti Telecom —
/// celui-là même qu'utilise Ookla — et l'on ne retombe sur Cloudflare que s'il
/// est injoignable, auquel cas le chiffre affiché redevient un débit
/// international.
///
/// Le serveur DT n'écoute qu'en HTTP clair : le trafic n'est fait que d'octets
/// aléatoires, sans donnée personnelle, et l'exception cleartext est limitée à
/// cet hôte (network_security_config.xml, NSAppTransportSecurity). À revoir le
/// jour où son certificat sera renouvelé.
///
/// Principes de fiabilité :
///   * plusieurs connexions parallèles pour saturer les liens rapides ;
///   * mesure bornée dans le temps (régime établi) et non sur une taille fixe ;
///   * exclusion de la phase de démarrage lent (« slow-start » TCP) ;
///   * vitesse instantanée calculée par fenêtre glissante ;
///   * upload basé sur les octets réellement poussés dans la socket
///     (plus aucune simulation par minuterie).
class SpeedTestService {
  /// Serveur de test de Djibouti Telecom (OoklaServer). Cible par défaut.
  static const SpeedTestTarget djiboutiTelecom = SpeedTestTarget(
    name: 'Djibouti Telecom',
    downloadUrl: 'http://ookla.djiboutitelecom.dj:8080/download',
    uploadUrl: 'http://ookla.djiboutitelecom.dj:8080/upload',
    latencyUrl: 'http://ookla.djiboutitelecom.dj:8080/hello',
    sizeParam: 'size',
  );

  /// Repli international, si le serveur local ne répond pas.
  static const SpeedTestTarget cloudflare = SpeedTestTarget(
    name: 'Cloudflare',
    downloadUrl: 'https://speed.cloudflare.com/__down',
    uploadUrl: 'https://speed.cloudflare.com/__up',
    latencyUrl: 'https://speed.cloudflare.com/__down?bytes=0',
    sizeParam: 'bytes',
  );

  static SpeedTestTarget? _target;

  /// Cible tentée en premier. Variable uniquement pour les tests : en
  /// production c'est toujours le serveur de Djibouti Telecom.
  @visibleForTesting
  static SpeedTestTarget primaryTarget = djiboutiTelecom;

  /// Cible retenue pour la session, choisie au premier test.
  static Future<SpeedTestTarget> resolveTarget() async {
    final known = _target;
    if (known != null) return known;

    final primary = primaryTarget;
    final chosen = await _isReachable(primary) ? primary : cloudflare;
    if (chosen == cloudflare) {
      debugPrint(
        '⚠️ SpeedTest: serveur DT injoignable → repli sur Cloudflare, '
        'le chiffre mesuré sera un débit international',
      );
    }
    _target = chosen;
    return chosen;
  }

  /// Sonde courte : inutile de faire patienter l'utilisateur si le serveur
  /// local ne répond pas.
  static Future<bool> _isReachable(SpeedTestTarget target) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client.getUrl(Uri.parse(target.latencyUrl));
      final resp = await req.close().timeout(const Duration(seconds: 3));
      await resp.drain<void>();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  @visibleForTesting
  static void setTargetForTest(SpeedTestTarget? target) => _target = target;

  // Le serveur local répond en quelques millisecondes : quelques connexions
  // suffisent à saturer le lien. Sur le repli international, où la latence
  // plafonne chaque connexion (débit ≈ fenêtre / RTT), le parallélisme est ce
  // qui permet d'approcher la capacité réelle — d'où un nombre relevé.
  static const int _downloadConnections = 8;
  static const int _uploadConnections = 4;
  static const Duration _downloadDuration = Duration(seconds: 10);
  static const Duration _uploadDuration = Duration(seconds: 10);
  // Fenêtre de démarrage ignorée pour ne mesurer que le régime établi.
  static const Duration _warmup = Duration(milliseconds: 1500);
  static const int _latencySamples = 8;

  static const int _chunkSize = 256 * 1024; // 256 KB
  // Cloudflare plafonne __down (100 Mo => 403). On reste sous la limite.
  static const int _downloadBytesPerRequest = 50 * 1000 * 1000; // 50 MB
  static const int _uploadBytesPerRequest = 50 * 1024 * 1024; // 50 MB

  /// Mesure la latence (ping médian) et la gigue (jitter) en millisecondes.
  ///
  /// Réutilise une même connexion (keep-alive) pour ne pas recompter le
  /// DNS/TCP/TLS à chaque échantillon, et ignore la première requête (à froid).
  static Future<({double ping, double jitter})> measureLatency() async {
    final target = await resolveTarget();
    final url = Uri.parse(target.latencyUrl);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    final samples = <double>[];
    try {
      // Requête de chauffe hors mesure (établit la connexion).
      await _timedRequest(client, url);
      for (var i = 0; i < _latencySamples; i++) {
        final ms = await _timedRequest(client, url);
        if (ms != null) samples.add(ms);
      }
    } catch (e) {
      debugPrint('Erreur latence: $e');
    } finally {
      client.close(force: true);
    }

    if (samples.isEmpty) return (ping: -1.0, jitter: 0.0);
    samples.sort();
    final ping = samples[samples.length ~/ 2]; // médiane

    double jitter = 0;
    if (samples.length > 1) {
      double sum = 0;
      for (var i = 1; i < samples.length; i++) {
        sum += (samples[i] - samples[i - 1]).abs();
      }
      jitter = sum / (samples.length - 1);
    }
    return (ping: ping, jitter: jitter);
  }

  static Future<double?> _timedRequest(HttpClient client, Uri url) async {
    try {
      final sw = Stopwatch()..start();
      final req = await client.getUrl(url);
      final resp = await req.close();
      await resp.drain<void>();
      sw.stop();
      return sw.elapsedMicroseconds / 1000.0;
    } catch (_) {
      return null;
    }
  }

  /// Débit descendant en Mbps. `onProgress` reçoit la vitesse instantanée.
  static Future<double> measureDownload({
    void Function(double instantMbps)? onProgress,
  }) async {
    final url = (await resolveTarget()).downloadFor(_downloadBytesPerRequest);
    return _measureThroughput(
      connections: _downloadConnections,
      duration: _downloadDuration,
      onProgress: onProgress,
      task: (client, addBytes, shouldStop) async {
        while (!shouldStop()) {
          final req = await client.getUrl(url);
          final resp = await req.close();
          if (resp.statusCode != 200) {
            await resp.drain<void>();
            throw SpeedTestException('HTTP ${resp.statusCode}');
          }
          await for (final chunk in resp) {
            addBytes(chunk.length);
            if (shouldStop()) break;
          }
        }
      },
    );
  }

  /// Débit montant en Mbps. `onProgress` reçoit la vitesse instantanée.
  static Future<double> measureUpload({
    void Function(double instantMbps)? onProgress,
  }) async {
    final uploadUrl = Uri.parse((await resolveTarget()).uploadUrl);
    final chunk = Uint8List(_chunkSize);
    return _measureThroughput(
      connections: _uploadConnections,
      duration: _uploadDuration,
      onProgress: onProgress,
      task: (client, addBytes, shouldStop) async {
        while (!shouldStop()) {
          final req = await client.postUrl(uploadUrl);
          req.headers.contentType = ContentType.binary;
          req.contentLength = _uploadBytesPerRequest;

          int sent = 0;
          final stream = () async* {
            while (sent < _uploadBytesPerRequest && !shouldStop()) {
              final take = (_uploadBytesPerRequest - sent) < chunk.length
                  ? (_uploadBytesPerRequest - sent)
                  : chunk.length;
              sent += take;
              // Compté au moment où la socket accepte le bloc (backpressure
              // gérée par addStream) → reflète le débit réel.
              addBytes(take);
              yield take == chunk.length
                  ? chunk
                  : Uint8List.sublistView(chunk, 0, take);
            }
          }();

          try {
            await req.addStream(stream);
            final resp = await req.close();
            await resp.drain<void>();
          } catch (_) {
            break; // connexion coupée à l'arrêt du test
          }
        }
      },
    );
  }

  /// Moteur commun : lance `connections` tâches en parallèle, agrège les octets,
  /// borne la mesure à `duration`, et renvoie le débit du régime établi (Mbps).
  static Future<double> _measureThroughput({
    required int connections,
    required Duration duration,
    required void Function(double instantMbps)? onProgress,
    required Future<void> Function(
      HttpClient client,
      void Function(int) addBytes,
      bool Function() shouldStop,
    ) task,
  }) async {
    var totalBytes = 0;
    var stop = false;
    final overall = Stopwatch()..start();

    void addBytes(int n) => totalBytes += n;
    bool shouldStop() => stop;

    // Fenêtre glissante (vitesse instantanée) + borne de fin de warm-up.
    var lastBytes = 0;
    var lastTickUs = 0;
    var warmupBytes = 0;
    var warmupUs = 0;
    var warmupDone = false;

    final ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final nowUs = overall.elapsedMicroseconds;
      final dUs = nowUs - lastTickUs;
      if (dUs > 0) {
        final dBytes = totalBytes - lastBytes;
        onProgress?.call((dBytes * 8) / dUs); // octets*8 / µs == Mbit/s
      }
      lastBytes = totalBytes;
      lastTickUs = nowUs;

      if (!warmupDone && overall.elapsed >= _warmup) {
        warmupDone = true;
        warmupBytes = totalBytes;
        warmupUs = nowUs;
      }
    });

    final clients = <HttpClient>[];
    final futures = <Future<void>>[];
    for (var i = 0; i < connections; i++) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..idleTimeout = const Duration(seconds: 8);
      clients.add(client);
      futures.add(task(client, addBytes, shouldStop).catchError((_) {}));
    }

    // On s'arrête à la durée impartie, ou plus tôt si toutes les tâches meurent.
    await Future.any([
      Future<void>.delayed(duration),
      Future.wait(futures),
    ]);

    stop = true;
    final endUs = overall.elapsedMicroseconds;
    final endBytes = totalBytes;
    ticker.cancel();
    for (final c in clients) {
      c.close(force: true);
    }
    try {
      await Future.wait(futures).timeout(const Duration(seconds: 2));
    } catch (_) {}
    overall.stop();

    if (endBytes == 0) {
      throw const SpeedTestException('Aucune donnée transférée');
    }

    // Régime établi (après warm-up) si disponible, sinon mesure globale.
    final measuredBytes = warmupDone ? (endBytes - warmupBytes) : endBytes;
    final measuredUs = warmupDone ? (endUs - warmupUs) : endUs;
    if (measuredUs <= 0) return 0;
    return (measuredBytes * 8) / measuredUs; // Mbps
  }
}

class SpeedTestException implements Exception {
  final String message;
  const SpeedTestException(this.message);
  @override
  String toString() => message;
}
