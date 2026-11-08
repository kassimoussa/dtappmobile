import 'package:dtservices/utils/refill_code_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = RefillCodeInputFormatter();

  /// Ce que contient le champ après avoir tapé / collé [text] dans [before].
  String apply(String text, {String before = ''}) =>
      formatter
          .formatEditUpdate(
            TextEditingValue(text: before),
            TextEditingValue(text: text),
          )
          .text;

  group('RefillCodeInputFormatter', () {
    test('groupe les chiffres par 4', () {
      expect(apply('1'), '1');
      expect(apply('1234'), '1234');
      expect(apply('12345'), '1234 5');
      expect(apply('348627345500'), '3486 2734 5500');
    });

    test('écarte tout ce qui n\'est pas un chiffre', () {
      expect(apply('abc'), '');
      expect(apply('12a3-4'), '1234');
      expect(apply('*#+.,'), '');
      expect(apply('3486-2734-5500'), '3486 2734 5500');
      expect(apply('Code : 348627345500'), '3486 2734 5500');
    });

    test('refuse un collage de plus de 12 chiffres au lieu de le tronquer', () {
      // Sans ce refus : « 1663 4862 7345 », un faux code.
      expect(apply('*166*348627345500#', before: '12'), '12');
      expect(apply('*166#348627345500#'), '');
      expect(apply('3486273455001'), '');
    });

    test('un 13e chiffre tapé est refusé', () {
      expect(
        apply('3486 2734 55001', before: '3486 2734 5500'),
        '3486 2734 5500',
      );
    });

    test('un retour arrière efface le dernier chiffre', () {
      expect(apply('3486 2734 550', before: '3486 2734 5500'), '3486 2734 550');
      expect(apply('3486 ', before: '3486 2'), '3486');
    });

    test('garde le curseur à la fin', () {
      final value = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '12345'),
      );
      expect(value.selection, const TextSelection.collapsed(offset: 6));
    });
  });

  testWidgets('dans un champ : lettres et symboles ne s\'affichent pas', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: const [RefillCodeInputFormatter()],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ab12*#34');
    expect(controller.text, '1234');

    await tester.enterText(find.byType(TextField), '*166*348627345500#');
    expect(controller.text, '1234'); // refusé : le champ garde sa valeur

    await tester.enterText(find.byType(TextField), '348627345500');
    expect(controller.text, '3486 2734 5500');
  });
}
