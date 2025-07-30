// lib/services/activity_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'user_session.dart';

class ActivityService {
  static const String baseUrl = 'http://10.39.230.106/api/activity';

  /// Récupère l'historique des activités d'un utilisateur
  static Future<ActivityHistoryResponse?> getHistory({
    String? msisdn,
    int page = 1,
    int perPage = 20,
    int days = 30,
  }) async {
    try {
      // Utiliser le numéro de session si non fourni
      final phoneNumber = msisdn ?? await UserSession.getPhoneNumber();
      if (phoneNumber == null) {
        debugPrint('ActivityService: Aucun numéro de téléphone disponible');
        return null;
      }

      // Nettoyer le numéro et s'assurer qu'il est au format international
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (!cleanNumber.startsWith('253')) {
        cleanNumber = '253$cleanNumber';
      }

      debugPrint('ActivityService: Récupération historique pour $cleanNumber');

      final url = '$baseUrl/history/$cleanNumber?page=$page&per_page=$perPage&days=$days';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Activity History API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          debugPrint('Activity API: Données récupérées - ${responseData['data']?.length ?? 0} activités');
          debugPrint('Activity API: Structure pagination - ${responseData['pagination']}');
          debugPrint('Activity API: Structure filters - ${responseData['filters']}');
          debugPrint('Activity API: Premier élément - ${responseData['data']?.isNotEmpty == true ? responseData['data'][0] : 'Aucun'}');
          return ActivityHistoryResponse.fromJson(responseData);
        } else {
          debugPrint('Activity API: Échec - ${responseData['message'] ?? 'Erreur inconnue'}');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint('Activity API: MSISDN non trouvé - ${response.statusCode}');
        return null;
      } else if (response.statusCode == 422) {
        debugPrint('Activity API: Données invalides - ${response.body}');
        return null;
      } else {
        debugPrint('Activity API: Erreur HTTP ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur ActivityService.getHistory: $e');
      return null;
    }
  }

  /// Version POST pour récupérer l'historique
  static Future<ActivityHistoryResponse?> getHistoryPost({
    String? msisdn,
    int page = 1,
    int perPage = 20,
    int days = 30,
  }) async {
    try {
      // Utiliser le numéro de session si non fourni
      final phoneNumber = msisdn ?? await UserSession.getPhoneNumber();
      if (phoneNumber == null) {
        debugPrint('ActivityService: Aucun numéro de téléphone disponible');
        return null;
      }

      // Nettoyer le numéro et s'assurer qu'il est au format international
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (!cleanNumber.startsWith('253')) {
        cleanNumber = '253$cleanNumber';
      }

      final payload = {
        'msisdn': cleanNumber,
        'page': page,
        'per_page': perPage,
        'days': days,
      };

      debugPrint('ActivityService POST: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('Activity History POST API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          debugPrint('Activity POST API: Données récupérées - ${responseData['data']?.length ?? 0} activités');
          return ActivityHistoryResponse.fromJson(responseData);
        } else {
          debugPrint('Activity POST API: Échec - ${responseData['message'] ?? 'Erreur inconnue'}');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint('Activity POST API: MSISDN non trouvé - ${response.statusCode}');
        return null;
      } else if (response.statusCode == 422) {
        debugPrint('Activity POST API: Données invalides - ${response.body}');
        return null;
      } else {
        debugPrint('Activity POST API: Erreur HTTP ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur ActivityService.getHistoryPost: $e');
      return null;
    }
  }

  /// Récupère les statistiques d'activité d'un utilisateur
  static Future<ActivityStatsResponse?> getStats({
    String? msisdn,
    int days = 30,
  }) async {
    try {
      // Utiliser le numéro de session si non fourni
      final phoneNumber = msisdn ?? await UserSession.getPhoneNumber();
      if (phoneNumber == null) {
        debugPrint('ActivityService: Aucun numéro de téléphone disponible');
        return null;
      }

      // Nettoyer le numéro et s'assurer qu'il est au format international
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (!cleanNumber.startsWith('253')) {
        cleanNumber = '253$cleanNumber';
      }

      debugPrint('ActivityService: Récupération stats pour $cleanNumber');

      final url = '$baseUrl/stats/$cleanNumber?days=$days';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Activity Stats API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          debugPrint('Activity Stats API: Données récupérées - ${responseData['data']?.length ?? 0} types d\'action');
          return ActivityStatsResponse.fromJson(responseData);
        } else {
          debugPrint('Activity Stats API: Échec - ${responseData['message'] ?? 'Erreur inconnue'}');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint('Activity Stats API: MSISDN non trouvé - ${response.statusCode}');
        return null;
      } else if (response.statusCode == 422) {
        debugPrint('Activity Stats API: Données invalides - ${response.body}');
        return null;
      } else {
        debugPrint('Activity Stats API: Erreur HTTP ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur ActivityService.getStats: $e');
      return null;
    }
  }

  /// Version POST pour récupérer les statistiques
  static Future<ActivityStatsResponse?> getStatsPost({
    String? msisdn,
    int days = 30,
  }) async {
    try {
      // Utiliser le numéro de session si non fourni
      final phoneNumber = msisdn ?? await UserSession.getPhoneNumber();
      if (phoneNumber == null) {
        debugPrint('ActivityService: Aucun numéro de téléphone disponible');
        return null;
      }

      // Nettoyer le numéro et s'assurer qu'il est au format international
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (!cleanNumber.startsWith('253')) {
        cleanNumber = '253$cleanNumber';
      }

      final payload = {
        'msisdn': cleanNumber,
        'days': days,
      };

      debugPrint('ActivityService Stats POST: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('Activity Stats POST API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          debugPrint('Activity Stats POST API: Données récupérées - ${responseData['data']?.length ?? 0} types d\'action');
          return ActivityStatsResponse.fromJson(responseData);
        } else {
          debugPrint('Activity Stats POST API: Échec - ${responseData['message'] ?? 'Erreur inconnue'}');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint('Activity Stats POST API: MSISDN non trouvé - ${response.statusCode}');
        return null;
      } else if (response.statusCode == 422) {
        debugPrint('Activity Stats POST API: Données invalides - ${response.body}');
        return null;
      } else {
        debugPrint('Activity Stats POST API: Erreur HTTP ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur ActivityService.getStatsPost: $e');
      return null;
    }
  }
}