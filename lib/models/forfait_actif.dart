// lib/models/forfait_actif.dart
class ForfaitActif {
  final int id;
  final String nom;
  final String type;
  final double dataTotal;
  final double dataUtilisee;
  final String validite;
  final String dateAchat;
  final Map<String, double>? minutes;
  final Map<String, double>? sms;

  ForfaitActif({
    required this.id,
    required this.nom,
    required this.type,
    required this.dataTotal,
    required this.dataUtilisee,
    required this.validite,
    required this.dateAchat,
    this.minutes,
    this.sms,
  });

  double get dataRestante => dataTotal - dataUtilisee;
  double get dataPercentage => (dataUtilisee / dataTotal) * 100;
  
  double? get minutesRestantes => 
      minutes != null ? minutes!['total']! - minutes!['utilisees']! : null;
  double? get minutesPercentage => 
      minutes != null ? (minutes!['utilisees']! / minutes!['total']!) * 100 : null;
  
  double? get smsRestants => 
      sms != null ? sms!['total']! - sms!['utilisees']! : null;
  double? get smsPercentage => 
      sms != null ? (sms!['utilisees']! / sms!['total']!) * 100 : null;
}