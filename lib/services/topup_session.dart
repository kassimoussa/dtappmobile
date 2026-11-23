// lib/services/topup_session.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service pour gérer la session TopUp (numéro fixe connecté)
///
/// Deux choses sont mémorisées sur l'appareil :
/// - la dernière ligne utilisée (numéros fixe et mobile), qui préremplit le champ ;
/// - la date où son PIN a été vérifié pour ce compte mobile. Tant qu'elle a moins
///   de [verificationValidity], « Ma ligne » s'ouvre sans redemander le PIN.
class TopUpSession {
  static const String _fixedNumberKey = 'topup_fixed_number';
  static const String _mobileNumberKey = 'topup_mobile_number';
  static const String _verifiedAtKey = 'topup_verified_at';

  /// Durée pendant laquelle une vérification du PIN reste valable. Au-delà, le
  /// PIN est redemandé : cela borne le temps où un PIN changé ailleurs (portail,
  /// agence) resterait ignoré de l'app.
  static const Duration verificationValidity = Duration(days: 30);

  /// Sauvegarde les numéros mobile et fixe. N'atteste PAS que le PIN a été
  /// vérifié : une ligne enregistrée perd toute vérification précédente, il faut
  /// appeler [markVerified] après un PIN correct.
  static Future<void> saveSession({
    required String mobileNumber,
    required String fixedNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mobileNumberKey, mobileNumber);
      await prefs.setString(_fixedNumberKey, fixedNumber);
      await prefs.remove(_verifiedAtKey);
      
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
  
  /// Enregistre que le PIN de la ligne mémorisée vient d'être vérifié.
  static Future<void> markVerified({DateTime? now}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _verifiedAtKey,
        (now ?? DateTime.now()).millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('TopUp Session - Erreur enregistrement vérification: $e');
    }
  }

  /// Oublie la vérification du PIN mais garde la ligne (préremplissage).
  /// À appeler dès que le PIN change : l'ancienne preuve ne vaut plus.
  static Future<void> clearVerification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_verifiedAtKey);
    } catch (e) {
      debugPrint('TopUp Session - Erreur oubli vérification: $e');
    }
  }

  /// Vrai si la ligne mémorisée a été vérifiée par PIN pour ce compte mobile il
  /// y a moins de [verificationValidity]. Une date dans le futur (horloge
  /// reculée) ne compte pas.
  static Future<bool> isLineVerifiedFor(
    String mobileNumber, {
    DateTime? now,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedMobile = prefs.getString(_mobileNumberKey);
      final fixed = prefs.getString(_fixedNumberKey);
      final verifiedAtMs = prefs.getInt(_verifiedAtKey);
      if (storedMobile == null ||
          fixed == null ||
          fixed.isEmpty ||
          verifiedAtMs == null) {
        return false;
      }
      if (_digits(storedMobile) != _digits(mobileNumber)) return false;

      final age = (now ?? DateTime.now()).difference(
        DateTime.fromMillisecondsSinceEpoch(verifiedAtMs),
      );
      return !age.isNegative && age < verificationValidity;
    } catch (e) {
      debugPrint('TopUp Session - Erreur lecture vérification: $e');
      return false;
    }
  }

  /// Chiffres du numéro sans l'indicatif 253, pour comparer deux écritures.
  static String _digits(String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.startsWith('253') ? digits.substring(3) : digits;
  }

  /// Supprime la session TopUp (déconnexion) : ligne mémorisée et vérification
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fixedNumberKey);
      await prefs.remove(_mobileNumberKey);
      await prefs.remove(_verifiedAtKey);
      
      debugPrint('TopUp Session - Session supprimée');
    } catch (e) {
      debugPrint('TopUp Session - Erreur suppression session: $e');
    }
  }
  
  /// Met à jour seulement le numéro fixe (garde le mobile). Une autre ligne
  /// n'est pas vérifiée pour autant : la vérification précédente tombe.
  static Future<void> updateFixedNumber(String fixedNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fixedNumberKey, fixedNumber);
      await prefs.remove(_verifiedAtKey);
      
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