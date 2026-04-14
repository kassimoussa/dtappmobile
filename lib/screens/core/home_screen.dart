// lib/screens/core/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/agencies/agencies_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/auth/login_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/speedtest/speedtest_native_screen.dart';
import 'package:dtservices/services/user_session.dart';

import '../../providers/balance_provider.dart';
import '../../services/offers_service.dart';
import '../user/profile_screen.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../routes/custom_route_transitions.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/banner_slider.dart';
import '../../services/banner_service.dart';
import '../../providers/topup_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMainBalance = false;
  bool _showBonusBalance = false;
  String _normalPhoneNumber = '';
  final PageController _balancePageController = PageController(viewportFraction: 0.92);
  int _currentBalancePage = 0;
  Key _bannerSliderKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _balancePageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await _loadPhoneNumber();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BalanceProvider>().loadBalance();
        OffersService.prefetch();
      });
    }
  }

  Future<void> _loadPhoneNumber() async {
    try {
      final phoneNumber = await UserSession.getPhoneNumber();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          CustomRouteTransitions.fadeScaleRoute(page: const LoginScreen()),
          (route) => false,
        );
        return;
      }
      if (mounted) setState(() => _normalPhoneNumber = phoneNumber);
    } catch (e) {
      debugPrint('Erreur lors du chargement du numéro: $e');
    }
  }

  Future<void> _handleRefresh() async {
    // Invalider le cache pour forcer le rechargement des bannières
    BannerService.clearCache();

    // Lancer les rafraîchissements en parallèle
    final futures = <Future>[
      context.read<BalanceProvider>().refreshBalance(),
    ];

    // Rafraîchir TopUp si une session est active
    final topUpProvider = context.read<TopUpProvider>();
    if (topUpProvider.hasActiveSession) {
      futures.add(topUpProvider.refreshBalances());
    }

    await Future.wait(futures);

    // Mettre à jour la clé pour forcer le BannerSlider à se reconstruire
    if (mounted) {
      setState(() {
        _bannerSliderKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final balanceProvider = context.watch<BalanceProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.dtBlue,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header with Swipable Cards
            _buildHeroCard(balanceProvider, l10n),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.getWidth(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ResponsiveSize.getHeight(10)),

                  // Titre section actions
                  Text(
                    l10n.quickActions,
                    style: AppTheme.subheadingStyle,
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(16)),

                  // Actions rapides
                  _buildQuickActions(l10n),

                  SizedBox(height: ResponsiveSize.getHeight(32)),

                  // Bannières
                  Container(
                    decoration: AppTheme.cardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BannerSlider(key: _bannerSliderKey),
                    ),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(32)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeroCard(BalanceProvider balanceProvider, AppLocalizations l10n) {
    return Stack(
      children: [
        // Background Gradient that spans top half organically
        Container(
          height: ResponsiveSize.getHeight(230),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.dtBlueDark, AppTheme.dtBlueDark],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveSize.getHeight(12)),
              _buildGlassAppBar(l10n),
              SizedBox(height: ResponsiveSize.getHeight(24)),
              
              // Swipeable Cards
              _buildSwipeableBalances(balanceProvider, l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassAppBar(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveSize.getWidth(16),
              vertical: ResponsiveSize.getHeight(12),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(8),
                    vertical: ResponsiveSize.getHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/djibtelogo.png',
                    height: ResponsiveSize.getHeight(24),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(8)),
                  child: Text(
                    l10n.welcomeMessage(_normalPhoneNumber),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: ResponsiveSize.getFontSize(14),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                SizedBox(width: ResponsiveSize.getWidth(8)),
                GestureDetector(
                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                   child: Container(
                     padding: EdgeInsets.all(ResponsiveSize.getWidth(8)),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white.withOpacity(0.2)
                     ),
                     child: Icon(Icons.person_rounded, color: Colors.white, size: ResponsiveSize.getFontSize(20))
                   )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableBalances(BalanceProvider balanceProvider, AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          height: ResponsiveSize.getHeight(140),
          child: PageView(
            controller: _balancePageController,
            onPageChanged: (int page) {
              setState(() {
                _currentBalancePage = page;
              });
            },
            children: [
              _buildCreditCard(
                title: l10n.mainAccount,
                amount: '${balanceProvider.solde.toStringAsFixed(0)} DJF',
                icon: Icons.account_balance_wallet_rounded,
                colorStart: Colors.white,
                colorEnd: Colors.white,
                textDark: true,
                isLoading: balanceProvider.isLoading,
                dateExp: balanceProvider.dateExpiration,
                l10n: l10n,
                isVisible: _showMainBalance,
                onToggleVisibility: () => setState(() => _showMainBalance = !_showMainBalance),
              ),
              _buildCreditCard(
                title: l10n.bonusBalance,
                amount: '${balanceProvider.bonus.toStringAsFixed(2)} DJF',
                icon: Icons.card_giftcard_rounded,
                colorStart: Colors.white,
                colorEnd: Colors.white,
                textDark: true,
                isLoading: balanceProvider.isLoading,
                dateExp: null,
                l10n: l10n,
                isVisible: _showBonusBalance,
                onToggleVisibility: () => setState(() => _showBonusBalance = !_showBonusBalance),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(16)),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(4)),
              height: ResponsiveSize.getHeight(6),
              width: _currentBalancePage == index ? ResponsiveSize.getWidth(24) : ResponsiveSize.getWidth(8),
              decoration: BoxDecoration(
                color: _currentBalancePage == index ? AppTheme.dtYellow : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCreditCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color colorStart,
    required Color colorEnd,
    required bool isLoading,
    required String? dateExp,
    required AppLocalizations l10n,
    bool textDark = false,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    final textColor = textDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(8)),
      padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorStart, colorEnd],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          // Decorative background icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon, size: ResponsiveSize.getHeight(90), color: textColor.withOpacity(0.1)),
          ),
          Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: textColor.withOpacity(0.9),
                            fontSize: ResponsiveSize.getFontSize(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: onToggleVisibility,
                          child: Container(
                            padding: EdgeInsets.all(ResponsiveSize.getWidth(6)),
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: textColor,
                              size: ResponsiveSize.getFontSize(18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isLoading)
                            SizedBox(
                              height: ResponsiveSize.getHeight(24),
                              width: ResponsiveSize.getHeight(24),
                              child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
                            )
                          else
                            Text(
                              isVisible ? amount : '••••••••',
                              style: GoogleFonts.outfit(
                                color: textColor,
                                fontSize: ResponsiveSize.getFontSize(28),
                                fontWeight: FontWeight.bold,
                                letterSpacing: isVisible ? 0 : 4.0,
                              ),
                            ),
                          if (dateExp != null && dateExp.isNotEmpty && !isLoading) ...[
                            SizedBox(height: ResponsiveSize.getHeight(6)),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 14, color: textColor.withOpacity(0.7)),
                                SizedBox(width: ResponsiveSize.getWidth(6)),
                                Text(
                                  l10n.expiresOn(dateExp),
                                  style: GoogleFonts.inter(
                                    color: textColor.withOpacity(0.8),
                                    fontSize: ResponsiveSize.getFontSize(12),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildUnifiedAction(
                icon: Icons.local_mall_rounded,
                label: l10n.buyPackage,
                onTap: () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(page: ForfaitRecipientScreen(phoneNumber: _normalPhoneNumber))),
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(12)),
            Expanded(
              child: _buildUnifiedAction(
                icon: Icons.add_circle_rounded,
                label: l10n.creditRefill,
                onTap: () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(page: RefillRecipientScreen(phoneNumber: _normalPhoneNumber))),
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(12)),
            Expanded(
              child: _buildUnifiedAction(
                icon: Icons.inventory_2_rounded,
                label: l10n.myPackages,
                onTap: () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(page: ForfaitsActifsScreen())),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.getHeight(20)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildUnifiedAction(
                icon: Icons.send_rounded,
                label: l10n.creditTransfer,
                onTap: () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(page: TransferInputScreen(phoneNumber: _normalPhoneNumber))),
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(12)),
            Expanded(
              child: _buildUnifiedAction(
                icon: Icons.location_on_rounded,
                label: l10n.ourAgencies,
                onTap: () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(page: const AgenciesScreen())),
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(12)),
            Expanded(
              child: _buildUnifiedAction(
                icon: Icons.speed_rounded,
                label: l10n.speedTest,
                onTap: () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(page: const SpeedtestNativeScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnifiedAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
            decoration: AppTheme.cardDecoration.copyWith(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon, 
              color: AppTheme.dtBlueDark, 
              size: ResponsiveSize.getFontSize(24),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(6)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.inter(
              fontSize: ResponsiveSize.getFontSize(12),
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

}
