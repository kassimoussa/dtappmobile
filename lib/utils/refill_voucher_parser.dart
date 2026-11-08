/// Extrait le code de recharge à 12 chiffres d'un QR code de ticket (voucher).
///
/// Le QR du ticket contient la commande USSD de recharge sous forme de lien
/// `tel:` : `tel:*166*348627345500%23`. On accepte aussi les écritures voisines
/// (`#` non encodé, `*166#<code>#` comme dans le guide imprimé sur le ticket)
/// et le code seul. Tout le reste est refusé : le code vaut de l'argent, on ne
/// va jamais chercher des chiffres au hasard dans un QR code quelconque (lien,
/// Wi-Fi, ticket d'une autre application…).
class RefillVoucherParser {
  const RefillVoucherParser._();

  static final _ussd = RegExp(r'^\*166[*#](\d{12})#?$');
  static final _plain = RegExp(r'^\d{12}$');
  static final _separators = RegExp(r'[\s-]');

  /// Le code à 12 chiffres contenu dans [raw], ou null si [raw] n'en est pas un.
  static String? extractCode(String? raw) {
    if (raw == null) return null;

    var text = _decode(raw.trim());
    if (text.toLowerCase().startsWith('tel:')) text = text.substring(4);
    text = text.replaceAll(_separators, '');

    final ussd = _ussd.firstMatch(text);
    if (ussd != null) return ussd.group(1);
    return _plain.hasMatch(text) ? text : null;
  }

  // `%23` (#) et `%2A` (*) : le lien `tel:` encode les caractères USSD.
  static String _decode(String text) {
    try {
      return Uri.decodeComponent(text);
    } catch (_) {
      // Encodage cassé : on garde le texte brut, il sera refusé plus haut.
      return text;
    }
  }
}
