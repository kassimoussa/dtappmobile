import 'package:dtservices/services/persisted_api_cache.dart';
import 'package:dtservices/services/topup_api_service.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Soldes, packages et forfaits gardés sur disque sont liés à la ligne de la
/// session : la fin de session doit les effacer, sans toucher au reste.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Clés qui ne dépendent pas de la session et doivent survivre. Trois d'entre
  // elles commencent par « api_ » comme les caches, sans en être : un nettoyage
  // trop large effacerait l'hôte du backend appris ou publié.
  const survivors = {
    'language_code': 'fr',
    'api_timeout': 123,
    'api_remote_base': 'https://api.djiboutitelecom.dj',
    'api_active_host': 'api.djiboutitelecom.dj',
  };

  const cached = {
    'topup_cache_balances_77000000_21000000': '{"success":true}',
    'topup_ttl_balances_77000000_21000000': 1,
    'topup_cache_packages_77000000_21000000_4': '{"success":true}',
    'topup_ttl_packages_77000000_21000000_4': 1,
    'api_cache_forfaits_77000000': '[]',
    'api_ttl_forfaits_77000000': 1,
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({
      ...survivors,
      ...cached,
      'user_phone_number': '25377000000',
      'session_token': 'jeton',
    });
  });

  Future<Set<String>> keys() async =>
      (await SharedPreferences.getInstance()).getKeys();

  test('clearSession efface les réponses gardées, garde le reste', () async {
    await UserSession.clearSession();

    final left = await keys();
    expect(left.intersection(cached.keys.toSet()), isEmpty);
    expect(left.containsAll(survivors.keys), isTrue);
  });

  test('clearAllData aussi', () async {
    await UserSession.clearAllData();

    final left = await keys();
    expect(left.intersection(cached.keys.toSet()), isEmpty);
    expect(left.containsAll(survivors.keys), isTrue);
  });

  test('PersistedApiCache.clear ne touche pas à la session elle-même', () async {
    await PersistedApiCache.clear();

    final left = await keys();
    expect(left.intersection(cached.keys.toSet()), isEmpty);
    expect(left, containsAll(['user_phone_number', 'session_token']));
  });

  // Le test qui compte : une vraie réponse mise en cache PAR LE SERVICE est
  // retrouvée par le nettoyage. Un préfixe changé d'un côté seulement le casse.
  test('une réponse TopUp réellement mise en cache est effacée à la fin de session',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = TopUpApiService(
      client: MockClient(
        (request) async => http.Response(
          '{"success":true,"balances":[],"total_balances":0,'
          '"summary":{"total_balances":0,"data_total_bytes":0,'
          '"voice_total_seconds":0}}',
          200,
        ),
      ),
    );

    await service.getBalances(
      msisdn: '77000000',
      isdn: '21000000',
      useCache: true,
    );

    final written = (await keys()).where((k) => k.startsWith('topup_')).toSet();
    expect(written, isNotEmpty, reason: 'le service doit avoir mis en cache');

    await UserSession.clearSession();

    expect((await keys()).where((k) => k.startsWith('topup_')), isEmpty);
  });
}
