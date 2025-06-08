// lib/services/user_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _phoneNumberKey = 'user_phone_number';
  
  // Enregistrer le numéro de téléphone
  static Future<bool> savePhoneNumber(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_phoneNumberKey, phoneNumber);
    } catch (e) {
      print('Erreur lors de l\'enregistrement du numéro: $e');
      return false;
    }
  }
  
  // Récupérer le numéro de téléphone
  static Future<String?> getPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_phoneNumberKey);
    } catch (e) {
      print('Erreur lors de la récupération du numéro: $e');
      return null;
    }
  }
  
  // Vérifier si un numéro est enregistré
  static Future<bool> hasPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_phoneNumberKey);
    } catch (e) {
      print('Erreur lors de la vérification du numéro: $e');
      return false;
    }
  }
  
  // Supprimer le numéro de téléphone (pour la déconnexion)
  static Future<bool> clearPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_phoneNumberKey);
    } catch (e) {
      print('Erreur lors de la suppression du numéro: $e');
      return false;
    }
  }
}