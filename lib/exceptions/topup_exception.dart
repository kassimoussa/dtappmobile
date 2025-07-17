// lib/exceptions/topup_exception.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class TopUpException implements Exception {
  final String error;
  final String message;
  final String? returnCode;
  final int statusCode;
  final Map<String, dynamic>? details;

  TopUpException({
    required this.error,
    required this.message,
    this.returnCode,
    required this.statusCode,
    this.details,
  });

  factory TopUpException.fromResponse(http.Response response) {
    Map<String, dynamic> body = {};
    
    try {
      body = json.decode(response.body);
    } catch (e) {
      body = {'erreur': 'Erreur de décodage', 'message': 'Réponse invalide du serveur'};
    }
    
    return TopUpException(
      error: body['erreur'] ?? 'Erreur inconnue',
      message: body['message'] ?? 'Une erreur est survenue',
      returnCode: body['returnCode'],
      statusCode: response.statusCode,
      details: body['details'],
    );
  }

  factory TopUpException.networkError(String message) {
    return TopUpException(
      error: 'Erreur réseau',
      message: message,
      statusCode: 0,
    );
  }

  factory TopUpException.timeoutError() {
    return TopUpException(
      error: 'Timeout',
      message: 'La requête a expiré. Veuillez réessayer.',
      statusCode: 0,
    );
  }

  factory TopUpException.validationError(String message) {
    return TopUpException(
      error: 'Validation',
      message: message,
      statusCode: 400,
    );
  }

  // Helpers pour identifier les types d'erreur
  bool get isNetworkError => statusCode == 0;
  bool get isValidationError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
  bool get isAuthError => statusCode == 401;
  bool get isNotFoundError => statusCode == 404;
  bool get isInsufficientBalanceError => returnCode == '400';
  bool get isNumberNotFoundError => returnCode == '1';
  bool get isNumberBlockedError => returnCode == '2';
  bool get isPostpaidError => returnCode == '3';
  bool get isNumberExpiredError => returnCode == '5';

  // Message utilisateur amélioré
  String get userFriendlyMessage {
    if (isNetworkError) {
      return 'Problème de connexion. Vérifiez votre connexion internet.';
    }
    
    if (isAuthError) {
      return 'Erreur d\'authentification. Veuillez vérifier vos identifiants.';
    }
    
    if (isInsufficientBalanceError) {
      return 'Solde insuffisant pour effectuer cette opération.';
    }
    
    if (isNumberNotFoundError) {
      return 'Le numéro de téléphone n\'existe pas.';
    }
    
    if (isNumberBlockedError) {
      return 'Le numéro de téléphone est bloqué ou suspendu.';
    }
    
    if (isPostpaidError) {
      return 'Les numéros postpaid ne sont pas supportés pour cette opération.';
    }
    
    if (isNumberExpiredError) {
      return 'Le numéro de téléphone a expiré.';
    }
    
    if (isServerError) {
      return 'Erreur serveur. Veuillez réessayer plus tard.';
    }
    
    return message;
  }

  @override
  String toString() {
    return 'TopUpException: $error - $message (HTTP $statusCode)';
  }
}

// Validation des numéros de téléphone
class TopUpValidator {
  static const String _mobileRegex = r'^(77|25377)[0-9]{6}$';
  static const String _fixedRegex = r'^(21|25321)[0-9]{6}$';
  static const String _pinRegex = r'^[0-9]{4}$';
  
  static bool isValidMobile(String msisdn) {
    return RegExp(_mobileRegex).hasMatch(msisdn);
  }
  
  static bool isValidFixed(String isdn) {
    return RegExp(_fixedRegex).hasMatch(isdn);
  }
  
  static bool isValidPin(String pin) {
    return RegExp(_pinRegex).hasMatch(pin);
  }
  
  static void validateMobile(String msisdn) {
    if (!isValidMobile(msisdn)) {
      throw TopUpException.validationError(
        'Le numéro mobile doit commencer par 77 ou 25377 et contenir 8 ou 11 chiffres'
      );
    }
  }
  
  static void validateFixed(String isdn) {
    if (!isValidFixed(isdn)) {
      throw TopUpException.validationError(
        'Le numéro fixe doit commencer par 21 ou 25321 et contenir 8 ou 11 chiffres'
      );
    }
  }
  
  static void validatePin(String pin) {
    if (!isValidPin(pin)) {
      throw TopUpException.validationError(
        'Le code PIN doit contenir exactement 4 chiffres'
      );
    }
  }
  
  static void validateAmount(double amount) {
    if (amount < 100) {
      throw TopUpException.validationError('Le montant minimum est de 100 DJF');
    }
    if (amount > 50000) {
      throw TopUpException.validationError('Le montant maximum est de 50 000 DJF');
    }
  }
  
  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString().substring(10);
    return 'dtapp$timestamp$random';
  }
}