// lib/services/purchase_offer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'user_session.dart';

/// Service pour l'achat d'offres
class PurchaseOfferService {
  // URL de l'API d'achat d'offres
  static const String baseUrl = 'http://10.39.230.106/api/air';
  
  /// Achète une offre pour l'utilisateur actuellement connecté
  /// [offerId] : ID de l'offre à acheter (10, 11, 12, 13, 15, 16, 17, 29)
  /// Retourne un map contenant les informations de l'achat
  static Future<Map<String, dynamic>> purchaseOffer(int offerId) async {
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
      
      // S'assurer que le numéro contient le préfixe pays si nécessaire
      // (garde le format original selon votre logique existante)
      if (!cleanNumber.startsWith('253')) {
        cleanNumber = '253$cleanNumber';
      }
      
      debugPrint('Achat offre $offerId pour le numéro: $cleanNumber');

      // Faire la requête POST vers l'API
      final response = await http.post(
        Uri.parse('$baseUrl/purchase/$cleanNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'offer_id': offerId,
        }),
      );

      debugPrint('Réponse API achat: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['erreur'] ?? 'Erreur lors de l\'achat de l\'offre');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'achat de l\'offre: $e');
      throw Exception('Erreur lors de l\'achat de l\'offre: $e');
    }
  }

  /// Achète une offre cadeau pour quelqu'un d'autre
  /// [beneficiaryNumber] : Numéro du bénéficiaire
  /// [offerId] : ID de l'offre à offrir
  static Future<Map<String, dynamic>> purchaseOfferGift(String beneficiaryNumber, int offerId) async {
    try {
      // Vérifier si l'utilisateur est authentifié
      final isAuthenticated = await UserSession.isAuthenticated();
      if (!isAuthenticated) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      }
      
      // Récupérer le numéro de téléphone du payeur depuis la session
      final payerNumber = await UserSession.getPhoneNumber();
      
      if (payerNumber == null || payerNumber.isEmpty) {
        throw Exception('Aucun utilisateur connecté');
      }
      
      // Nettoyer les numéros de téléphone
      String cleanPayerNumber = payerNumber.replaceAll(RegExp(r'[^0-9]'), '');
      String cleanBeneficiaryNumber = beneficiaryNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      // S'assurer que les numéros contiennent le préfixe pays si nécessaire
      if (!cleanPayerNumber.startsWith('253')) {
        cleanPayerNumber = '253$cleanPayerNumber';
      }
      if (!cleanBeneficiaryNumber.startsWith('253')) {
        cleanBeneficiaryNumber = '253$cleanBeneficiaryNumber';
      }
      
      debugPrint('Achat cadeau offre $offerId - Payeur: $cleanPayerNumber, Bénéficiaire: $cleanBeneficiaryNumber');

      // Faire la requête POST vers l'API
      final response = await http.post(
        Uri.parse('$baseUrl/gift/$cleanPayerNumber'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'beneficiary_msisdn': cleanBeneficiaryNumber,
          'offer_id': offerId,
        }),
      );

      debugPrint('Réponse API achat cadeau: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['erreur'] ?? 'Erreur lors de l\'achat cadeau');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'achat cadeau: $e');
      throw Exception('Erreur lors de l\'achat cadeau: $e');
    }
  }
}