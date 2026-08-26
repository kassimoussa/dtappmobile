// lib/screens/forfait_detail_screen.dart
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/services/forfait_actif_service.dart';
import 'package:dtservices/widgets/cards/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
import '../../utils/forfait_state_translator.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';

class ForfaitDetailScreen extends StatefulWidget {
  final ForfaitActif2 forfait;

  const ForfaitDetailScreen({super.key, required this.forfait});

  @override
  State<ForfaitDetailScreen> createState() => _ForfaitDetailScreenState();
}

class _ForfaitDetailScreenState extends State<ForfaitDetailScreen> {
  late ForfaitActif2 _forfait;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _forfait = widget.forfait;
  }

  Future<void> _refreshForfaitDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer tous les forfaits et trouver celui qui correspond
      final forfaits = await ForfaitActifService.getForfaitsActifs(
        useCache: false,
      );
      final updatedForfait = forfaits.firstWhere(
        (f) => f.id == _forfait.id,
        orElse: () => _forfait,
      );

      if (!mounted) return;

      setState(() {
        _forfait = updatedForfait;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Afficher un message d'erreur temporaire
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.refreshError(e.toString()),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Parse le format de l'API: "15/05/2025 19:04:28"
  DateTime? _parseDate(String dateString) {
    try {
      return DateFormat("dd/MM/yyyy HH:mm:ss").parse(dateString);
    } catch (e) {
      // Format non reconnu
      return null;
    }
  }

  // Format de sortie: "15 mai 2025"
  String _formatDay(String dateString) {
    final date = _parseDate(dateString);
    if (date == null) return dateString;

    // Use current locale for date formatting
    final locale = Localizations.localeOf(context).toString();
    return DateFormat("d MMM yyyy", locale).format(date);
  }

  // Format de sortie: "19:04"
  String _formatTime(String dateString) {
    final date = _parseDate(dateString);
    if (date == null) return '';
    return DateFormat("HH:mm").format(date);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.dtBlueO08, Colors.transparent],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(
                  title: _forfait.nom,
                  actions: [
                    GlassAppBarAction(
                      icon: Icons.refresh_rounded,
                      onTap: _isLoading ? null : _refreshForfaitDetails,
                    ),
                    SizedBox(width: ResponsiveSize.getWidth(8)),
                    GlassAppBarAction(
                      icon: Icons.close,
                      onTap:
                          () => Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Stack(
        children: [
          _buildForfaitDetails(),
          Container(
            color: Colors.black.withValues(alpha: 0.3),
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
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            AppLocalizations.of(context)!.loadingDetails,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveSize.getWidth(AppTheme.spacingS),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.dtBlueO10,
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(20),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingXS),
                      ),
                      Text(
                        isCombo
                            ? AppLocalizations.of(context)!.comboPackage
                            : AppLocalizations.of(context)!.internetPackage,
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusS),
                    ),
                  ),
                  child: Text(
                    translateForfaitState(
                      forfait.etatTexte,
                      AppLocalizations.of(context)!,
                    ),
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

            // Validité : les compteurs sont détaillés dans la carte Consommation
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildDateBlock(
                      AppLocalizations.of(context)!.purchaseDateShort,
                      forfait.dateDebut,
                      Icons.calendar_today,
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                  Expanded(
                    child: _buildDateBlock(
                      AppLocalizations.of(context)!.expirationDateShort,
                      forfait.dateFin,
                      Icons.event,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte de consommation
  Widget _buildConsommationCard(ForfaitActif2 forfait) {
    final l10n = AppLocalizations.of(context)!;
    final sections = <Widget>[
      if (forfait.dataCompteur != null)
        _buildCounterSection(
          label: l10n.internetData,
          used: forfait.dataCompteur!.vuLisible,
          remaining: forfait.dataCompteur!.vrLisible,
          total: forfait.dataCompteur!.seuilsLisible,
          percentage: forfait.dataCompteur!.pourcentageUtilisation,
          color: AppTheme.dtBlue,
        ),
      if (forfait.minutesCompteur != null)
        _buildCounterSection(
          label: l10n.minutesLabel,
          used: forfait.minutesCompteur!.vuLisibleSansSecondes,
          remaining: forfait.minutesCompteur!.vrLisibleSansSecondes,
          total: forfait.minutesCompteur!.seuilsLisibleSansSecondes,
          percentage: forfait.minutesCompteur!.pourcentageUtilisation,
          color: Colors.green,
        ),
      if (forfait.smsCompteur != null)
        _buildCounterSection(
          label: l10n.smsLabel,
          used: forfait.smsCompteur!.vuLisible,
          remaining: forfait.smsCompteur!.vrLisible,
          total: forfait.smsCompteur!.seuilsLisible,
          percentage: forfait.smsCompteur!.pourcentageUtilisation,
          color: Colors.orange,
        ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.consumption,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            for (int i = 0; i < sections.length; i++) ...[
              if (i > 0)
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              sections[i],
            ],
          ],
        ),
      ),
    );
  }

  // Une ligne de consommation: barre de progression + répartition utilisé /
  // restant / total
  Widget _buildCounterSection({
    required String label,
    required String used,
    required String remaining,
    required String total,
    required double percentage,
    required Color color,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressBar(
          label: label,
          value: '$remaining / $total',
          percentage: percentage,
          color: color,
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildDataInfoContainer(l10n.used, used, Colors.orange),
              ),
              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
              Expanded(
                child: _buildDataInfoContainer(
                  l10n.remaining,
                  remaining,
                  Colors.green,
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
              Expanded(
                child: _buildDataInfoContainer(
                  l10n.total,
                  total,
                  AppTheme.dtBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bloc date (achat / expiration)
  Widget _buildDateBlock(String label, String dateString, IconData icon) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: AppTheme.dtBlueO05,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusS),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: ResponsiveSize.getFontSize(14),
                color: AppTheme.dtBlue,
              ),
              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(12),
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatDay(dateString),
              maxLines: 1,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(15),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            _formatTime(dateString),
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(12),
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher des informations de consommation
  Widget _buildDataInfoContainer(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingXS),
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusS),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(12),
              color: color,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
