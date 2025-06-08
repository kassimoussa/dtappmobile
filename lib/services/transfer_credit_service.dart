// lib/services/transfer_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class TransferService {
  static const String baseUrl = 'http://10.39.230.106/api/air'; // Remplacez par votre URL
  
  Future<Map<String, dynamic>> transferCredit({
    required String senderMsisdn,
    required String receiverMsisdn,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transfer-credit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'Authorization': 'Bearer your-token', // Si vous avez une auth
        },
        body: jsonEncode({
          'sender_msisdn': senderMsisdn,
          'receiver_msisdn': receiverMsisdn,
          'amount': amount,
        }),
      ).timeout(Duration(seconds: 30));

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