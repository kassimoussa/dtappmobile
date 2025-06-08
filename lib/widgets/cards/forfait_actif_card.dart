// lib/widgets/forfait_actif_card.dart
import 'package:flutter/material.dart';
import '../../models/forfait_actif.dart';
import 'progress_bar.dart';

class ForfaitActifCard extends StatelessWidget {
  final ForfaitActif forfait;

  const ForfaitActifCard({
    super.key,
    required this.forfait,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forfait.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acheté le ${forfait.dateAchat}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    forfait.validite,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Consommation data
            ProgressBar(
              label: 'Données Internet',
              value: '${forfait.dataRestante.toStringAsFixed(1)} Go / ${forfait.dataTotal} Go',
              percentage: forfait.dataPercentage,
            ),
            // Consommation minutes et SMS pour les forfaits combo
            if (forfait.type == 'combo') ...[
              const SizedBox(height: 12),
              if (forfait.minutes != null)
                ProgressBar(
                  label: 'Minutes d\'appel',
                  value: '${forfait.minutesRestantes?.toStringAsFixed(0)} / ${forfait.minutes!['total']?.toStringAsFixed(0)} min',
                  percentage: forfait.minutesPercentage!,
                  color: Colors.green,
                ),
              const SizedBox(height: 12),
              if (forfait.sms != null)
                ProgressBar(
                  label: 'SMS',
                  value: '${forfait.smsRestants?.toStringAsFixed(0)} / ${forfait.sms!['total']?.toStringAsFixed(0)}',
                  percentage: forfait.smsPercentage!,
                  color: Colors.orange,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
