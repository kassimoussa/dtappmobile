import 'package:dtservices/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agency.dart';

class AgencyService {
  static const String baseUrl = AppConfig.baseUrl;

  // Cache mémoire pour éviter de rappeler l'API à chaque ouverture de l'écran.
  static const Duration _cacheTtl = Duration(minutes: 30);
  static List<Agency>? _cachedAgencies;
  static DateTime? _cacheTimestamp;

  static bool get _isCacheValid =>
      _cachedAgencies != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheTtl;

  /// Vide le cache pour forcer un rechargement au prochain appel.
  static void clearCache() {
    _cachedAgencies = null;
    _cacheTimestamp = null;
  }

  static Future<List<Agency>> getAgencies({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedAgencies!;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agencies'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> agenciesData = jsonData['data'];
          final agencies =
              agenciesData
                  .map((json) => Agency.fromJson(json))
                  .where((agency) => agency.isActive)
                  .toList();

          // Mise en cache du résultat.
          _cachedAgencies = agencies;
          _cacheTimestamp = DateTime.now();

          return agencies;
        } else {
          throw Exception('Format de réponse invalide');
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération des agences: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
