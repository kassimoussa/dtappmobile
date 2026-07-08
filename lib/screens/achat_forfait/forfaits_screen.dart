import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/extensions/color_extensions.dart';
import 'package:dtservices/models/forfait.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/services/offers_service.dart';
import 'package:dtservices/utils/responsive_size.dart';
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
  Map<String, List<Forfait>>? _offers;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadOffers();
  }

  Future<void> _loadOffers({bool forceRefresh = false}) async {
    // Si le cache est valide, OffersService résout instantanément → pas de spinner
    if (!forceRefresh && _offers == null) {
      setState(() => _isLoading = true);
    }
    try {
      final offers = await OffersService.getOffers(forceRefresh: forceRefresh);
      if (mounted) setState(() { _offers = offers; _isLoading = false; _errorMessage = null; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final balanceProvider = context.watch<BalanceProvider>();
    final l10n = AppLocalizations.of(context)!;

    final forfaitsToDisplay = _offers?[_selectedType] ?? [];
    final forfaitsTempo = _offers?['tempo'] ?? [];

    return Scaffold(

      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.dtBlueDark.withOpacityValue(0.05),
                  Colors.white,
                  AppTheme.dtBlueLight.withOpacityValue(0.05),
                ],
              ),
            ),
          ),
          PositionNotifier(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueO08,
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
                GlassAppBar(title: widget.forfaitTitle, actions: [GlassAppBarAction(icon: Icons.close, onTap: () => Navigator.of(context).popUntil((route) => route.isFirst))]),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.choosePackageHeader,
                              style: TextStyle(
                                fontSize: ResponsiveSize.getFontSize(18),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dtBlueDark,
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
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await Future.wait([
                              _loadOffers(forceRefresh: true),
                              context.read<BalanceProvider>().refreshBalance(),
                            ]);
                          },
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlueDark),
                                  ),
                                )
                              : _errorMessage != null
                                  ? Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
                                            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                                            Text(
                                              l10n.genericRetryError,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: ResponsiveSize.getFontSize(14), color: Colors.grey[600]),
                                            ),
                                            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                                            ElevatedButton.icon(
                                              onPressed: () => _loadOffers(forceRefresh: true),
                                              icon: const Icon(Icons.refresh),
                                              label: Text(l10n.retry),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.dtBlueDark,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _selectedType == 'tempo' && forfaitsTempo.isEmpty
                                      ? _buildEmptyTempoState()
                                      : Padding(
                                      padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(AppTheme.spacingM)),
                                      child: ListView.separated(
                                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                        itemCount: forfaitsToDisplay.length,
                                        separatorBuilder: (context, index) => SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                                        itemBuilder: (context, index) {
                                          final forfait = forfaitsToDisplay[index];
                                          return ForfaitCard(
                                            forfait: forfait,
                                            soldeActuel: balanceProvider.solde,
                                            phoneNumber: widget.phoneNumber,
                                            purchaseMode: widget.purchaseMode,
                                            onAchatReussi: () {
                                              context.read<BalanceProvider>().refreshBalance();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              Icons.weekend_rounded,
              size: ResponsiveSize.getFontSize(80),
              color: AppTheme.dtBlueDark.withOpacityValue(0.6),
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

class PositionNotifier extends StatelessWidget {
  final Widget child;
  const PositionNotifier({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -100,
      right: -100,
      width: 400,
      height: 400,
      child: child,
    );
  }
}
