// lib/services/user_session.dart 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service pour gérer la session utilisateur avec expiration après inactivité
class UserSession {
  // Clés pour SharedPreferences
  static const String _phoneNumberKey = 'user_phone_number';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _lastActivityTimeKey = 'last_activity_time';
  static const String _lastUsedPhoneKey = 'last_used_phone';
  static const String _isAppRunningKey = 'is_app_running';
  static const String _sessionTokenKey = 'session_token';
  
  // Durée d'inactivité tolérée en minutes (après mise en arrière-plan)
  static const int _inactivityTimeoutMinutes = 10;
  
  // Cache pour optimiser les performances
  static String? _cachedPhoneNumber;
  static bool _cachedIsAuthenticated = false;
  static DateTime? _cachedLastActivityTime;
  static String? _cachedLastUsedPhone;
  static String? _cachedSessionToken;
  
  /// Enregistre les informations de session après la vérification OTP réussie
  static Future<void> createSession(String phoneNumber, {String? sessionToken}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Enregistrer l'heure actuelle comme dernière activité
    final now = DateTime.now();
    final activityTimestamp = now.millisecondsSinceEpoch;
    
    // Enregistrer les données de session
    await prefs.setString(_phoneNumberKey, phoneNumber);
    await prefs.setBool(_isAuthenticatedKey, true);
    await prefs.setInt(_lastActivityTimeKey, activityTimestamp);
    await prefs.setBool(_isAppRunningKey, true);
    
    // Enregistrer le session token si fourni
    if (sessionToken != null) {
      await prefs.setString(_sessionTokenKey, sessionToken);
      _cachedSessionToken = sessionToken;
    }
    
    // Stocker également comme dernier numéro utilisé
    await prefs.setString(_lastUsedPhoneKey, phoneNumber);
    
    // Mettre à jour le cache
    _cachedPhoneNumber = phoneNumber;
    _cachedIsAuthenticated = true;
    _cachedLastActivityTime = now;
    _cachedLastUsedPhone = phoneNumber;
    
    debugPrint('Session créée pour le numéro: $phoneNumber à $now${sessionToken != null ? ' avec token' : ''}');
  }
  
  /// Met à jour le timestamp de dernière activité
  /// À appeler périodiquement lorsque l'utilisateur interagit avec l'app
  static Future<void> updateActivity() async {
    final isAuth = await isAuthenticated();
    if (!isAuth) return;
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final activityTimestamp = now.millisecondsSinceEpoch;
    
    await prefs.setInt(_lastActivityTimeKey, activityTimestamp);
    _cachedLastActivityTime = now;
    
    //debugPrint('Activité mise à jour: $now');
  }
  
  /// Doit être appelé quand l'application passe au premier plan
  static Future<void> appResumed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAppRunningKey, true);
    
    // Si l'app était en arrière-plan trop longtemps, la session a pu expirer
    // On vérifie si la session est toujours valide
    final isValid = await isAuthenticated();
    if (isValid) {
      // Si la session est valide, mettre à jour l'activité
      updateActivity();
    }
    
    debugPrint('Application revenue au premier plan');
  }
  
  /// Doit être appelé quand l'application passe en arrière-plan
  static Future<void> appPaused() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAppRunningKey, false);
    // Enregistrer le moment où l'application est passée en arrière-plan
    final now = DateTime.now();
    await prefs.setInt(_lastActivityTimeKey, now.millisecondsSinceEpoch);
    _cachedLastActivityTime = now;
    
    debugPrint('Application passée en arrière-plan à: $now');
  }
  
  /// Doit être appelé quand l'application est complètement fermée
  static Future<void> appTerminated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAppRunningKey, false);
    await prefs.setBool(_isAuthenticatedKey, false);
    _cachedIsAuthenticated = false;
    
    debugPrint('Application terminée, session invalidée');
  }
  
  /// Vérifie si l'utilisateur est authentifié et si la session n'a pas expiré
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Vérifier si l'app est marquée comme fermée
    final isAppRunning = prefs.getBool(_isAppRunningKey) ?? false;
    if (!isAppRunning) {
      // Vérifier si l'inactivité a dépassé le délai autorisé
      final lastActivityTimestamp = prefs.getInt(_lastActivityTimeKey);
      
      if (lastActivityTimestamp != null) {
        final lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityTimestamp);
        final now = DateTime.now();
        final inactivityDuration = now.difference(lastActivity);
        
        // Si l'inactivité est inférieure au délai, la session reste valide
        if (inactivityDuration.inMinutes <= _inactivityTimeoutMinutes) {
          debugPrint('App en arrière-plan depuis ${inactivityDuration.inMinutes} minutes, session toujours valide');
          // Mettre à jour pour indiquer que l'app est de nouveau active
          await prefs.setBool(_isAppRunningKey, true);
          return true;
        } else {
          // Inactivité trop longue, session expirée
          debugPrint('Session expirée après ${inactivityDuration.inMinutes} minutes d\'inactivité');
          await prefs.setBool(_isAuthenticatedKey, false);
          _cachedIsAuthenticated = false;
          return false;
        }
      } else {
        // Pas de timestamp d'activité, session expirée
        await prefs.setBool(_isAuthenticatedKey, false);
        _cachedIsAuthenticated = false;
        return false;
      }
    }
    
    // 2. Si l'app est active, vérifier si authentifié
    // Utiliser la valeur en cache si disponible
    if (_cachedIsAuthenticated) {
      return true;
    }
    
    final isAuthenticated = prefs.getBool(_isAuthenticatedKey) ?? false;
    _cachedIsAuthenticated = isAuthenticated;
    
    return isAuthenticated;
  }
  
  /// Récupère le numéro de téléphone de l'utilisateur connecté
  /// Retourne null si l'utilisateur n'est pas authentifié
  static Future<String?> getPhoneNumber() async {
    // Si la session a expiré, on renvoie null (car pas authentifié)
    if (!await isAuthenticated()) {
      return null;
    }
    
    // Utiliser la valeur en cache si disponible
    if (_cachedPhoneNumber != null) {
      return _cachedPhoneNumber;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString(_phoneNumberKey);
    
    // Mettre à jour le cache
    _cachedPhoneNumber = phoneNumber;
    
    return phoneNumber;
  }
  
  /// Récupère le session token de l'utilisateur connecté
  /// Retourne null si l'utilisateur n'est pas authentifié ou si aucun token n'existe
  static Future<String?> getSessionToken() async {
    // Si la session a expiré, on renvoie null
    if (!await isAuthenticated()) {
      return null;
    }
    
    // Utiliser la valeur en cache si disponible
    if (_cachedSessionToken != null) {
      return _cachedSessionToken;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final sessionToken = prefs.getString(_sessionTokenKey);
    
    // Mettre à jour le cache
    _cachedSessionToken = sessionToken;
    
    return sessionToken;
  }
  
  /// Récupère le dernier numéro de téléphone utilisé, même si la session a expiré
  /// Utile pour pré-remplir le champ de téléphone lors de la reconnexion
  static Future<String?> getLastUsedPhoneNumber() async {
    // Utiliser la valeur en cache si disponible
    if (_cachedLastUsedPhone != null) {
      return _cachedLastUsedPhone;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString(_lastUsedPhoneKey);
    
    // Mettre à jour le cache
    _cachedLastUsedPhone = phoneNumber;
    
    return phoneNumber;
  }
  
  /// Récupère le temps d'inactivité en secondes
  static Future<int> getInactivityTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityTimestamp = prefs.getInt(_lastActivityTimeKey);
    
    if (lastActivityTimestamp == null) {
      return 0;
    }
    
    final lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityTimestamp);
    final now = DateTime.now();
    
    return now.difference(lastActivity).inSeconds;
  }
  
  /// Termine complètement la session utilisateur mais conserve le dernier numéro
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_lastActivityTimeKey);
    await prefs.remove(_sessionTokenKey);
    // Ne pas supprimer _lastUsedPhoneKey ni _phoneNumberKey pour permettre une reconnexion facile
    
    // Réinitialiser le cache
    _cachedIsAuthenticated = false;
    _cachedLastActivityTime = null;
    _cachedSessionToken = null;
    
    debugPrint('Session utilisateur terminée');
  }
  
  /// Supprime toutes les données, y compris le dernier numéro utilisé
  /// À utiliser lors d'une déconnexion explicite par l'utilisateur
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_isAuthenticatedKey);
    await prefs.remove(_lastActivityTimeKey);
    await prefs.remove(_lastUsedPhoneKey);
    await prefs.remove(_isAppRunningKey);
    await prefs.remove(_sessionTokenKey);
    
    // Réinitialiser tout le cache
    _cachedPhoneNumber = null;
    _cachedIsAuthenticated = false;
    _cachedLastActivityTime = null;
    _cachedLastUsedPhone = null;
    _cachedSessionToken = null;
    
    debugPrint('Toutes les données utilisateur supprimées');
  }
}