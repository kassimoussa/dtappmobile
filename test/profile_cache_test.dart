import 'package:dtservices/services/profile_cache.dart';
import 'package:dtservices/services/profile_service.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _profile(Object? name) => {
  'user': {'phone_number': '25377000000', 'name': name},
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileCache.clear();
  });

  group('ProfileCache.firstName', () {
    test('prend le premier mot du nom', () {
      expect(ProfileCache.firstName(_profile('Kassim Moussa Ali')), 'Kassim');
    });

    test('garde un nom d\'un seul mot', () {
      expect(ProfileCache.firstName(_profile('Kassim')), 'Kassim');
    });

    test('ignore les espaces autour et entre les mots', () {
      expect(ProfileCache.firstName(_profile('  Kassim \t Ali\n')), 'Kassim');
    });

    test('garde les accents et les tirets', () {
      expect(
        ProfileCache.firstName(_profile('Aïcha-Fatouma Ali')),
        'Aïcha-Fatouma',
      );
    });

    test('renvoie null quand il n\'y a pas de nom exploitable', () {
      for (final name in [null, '', '   ', 42]) {
        expect(ProfileCache.firstName(_profile(name)), isNull, reason: '$name');
      }
    });

    test('renvoie null quand le profil est absent ou incomplet', () {
      expect(ProfileCache.firstName(null), isNull);
      expect(ProfileCache.firstName(<String, dynamic>{}), isNull);
      expect(ProfileCache.firstName({'user': null}), isNull);
      expect(ProfileCache.firstName({'user': 'pas une map'}), isNull);
    });
  });

  group('cache partagé', () {
    test('ProfileService.cachedProfile alimente le notifier', () {
      var notified = 0;
      ProfileCache.profile.addListener(() => notified++);
      addTearDown(ProfileCache.clear);

      ProfileService.cachedProfile = _profile('Kassim Ali');

      expect(notified, 1);
      expect(ProfileCache.firstName(ProfileCache.profile.value), 'Kassim');
      expect(ProfileService.cachedProfile, same(ProfileCache.profile.value));
    });

    test('un nouveau profil (nom modifié) est signalé à l\'accueil', () {
      ProfileService.cachedProfile = _profile('Kassim Ali');
      final names = <String?>[];
      ProfileCache.profile.addListener(
        () => names.add(ProfileCache.firstName(ProfileCache.profile.value)),
      );

      ProfileService.cachedProfile = _profile('Hodan Ali');

      expect(names, ['Hodan']);
    });

    test(
      'clearSession vide le profil : pas de prénom d\'un autre compte',
      () async {
        ProfileService.cachedProfile = _profile('Kassim Ali');

        await UserSession.clearSession();

        expect(ProfileService.cachedProfile, isNull);
        expect(ProfileCache.firstName(ProfileCache.profile.value), isNull);
      },
    );

    test('clearAllData vide aussi le profil', () async {
      ProfileService.cachedProfile = _profile('Kassim Ali');

      await UserSession.clearAllData();

      expect(ProfileService.cachedProfile, isNull);
    });
  });
}
