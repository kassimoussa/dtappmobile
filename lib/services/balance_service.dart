// lib/services/balance_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'user_session.dart';

/// Service pour récupérer le solde du compte
class BalanceService {
  // URL de l'API de solde
  static const String balanceApiUrl = 'http://10.39.230.106/api/air/balance';
  
  /// Récupère le solde pour l'utilisateur actuellement connecté
  /// Retourne un map contenant les informations de solde
  static Future<Map<String, dynamic>> getCurrentBalance() async {
    try {
      // Vérifier si l'utilisateur est authentifié
      final isAuthenticated = await UserSession.isAuthenticated();
      if (!isAuthenticated) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      
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
      
      debugPrint('Récupération du solde pour le numéro: $cleanNumber');

      // Faire la requête GET vers l'API
      final response = await http.get(
        Uri.parse('$balanceApiUrl/$cleanNumber'),
      );

      debugPrint('Réponse API balance: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Vérifier le code de réponse
        if (data['code_reponse'] == 0) {
          /* // Prolonger automatiquement la session après une requête réussie
          await UserSession.extendSession(); */
          return data;
        } else {
          throw Exception('Erreur lors de la récupération du solde: ${data['message_reponse']}');
        }
      } else {
        throw Exception('Échec de la récupération du solde: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du solde: $e');
      throw Exception('Erreur lors de la récupération du solde: $e');
    }
  }
}