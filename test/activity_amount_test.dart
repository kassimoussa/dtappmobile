import 'package:flutter_test/flutter_test.dart';
import 'package:dtservices/models/activity.dart';

Activity make({
  required String type,
  double? amount,
  Map<String, dynamic>? metadata,
  String? description,
}) => Activity.fromJson({
      'transaction_no': '000000000078',
      'action_type': type,
      'action_label': 'Transfert de credit',
      'endpoint': '',
      'status': 'success',
      'amount': amount,
      'created_at': '2026-08-30T08:24:00',
      'description': description,
      'metadata': metadata,
    });

void main() {
  test('transfert 500 + frais 25', () {
    final a = make(type: 'credit_transfer', amount: 500, metadata: {'fee': 25});
    expect(a.feeValue, 25);
    expect(a.totalAmount, 525);
  });

  test('frais uniquement dans la description', () {
    final a = make(
      type: 'credit_transfer',
      amount: 500,
      description: 'Transfert vers 77039173 (frais 25 DJF)',
    );
    expect(a.totalAmount, 525);
  });

  test('credit recu : pas de frais ajoutes', () {
    final a = make(type: 'credit_received', amount: 50, metadata: {'fee': 25});
    expect(a.totalAmount, 50);
  });

  test('achat sans frais', () {
    final a = make(type: 'offer_purchase', amount: 300);
    expect(a.totalAmount, 300);
  });

  test('montant signe negatif', () {
    final a = make(type: 'credit_transfer', amount: -500, metadata: {'fee': 25});
    expect(a.totalAmount, -525);
  });

  test('date formatee avec padding', () {
    final a = make(type: 'credit_transfer', amount: 500);
    expect(a.formattedDate, '30/08/2026 08:24');
  });
}
