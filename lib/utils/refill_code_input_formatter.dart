import 'package:flutter/services.dart';

/// Champ du code de recharge : des chiffres uniquement, 12 au plus, affichés
/// par groupes de 4 (« 3486 2734 5500 ») pour la lisibilité.
///
/// Tout ce qui n'est pas un chiffre est écarté, à la frappe comme au collage.
/// Un texte qui contiendrait plus de 12 chiffres est refusé en entier plutôt
/// que tronqué : coller `*166*348627345500#` donnerait sinon `166348627345`,
/// un faux code qui part au serveur sans que rien ne le signale.
class RefillCodeInputFormatter extends TextInputFormatter {
  const RefillCodeInputFormatter();

  static const codeLength = 12;
  static const _groupSize = 4;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > codeLength) return oldValue;

    final formatted = [
      for (var i = 0; i < digits.length; i += _groupSize)
        digits.substring(i, (i + _groupSize).clamp(0, digits.length)),
    ].join(' ');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
