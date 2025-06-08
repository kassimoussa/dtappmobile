// lib/screens/forfaits_screen.dart
import 'package:dtapp3/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import '../models/forfait.dart';
import '../widgets/cards/forfait_card.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../extensions/color_extensions.dart';

class ForfaitsScreen2 extends StatefulWidget {
  final double? soldeActuel;
  final Function()? onRefreshSolde;
  final String? phoneNumber; 
  final String initialType;
  final String forfaitTitle;

  const ForfaitsScreen2({
    super.key,
    this.soldeActuel,
    this.onRefreshSolde,
    this.phoneNumber,
    this.initialType = 'internet',
    this.forfaitTitle = 'Forfaits Internet',
  });

  @override
  State<ForfaitsScreen2> createState() => _ForfaitsScreen2State();
}

class _ForfaitsScreen2State extends State<ForfaitsScreen2> {
  late String _selectedType;
  bool _isLoading = false; 

  // Liste des forfaits Internet
  final List<Forfait> forfaitsInternet = [
    Forfait(
       id: 13,
      nom: 'Forfait Express',
      data: '1 Go',
      prix: 200,
      validite: '24h',
      type: 'internet',
      code: '*164*2*1*1#',
    ),
    Forfait(
       id: 15,
      nom: 'Forfait Découverte',
      data: '5 Go',
      prix: 500,
      validite: '3 jours',
      type: 'internet',
      code: '*164*2*2*1#',
    ),
    Forfait(
       id: 16,
      nom: 'Forfait Evasion',
      data: '12 Go',
      prix: 1000,
      validite: '7 jours',
      type: 'internet',
      code: '*164*2*3*1#',
    ),
    Forfait(
       id: 17,
      nom: 'Forfait Comfort',
      data: '20 Go',
      prix: 3000,
      validite: '30 jours',
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
      validite: '30 jours',
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
      validite: '30 jours',
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
      validite: '30 jours',
      type: 'combo',
      code: '*164*1*3*1#',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType; 
  } 

  @override
  Widget build(BuildContext context) {
    // Initialiser le responsive size
    ResponsiveSize.init(context);

    // Utiliser le solde fourni par le parent ou une valeur par défaut
    final soldeActuel = widget.soldeActuel ?? 0.0;

    // Liste des forfaits à afficher
    final forfaitsToDisplay =
        _selectedType == 'internet' ? forfaitsInternet : forfaitsCombo; 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:  AppBarWidget(title: widget.forfaitTitle, showAction: false, value: soldeActuel),
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
                  'Choisissez votre forfait',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                Text(
                  _selectedType == 'internet'
                      ? 'Sélectionnez l\'un de nos forfaits internet pour rester connecté.'
                      : 'Profitez d\'appels, SMS et data avec nos forfaits tout-en-un.',
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
              // Rafraîchir le solde si la fonction de rafraîchissement est fournie
              onRefresh:
                  widget.onRefreshSolde != null
                      ? () async {
                        setState(() => _isLoading = true);
                        await widget.onRefreshSolde!();
                        setState(() => _isLoading = false);
                      }
                      : () async {},
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.dtBlue,
                          ),
                        ),
                      )
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
                              soldeActuel: soldeActuel,
                              phoneNumber: widget.phoneNumber, 
                              onAchatReussi: () {
                                // Appeler la méthode de rafraîchissement si elle est fournie
                                if (widget.onRefreshSolde != null) {
                                  widget.onRefreshSolde!();
                                }
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
}
