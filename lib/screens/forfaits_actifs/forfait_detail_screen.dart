// lib/screens/forfait_detail_screen.dart
import 'package:dtapp3/models/forfait_actif2.dart';
import 'package:dtapp3/services/forfait_actif_service.dart';
import 'package:dtapp3/widgets/cards/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart'; 

class ForfaitDetailScreen extends StatefulWidget {
  final ForfaitActif2 forfait;

  const ForfaitDetailScreen({
    super.key,
    required this.forfait,
  });

  @override
  State<ForfaitDetailScreen> createState() => _ForfaitDetailScreenState();
}

class _ForfaitDetailScreenState extends State<ForfaitDetailScreen> {
  late ForfaitActif2 _forfait;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _forfait = widget.forfait;
  }

  Future<void> _refreshForfaitDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer tous les forfaits et trouver celui qui correspond
      final forfaits = await ForfaitActifService.getForfaitsActifs(useCache: false);
      final updatedForfait = forfaits.firstWhere(
        (f) => f.id == _forfait.id,
        orElse: () => _forfait,
      );
      
      setState(() {
        _forfait = updatedForfait;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      
      // Afficher un message d'erreur temporaire
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de rafraîchir les données: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Fonction pour formater la date de l'API
  String _formatDate(String dateString) {
    try {
      // Format d'entrée: "15/05/2025 19:04:28"
      final inputFormat = DateFormat("dd/MM/yyyy HH:mm:ss");
      final date = inputFormat.parse(dateString);
      
      // Format de sortie: "15 mai 2025 à 19:04"
      final outputFormat = DateFormat("d MMMM yyyy 'à' HH:mm", 'fr_FR');
      return outputFormat.format(date);
    } catch (e) {
      // Fallback si le format n'est pas reconnu
      return dateString;
    }
  }


  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          _forfait.nom,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppTheme.dtYellow,
            onPressed: _isLoading ? null : _refreshForfaitDetails,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Stack(
        children: [
          _buildForfaitDetails(),
          Container(
            color: Colors.black.withOpacity(0.3),
            child: _buildLoadingState(),
          ),
        ],
      );
    }
    
    return _buildForfaitDetails();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            'Chargement des détails...',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveSize.getFontSize(60),
              color: Colors.red,
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            ElevatedButton.icon(
              onPressed: _refreshForfaitDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: AppTheme.dtYellow,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                  vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForfaitNotFoundState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: ResponsiveSize.getFontSize(60),
              color: Colors.grey,
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              'Forfait introuvable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              'Ce forfait n\'existe pas ou n\'est plus disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: AppTheme.dtYellow,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                  vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForfaitDetails() {
    final forfait = _forfait;
    final bool isCombo = forfait.minutesCompteur != null;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte principale avec résumé
          _buildInfoCard(forfait, isCombo),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          
          // Consommation détaillée
          _buildConsommationCard(forfait),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
        ],
      ),
    );
  }

  // Carte d'informations générales
  Widget _buildInfoCard(ForfaitActif2 forfait, bool isCombo) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
                  decoration: BoxDecoration(
                    color: AppTheme.dtBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                  ),
                  child: Icon(
                    isCombo ? Icons.phone_android : Icons.wifi,
                    color: AppTheme.dtBlue,
                    size: ResponsiveSize.getFontSize(24),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forfait.nom,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(20),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                      Text(
                        'Forfait ${isCombo ? 'Combo' : 'Internet'}',
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(14),
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
                    vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                  ),
                  child: Text(
                    forfait.etatTexte,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: ResponsiveSize.getFontSize(12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            
            // Validité
            _buildInfoRow(
              'Date d\'achat:',
              _formatDate(forfait.dateDebut),
              Icons.calendar_today,
            ),
            Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            _buildInfoRow(
              'Date d\'expiration:',
              _formatDate(forfait.dateFin),
              Icons.event,
            ),
            
            // Afficher les compteurs résumés
            if (forfait.dataCompteur != null) ...[
              Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              _buildInfoRow(
                'Données Internet:',
                '${forfait.dataCompteur!.vrLisible} restants / ${forfait.dataCompteur!.seuilsLisible}',
                Icons.data_usage,
              ),
            ],
            
            if (forfait.minutesCompteur != null) ...[
              Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              _buildInfoRow(
                'Minutes d\'appel:',
                '${forfait.minutesCompteur!.vrLisibleSansSecondes} restantes / ${forfait.minutesCompteur!.seuilsLisibleSansSecondes}',
                Icons.phone,
              ),
            ],
            
            if (forfait.smsCompteur != null) ...[
              Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              _buildInfoRow(
                'SMS:',
                '${forfait.smsCompteur!.vrLisible} restants / ${forfait.smsCompteur!.seuilsLisible}',
                Icons.message,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Carte de consommation
  Widget _buildConsommationCard(ForfaitActif2 forfait) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consommation',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            
            // Données Internet
            if (forfait.dataCompteur != null) ...[
              ProgressBar(
                label: 'Données Internet',
                value: '${forfait.dataCompteur!.vrLisible} / ${forfait.dataCompteur!.seuilsLisible}',
                percentage: forfait.dataCompteur!.pourcentageUtilisation,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataInfoContainer(
                    'Utilisé',
                    forfait.dataCompteur!.vuLisible,
                    Colors.orange,
                  ),
                  _buildDataInfoContainer(
                    'Restant',
                    forfait.dataCompteur!.vrLisible,
                    Colors.green,
                  ),
                  _buildDataInfoContainer(
                    'Total',
                    forfait.dataCompteur!.seuilsLisible,
                    AppTheme.dtBlue,
                  ),
                ],
              ),
            ],
            
            // Minutes d'appel
            if (forfait.minutesCompteur != null) ...[
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              ProgressBar(
                label: 'Minutes d\'appel',
                value: '${forfait.minutesCompteur!.vrLisibleSansSecondes} / ${forfait.minutesCompteur!.seuilsLisibleSansSecondes}',
                percentage: forfait.minutesCompteur!.pourcentageUtilisation,
                color: Colors.green,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataInfoContainer(
                    'Utilisé',
                    forfait.minutesCompteur!.vuLisibleSansSecondes,
                    Colors.orange,
                  ),
                  _buildDataInfoContainer(
                    'Restant',
                    forfait.minutesCompteur!.vrLisibleSansSecondes,
                    Colors.green,
                  ),
                  _buildDataInfoContainer(
                    'Total',
                    forfait.minutesCompteur!.seuilsLisibleSansSecondes,
                    AppTheme.dtBlue,
                  ),
                ],
              ),
            ],
            
            // SMS
            if (forfait.smsCompteur != null) ...[
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              ProgressBar(
                label: 'SMS',
                value: '${forfait.smsCompteur!.vrLisible} / ${forfait.smsCompteur!.seuilsLisible}',
                percentage: forfait.smsCompteur!.pourcentageUtilisation,
                color: Colors.orange,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataInfoContainer(
                    'Utilisé',
                    forfait.smsCompteur!.vuLisible,
                    Colors.orange,
                  ),
                  _buildDataInfoContainer(
                    'Restant',
                    forfait.smsCompteur!.vrLisible,
                    Colors.green,
                  ),
                  _buildDataInfoContainer(
                    'Total',
                    forfait.smsCompteur!.seuilsLisible,
                    AppTheme.dtBlue,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }


  // Widget pour une ligne d'information
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveSize.getFontSize(20),
          color: AppTheme.dtBlue,
        ),
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }


  // Widget pour afficher des informations de consommation
  Widget _buildDataInfoContainer(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
        vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(12),
              color: color,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}