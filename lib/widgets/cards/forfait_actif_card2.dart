// lib/widgets/forfait_actif_card.dart
import 'package:dtapp3/models/forfait_actif2.dart';
import 'package:dtapp3/screens/forfaits_actifs/forfait_detail_screen.dart';
import 'package:flutter/material.dart'; 
import 'progress_bar.dart';
import 'package:intl/intl.dart';

class ForfaitActifCard2 extends StatelessWidget {
  final ForfaitActif2 forfait;

  const ForfaitActifCard2({
    super.key,
    required this.forfait,
  });

  // Fonction pour formater la date de l'API
  String _formatDate(String dateString) {
    try {
      // Format d'entrée: "15/05/2025 19:04:28"
      final inputFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
      final date = inputFormat.parse(dateString);
      
      // Format de sortie: "15/05/2025"
      final outputFormat = DateFormat("dd/MM/yyyy");
      return outputFormat.format(date);
    } catch (e) {
      // Fallback si le format n'est pas reconnu
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ForfaitDetailScreen(
                forfait: forfait,
              ),
            ),
          );
        },
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
                      /* const SizedBox(height: 4),
                      Text(
                        'Acheté le ${_formatDate(forfait.dateDebut)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ), */
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Expire le ${_formatDate(forfait.dateFin)}',
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
              
              // Données Internet (présent dans tous les forfaits)
              if (forfait.dataCompteur != null)
                ProgressBar(
                  label: 'Données Internet',
                  value: '${forfait.dataCompteur!.vrLisible} / ${forfait.dataCompteur!.seuilsLisible}',
                  percentage: forfait.dataCompteur!.pourcentageUtilisation,
                ),
                
              // Minutes (si présent)
              if (forfait.minutesCompteur != null) ...[
                const SizedBox(height: 12),
                ProgressBar(
                  label: 'Minutes d\'appel',
                  value: '${forfait.minutesCompteur!.vrLisibleSansSecondes} / ${forfait.minutesCompteur!.seuilsLisibleSansSecondes}',
                  percentage: forfait.minutesCompteur!.pourcentageUtilisation,
                  color: Colors.green,
                ),
              ],
                
              // SMS (si présent)  
              if (forfait.smsCompteur != null) ...[
                const SizedBox(height: 12),
                ProgressBar(
                  label: 'SMS',
                  value: '${forfait.smsCompteur!.vrLisible} / ${forfait.smsCompteur!.seuilsLisible}',
                  percentage: forfait.smsCompteur!.pourcentageUtilisation,
                  color: Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}