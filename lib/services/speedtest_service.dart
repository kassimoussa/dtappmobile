import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SpeedTestService {
  // URLs de test fiables
  static const String downloadTestUrl = 'https://speed.cloudflare.com/__down?bytes=10000000'; // 10 MB
  static const String uploadTestUrl = 'https://speed.cloudflare.com/__up'; // Upload test

  /// Teste la vitesse de téléchargement
  static Future<SpeedTestResult> testDownloadSpeed({
    Function(double progress, double currentSpeed)? onProgress,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      int totalBytes = 0;
      double currentSpeed = 0.0;

      final request = http.Request('GET', Uri.parse(downloadTestUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 10000000;

      await for (var chunk in response.stream) {
        totalBytes += chunk.length;
        final elapsedSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;

        if (elapsedSeconds > 0) {
          // Calcul de la vitesse en Mbps
          currentSpeed = (totalBytes * 8) / (elapsedSeconds * 1000000);

          // Calcul du pourcentage de progression
          final progress = (totalBytes / contentLength) * 100;

          onProgress?.call(progress, currentSpeed);
        }
      }

      stopwatch.stop();
      final totalSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;
      final speedMbps = (totalBytes * 8) / (totalSeconds * 1000000);

      return SpeedTestResult(
        speedMbps: speedMbps,
        bytes: totalBytes,
        durationSeconds: totalSeconds,
      );
    } catch (e) {
      debugPrint('Erreur test download: $e');
      rethrow;
    }
  }

  /// Teste la vitesse d'upload
  static Future<SpeedTestResult> testUploadSpeed({
    Function(double progress, double currentSpeed)? onProgress,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Créer des données de test (5 MB)
      final testDataSize = 5 * 1024 * 1024;
      final testData = List<int>.filled(testDataSize, 0);

      double currentSpeed = 0.0;
      int bytesSent = 0;

      final request = http.MultipartRequest('POST', Uri.parse(uploadTestUrl));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        testData,
        filename: 'speedtest.bin',
      ));

      // Simuler le progrès pour l'upload
      final progressTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) {
          bytesSent += (testDataSize ~/ 50); // Simuler l'envoi progressif
          if (bytesSent > testDataSize) bytesSent = testDataSize;

          final elapsedSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;
          if (elapsedSeconds > 0) {
            currentSpeed = (bytesSent * 8) / (elapsedSeconds * 1000000);
            final progress = (bytesSent / testDataSize) * 100;
            onProgress?.call(progress, currentSpeed);
          }

          if (bytesSent >= testDataSize) {
            timer.cancel();
          }
        },
      );

      final response = await request.send();
      progressTimer.cancel();

      stopwatch.stop();

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Upload status: ${response.statusCode}');
      }

      final totalSeconds = stopwatch.elapsed.inMilliseconds / 1000.0;
      final speedMbps = (testDataSize * 8) / (totalSeconds * 1000000);

      return SpeedTestResult(
        speedMbps: speedMbps,
        bytes: testDataSize,
        durationSeconds: totalSeconds,
      );
    } catch (e) {
      debugPrint('Erreur test upload: $e');
      rethrow;
    }
  }

  /// Teste le ping (latence)
  static Future<double> testPing() async {
    try {
      final stopwatch = Stopwatch()..start();

      await http.head(Uri.parse('https://www.google.com'));

      stopwatch.stop();
      return stopwatch.elapsed.inMilliseconds.toDouble();
    } catch (e) {
      debugPrint('Erreur test ping: $e');
      return -1;
    }
  }
}

class SpeedTestResult {
  final double speedMbps;
  final int bytes;
  final double durationSeconds;

  SpeedTestResult({
    required this.speedMbps,
    required this.bytes,
    required this.durationSeconds,
  });

  @override
  String toString() {
    return 'Speed: ${speedMbps.toStringAsFixed(2)} Mbps, '
        'Bytes: $bytes, Duration: ${durationSeconds.toStringAsFixed(2)}s';
  }
}
