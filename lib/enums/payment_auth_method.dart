/// Méthode d'authentification exigée pour valider un paiement : achat de
/// forfait ou transfert de crédit.
///
/// Le choix est stocké par numéro de téléphone (voir UserSession), comme la
/// biométrie : deux comptes utilisés sur le même appareil ne doivent pas
/// partager ce réglage.
enum PaymentAuthMethod {
  /// Boîte de dialogue système : biométrie ou code de déverrouillage de
  /// l'appareil, avec repli sur le code PIN de l'application si elle échoue.
  /// C'est le comportement historique, et la valeur par défaut.
  biometric,

  /// Code PIN de l'application uniquement, sans passer par la biométrie.
  pin;

  static const String _storageBiometric = 'biometric';
  static const String _storagePin = 'pin';

  /// Valeur persistée. On stocke une chaîne explicite plutôt que l'index de
  /// l'enum : réordonner les valeurs ne doit pas changer le réglage des
  /// utilisateurs déjà installés.
  String get storageValue => switch (this) {
        PaymentAuthMethod.biometric => _storageBiometric,
        PaymentAuthMethod.pin => _storagePin,
      };

  /// Toute valeur inconnue ou absente retombe sur la biométrie.
  static PaymentAuthMethod fromStorage(String? value) =>
      value == _storagePin ? PaymentAuthMethod.pin : PaymentAuthMethod.biometric;
}
