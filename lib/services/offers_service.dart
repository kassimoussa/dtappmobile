import 'package:dtservices/config/app_config.dart';
// lib/services/offers_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forfait.dart';

class OffersService {
  static const _url = '${AppConfig.baseUrl}/offers';
  static const _cacheTtl = Duration(hours: 1);

  static Map<String, List<Forfait>>? _cache;
  static DateTime? _cacheTime;

  static bool get _isCacheValid =>
      _cache != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  /// Retourne les offres groupées par catégorie (internet / combo / tempo).
  /// Résout instantanément depuis le cache si valide, sinon appel réseau.
  static Future<Map<String, List<Forfait>>> getOffers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid) return _cache!;

    final response = await http.get(Uri.parse(_url));
    if (response.statusCode != 200) {
      throw Exception('Erreur réseau: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw Exception('Erreur API: ${json['message'] ?? 'inconnue'}');
    }

    final data = json['data'] as Map<String, dynamic>;
    final result = <String, List<Forfait>>{};
    for (final entry in data.entries) {
      result[entry.key] = (entry.value as List)
          .map((e) => Forfait.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _cache = result;
    _cacheTime = DateTime.now();
    return result;
  }

  /// Prefetch silencieux en arrière-plan (appelé depuis l'écran d'accueil).
  /// N'affiche aucune erreur si le réseau est indisponible.
  static void prefetch() {
    if (_isCacheValid) return;
    getOffers().ignore();
  }

  /// Vide le cache manuellement.
  static void clearCache() {
    _cache = null;
    _cacheTime = null;
  }
}
