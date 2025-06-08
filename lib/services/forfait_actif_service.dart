// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:dtapp3/models/forfait_actif2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart'; 
 
import 'user_session.dart';

class ForfaitActifService {
  // URL de base de l'API
  static const String baseUrl = 'http://10.39.230.106/api';
  
  // Préfixes pour le cache
  static const String _cachePrefix = 'api_cache_';
  static const String _cacheTTLPrefix = 'api_ttl_';
  static const String apiTimeout = 'api_timeout';
  
  // En-têtes par défaut pour les requêtes
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Délai d'attente et tentatives
  static const Duration _timeout = Duration(seconds: 30);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);
  
  /// Récupère la liste des forfaits actifs pour l'utilisateur connecté
  static Future<List<ForfaitActif2>> getForfaitsActifs({bool useCache = false}) async {
    try {
      // Récupérer le numéro de téléphone depuis la session
      final phoneNumber = await UserSession.getPhoneNumber();
      
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      // Nettoyer le numéro de téléphone
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      // S'assurer que le numéro contient le préfixe pays (253)
      if (!cleanNumber.startsWith('253')) {
        cleanNumber = '253$cleanNumber';
      }
      
      debugPrint('Récupération des forfaits pour le numéro: $cleanNumber');
      
      // Vérifier le cache si demandé
      if (useCache) {
        final cachedData = await _getCachedResponse('forfaits_$cleanNumber');
        if (cachedData != null) {
          // Convertir les données mises en cache en liste de forfaits
          final List<dynamic> offres = cachedData['offres'] ?? [];
          return offres.map((offre) => ForfaitActif2.fromJson(offre)).toList();
        }
      }
      
      // Construire l'URL avec le numéro de téléphone à la fin
      final url = Uri.parse('$baseUrl/air/offers/$cleanNumber');
      
      // Variables pour la gestion des tentatives
      int attempts = 0;
      Exception? lastError;
      
      // Tentatives avec délai exponentiel
      while (attempts < maxRetries) {
        attempts++;
        
        try {
          // Effectuer la requête
          final response = await http.get(
            url,
            headers: _headers,
          ).timeout(_timeout);
          
          // Traiter la réponse
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            
            // Vérifier le code de réponse
            if (responseData['code_reponse'] == 0) {
              // Mettre en cache la réponse si demandé
              if (useCache) {
                await _cacheResponse(
                  'forfaits_$cleanNumber', 
                  responseData, 
                  const Duration(minutes: 15)
                );
              }
              
              // Extraire et retourner les forfaits
              final List<dynamic> offres = responseData['offres'] ?? [];
              return offres.map((offre) => ForfaitActif2.fromJson(offre)).toList();
            } else {
              throw Exception('Erreur API: ${responseData['message_reponse']}');
            }
          } else {
            throw Exception('Erreur réseau: ${response.statusCode}');
          }
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          
          // Attendre avant de réessayer
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay * attempts);
          }
        }
      }
      
      // Si toutes les tentatives ont échoué
      await recordApiTimeout();
      throw lastError ?? Exception('Échec de connexion à l\'API');
    } catch (e) {
      debugPrint('Erreur lors de la récupération des forfaits: $e');
      
      // Retourner une liste vide en cas d'erreur
      return [];
    }
  }
  
  /// Récupère les détails d'un forfait spécifique par son ID
  static Future<ForfaitActif2?> getForfaitById(int forfaitId) async {
    try {
      // Récupérer le numéro de téléphone depuis la session
      final phoneNumber = await UserSession.getPhoneNumber();
      
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      // Nettoyer le numéro de téléphone
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      // S'assurer que le numéro contient le préfixe pays (253)
      if (!cleanNumber.startsWith('253')) {
        cleanNumber = '253$cleanNumber';
      }
      
      // Construire l'URL pour récupérer un forfait spécifique
      final url = Uri.parse('$baseUrl/getOfferDetails/$cleanNumber/$forfaitId');
      
      // Effectuer la requête
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(_timeout);
      
      // Vérifier la réponse
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['code_reponse'] == 0 && responseData.containsKey('offre')) {
          return ForfaitActif2.fromJson(responseData['offre']);
        }
      }
      
      // En cas d'erreur ou de réponse vide
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du forfait $forfaitId: $e');
      return null;
    }
  }
  
  /// Vérifie si l'API est en délai d'attente
  static Future<bool> isApiTimedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFailure = prefs.getInt(apiTimeout) ?? 0;
    
    // Vérifier si le dernier échec remonte à moins de 5 minutes
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastFailure) < 5 * 60 * 1000; // 5 minutes en millisecondes
  }
  
  /// Enregistre un délai d'attente de l'API
  static Future<void> recordApiTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(apiTimeout, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Efface le délai d'attente de l'API
  static Future<void> clearApiTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(apiTimeout);
  }
  
  /// Récupère une réponse mise en cache
  static Future<Map<String, dynamic>?> _getCachedResponse(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier si le cache existe et s'il est encore valide
      final cacheKey = '$_cachePrefix$key';
      final ttlKey = '$_cacheTTLPrefix$key';
      
      if (!prefs.containsKey(cacheKey) || !prefs.containsKey(ttlKey)) {
        return null;
      }
      
      // Vérifier si le cache a expiré
      final ttl = prefs.getInt(ttlKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (ttl < now) {
        // Le cache a expiré, le supprimer
        await prefs.remove(cacheKey);
        await prefs.remove(ttlKey);
        return null;
      }
      
      // Récupérer et décoder le cache
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return null;
      
      return json.decode(cachedJson) as Map<String, dynamic>;
    } catch (e) {
      // En cas d'erreur, simplement ignorer le cache
      debugPrint('Erreur lors de la récupération du cache: $e');
      return null;
    }
  }
  
  /// Met en cache une réponse d'API
  static Future<void> _cacheResponse(
    String key,
    Map<String, dynamic> data,
    Duration ttl,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Calculer le timestamp d'expiration
      final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
      
      // Stocker les données et le TTL
      final cacheKey = '$_cachePrefix$key';
      final ttlKey = '$_cacheTTLPrefix$key';
      
      await prefs.setString(cacheKey, json.encode(data));
      await prefs.setInt(ttlKey, expiryTime);
    } catch (e) {
      // Ignorer les erreurs de mise en cache
      debugPrint('Erreur de mise en cache: $e');
    }
  }
  
  /// Vide le cache de l'API
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Supprimer toutes les clés qui commencent par les préfixes du cache
      final keys = prefs.getKeys();
      final cacheKeys = keys.where(
        (key) => key.startsWith(_cachePrefix) || key.startsWith(_cacheTTLPrefix)
      );
      
      for (var key in cacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage du cache: $e');
    }
  }
}