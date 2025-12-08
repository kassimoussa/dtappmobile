// lib/screens/forfaits_screen.dart
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/models/forfait.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/appbar_widget.dart';
import 'package:dtservices/enums/purchase_enums.dart';
import 'package:dtservices/widgets/cards/forfait_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';

class ForfaitsScreen extends StatefulWidget {
  final String? phoneNumber;
  final String initialType;
  final String forfaitTitle;
  final PurchaseMode purchaseMode;

  const ForfaitsScreen({
    super.key,
    this.phoneNumber,
    this.initialType = 'internet',
    this.forfaitTitle = 'Forfaits Internet',
    this.purchaseMode = PurchaseMode.personal,
  });

  @override
  State<ForfaitsScreen> createState() => _ForfaitsScreenState();
}

class _ForfaitsScreenState extends State<ForfaitsScreen> {
  late String _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    // Initialiser le responsive size
    ResponsiveSize.init(context);
    final balanceProvider = context.watch<BalanceProvider>();
    final l10n = AppLocalizations.of(context)!;

    // Liste des forfaits Internet
    final List<Forfait> forfaitsInternet = [
      Forfait(
        id: 13,
        nom: 'Forfait Express',
        data: '1 Go',
        prix: 200,
        validite: l10n.validityHours(24),
        type: 'internet',
        code: '*164*2*1*1#',
      ),
      Forfait(
        id: 15,
        nom: 'Forfait Découverte',
        data: '5 Go',
        prix: 500,
        validite: l10n.validityDays(3),
        type: 'internet',
        code: '*164*2*2*1#',
      ),
      Forfait(
        id: 16,
        nom: 'Forfait Evasion',
        data: '12 Go',
        prix: 1000,
        validite: l10n.validityDays(7),
        type: 'internet',
        code: '*164*2*3*1#',
      ),
      Forfait(
        id: 17,
        nom: 'Forfait Comfort',
        data: '20 Go',
        prix: 3000,
        validite: l10n.validityDays(30),
        isPopulaire: true,
        type: 'internet',
        code: '*164*2*4*1#',
      ),
    ];

    // Liste des forfaits Combo
    final List<Forfait> forfaitsCombo = [
      Forfait(
        id: 10,
        nom: 'Forfait Classic',
        minutes: '35',
        sms: '50',
        data: '100 Mo',
        prix: 500,
        validite: l10n.validityDays(30),
        type: 'combo',
        code: '*164*1*1*1#',
      ),
      Forfait(
        id: 11,
        nom: 'Forfait Median',
        minutes: '75',
        sms: '100',
        data: '200 Mo',
        prix: 1000,
        validite: l10n.validityDays(30),
        type: 'combo',
        isPopulaire: true,
        code: '*164*1*2*1#',
      ),
      Forfait(
        id: 12,
        nom: 'Forfait Premium',
        minutes: '155',
        sms: '250',
        data: '400 Mo',
        prix: 2000,
        validite: l10n.validityDays(30),
        type: 'combo',
        code: '*164*1*3*1#',
      ),
    ];

    // Liste des forfaits Tempo
    final List<Forfait> forfaitsTempo = [
      Forfait(
        id: 29,
        nom: 'Forfait Sensation',
        minutes: '60',
        data: null, // Pas de data pour les forfaits Tempo
        prix: 500,
        validite: l10n.validityWeekendLong,
        type: 'tempo',
        code: '*164*3*1*1#',
        isPopulaire: true,
      ),
    ];

    // Liste des forfaits à afficher
    final forfaitsToDisplay =
        _selectedType == 'internet'
            ? forfaitsInternet
            : _selectedType == 'combo'
            ? forfaitsCombo
            : forfaitsTempo;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: widget.forfaitTitle,
        value: balanceProvider.solde,
        showAction: false,
        showCancelToHome: true, // Affiche le bouton Annuler
      ),
      body: Column(
        children: [
          // En-tête explicatif
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
            decoration: BoxDecoration(
              color: AppTheme.dtBlue.withOpacityValue(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.dtBlue.withOpacityValue(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.choosePackageHeader,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                Text(
                  _getDescriptionText(),
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Liste des forfaits
          Expanded(
            child: RefreshIndicator(
              // Rafraîchir le solde avec BalanceProvider
              onRefresh: () async {
                setState(() => _isLoading = true);
                await context.read<BalanceProvider>().refreshBalance();
                setState(() => _isLoading = false);
              },
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.dtBlue,
                          ),
                        ),
                      )
                      : _selectedType == 'tempo' && forfaitsTempo.isEmpty
                      ? _buildEmptyTempoState()
                      : Padding(
                        padding: EdgeInsets.all(
                          ResponsiveSize.getWidth(AppTheme.spacingM),
                        ),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: forfaitsToDisplay.length,
                          separatorBuilder:
                              (context, index) => SizedBox(
                                height: ResponsiveSize.getHeight(
                                  AppTheme.spacingM,
                                ),
                              ),
                          itemBuilder: (context, index) {
                            final forfait = forfaitsToDisplay[index];
                            return ForfaitCard(
                              forfait: forfait,
                              soldeActuel: balanceProvider.solde,
                              phoneNumber: widget.phoneNumber,
                              purchaseMode:
                                  widget
                                      .purchaseMode, // Transmettre le mode d'achat
                              onAchatReussi: () {
                                // Rafraîchir le solde après achat réussi
                                context
                                    .read<BalanceProvider>()
                                    .refreshBalance();
                              },
                            );
                          },
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDescriptionText() {
    switch (_selectedType) {
      case 'internet':
        return AppLocalizations.of(context)!.internetDesc;
      case 'combo':
        return AppLocalizations.of(context)!.comboDesc;
      case 'tempo':
        return AppLocalizations.of(context)!.tempoDesc;
      default:
        return AppLocalizations.of(context)!.defaultPackageDesc;
    }
  }

  Widget _buildEmptyTempoState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.weekend,
              size: ResponsiveSize.getFontSize(80),
              color: AppTheme.dtBlue.withOpacityValue(0.6),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              AppLocalizations.of(context)!.emptyTempoTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(20),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              AppLocalizations.of(context)!.emptyTempoDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
