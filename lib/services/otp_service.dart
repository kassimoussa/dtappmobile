// lib/services/otp_service.dart (version corrigée)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class OtpService {
  // Définissez les URLs de vos APIs ici
  final String sendOtpUrl = 'http://10.39.230.106/api/sms/otp/send';
  final String verifyOtpUrl = 'http://10.39.230.106/api/sms/otp/verify';

  // Nom de l'expéditeur du SMS
  final String senderName = 'DTAPP';

  // Méthode pour envoyer le numéro de téléphone et recevoir un OTP
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      // Assurez-vous que le numéro de téléphone ne contient que 8 chiffres
      String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // Si le numéro commence par 253, on le supprime
      if (cleanPhoneNumber.startsWith('253')) {
        cleanPhoneNumber = cleanPhoneNumber.substring(3);
      }

      // Vérification que le numéro a 8 chiffres
      if (cleanPhoneNumber.length != 8) {
        return {
          'status': 'error',
          'message': 'Le numéro de téléphone doit contenir 8 chiffres',
        };
      }

      debugPrint('Envoi OTP au numéro: $cleanPhoneNumber');

      final response = await http.post(
        Uri.parse(sendOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'to': cleanPhoneNumber, 'from': senderName}),
      );

      debugPrint('Réponse API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        debugPrint('Données décodées: $responseData');
        
        // S'assurer de retourner un Map<String, dynamic> cohérent
        return {
          'status': responseData['status'] ?? 'success',
          'message': responseData['message'] ?? 'Code OTP envoyé avec succès',
          'debug': responseData['debug'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': errorData['message'] ?? 'Échec de l\'envoi de l\'OTP: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de l\'OTP: $e');
      return {
        'status': 'error',
        'message': 'Erreur lors de l\'envoi de l\'OTP: $e',
      };
    }
  }

  // Méthode pour vérifier l'OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      // Même traitement du numéro que pour sendOtp
      String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanPhoneNumber.startsWith('253')) {
        cleanPhoneNumber = cleanPhoneNumber.substring(3);
      }

      if (cleanPhoneNumber.length != 8) {
        return {
          'status': 'error',
          'message': 'Le numéro de téléphone doit contenir 8 chiffres',
        };
      }

      debugPrint('Vérification OTP: $otp pour le numéro: $cleanPhoneNumber');

      final response = await http.post(
        Uri.parse(verifyOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'to': cleanPhoneNumber, 'otp': otp}),
      );

      debugPrint('Réponse API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'status': responseData['status'] ?? 'success',
          'message': responseData['message'] ?? 'Vérification réussie',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': errorData['message'] ?? 'Échec de la vérification de l\'OTP: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'OTP: $e');
      return {
        'status': 'error',
        'message': 'Erreur lors de la vérification de l\'OTP: $e',
      };
    }
  }
}