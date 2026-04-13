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

  factory Forfait.fromJson(Map<String, dynamic> json) {
    return Forfait(
      id: json['id'] as int,
      nom: json['name'] as String,
      data: json['data_label'] as String?,
      minutes: (json['voice_minutes'] as int?)?.toString(),
      sms: (json['sms_count'] as int?)?.toString(),
      prix: json['price'] as int,
      validite: json['validity_label'] as String,
      isPopulaire: json['is_popular'] as bool? ?? false,
      type: json['category'] as String,
      code: json['ussd_code'] as String,
    );
  }
}