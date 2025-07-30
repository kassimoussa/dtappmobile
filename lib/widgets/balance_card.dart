
// lib/widgets/balance_card.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/recharge_dialog.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  final Color djiboutiBlue = const Color(0xFF002555);
  final Color djiboutiYellow = const Color(0xFFF7C700);
  bool _showBalance = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solde principal - Ligne fixe',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: djiboutiBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showBalance = !_showBalance;
                      });
                    },
                    child: Icon(
                      _showBalance ? Icons.visibility : Icons.visibility_off,
                      color: djiboutiYellow,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _showBalance ? '6,200' : '****',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: djiboutiBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DJF',
                        style: TextStyle(fontSize: 16, color: djiboutiBlue),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: djiboutiYellow,
                      foregroundColor: djiboutiBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const RechargeDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Recharger',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Date d\'expiration: 15 Mai 2025',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}