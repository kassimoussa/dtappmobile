// lib/screens/debug_activity_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

class DebugActivityScreen extends StatefulWidget {
  const DebugActivityScreen({super.key});

  @override
  State<DebugActivityScreen> createState() => _DebugActivityScreenState();
}

class _DebugActivityScreenState extends State<DebugActivityScreen> {
  String _rawJsonResponse = '';
  List<Activity> _parsedActivities = [];
  String _debugInfo = '';
  bool _isLoading = false;

  Future<void> _fetchAndCompare() async {
    setState(() {
      _isLoading = true;
      _rawJsonResponse = '';
      _parsedActivities = [];
      _debugInfo = '';
    });

    try {
      // Récupérer les données via notre service
      final response = await ActivityService.getHistory(
        msisdn: '25377000146',
        page: 1,
        perPage: 3,
        days: 30,
      );

      if (response != null) {
        setState(() {
          _parsedActivities = response.data;
          
          // Simuler la réponse JSON brute pour comparaison
          _rawJsonResponse = '''Données parsées par notre service:
- Nombre d'activités: ${response.data.length}
- Page courante: ${response.pagination.currentPage}
- Total: ${response.pagination.total}
- MSISDN: ${response.filters.msisdn}
- Période: ${response.filters.days} jours

Première activité parsée:
- ID: ${response.data.isNotEmpty ? response.data.first.id : 'N/A'}
- Type: ${response.data.isNotEmpty ? response.data.first.actionType : 'N/A'}
- Label: ${response.data.isNotEmpty ? response.data.first.actionLabel : 'N/A'}
- Montant: ${response.data.isNotEmpty ? response.data.first.formattedAmount : 'N/A'}
- Date: ${response.data.isNotEmpty ? response.data.first.formattedDate : 'N/A'}
- Détails: ${response.data.isNotEmpty ? (response.data.first.detailsText ?? 'Aucun') : 'N/A'}''';

          _debugInfo = _generateDebugInfo(response);
        });
      } else {
        setState(() {
          _rawJsonResponse = 'Erreur: Aucune donnée reçue du service';
        });
      }
    } catch (e) {
      setState(() {
        _rawJsonResponse = 'Erreur: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _generateDebugInfo(ActivityHistoryResponse response) {
    String debug = '=== ANALYSE DÉTAILLÉE ===\n\n';
    
    debug += 'PAGINATION:\n';
    debug += '- Type currentPage: ${response.pagination.currentPage.runtimeType}\n';
    debug += '- Valeur currentPage: ${response.pagination.currentPage}\n';
    debug += '- Type total: ${response.pagination.total.runtimeType}\n';
    debug += '- Valeur total: ${response.pagination.total}\n\n';
    
    debug += 'FILTERS:\n';
    debug += '- Type days: ${response.filters.days.runtimeType}\n';
    debug += '- Valeur days: ${response.filters.days}\n';
    debug += '- Type perPage: ${response.filters.perPage.runtimeType}\n';
    debug += '- Valeur perPage: ${response.filters.perPage}\n\n';
    
    if (response.data.isNotEmpty) {
      final first = response.data.first;
      debug += 'PREMIÈRE ACTIVITÉ:\n';
      debug += '- Type ID: ${first.id.runtimeType} = ${first.id}\n';
      debug += '- Type amount: ${first.amount.runtimeType} = ${first.amount}\n';
      debug += '- Currency: ${first.currency}\n';
      debug += '- External ref: ${first.externalReference}\n';
      debug += '- Details présents: ${first.details != null}\n';
      if (first.details != null) {
        debug += '- Clés details: ${first.details!.keys.toList()}\n';
        debug += '- Details complets: ${first.details}\n';
      }
      debug += '- Details formatés: ${first.detailsText}\n';
    }
    
    return debug;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        title: const Text(
          'Debug Activity API',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchAndCompare,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Analyser les données API'),
            ),
            const SizedBox(height: 16),
            
            if (_rawJsonResponse.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Données du Service',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rawJsonResponse,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            if (_debugInfo.isNotEmpty) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analyse Debug',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _debugInfo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            
            if (_parsedActivities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Aperçu des activités (${_parsedActivities.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.dtBlue,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _parsedActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _parsedActivities[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${activity.actionLabel} (ID: ${activity.id})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Montant: ${activity.formattedAmount}'),
                            Text('Date: ${activity.formattedDate}'),
                            if (activity.detailsText != null)
                              Text(
                                'Détails: ${activity.detailsText}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            if (activity.externalReference != null)
                              Text(
                                'Réf: ${activity.externalReference}',
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}