// lib/services/topup_session.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service pour gérer la session TopUp (numéro fixe connecté)
class TopUpSession {
  static const String _fixedNumberKey = 'topup_fixed_number';
  static const String _mobileNumberKey = 'topup_mobile_number';
  
  /// Sauvegarde la session TopUp avec les numéros mobile et fixe
  static Future<void> saveSession({
    required String mobileNumber,
    required String fixedNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mobileNumberKey, mobileNumber);
      await prefs.setString(_fixedNumberKey, fixedNumber);
      
      debugPrint('TopUp Session - Numéros sauvegardés: $mobileNumber -> $fixedNumber');
    } catch (e) {
      debugPrint('TopUp Session - Erreur sauvegarde: $e');
    }
  }
  
  /// Récupère le numéro fixe de la session active
  static Future<String?> getFixedNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fixedNumber = prefs.getString(_fixedNumberKey);
      debugPrint('TopUp Session - Numéro fixe récupéré: $fixedNumber');
      return fixedNumber;
    } catch (e) {
      debugPrint('TopUp Session - Erreur récupération fixe: $e');
      return null;
    }
  }
  
  /// Récupère le numéro mobile de la session active
  static Future<String?> getMobileNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mobileNumber = prefs.getString(_mobileNumberKey);
      debugPrint('TopUp Session - Numéro mobile récupéré: $mobileNumber');
      return mobileNumber;
    } catch (e) {
      debugPrint('TopUp Session - Erreur récupération mobile: $e');
      return null;
    }
  }
  
  /// Vérifie si une session TopUp est active
  static Future<bool> hasActiveSession() async {
    try {
      final fixedNumber = await getFixedNumber();
      final mobileNumber = await getMobileNumber();
      final isActive = fixedNumber != null && 
                      fixedNumber.isNotEmpty && 
                      mobileNumber != null && 
                      mobileNumber.isNotEmpty;
      
      debugPrint('TopUp Session - Session active: $isActive');
      return isActive;
    } catch (e) {
      debugPrint('TopUp Session - Erreur vérification session: $e');
      return false;
    }
  }
  
  /// Supprime la session TopUp (déconnexion)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fixedNumberKey);
      await prefs.remove(_mobileNumberKey);
      
      debugPrint('TopUp Session - Session supprimée');
    } catch (e) {
      debugPrint('TopUp Session - Erreur suppression session: $e');
    }
  }
  
  /// Met à jour seulement le numéro fixe (garde le mobile)
  static Future<void> updateFixedNumber(String fixedNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fixedNumberKey, fixedNumber);
      
      debugPrint('TopUp Session - Numéro fixe mis à jour: $fixedNumber');
    } catch (e) {
      debugPrint('TopUp Session - Erreur mise à jour fixe: $e');
    }
  }
  
  /// Récupère les deux numéros de la session
  static Future<Map<String, String?>> getSessionData() async {
    return {
      'mobile': await getMobileNumber(),
      'fixed': await getFixedNumber(),
    };
  }
}