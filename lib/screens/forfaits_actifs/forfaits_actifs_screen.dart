// lib/screens/forfaits_actifs_screen.dart
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:dtservices/services/forfait_actif_service.dart';
import 'package:dtservices/widgets/cards/forfait_actif_card2.dart';
import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart'; 

class ForfaitsActifsScreen extends StatefulWidget {
  const ForfaitsActifsScreen({super.key});

  @override
  State<ForfaitsActifsScreen> createState() => _ForfaitsActifsScreenState();
}

class _ForfaitsActifsScreenState extends State<ForfaitsActifsScreen> {
  List<ForfaitActif2> _forfaitsActifs = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _loadForfaitsActifs();
  }

  Future<void> _loadForfaitsActifs() async {
    if (_isLoading && _lastUpdate != null) return; // Éviter les appels multiples si déjà en cours

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier si l'API est en délai d'attente
      final isTimedOut = await ForfaitActifService.isApiTimedOut();
      
      // Si on a déjà des données et que l'API est en délai d'attente, on s'arrête
      if (isTimedOut && _forfaitsActifs.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        
        // Afficher un message temporaire sur l'attente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le serveur est temporairement indisponible. Veuillez réessayer plus tard.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
        
        return;
      }

      // Récupérer les forfaits actifs (avec cache si API en délai d'attente)
      final forfaits = await ForfaitActifService.getForfaitsActifs(useCache: isTimedOut);
      
      setState(() {
        _forfaitsActifs = forfaits;
        _lastUpdate = DateTime.now();
        _isLoading = false;
      });
      
      // Si aucun forfait n'a été trouvé avec le cache actif
      if (forfaits.isEmpty && isTimedOut) {
        setState(() {
          _errorMessage = 'Impossible de se connecter au serveur. Veuillez réessayer plus tard.';
        });
      }
      
      // Effacer le timeout si la requête a réussi
      await ForfaitActifService.clearApiTimeout();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text(
          'Mes Forfaits',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.dtBlue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 30,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppTheme.dtYellow,
            onPressed: _isLoading ? null : _loadForfaitsActifs,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _forfaitsActifs.isEmpty) {
      return _buildLoadingState();
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_forfaitsActifs.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildForfaitsList();
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
            'Chargement des forfaits...',
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
              onPressed: _loadForfaitsActifs,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: ResponsiveSize.getFontSize(60),
              color: AppTheme.dtYellow,
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              'Vous n\'avez aucun forfait actif',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              'Achetez un forfait pour commencer à utiliser nos services!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            ElevatedButton.icon(
              onPressed: () {
                // Navigation vers l'écran d'achat de forfaits
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Acheter un forfait'),
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

  Widget _buildForfaitsList() {
    return RefreshIndicator(
      onRefresh: _loadForfaitsActifs,
      color: AppTheme.dtBlue,
      child: CustomScrollView(
        slivers: [
          // Indicateur de chargement en cours (quand rafraîchissement)
          if (_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
                child: const LinearProgressIndicator(),
              ),
            ),
          
          // En-tête avec informations sur la dernière mise à jour
          if (_lastUpdate != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
                  vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
                ),
                child: _buildLastUpdateInfo(),
              ),
            ),
          
          // Résumé des forfaits (si plusieurs forfaits)
          if (_forfaitsActifs.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                child: _buildForfaitsResume(),
              ),
            ),
            
          // Liste des forfaits
          SliverPadding(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                    ),
                    child: ForfaitActifCard2(
                      forfait: _forfaitsActifs[index],
                    ),
                  );
                },
                childCount: _forfaitsActifs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdateInfo() {
    if (_lastUpdate == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final diff = now.difference(_lastUpdate!);
    String timeText;
    
    if (diff.inMinutes < 1) {
      timeText = 'il y a quelques secondes';
    } else if (diff.inMinutes < 60) {
      timeText = 'il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
    } else if (diff.inHours < 24) {
      timeText = 'il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
    } else {
      timeText = 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.update,
          size: ResponsiveSize.getFontSize(14),
          color: AppTheme.textSecondary,
        ),
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
        Text(
          'Dernière mise à jour $timeText',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(12),
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildForfaitsResume() {
    // Calculer les totaux pour l'affichage
    double totalDataUsedGo = 0;
    double totalDataAvailableGo = 0;
    int forfaitsInternet = 0;
    int forfaitsCombo = 0;
    
    for (var forfait in _forfaitsActifs) {
      if (forfait.dataCompteur != null) {
        totalDataUsedGo += forfait.dataCompteur!.valeurUtiliseeGo;
        totalDataAvailableGo += forfait.dataCompteur!.seuilsGo;
      }
      
      if (forfait.minutesCompteur != null) {
        forfaitsCombo++;
      } else {
        forfaitsInternet++;
      }
    }
    
    // Calcul du data restant
    final totalDataRemainingGo = totalDataAvailableGo - totalDataUsedGo;
    
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
              'Résumé de consommation',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            
            // Progression totale des données - CORRIGÉE pour afficher le DISPONIBLE
            LinearProgressIndicator(
              value: totalDataAvailableGo > 0 
                  ? totalDataRemainingGo / totalDataAvailableGo  // Pourcentage RESTANT (sera pleine si tout est dispo)
                  : 0,
              backgroundColor: Colors.grey.withOpacity(0.2), // Fond gris = consommé
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue), // Bleu = disponible
              minHeight: ResponsiveSize.getHeight(10),
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusXS)),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

            // Texte de progression - CORRECT (restant / total)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Données Internet',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${totalDataRemainingGo.toStringAsFixed(1)} Go / ${totalDataAvailableGo.toStringAsFixed(1)} Go', // Restant / Total
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            
            // Statistiques forfaits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${_forfaitsActifs.length}',
                  'Forfaits',
                  Icons.sim_card,
                  Colors.purple,
                ),
                _buildStatItem(
                  '$forfaitsInternet',
                  'Internet',
                  Icons.wifi,
                  Colors.blue,
                ),
                _buildStatItem(
                  '$forfaitsCombo',
                  'Combo',
                  Icons.phone_android,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveSize.getFontSize(24),
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(12),
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}