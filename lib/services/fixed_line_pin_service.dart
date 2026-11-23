// lib/services/fixed_line_pin_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_client.dart';

/// Issue d'une vérification du PIN d'une ligne fixe.
enum FixedLinePinStatus {
  /// Couple (numéro, PIN) correct.
  verified,

  /// Numéro ou PIN incorrect (401 portant la clé `verified`).
  wrongPin,

  /// Format du numéro ou du PIN refusé par le serveur (422).
  invalidFormat,

  /// Verrou anti brute-force sur ce numéro (429 avec `retry_after`).
  locked,

  /// Limite de requêtes par IP atteinte (429 sans clé `verified`).
  tooManyRequests,

  /// OCS ou réseau indisponible (503, délai dépassé, réponse illisible).
  /// Ne dit RIEN sur le PIN : il ne faut surtout pas le présenter comme faux.
  unavailable,

  /// Session de l'app invalide ou expirée (401 sans clé `verified`).
  /// [ApiClient] a déjà effacé la session et renvoyé vers le login.
  sessionExpired,
}

class FixedLinePinResult {
  final FixedLinePinStatus status;

  /// Secondes avant de pouvoir réessayer ([locked], parfois [tooManyRequests]).
  final int? retryAfterSeconds;

  const FixedLinePinResult(this.status, {this.retryAfterSeconds});

  bool get isVerified => status == FixedLinePinStatus.verified;
}

/// Vérification du PIN d'une ligne fixe (le même que sur le portail client).
///
/// Le serveur parle à l'OCS : l'app ne le contacte jamais. Le PIN n'est ni
/// stocké ni journalisé ici ; il part dans le corps d'un POST, jamais dans l'URL.
class FixedLinePinService {
  /// Chemin sous `AppConfig.baseUrl` (route `api.fix.pin.verify`).
  static const String verifyPath = '/fix/pin/verify';

  /// Longueur acceptée par le serveur ; la règle exacte reste à l'OCS.
  static final RegExp _pinFormat = RegExp(r'^\d{3,12}$');

  static bool isValidPinFormat(String pin) => _pinFormat.hasMatch(pin);

  static Future<FixedLinePinResult> verify({
    required String cli,
    required String pin,
  }) async {
    try {
      final response = await ApiClient.postKeepingSessionOnAnswer(
        verifyPath,
        // Toujours des chaînes : un entier perdrait les zéros de tête.
        {'cli': cli.replaceAll(RegExp(r'\D'), ''), 'pin': pin},
        answerKey: 'verified',
      );
      return _interpret(response.statusCode, response.body, response.headers);
    } on TimeoutException {
      return const FixedLinePinResult(FixedLinePinStatus.unavailable);
    } catch (e) {
      // Pas de détail de l'erreur : une exception peut citer la requête.
      debugPrint('FixedLinePinService: échec réseau (${e.runtimeType})');
      return const FixedLinePinResult(FixedLinePinStatus.unavailable);
    }
  }

  static FixedLinePinResult _interpret(
    int statusCode,
    String body,
    Map<String, String> headers,
  ) {
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      // Corps non JSON (page d'erreur d'un proxy, par exemple).
    }
    final isBusinessAnswer = json != null && json.containsKey('verified');

    switch (statusCode) {
      case 200:
        return json?['verified'] == true
            ? const FixedLinePinResult(FixedLinePinStatus.verified)
            : const FixedLinePinResult(FixedLinePinStatus.unavailable);
      case 401:
        return isBusinessAnswer
            ? const FixedLinePinResult(FixedLinePinStatus.wrongPin)
            : const FixedLinePinResult(FixedLinePinStatus.sessionExpired);
      case 422:
        return const FixedLinePinResult(FixedLinePinStatus.invalidFormat);
      case 429:
        final retryAfter =
            _seconds(json?['retry_after']) ?? _seconds(headers['retry-after']);
        return FixedLinePinResult(
          isBusinessAnswer
              ? FixedLinePinStatus.locked
              : FixedLinePinStatus.tooManyRequests,
          retryAfterSeconds: retryAfter,
        );
      default:
        return const FixedLinePinResult(FixedLinePinStatus.unavailable);
    }
  }

  static int? _seconds(Object? value) {
    final seconds = value is num ? value.toInt() : int.tryParse('$value');
    return seconds != null && seconds > 0 ? seconds : null;
  }
}
