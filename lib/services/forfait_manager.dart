// lib/services/forfait_manager.dart

import '../models/forfait.dart';
import 'config_service.dart';
import 'ussd_service.dart';

class ForfaitManager {
  final ConfigService _configService = ConfigService();
  // final ForfaitService _apiService = ForfaitService(); // Commenté pour éviter l'erreur
  
  Future<bool> acheterForfait(Forfait forfait, double soldeActuel) async {
    final mode = await _configService.getConnectionMode();
    
    if (mode == ConnectionMode.api) {
      // Simulation de l'appel API (à remplacer par l'intégration réelle plus tard)
      await Future.delayed(const Duration(milliseconds: 800)); // Simule un délai réseau
      // Vérification du solde pour la simulation
      return forfait.prix <= soldeActuel;
    } else {
      // Utilisation de UssdService pour l'achat de forfaits
      try {
        // Supposons que les forfaits internet et combo ont des codes USSD spécifiques
        // stockés dans la propriété 'code' du forfait
        final String response = await UssdService.sendUssdRequest(forfait.code);
        
        // Analyser la réponse pour déterminer si l'achat a réussi
        // Exemple simple - vous devrez adapter selon les réponses réelles
        return !response.contains('Erreur') && 
               (response.contains('succès') || response.contains('activé'));
      } catch (e) {
        print('Erreur lors de l\'achat du forfait: $e');
        return false;
      }
    }
  }
  
  Future<String> getBalance() async {
    final mode = await _configService.getConnectionMode();
    
    if (mode == ConnectionMode.api) {
      // Simulation pour l'exemple
      return Future.delayed(const Duration(seconds: 1), () => '5000');
    } else {
      // Utilisation de la méthode statique de UssdService
      return UssdService.checkBalance();
    }
  }
  
  // Nouvelle méthode pour obtenir des informations détaillées sur le solde
  Future<Map<String, dynamic>> getBalanceDetails() async {
    final mode = await _configService.getConnectionMode();
    
    if (mode == ConnectionMode.api) {
      // Simulation pour le mode API
      return Future.delayed(const Duration(seconds: 1), () => {
        'solde': 5000.0,
        'bonus': 200.0,
        'dateExpiration': '31-12-23',
        'success': true
      });
    } else {
      return UssdService.getBalanceInfo();
    }
  }
  
  // Nouvelle méthode pour vérifier le solde de données Internet
  Future<String> getDataBalance() async {
    final mode = await _configService.getConnectionMode();
    
    if (mode == ConnectionMode.api) {
      // Simulation pour le mode API
      return Future.delayed(const Duration(seconds: 1), () => 'Données restantes: 5 Go');
    } else {
      return UssdService.checkDataBalance();
    }
  }
}