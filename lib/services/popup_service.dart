import 'package:dtservices/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/popup.dart';

class PopupService {
  static const String baseUrl = AppConfig.baseUrl;

  /// Cache statique du popup
  static PromoPopup? _cachedPopup;
  static bool _hasFetched = false;

  static Future<PromoPopup?> getPopup() async {
    if (_hasFetched) return _cachedPopup;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/popup'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          _cachedPopup = PromoPopup.fromJson(jsonData['data']);
          _hasFetched = true;
          return _cachedPopup;
        }
        _hasFetched = true;
        return null;
      } else {
        _hasFetched = true;
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
