// lib/services/user_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Utilise la même clé que UserSession pour le dernier numéro utilisé
  static const String _lastUsedPhoneKey = 'last_used_phone';

  // Enregistrer le numéro de téléphone
  static Future<bool> savePhoneNumber(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_lastUsedPhoneKey, phoneNumber);
    } catch (e) {
      print('Erreur lors de l\'enregistrement du numéro: $e');
      return false;
    }
  }

  // Récupérer le numéro de téléphone (depuis last_used_phone)
  static Future<String?> getPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUsedPhoneKey);
    } catch (e) {
      print('Erreur lors de la récupération du numéro: $e');
      return null;
    }
  }

  // Vérifier si un numéro est enregistré
  static Future<bool> hasPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_lastUsedPhoneKey);
    } catch (e) {
      print('Erreur lors de la vérification du numéro: $e');
      return false;
    }
  }

  // Supprimer le numéro de téléphone (pour la déconnexion complète)
  static Future<bool> clearPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_lastUsedPhoneKey);
    } catch (e) {
      print('Erreur lors de la suppression du numéro: $e');
      return false;
    }
  }
}