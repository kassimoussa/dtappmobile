// lib/widgets/forfait_actif_card.dart
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/screens/forfaits_actifs/forfait_detail_screen.dart';
import 'package:flutter/material.dart';
import 'progress_bar.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';

class ForfaitActifCard2 extends StatelessWidget {
  final ForfaitActif2 forfait;

  const ForfaitActifCard2({super.key, required this.forfait});

  // Fonction pour formater la date de l'API
  String _formatDate(String dateString) {
    try {
      // Format d'entrée: "15/05/2025 19:04:28"
      final inputFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
      final date = inputFormat.parse(dateString);

      // Format de sortie: "15/05/2025 19:04"
      final outputFormat = DateFormat("dd/MM/yyyy HH:mm");
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ForfaitDetailScreen(forfait: forfait),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          forfait.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dtBlueO05,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.expiresOn(_formatDate(forfait.dateFin)),
                      style: const TextStyle(
                        color: AppTheme.dtBlue,
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
                  label: AppLocalizations.of(context)!.internetData,
                  value:
                      '${forfait.dataCompteur!.vrLisible} / ${forfait.dataCompteur!.seuilsLisible}',
                  percentage: forfait.dataCompteur!.pourcentageUtilisation,
                ),

              // Minutes (si présent)
              if (forfait.minutesCompteur != null) ...[
                const SizedBox(height: 12),
                ProgressBar(
                  label: AppLocalizations.of(context)!.minutesLabel,
                  value:
                      '${forfait.minutesCompteur!.vrLisibleSansSecondes} / ${forfait.minutesCompteur!.seuilsLisibleSansSecondes}',
                  percentage: forfait.minutesCompteur!.pourcentageUtilisation,
                  color: Colors.green,
                ),
              ],

              // SMS (si présent)
              if (forfait.smsCompteur != null) ...[
                const SizedBox(height: 12),
                ProgressBar(
                  label: AppLocalizations.of(context)!.smsLabel,
                  value:
                      '${forfait.smsCompteur!.vrLisible} / ${forfait.smsCompteur!.seuilsLisible}',
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
