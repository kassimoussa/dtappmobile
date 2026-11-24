import 'package:dtservices/utils/safe_link.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les liens des bannières et popups viennent du serveur : seul l'HTTPS peut
/// être ouvert hors de l'app.
void main() {
  group('parseWebLink : liens acceptés', () {
    test('une adresse HTTPS passe telle quelle', () {
      final uri = parseWebLink('https://djiboutitelecom.dj/promo?id=3#haut');

      expect(uri, isNotNull);
      expect(uri!.host, 'djiboutitelecom.dj');
      expect(uri.path, '/promo');
      expect(uri.queryParameters, {'id': '3'});
    });

    test('espaces autour et schéma en majuscules tolérés', () {
      expect(parseWebLink('  https://mydtapp.djiboutitelecom.dj/a \n'), isNotNull);
      expect(parseWebLink('HTTPS://djiboutitelecom.dj'), isNotNull);
    });

    test('un port explicite est conservé', () {
      expect(parseWebLink('https://djiboutitelecom.dj:8443/x')!.port, 8443);
    });
  });

  group('parseWebLink : liens refusés', () {
    test('vide, absent ou illisible', () {
      for (final value in [null, '', '   ', 'pas une url', '//djiboutitelecom.dj/a']) {
        expect(parseWebLink(value), isNull, reason: '"$value"');
      }
    });

    test('tout schéma autre que HTTPS', () {
      const refuses = [
        'http://djiboutitelecom.dj',
        'tel:+25377000000',
        'tel:*100%23',
        'sms:77000000?body=STOP',
        'mailto:contact@djiboutitelecom.dj',
        'intent://scan/#Intent;scheme=zxing;package=com.x;end',
        'market://details?id=com.djiboutitelecom.dtappmobile',
        'itms-apps://apps.apple.com/app/id1',
        'whatsapp://send?phone=25377000000',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'content://com.android.contacts/contacts',
        'ftp://djiboutitelecom.dj/x',
      ];

      for (final value in refuses) {
        expect(parseWebLink(value), isNull, reason: '"$value"');
      }
    });

    test('HTTPS sans hôte', () {
      expect(parseWebLink('https://'), isNull);
      expect(parseWebLink('https:///chemin'), isNull);
    });

    test('identifiants dans l\'adresse : l\'hôte affiché n\'est pas l\'hôte réel',
        () {
      expect(parseWebLink('https://djiboutitelecom.dj@evil.com/x'), isNull);
      expect(parseWebLink('https://user:pw@djiboutitelecom.dj'), isNull);
    });
  });
}
