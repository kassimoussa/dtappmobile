// lib/models/forfait.dart
class Forfait {
  final int id;
  final String nom;
  final String? data;
  final String? minutes;
  final String? sms;
  final int prix;
  final String validite;
  final bool isPopulaire;
  final String type;
  final String code;

  Forfait({
    required this.id,
    required this.nom,
    this.data,
    this.minutes,
    this.sms,
    required this.prix,
    required this.validite,
    this.isPopulaire = false,
    required this.type,
    required this.code,
  });
}