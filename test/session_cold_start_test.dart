import 'dart:convert';

import 'package:dtservices/providers/auth_provider.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phone = '25377000000';
const _token = 'tok-1234567890';

/// État du disque comme l'exécution précédente l'a laissé.
Future<void> _persistSession({required Duration idle}) async {
  // Repart d'une mémoire vide, comme un processus neuf.
  SharedPreferences.setMockInitialValues({});
  await UserSession.clearSession();

  SharedPreferences.setMockInitialValues({
    'user_phone_number': _phone,
    'last_activity_time': DateTime.now().subtract(idle).millisecondsSinceEpoch,
    'session_token': _token,
    'has_pin': true,
  });
}

/// Crée l'AuthProvider (donc « démarre l'app ») et rend les requêtes émises.
Future<List<http.Request>> _coldStart({int expectedRequests = 0}) async {
  final requests = <http.Request>[];
  await http.runWithClient(
    () async {
      AuthProvider();
      // Le nettoyage est asynchrone : on attend qu'il ait fini.
      for (var i = 0; i < 200; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (requests.length >= expectedRequests && i >= 5) break;
      }
    },
    () => MockClient((request) async {
      requests.add(request);
      return http.Response('{"status":"success"}', 200);
    }),
  );
  return requests;
}

void main() {
  test(
    'démarrage à froid avec une session valide : elle est terminée',
    () async {
      await _persistSession(idle: const Duration(minutes: 1));

      await _coldStart(expectedRequests: 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('session_token'), isNull);
      expect(prefs.getString('user_phone_number'), isNull);
      expect(await UserSession.isAuthenticated(), isFalse);
      // Le numéro reste proposé sur l'écran de connexion.
      expect(prefs.getString('last_used_phone'), _phone);
    },
  );

  test('le jeton est révoqué côté serveur', () async {
    await _persistSession(idle: const Duration(minutes: 1));

    final requests = await _coldStart(expectedRequests: 1);

    expect(requests, hasLength(1));
    expect(requests.single.url.path, endsWith('/mobile/logout'));
    expect(requests.single.headers['Authorization'], 'Bearer $_token');
    expect(jsonDecode(requests.single.body), {'session_token': _token});
  });

  test('sans session : rien à terminer, aucun appel réseau', () async {
    SharedPreferences.setMockInitialValues({});
    await UserSession.clearSession();

    final requests = await _coldStart();

    expect(requests, isEmpty);
    expect(await UserSession.isAuthenticated(), isFalse);
  });

  test(
    'session déjà expirée : pas de révocation (jeton inutilisable)',
    () async {
      await _persistSession(idle: const Duration(minutes: 30));

      final requests = await _coldStart();

      expect(requests, isEmpty);
      expect(await UserSession.isAuthenticated(), isFalse);
    },
  );

  test(
    'mise en arrière-plan puis retour sous 5 min : la session est gardée',
    () async {
      SharedPreferences.setMockInitialValues({});
      await UserSession.clearSession();
      await UserSession.createSession(
        _phone,
        sessionToken: _token,
        hasPin: true,
      );

      await UserSession.appPaused();
      await UserSession.appResumed();

      expect(await UserSession.isAuthenticated(), isTrue);
      expect(await UserSession.getSessionToken(), _token);
    },
  );
}
