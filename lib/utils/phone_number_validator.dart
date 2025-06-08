
class PhoneNumberValidator {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir un numéro de téléphone';
    }
    
    // Enlever les espaces pour la validation
    final cleanNumber = value.replaceAll(' ', '');
    
    if (cleanNumber.length != 8) {
      return 'Le numéro doit contenir 8 chiffres';
    }
    
    if (!cleanNumber.startsWith('77')) {
      return 'Les numéros mobiles djiboutiens commencent par 77';
    }
    
    return null;
  }
  
  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(' ', '');
  }
}