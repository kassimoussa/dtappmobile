// lib/services/balance_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_client.dart';
import 'user_session.dart';

class BalanceService {
  static Future<Map<String, dynamic>> getCurrentBalance() async {
    final isAuthenticated = await UserSession.isAuthenticated();
    if (!isAuthenticated) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }

    final phoneNumber = await UserSession.getPhoneNumber();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception('Aucun utilisateur connecté');
    }

    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanNumber.startsWith('253')) cleanNumber = '253$cleanNumber';

    debugPrint('Récupération du solde pour le numéro: $cleanNumber');

    final response = await ApiClient.get('/air/balance/$cleanNumber');

    debugPrint('Réponse API balance: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['code_reponse'] == 0) return data;
      throw Exception('Erreur solde: ${data['message_reponse']}');
    }
    throw Exception('Échec de la récupération du solde: ${response.statusCode}');
  }
}
