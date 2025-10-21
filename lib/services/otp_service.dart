// lib/services/otp_service.dart (version corrigée)
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class OtpService {
  // Définissez les URLs de vos APIs ici
  final String sendOtpUrl = 'http://10.39.230.106/api/sms/otp/send';
  final String verifyOtpUrl = 'http://10.39.230.106/api/sms/otp/verify';

  // Nom de l'expéditeur du SMS
  final String senderName = 'DjibTel';

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

  // Méthode pour vérifier l'OTP avec device_info
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

      // Collecter les informations du device
      final deviceInfo = await _getDeviceInfo();

      // Préparer le payload avec device_info selon l'API
      final payload = {
        'to': cleanPhoneNumber,
        'otp': otp,
        'device_type': deviceInfo['device_type'],
        'device_info': {
          'model': deviceInfo['model'],
          'os_version': deviceInfo['os_version'],
          'app_version': deviceInfo['app_version'],
          'device_id': deviceInfo['device_id'],
        }
      };

      debugPrint('Payload OTP avec device_info: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(verifyOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('Réponse API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'status': responseData['status'] ?? 'success',
          'message': responseData['message'] ?? 'Vérification réussie',
          'data': responseData['data'], // Inclure les données de session
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

  // Méthode pour récupérer les informations du device
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      Map<String, dynamic> info = {
        'app_version': packageInfo.version,
      };

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info.addAll({
          'device_type': 'android',
          'model': '${androidInfo.brand} ${androidInfo.model}',
          'os_version': 'Android ${androidInfo.version.release}',
          'device_id': androidInfo.id,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info.addAll({
          'device_type': 'ios',
          'model': '${iosInfo.name} ${iosInfo.model}',
          'os_version': '${iosInfo.systemName} ${iosInfo.systemVersion}',
          'device_id': iosInfo.identifierForVendor ?? 'unknown',
        });
      } else {
        // Fallback pour autres plateformes
        info.addAll({
          'device_type': 'web',
          'model': 'Unknown',
          'os_version': 'Unknown',
          'device_id': 'web-${DateTime.now().millisecondsSinceEpoch}',
        });
      }

      debugPrint('Device info collecté: $info');
      return info;
    } catch (e) {
      debugPrint('Erreur lors de la collecte device info: $e');
      // Retourner des valeurs par défaut en cas d'erreur
      return {
        'device_type': 'unknown',
        'model': 'Unknown',
        'os_version': 'Unknown',
        'app_version': '1.0.0',
        'device_id': 'unknown-${DateTime.now().millisecondsSinceEpoch}',
      };
    }
  }
}