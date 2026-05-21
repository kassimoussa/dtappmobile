import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Résultat d'une vérification de rate limit.
class RateLimitResult {
  /// true = l'envoi est autorisé.
  final bool allowed;

  /// Durée restante avant de pouvoir renvoyer (null si autorisé).
  final Duration? waitDuration;

  /// true = limite globale de la fenêtre atteinte (ex: 3 envois / 10 min).
  final bool windowExceeded;

  const RateLimitResult.allowed()
      : allowed = true,
        waitDuration = null,
        windowExceeded = false;

  const RateLimitResult.cooldown(Duration wait)
      : allowed = false,
        waitDuration = wait,
        windowExceeded = false;

  const RateLimitResult.windowExceeded(Duration wait)
      : allowed = false,
        waitDuration = wait,
        windowExceeded = true;
}

/// Limite les envois d'OTP par numéro de téléphone.
///
/// Règles :
///   - Délai minimum entre deux envois     : [_cooldown]   (60 s)
///   - Nombre max d'envois par fenêtre      : [_maxAttempts] (3)
///   - Durée de la fenêtre                  : [_window]     (10 min)
class OtpRateLimiter {
  static const int _maxAttempts = 3;
  static const Duration _window = Duration(minutes: 10);
  static const Duration _cooldown = Duration(seconds: 60);

  static String _key(String phone) => 'otp_attempts_$phone';

  /// Vérifie si un envoi est autorisé pour ce numéro.
  static Future<RateLimitResult> check(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(phoneNumber));
    final attempts = _parseAttempts(raw);
    final now = DateTime.now();

    // Purger les entrées hors fenêtre
    attempts.removeWhere((t) => now.difference(t) > _window);

    if (attempts.isEmpty) return const RateLimitResult.allowed();

    // Cooldown : délai depuis le dernier envoi
    final lastSent = attempts.last;
    final sinceLast = now.difference(lastSent);
    if (sinceLast < _cooldown) {
      return RateLimitResult.cooldown(_cooldown - sinceLast);
    }

    // Fenêtre : trop d'envois sur la période
    if (attempts.length >= _maxAttempts) {
      final oldest = attempts.first;
      final windowEnd = oldest.add(_window);
      return RateLimitResult.windowExceeded(windowEnd.difference(now));
    }

    return const RateLimitResult.allowed();
  }

  /// Enregistre un envoi réussi.
  static Future<void> record(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(phoneNumber));
    final attempts = _parseAttempts(raw);
    final now = DateTime.now();

    // Purger avant d'enregistrer
    attempts.removeWhere((t) => now.difference(t) > _window);
    attempts.add(now);

    await prefs.setString(
      _key(phoneNumber),
      jsonEncode(attempts.map((t) => t.toIso8601String()).toList()),
    );
  }

  /// Réinitialise le compteur (ex: après connexion réussie).
  static Future<void> reset(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(phoneNumber));
  }

  static List<DateTime> _parseAttempts(String? raw) {
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((s) => DateTime.parse(s as String)).toList();
    } catch (_) {
      return [];
    }
  }
}
