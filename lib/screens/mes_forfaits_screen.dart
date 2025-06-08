// lib/screens/mes_forfaits_screen.dart
import 'package:dtapp3/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import '../models/forfait_actif.dart';
import '../widgets/cards/forfait_actif_card.dart';

class MesForfaitsScreen extends StatelessWidget {
  MesForfaitsScreen({super.key});

  final List<ForfaitActif> forfaitsActifs = [
    ForfaitActif(
      nom: 'Forfait Comfort',
      type: 'internet',
      dataTotal: 20,
      dataUtilisee: 12.5,
      validite: '15 jours restants',
      dateAchat: '10/02/2024', 
      id: 17,
    ),
    ForfaitActif(
      nom: 'Forfait Median',
      type: 'combo',
      dataTotal: 0.2,
      dataUtilisee: 0.15,
      validite: '20 jours restants',
      dateAchat: '15/02/2024',
      minutes: {'total': 75, 'utilisees': 45},
      sms: {'total': 100, 'utilisees': 30}, 
      id: 11,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Achat de forfait', showAction: false),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: forfaitsActifs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun forfait actif',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8),
              itemCount: forfaitsActifs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => ForfaitActifCard(
                forfait: forfaitsActifs[index],
              ),
            ),
      )
    );
  }
}
