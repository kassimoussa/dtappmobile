import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner.dart';

class BannerService {
  static const String baseUrl = 'http://10.39.230.106/api';

  /// Cache statique des bannières
  static List<PromoBanner>? _cachedBanners;

  /// Vide le cache pour forcer le rechargement
  static void clearCache() {
    _cachedBanners = null;
  }

  static Future<List<PromoBanner>> getBanners() async {
    if (_cachedBanners != null) return _cachedBanners!;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/banners'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> bannersData = jsonData['data'];
          final banners =
              bannersData.map((json) => PromoBanner.fromJson(json)).toList();
          banners.sort((a, b) => a.order.compareTo(b.order));
          _cachedBanners = banners;
          return banners;
        } else {
          throw Exception('Format de réponse invalide');
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des bannières: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
