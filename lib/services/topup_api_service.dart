// lib/services/topup_api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/topup_balance.dart';
import '../exceptions/topup_exception.dart';

class TopUpApiService {
  // Configuration de l'API
  static const String baseUrl = 'http://10.39.230.106/api/topup';
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  // Clés pour le cache
  static const String _cachePrefix = 'topup_cache_';
  static const String _cacheTTLPrefix = 'topup_ttl_';
  
  final http.Client _client;
  
  TopUpApiService({http.Client? client}) : _client = client ?? http.Client();
  
  // Headers par défaut pour les requêtes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Récupère les soldes d'un numéro fixe
  Future<TopUpBalanceResponse> getBalances({
    required String msisdn,
    required String isdn,
    bool useCache = true,
  }) async {
    // Validation des entrées
    TopUpValidator.validateMobile(msisdn);
    TopUpValidator.validateFixed(isdn);
    
    final cacheKey = 'balances_${msisdn}_$isdn';
    
    // Vérifier le cache si demandé
    if (useCache) {
      final cachedData = await _getCachedResponse(cacheKey);
      if (cachedData != null) {
        try {
          final cachedResponse = TopUpBalanceResponse.fromJson(cachedData);
          debugPrint('TopUp API - Cache valide - Succès: ${cachedResponse.success}, Soldes: ${cachedResponse.totalBalances}');
          return cachedResponse;
        } catch (e) {
          debugPrint('TopUp API - Cache corrompu pour $cacheKey: $e');
          debugPrint('TopUp API - Données cache: $cachedData');
          // Nettoyer le cache corrompu
          await _clearSpecificCache(cacheKey);
        }
      }
    }
    
    // Préparer la requête
    final requestBody = {
      'msisdn': msisdn,
      'isdn': isdn,
    };
    
    debugPrint('TopUp API - Consultation soldes: $msisdn -> $isdn');
    debugPrint('TopUp API - URL: $baseUrl/balances');
    debugPrint('TopUp API - Payload: ${json.encode(requestBody)}');
    
    // Exécuter la requête avec retry
    final response = await _executeWithRetry(() async {
      return await _client.post(
        Uri.parse('$baseUrl/balances'),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(_timeout);
    });
    
    // Traiter la réponse
    debugPrint('TopUp API - Statut HTTP: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      debugPrint('TopUp API - Parsing avec format standard...');
      
      // Mettre en cache la réponse
      if (useCache) {
        await _cacheResponse(cacheKey, responseData, const Duration(minutes: 10));
      }
      
      try {
        final standardResponse = TopUpBalanceResponse.fromJson(responseData);
        debugPrint('TopUp API - Succès: ${standardResponse.success}, Soldes: ${standardResponse.totalBalances}');
        
        if (!standardResponse.success) {
          debugPrint('TopUp API - ÉCHEC: ${standardResponse.message}');
        }
        
        return standardResponse;
      } catch (e) {
        debugPrint('TopUp API - ERREUR PARSING: $e');
        debugPrint('TopUp API - Données problématiques: $responseData');
        rethrow;
      }
    } else {
      debugPrint('TopUp API - Erreur HTTP: ${response.statusCode} - ${response.body}');
      throw TopUpException.fromResponse(response);
    }
  }

  /// Souscrit à un package TopUp
  Future<TopUpSubscriptionResponse> subscribePackage({
    required String msisdn,
    required String isdn,
    required String packageCode,
    String? pincode,
    String? transactionId,
  }) async {
    // Validation des entrées
    TopUpValidator.validateMobile(msisdn);
    TopUpValidator.validateFixed(isdn);
    
    if (packageCode.isEmpty) {
      throw TopUpException.validationError('Le code du package est requis');
    }
    
    // Préparer la requête
    final requestBody = {
      'msisdn': msisdn,
      'isdn': isdn,
      'package_code': packageCode,
    };
    
    // Ajouter les paramètres optionnels
    if (pincode != null && pincode.isNotEmpty) {
      requestBody['pincode'] = pincode;
    }
    
    if (transactionId != null && transactionId.isNotEmpty) {
      requestBody['transaction_id'] = transactionId;
    } else {
      // Générer un ID de transaction automatiquement
      requestBody['transaction_id'] = 'dtapp${DateTime.now().millisecondsSinceEpoch}${DateTime.now().microsecond}';
    }
    
    debugPrint('TopUp API - Souscription package: $msisdn -> $isdn ($packageCode)');
    debugPrint('TopUp API - URL: $baseUrl/subscribe-package');
    debugPrint('TopUp API - Payload: ${json.encode(requestBody)}');
    
    // Exécuter la requête avec retry
    final response = await _executeWithRetry(() async {
      return await _client.post(
        Uri.parse('$baseUrl/subscribe-package'),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(_timeout);
    });
    
    // Traiter la réponse
    debugPrint('TopUp API - Statut HTTP: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      debugPrint('TopUp API - Parsing souscription avec format standard...');
      
      try {
        final subscriptionResponse = TopUpSubscriptionResponse.fromJson(responseData);
        debugPrint('TopUp API - Souscription: Succès=${subscriptionResponse.success}, Transaction=${subscriptionResponse.transactionId}');
        
        if (!subscriptionResponse.success) {
          debugPrint('TopUp API - ÉCHEC souscription: ${subscriptionResponse.message}');
        }
        
        return subscriptionResponse;
      } catch (e) {
        debugPrint('TopUp API - ERREUR PARSING souscription: $e');
        debugPrint('TopUp API - Données problématiques: $responseData');
        rethrow;
      }
    } else {
      debugPrint('TopUp API - Erreur HTTP souscription: ${response.statusCode} - ${response.body}');
      throw TopUpException.fromResponse(response);
    }
  }

  /// Récupère les packages disponibles pour un numéro fixe
  Future<TopUpPackageResponse> getPackages({
    required String msisdn,
    required String isdn,
    required int type,
    bool useCache = true,
  }) async {
    // Validation des entrées
    TopUpValidator.validateMobile(msisdn);
    TopUpValidator.validateFixed(isdn);
    
    // Valider le type (1 = souscription voix, 2 = souscription données, 4 = package données, 6 = package voix)
    if (type != 1 && type != 2 && type != 4 && type != 6) {
      throw TopUpException.validationError('Type invalide. Utilisez 1 (souscription voix), 2 (souscription données), 4 (package données) ou 6 (package voix)');
    }
    
    final cacheKey = 'packages_${msisdn}_${isdn}_$type';
    
    // Vérifier le cache si demandé
    if (useCache) {
      final cachedData = await _getCachedResponse(cacheKey);
      if (cachedData != null) {
        try {
          final cachedResponse = TopUpPackageResponse.fromJson(cachedData);
          debugPrint('TopUp API - Cache packages valide - Succès: ${cachedResponse.success}, Packages: ${cachedResponse.totalPackages}');
          return cachedResponse;
        } catch (e) {
          debugPrint('TopUp API - Cache packages corrompu pour $cacheKey: $e');
          debugPrint('TopUp API - Données cache: $cachedData');
          // Nettoyer le cache corrompu
          await _clearSpecificCache(cacheKey);
        }
      }
    }
    
    // Préparer la requête
    final requestBody = {
      'msisdn': msisdn,
      'isdn': isdn,
      'type': type,
    };
    
    debugPrint('TopUp API - Consultation packages: $msisdn -> $isdn (type: $type)');
    debugPrint('TopUp API - URL: $baseUrl/packages');
    debugPrint('TopUp API - Payload: ${json.encode(requestBody)}');
    
    // Exécuter la requête avec retry
    final response = await _executeWithRetry(() async {
      return await _client.post(
        Uri.parse('$baseUrl/packages'),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(_timeout);
    });
    
    // Traiter la réponse
    debugPrint('TopUp API - Statut HTTP: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      debugPrint('TopUp API - Parsing packages avec format standard...');
      
      // Mettre en cache la réponse (5 minutes pour les packages)
      if (useCache) {
        await _cacheResponse(cacheKey, responseData, const Duration(minutes: 5));
      }
      
      try {
        final packageResponse = TopUpPackageResponse.fromJson(responseData);
        debugPrint('TopUp API - Succès: ${packageResponse.success}, Packages: ${packageResponse.totalPackages}');
        
        if (!packageResponse.success) {
          debugPrint('TopUp API - ÉCHEC packages: ${packageResponse.message}');
        }
        
        return packageResponse;
      } catch (e) {
        debugPrint('TopUp API - ERREUR PARSING packages: $e');
        debugPrint('TopUp API - Données problématiques: $responseData');
        rethrow;
      }
    } else {
      debugPrint('TopUp API - Erreur HTTP packages: ${response.statusCode} - ${response.body}');
      throw TopUpException.fromResponse(response);
    }
  }
  
  /// Exécute une requête avec retry automatique
  Future<http.Response> _executeWithRetry(Future<http.Response> Function() operation) async {
    int attempts = 0;
    Exception? lastError;
    
    while (attempts < _maxRetries) {
      attempts++;
      
      try {
        return await operation();
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        
        // Retry seulement pour les erreurs réseau ou serveur
        if (attempts < _maxRetries && _shouldRetry(e)) {
          debugPrint('TopUp API - Tentative $attempts/$_maxRetries échouée: $e');
          await Future.delayed(_retryDelay * attempts);
        }
      }
    }
    
    // Gérer les différents types d'erreurs
    if (lastError is TimeoutException) {
      throw TopUpException.timeoutError();
    } else if (lastError.toString().contains('SocketException') || 
               lastError.toString().contains('HttpException')) {
      throw TopUpException.networkError('Problème de connexion réseau');
    } else {
      throw lastError!;
    }
  }
  
  /// Détermine si une erreur justifie un retry
  bool _shouldRetry(dynamic error) {
    if (error is TimeoutException) return true;
    if (error.toString().contains('SocketException')) return true;
    if (error.toString().contains('HttpException')) return true;
    return false;
  }
  
  /// Récupère une réponse mise en cache
  Future<Map<String, dynamic>?> _getCachedResponse(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cacheKey = '$_cachePrefix$key';
      final ttlKey = '$_cacheTTLPrefix$key';
      
      // Vérifier si le cache existe
      if (!prefs.containsKey(cacheKey) || !prefs.containsKey(ttlKey)) {
        return null;
      }
      
      // Vérifier l'expiration
      final ttl = prefs.getInt(ttlKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (ttl < now) {
        // Cache expiré, le supprimer
        await prefs.remove(cacheKey);
        await prefs.remove(ttlKey);
        return null;
      }
      
      // Récupérer et décoder
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson == null) return null;
      
      debugPrint('TopUp API - Cache hit pour: $key');
      return json.decode(cachedJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('TopUp API - Erreur cache: $e');
      return null;
    }
  }
  
  /// Met en cache une réponse
  Future<void> _cacheResponse(
    String key,
    Map<String, dynamic> data,
    Duration ttl,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
      
      final cacheKey = '$_cachePrefix$key';
      final ttlKey = '$_cacheTTLPrefix$key';
      
      await prefs.setString(cacheKey, json.encode(data));
      await prefs.setInt(ttlKey, expiryTime);
      
      debugPrint('TopUp API - Mise en cache: $key (TTL: ${ttl.inMinutes}min)');
    } catch (e) {
      debugPrint('TopUp API - Erreur mise en cache: $e');
    }
  }
  
  /// Vide le cache TopUp
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final keys = prefs.getKeys();
      final cacheKeys = keys.where(
        (key) => key.startsWith(_cachePrefix) || key.startsWith(_cacheTTLPrefix)
      );
      
      for (var key in cacheKeys) {
        await prefs.remove(key);
      }
      
      debugPrint('TopUp API - Cache vidé');
    } catch (e) {
      debugPrint('TopUp API - Erreur vidage cache: $e');
    }
  }

  /// Vide une entrée spécifique du cache
  Future<void> _clearSpecificCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cacheKey = '$_cachePrefix$key';
      final ttlKey = '$_cacheTTLPrefix$key';
      
      await prefs.remove(cacheKey);
      await prefs.remove(ttlKey);
      
      debugPrint('TopUp API - Cache nettoyé pour: $key');
    } catch (e) {
      debugPrint('TopUp API - Erreur nettoyage cache: $e');
    }
  }
  
  /// Vérifie si l'API est disponible
  Future<bool> isApiAvailable() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Ferme le client HTTP
  void dispose() {
    _client.close();
  }
}

// Singleton pour faciliter l'utilisation
class TopUpApi {
  static TopUpApiService? _instance;
  
  static TopUpApiService get instance {
    _instance ??= TopUpApiService();
    return _instance!;
  }
  
  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}