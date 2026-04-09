// lib/screens/forfait_detail_screen.dart
import 'dart:ui';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:dtservices/services/forfait_actif_service.dart';
import 'package:dtservices/widgets/cards/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_theme.dart';
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
      final forfaits = await ForfaitActifService.getForfaitsActifs(
        useCache: false,
      );
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
          content: Text(
            AppLocalizations.of(context)!.refreshError(e.toString()),
          ),
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
      // Use current locale for date formatting
      final locale = Localizations.localeOf(context).toString();
      final outputFormat = DateFormat("d MMMM yyyy 'à' HH:mm", locale);
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
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueDark.withOpacityValue(0.08),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(context, _forfait.nom),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, String title) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: _isLoading ? null : _refreshForfaitDetails,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(Icons.refresh_rounded, color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
            ],
          ),
        ),
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
              label: Text(AppLocalizations.of(context)!.retry),
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
              AppLocalizations.of(context)!.packageNotFound,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              AppLocalizations.of(context)!.packageNotFoundDesc,
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
              label: Text(AppLocalizations.of(context)!.back),
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
                    color: AppTheme.dtBlue.withOpacity(0.1),
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusS),
                    ),
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
              AppLocalizations.of(context)!.purchaseDate,
              _formatDate(forfait.dateDebut),
              Icons.calendar_today,
            ),
            Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            _buildInfoRow(
              AppLocalizations.of(context)!.expirationDate,
              _formatDate(forfait.dateFin),
              Icons.event,
            ),

            // Afficher les compteurs résumés
            if (forfait.dataCompteur != null) ...[
              Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              _buildInfoRow(
                AppLocalizations.of(context)!.internetData,
                AppLocalizations.of(context)!.remainingOf(
                  forfait.dataCompteur!.vrLisible,
                  forfait.dataCompteur!.seuilsLisible,
                ),
                Icons.data_usage,
              ),
            ],

            if (forfait.minutesCompteur != null) ...[
              Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              _buildInfoRow(
                AppLocalizations.of(context)!.minutesLabel,
                AppLocalizations.of(context)!.remainingOfMinutes(
                  forfait.minutesCompteur!.vrLisibleSansSecondes,
                  forfait.minutesCompteur!.seuilsLisibleSansSecondes,
                ),
                Icons.phone,
              ),
            ],

            if (forfait.smsCompteur != null) ...[
              Divider(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              _buildInfoRow(
                AppLocalizations.of(context)!.smsLabel,
                AppLocalizations.of(context)!.remainingOf(
                  forfait.smsCompteur!.vrLisible,
                  forfait.smsCompteur!.seuilsLisible,
                ),
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
              AppLocalizations.of(context)!.consumption,
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
                label: AppLocalizations.of(context)!.internetData,
                value:
                    '${forfait.dataCompteur!.vrLisible} / ${forfait.dataCompteur!.seuilsLisible}',
                percentage: forfait.dataCompteur!.pourcentageUtilisation,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.used,
                    forfait.dataCompteur!.vuLisible,
                    Colors.orange,
                  ),
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.remaining,
                    forfait.dataCompteur!.vrLisible,
                    Colors.green,
                  ),
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.total,
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
                label: AppLocalizations.of(context)!.minutesLabel,
                value:
                    '${forfait.minutesCompteur!.vrLisibleSansSecondes} / ${forfait.minutesCompteur!.seuilsLisibleSansSecondes}',
                percentage: forfait.minutesCompteur!.pourcentageUtilisation,
                color: Colors.green,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.used,
                    forfait.minutesCompteur!.vuLisibleSansSecondes,
                    Colors.orange,
                  ),
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.remaining,
                    forfait.minutesCompteur!.vrLisibleSansSecondes,
                    Colors.green,
                  ),
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.total,
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
                label: AppLocalizations.of(context)!.smsLabel,
                value:
                    '${forfait.smsCompteur!.vrLisible} / ${forfait.smsCompteur!.seuilsLisible}',
                percentage: forfait.smsCompteur!.pourcentageUtilisation,
                color: Colors.orange,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.used,
                    forfait.smsCompteur!.vuLisible,
                    Colors.orange,
                  ),
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.remaining,
                    forfait.smsCompteur!.vrLisible,
                    Colors.green,
                  ),
                  _buildDataInfoContainer(
                    AppLocalizations.of(context)!.total,
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
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusS),
        ),
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
