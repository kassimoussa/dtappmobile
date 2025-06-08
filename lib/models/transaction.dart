// lib/models/transaction.dart
class Transaction {
  final String type;
  final String nomForfait;
  final String details;
  final int montant;
  final String date;
  final String status;

  Transaction({
    required this.type,
    required this.nomForfait,
    required this.details,
    required this.montant,
    required this.date,
    required this.status,
  });
}