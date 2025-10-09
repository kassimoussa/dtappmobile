import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agency.dart';

class AgencyService {
  static const String baseUrl = 'http://10.39.230.106/api';

  static Future<List<Agency>> getAgencies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agencies'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> agenciesData = jsonData['data'];
          return agenciesData
              .map((json) => Agency.fromJson(json))
              .where((agency) => agency.isActive)
              .toList();
        } else {
          throw Exception('Format de réponse invalide');
        }
      } else {
        throw Exception('Erreur lors de la récupération des agences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
