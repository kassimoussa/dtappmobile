// lib/services/forfait_service.dart

import '../models/forfait.dart';

class ForfaitService {
  static Future<bool> acheterForfait(Forfait forfait, double soldeActuel) async {
    // Vérification du solde
    if (forfait.prix > soldeActuel) {
      return false;
    }

    try {
      // Ici on ajoutera l'appel à l'API pour l'achat réel
      // Simulation d'un délai réseau
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      print('Erreur lors de l\'achat: $e');
      return false;
    }
  }
}
