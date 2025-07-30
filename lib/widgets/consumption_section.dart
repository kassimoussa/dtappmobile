// lib/widgets/consumption_section.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
// import 'package:dtservices/screens/history_page.dart';

class ConsumptionSection extends StatelessWidget {
  const ConsumptionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Color djiboutiBlue = const Color(0xFF002555);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Consommation récente - Ligne fixe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: djiboutiBlue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildConsumptionCard(context, djiboutiBlue),
      ],
    );
  }

  Widget _buildConsumptionCard(BuildContext context, Color djiboutiBlue) {
    final Color djiboutiYellow = const Color(0xFFF7C700);

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
              Text(
                'Derniers 30 jours',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: djiboutiBlue,
                ),
              ),
              const SizedBox(height: 16),
              // Données
              _buildConsumptionItem(
                'Internet fixe',
                '35 Go',
                '100 Go',
                0.35,
                Icons.wifi,
                djiboutiYellow,
              ),
              const SizedBox(height: 16),
              // Appels
              _buildConsumptionItem(
                'Appels fixe',
                '340 min',
                '500 min',
                0.68,
                Icons.call,
                djiboutiYellow,
              ),
              const SizedBox(height: 16),
              // Bouton pour plus de détails
              Center(
                child: TextButton(
                  onPressed: () { },
                  style: TextButton.styleFrom(foregroundColor: djiboutiBlue),
                  child: const Text(
                    'Voir l\'historique détaillé',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsumptionItem(
    String title,
    String used,
    String total,
    double percentage,
    IconData icon,
    Color progressColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text(
              '$used / $total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: percentage,
          progressColor: progressColor,
          backgroundColor: Colors.grey[200],
          barRadius: const Radius.circular(8),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

