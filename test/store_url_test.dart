import 'package:dtservices/config/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteConfigService.resolveStoreUrl', () {
    test('retient une URL https valide fournie par Remote Config', () {
      expect(
        RemoteConfigService.resolveStoreUrl(
          TargetPlatform.iOS,
          'https://apps.apple.com/app/id123456789',
        ),
        'https://apps.apple.com/app/id123456789',
      );
    });

    test('ignore les espaces autour de la valeur', () {
      expect(
        RemoteConfigService.resolveStoreUrl(
          TargetPlatform.iOS,
          '  https://apps.apple.com/app/id123456789\n',
        ),
        'https://apps.apple.com/app/id123456789',
      );
    });

    test('iOS sans lien : null, donc les actions sont masquées', () {
      expect(
        RemoteConfigService.resolveStoreUrl(TargetPlatform.iOS, ''),
        isNull,
      );
      expect(
        RemoteConfigService.resolveStoreUrl(TargetPlatform.iOS, null),
        isNull,
      );
    });

    test('Android sans lien exploitable : repli sur le Play Store compilé', () {
      for (final remote in [null, '', 'pas une url', 'http://exemple.dj']) {
        expect(
          RemoteConfigService.resolveStoreUrl(TargetPlatform.android, remote),
          RemoteConfigService.compiledPlayStoreUrl,
        );
      }
    });

    test('rejette le http en clair et les URL sans hôte', () {
      for (final remote in [
        'http://apps.apple.com/app/id1',
        'https://',
        'apps.apple.com/app/id1',
      ]) {
        expect(
          RemoteConfigService.resolveStoreUrl(TargetPlatform.iOS, remote),
          isNull,
          reason: remote,
        );
      }
    });
  });

  group('RemoteConfigService.reviewUrlFor', () {
    test('iOS : ajoute action=write-review', () {
      expect(
        RemoteConfigService.reviewUrlFor(
          TargetPlatform.iOS,
          'https://apps.apple.com/app/id123456789',
        ),
        'https://apps.apple.com/app/id123456789?action=write-review',
      );
    });

    test('iOS : conserve les paramètres existants', () {
      final url = Uri.parse(
        RemoteConfigService.reviewUrlFor(
          TargetPlatform.iOS,
          'https://apps.apple.com/dj/app/id123456789?l=fr',
        ),
      );
      expect(url.queryParameters, {'l': 'fr', 'action': 'write-review'});
    });

    test('Android : lien inchangé', () {
      expect(
        RemoteConfigService.reviewUrlFor(
          TargetPlatform.android,
          RemoteConfigService.compiledPlayStoreUrl,
        ),
        RemoteConfigService.compiledPlayStoreUrl,
      );
    });
  });
}
