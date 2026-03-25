import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/popup.dart';

class PopupService {
  static const String baseUrl = 'http://10.39.230.106/api';

  static Future<PromoPopup?> getPopup() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/popup'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          return PromoPopup.fromJson(jsonData['data']);
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
