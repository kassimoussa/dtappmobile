// lib/screens/test_activity_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../services/activity_service.dart';

class TestActivityScreen extends StatefulWidget {
  const TestActivityScreen({super.key});

  @override
  State<TestActivityScreen> createState() => _TestActivityScreenState();
}

class _TestActivityScreenState extends State<TestActivityScreen> {
  String _testResults = '';
  bool _isLoading = false;

  Future<void> _testHistoryEndpoint() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Test de l\'endpoint d\'historique...\n';
    });

    try {
      final response = await ActivityService.getHistory(
        msisdn: '25377000146',
        page: 1,
        perPage: 5,
        days: 30,
      );

      if (response != null) {
        setState(() {
          _testResults += '✅ Historique récupéré avec succès!\n';
          _testResults += 'Nombre d\'activités: ${response.data.length}\n';
          _testResults += 'Page actuelle: ${response.pagination.currentPage}\n';
          _testResults += 'Total: ${response.pagination.total}\n';
          _testResults += 'MSISDN: ${response.filters.msisdn}\n';
          _testResults += 'Période: ${response.filters.days} jours\n\n';
          
          _testResults += 'Première activité:\n';
          if (response.data.isNotEmpty) {
            final first = response.data.first;
            _testResults += '- ID: ${first.id}\n';
            _testResults += '- Type: ${first.actionType}\n';
            _testResults += '- Label: ${first.actionLabel}\n';
            _testResults += '- Statut: ${first.status}\n';
            _testResults += '- Montant: ${first.formattedAmount}\n';
            _testResults += '- Date: ${first.formattedDate}\n';
            if (first.detailsText != null) {
              _testResults += '- Détails: ${first.detailsText}\n';
            }
          }
        });
      } else {
        setState(() {
          _testResults += '❌ Échec de récupération de l\'historique\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += '❌ Erreur: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testStatsEndpoint() async {
    setState(() {
      _testResults += '\nTest de l\'endpoint de statistiques...\n';
    });

    try {
      final response = await ActivityService.getStats(
        msisdn: '25377000146',
        days: 30,
      );

      if (response != null) {
        setState(() {
          _testResults += '✅ Statistiques récupérées avec succès!\n';
          _testResults += 'Nombre de types d\'action: ${response.data.length}\n';
          _testResults += 'Période: ${response.periodDays} jours\n';
          _testResults += 'MSISDN: ${response.msisdn}\n';
          _testResults += 'Total actions: ${response.totalActions}\n';
          _testResults += 'Montant total: ${response.totalAmount.toStringAsFixed(0)} DJF\n';
          _testResults += 'Taux succès global: ${response.overallSuccessRate.toStringAsFixed(1)}%\n\n';
          
          _testResults += 'Détail par type:\n';
          for (final stat in response.data) {
            _testResults += '- ${stat.actionLabel}:\n';
            _testResults += '  Total: ${stat.totalCount}, Réussis: ${stat.successCount}\n';
            _testResults += '  Taux: ${stat.formattedSuccessRate}, Montant: ${stat.formattedTotalAmount}\n';
          }
        });
      } else {
        setState(() {
          _testResults += '❌ Échec de récupération des statistiques\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += '❌ Erreur stats: $e\n';
      });
    }
  }

  Future<void> _runAllTests() async {
    await _testHistoryEndpoint();
    await _testStatsEndpoint();
    
    setState(() {
      _testResults += '\n🎉 Tests terminés!\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        title: const Text(
          'Test Activity API',
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testHistoryEndpoint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Historique'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testStatsEndpoint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Stats'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _runAllTests,
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
                  : const Text('Lancer tous les tests'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'Résultats des tests s\'afficheront ici...' : _testResults,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: ResponsiveSize.getFontSize(12),
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}