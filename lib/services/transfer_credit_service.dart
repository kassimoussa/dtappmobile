// lib/services/transfer_service.dart
import 'dart:convert';
import 'package:dtservices/config/api_client.dart';

class TransferService {
  Future<Map<String, dynamic>> transferCredit({
    required String senderMsisdn,
    required String receiverMsisdn,
    required double amount,
  }) async {
    try {
      final response = await ApiClient.post('/air/transfer-credit', {
        'sender_msisdn': senderMsisdn,
        'receiver_msisdn': receiverMsisdn,
        'amount': amount,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Transfert effectué avec succès',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['erreur'] ?? 'Erreur de transfert',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }
}