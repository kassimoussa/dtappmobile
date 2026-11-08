import 'package:dtservices/utils/refill_voucher_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const code = '348627345500';

  group('RefillVoucherParser', () {
    test('lit le lien tel: du ticket (# encodé)', () {
      expect(RefillVoucherParser.extractCode('tel:*166*$code%23'), code);
    });

    test('lit les écritures voisines de la commande USSD', () {
      expect(RefillVoucherParser.extractCode('tel:*166*$code#'), code);
      expect(RefillVoucherParser.extractCode('tel:%2A166%2A$code%23'), code);
      expect(RefillVoucherParser.extractCode('TEL:*166*$code%23'), code);
      expect(RefillVoucherParser.extractCode('*166#$code#'), code);
      expect(RefillVoucherParser.extractCode('*166*$code#'), code);
      expect(RefillVoucherParser.extractCode('*166*$code'), code);
    });

    test('lit le code seul, avec espaces ou tirets', () {
      expect(RefillVoucherParser.extractCode(code), code);
      expect(RefillVoucherParser.extractCode(' 3486 2734 5500 '), code);
      expect(RefillVoucherParser.extractCode('3486-2734-5500'), code);
    });

    test('refuse ce qui n\'est pas un code de recharge', () {
      expect(RefillVoucherParser.extractCode(null), isNull);
      expect(RefillVoucherParser.extractCode(''), isNull);
      expect(RefillVoucherParser.extractCode('bonjour'), isNull);
      expect(
        RefillVoucherParser.extractCode('https://exemple.dj/$code'),
        isNull,
      );
      expect(
        RefillVoucherParser.extractCode('WIFI:S:box;T:WPA;P:$code;;'),
        isNull,
      );
    });

    test('refuse un autre code USSD que la recharge', () {
      expect(RefillVoucherParser.extractCode('tel:*100*$code%23'), isNull);
      expect(RefillVoucherParser.extractCode('tel:*166%23'), isNull);
      expect(RefillVoucherParser.extractCode('tel:*166*77123456%23'), isNull);
    });

    test('refuse un code de mauvaise longueur', () {
      expect(RefillVoucherParser.extractCode('tel:*166*${code}1%23'), isNull);
      expect(
        RefillVoucherParser.extractCode('tel:*166*${code.substring(1)}%23'),
        isNull,
      );
      expect(RefillVoucherParser.extractCode('${code}1'), isNull);
    });

    test('ne plante pas sur un encodage cassé', () {
      expect(RefillVoucherParser.extractCode('tel:*166*%E0%A4%23'), isNull);
      expect(RefillVoucherParser.extractCode('%'), isNull);
    });
  });
}
