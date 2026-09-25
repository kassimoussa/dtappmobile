import 'package:flutter_test/flutter_test.dart';
import 'package:dtservices/exceptions/topup_exception.dart';

void main() {
  group('TopUpValidator.isValidFixed', () {
    test('accepte les fixes de la capitale (21) et des régions (27)', () {
      for (final n in ['21123456', '27123456', '25321123456', '25327123456']) {
        expect(TopUpValidator.isValidFixed(n), isTrue, reason: n);
      }
    });

    test('refuse les autres préfixes et les longueurs incorrectes', () {
      for (final n in ['22123456', '77123456', '2112345', '271234567', '25322123456', '27']) {
        expect(TopUpValidator.isValidFixed(n), isFalse, reason: n);
      }
    });
  });
}
