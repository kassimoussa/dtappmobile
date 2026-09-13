import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';

/// Client HTTP tolérant à une panne d'un des deux points d'entrée du backend.
///
/// Le domaine et l'IP servent le même backend et présentent chacun un
/// certificat valide. Ce client :
///  1. aligne toute requête backend sur l'origine active
///     ([AppConfig.normalize]) — schéma et hôte, quelle que soit l'URL écrite
///     dans le code ou renvoyée par l'API ;
///  2. en cas d'échec purement réseau (DNS, connexion refusée, TLS, timeout),
///     rejoue la requête sur l'hôte de secours, **sans changer de schéma** :
///     la bascule contourne une panne d'hôte, jamais le chiffrement ;
///  3. mémorise l'hôte qui a fonctionné pour les requêtes suivantes et les
///     prochains lancements.
///
/// Les requêtes vers des services tiers (Cloudflare, Firebase, Google Maps…)
/// passent sans modification.
///
/// Branché globalement dans `main.dart` via `runWithClient`, il couvre aussi
/// bien `ApiClient` que les appels `http.get/post` directs des services.
class BackendFailoverClient extends http.BaseClient {
  BackendFailoverClient({http.Client? inner})
      // Zone.root : évite de récupérer ce même client via la fabrique
      // installée par `runWithClient` (récursion infinie).
      : _inner = inner ?? Zone.root.run(() => http.Client());

  /// Délai laissé au premier hôte avant de tenter le second.
  /// Volontairement court : un hôte injoignable ne renvoie rien, inutile
  /// d'attendre le timeout applicatif complet.
  static const Duration _firstAttemptTimeout = Duration(seconds: 10);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Sonde de joignabilité : passe telle quelle, sans réécriture ni bascule.
    if (request.headers.containsKey(AppConfig.probeHeader)) {
      request.headers.remove(AppConfig.probeHeader);
      return _inner.send(request);
    }

    if (!AppConfig.isBackend(request.url)) {
      return _inner.send(request);
    }

    // Le corps est mis en tampon : une requête finalisée n'est pas rejouable.
    final body = await request.finalize().toBytes();
    final headers = Map<String, String>.from(request.headers);
    final primary = AppConfig.normalize(request.url);

    try {
      return await _inner
          .send(_rebuild(request, headers, body, primary))
          .timeout(_firstAttemptTimeout);
    } catch (error) {
      if (!_isNetworkFailure(error)) rethrow;

      final fallback = AppConfig.withFallbackHost(primary);
      if (fallback == null) rethrow;

      debugPrint(
        '🌐 Failover: ${primary.host} a échoué (${error.runtimeType}) '
        '→ nouvelle tentative sur ${fallback.host}${primary.path}',
      );

      final response =
          await _inner.send(_rebuild(request, headers, body, fallback));
      // Le secours fonctionne : il devient l'hôte actif.
      unawaited(AppConfig.setActiveHost(fallback.host));
      return response;
    }
  }

  /// Reconstruit une requête rejouable vers [url].
  http.Request _rebuild(
    http.BaseRequest source,
    Map<String, String> headers,
    Uint8List body,
    Uri url,
  ) {
    return http.Request(source.method, url)
      ..headers.addAll(headers)
      ..followRedirects = source.followRedirects
      ..maxRedirects = source.maxRedirects
      ..persistentConnection = source.persistentConnection
      ..bodyBytes = body;
  }

  /// Distingue un échec de transport (à rejouer sur l'autre hôte) d'une
  /// réponse applicative en erreur (à laisser remonter telle quelle).
  bool _isNetworkFailure(Object error) =>
      error is SocketException ||
      error is HandshakeException ||
      error is TlsException ||
      error is HttpException ||
      error is http.ClientException ||
      error is TimeoutException;

  @override
  void close() => _inner.close();
}
