// lib/models/forfait_actif2.dart
class ForfaitActif2 {
  final int id;
  final int offreId;
  final String nom;
  final int type;
  final String typeTexte;
  final int etat;
  final String etatTexte;
  final int produitId;
  final String dateDebut;
  final String dateFin;
  final List<Compteur> compteurs;

  ForfaitActif2({
    required this.id,
    required this.offreId,
    required this.nom,
    required this.type,
    required this.typeTexte,
    required this.etat,
    required this.etatTexte,
    required this.produitId,
    required this.dateDebut,
    required this.dateFin,
    required this.compteurs,
  });

  // Méthodes pour obtenir facilement les compteurs par type
  // Modifié pour retourner un type nullable (Compteur?)
  Compteur? get dataCompteur => compteurs.where(
      (compteur) => compteur.id.toString().endsWith('01')).firstOrNull;

  Compteur? get minutesCompteur => compteurs.where(
      (compteur) => compteur.id.toString().endsWith('04')).firstOrNull;

  Compteur? get smsCompteur => compteurs.where(
      (compteur) => compteur.id.toString().endsWith('05')).firstOrNull;

  // Vérifier si c'est un forfait combo (avec minutes et SMS)
  bool get isCombo => minutesCompteur != null && smsCompteur != null;

  // Vérifier si c'est un forfait internet uniquement
  bool get isInternet => !isCombo;

  // Helpers pour la conversion et l'affichage
  double get dataRestanteGo => dataCompteur?.valeurRestanteGo ?? 0;
  double get dataTotaleGo => dataCompteur?.seuilsGo ?? 0;
  double get dataUtiliseeGo => dataCompteur?.valeurUtiliseeGo ?? 0;
  double get dataPercentage => 
      dataCompteur != null ? (dataCompteur!.valeurUtilisee / dataCompteur!.seuils) * 100 : 0;

  // Factory constructor pour créer à partir de JSON
  factory ForfaitActif2.fromJson(Map<String, dynamic> json) {
    return ForfaitActif2(
      id: json['produit_id'],
      offreId: json['id'],
      nom: json['nom'],
      type: json['type'],
      typeTexte: json['type_texte'],
      etat: json['etat'],
      etatTexte: json['etat_texte'],
      produitId: json['produit_id'],
      dateDebut: json['date_debut'],
      dateFin: json['date_fin'],
      compteurs: (json['compteurs'] as List)
          .map((compteurJson) => Compteur.fromJson(compteurJson))
          .toList(),
    );
  }
}

class Compteur {
  final int id;
  final int valeurUtilisee;
  final String vuLisible;
  final int valeurRestante;
  final String vrLisible;
  final int seuils;
  final String seuilsLisible;

  Compteur({
    required this.id,
    required this.valeurUtilisee,
    required this.vuLisible,
    required this.valeurRestante,
    required this.vrLisible,
    required this.seuils,
    required this.seuilsLisible,
  });

  // Helpers pour la conversion en Go
  double get valeurRestanteGo => valeurRestante / (1024 * 1024 * 1024);
  double get valeurUtiliseeGo => valeurUtilisee / (1024 * 1024 * 1024);
  double get seuilsGo => seuils / (1024 * 1024 * 1024);

  // Pourcentage d'utilisation
  double get pourcentageUtilisation => seuils > 0 ? (valeurUtilisee / seuils) * 100 : 0;
  
  // Pourcentage restant (pour un affichage alternatif)
  double get pourcentageRestant => seuils > 0 ? (valeurRestante / seuils) * 100 : 0;

  // Formatage des minutes sans secondes
  String get vrLisibleSansSecondes => _removeSecondsFromTime(vrLisible);
  String get seuilsLisibleSansSecondes => _removeSecondsFromTime(seuilsLisible);
  String get vuLisibleSansSecondes => _removeSecondsFromTime(vuLisible);

  // Fonction helper pour supprimer les secondes des formats de temps
  String _removeSecondsFromTime(String timeString) {
    // Supprimer les secondes du format "2h 30m 0s" -> "2h 30m"
    return timeString.replaceAll(RegExp(r'\s+0s$'), '').replaceAll(RegExp(r'\s+\d+s$'), '');
  }

  // Factory constructor pour créer à partir de JSON
  factory Compteur.fromJson(Map<String, dynamic> json) {
    return Compteur(
      id: json['id'],
      valeurUtilisee: json['valeur_utilise'],
      vuLisible: json['vu_lisible'],
      valeurRestante: json['valeur_restante'],
      vrLisible: json['vr_lisible'],
      seuils: json['seuils'],
      seuilsLisible: json['seuils_lisible'],
    );
  }
}