// lib/screens/core/home_screen.dart
import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/agencies/agencies_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/auth/login_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/speedtest/speedtest_native_screen.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:provider/provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/topup_provider.dart';
import '../user/profile_screen.dart';
import 'search_screen.dart';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../routes/custom_route_transitions.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/banner_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMainBalance = false;
  bool _showBonusBalance = false;
  String _normalPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await _loadPhoneNumber();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BalanceProvider>().loadBalance();
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

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final balanceProvider = context.watch<BalanceProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header fusionné : appbar + hero card
            _buildHeroCard(balanceProvider, l10n),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.getWidth(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ResponsiveSize.getHeight(24)),

                  // Titre section actions
                  Text(
                    l10n.quickActions,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dtBlue,
                    ),
                  ),

                  //SizedBox(height: ResponsiveSize.getHeight(8)),

                  // Actions rapides
                  _buildQuickActions(l10n),

                  SizedBox(height: ResponsiveSize.getHeight(24)),

                  // Bannières
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const BannerSlider(),
                  ),

                  SizedBox(height: ResponsiveSize.getHeight(24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BalanceProvider balanceProvider, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.dtBlue, AppTheme.dtBlue2],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        ResponsiveSize.getWidth(16),
        MediaQuery.of(context).padding.top + ResponsiveSize.getHeight(12),
        ResponsiveSize.getWidth(8),
        ResponsiveSize.getHeight(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de navigation (logo + icônes)
          Row(
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
                  height: ResponsiveSize.getHeight(28),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.search_rounded, color: Colors.white,
                    size: ResponsiveSize.getFontSize(22)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              IconButton(
                icon: Icon(Icons.person_outline_rounded, color: Colors.white,
                    size: ResponsiveSize.getFontSize(22)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              IconButton(
                icon: Icon(Icons.logout_rounded, color: Colors.white,
                    size: ResponsiveSize.getFontSize(22)),
                onPressed: () => _showLogoutDialog(l10n),
              ),
            ],
          ),

          SizedBox(height: ResponsiveSize.getHeight(16)),

          // Salutation
          Padding(
            padding: EdgeInsets.only(left: ResponsiveSize.getWidth(4)),
            child: Text(
              l10n.welcomeMessage(_normalPhoneNumber),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: ResponsiveSize.getFontSize(14),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          SizedBox(height: ResponsiveSize.getHeight(20)),

          // Deux cartes de solde côte à côte
          Padding(
            padding: EdgeInsets.only(right: ResponsiveSize.getWidth(8)),
            child: Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: l10n.mainAccount,
                    balance: '${balanceProvider.solde.toStringAsFixed(0)} DJF',
                    showBalance: _showMainBalance,
                    isLoading: balanceProvider.isLoading,
                    onToggle: () => setState(() => _showMainBalance = !_showMainBalance),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(12)),
                Expanded(
                  child: _buildBalanceCard(
                    icon: Icons.card_giftcard_outlined,
                    label: l10n.bonusBalance,
                    balance: '${balanceProvider.bonus.toStringAsFixed(2)} DJF',
                    showBalance: _showBonusBalance,
                    isLoading: balanceProvider.isLoading,
                    onToggle: () => setState(() => _showBonusBalance = !_showBonusBalance),
                  ),
                ),
              ],
            ),
          ),

          // Expiration
          if (!balanceProvider.isLoading) ...[
            SizedBox(height: ResponsiveSize.getHeight(12)),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: Colors.white.withValues(alpha: 0.6)),
                SizedBox(width: ResponsiveSize.getWidth(4)),
                Text(
                  l10n.expiresOn(balanceProvider.dateExpiration),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: ResponsiveSize.getFontSize(11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required String label,
    required String balance,
    required bool showBalance,
    required bool isLoading,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(6)),
                decoration: BoxDecoration(
                  color: AppTheme.dtYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.dtYellow,
                    size: ResponsiveSize.getFontSize(16)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isLoading ? null : onToggle,
                child: isLoading
                    ? SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
                        ),
                      )
                    : Icon(
                        showBalance ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: ResponsiveSize.getFontSize(16),
                      ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(12)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: ResponsiveSize.getFontSize(12),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(6)),
          Text(
            showBalance ? balance : '••••••',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveSize.getFontSize(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    final actions = [
      {
        'icon': Icons.local_mall_rounded,
        'label': l10n.buyPackage,
        'color': const Color(0xFF3B5BDB),
        'bg': const Color(0xFFEEF2FF),
        'onTap': () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(
              page: ForfaitRecipientScreen(phoneNumber: _normalPhoneNumber))),
      },
      {
        'icon': Icons.add_circle_rounded,
        'label': l10n.creditRefill,
        'color': const Color(0xFF0CA678),
        'bg': const Color(0xFFE6FCF5),
        'onTap': () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(
              page: RefillRecipientScreen(phoneNumber: _normalPhoneNumber))),
      },
      {
        'icon': Icons.inventory_2_rounded,
        'label': l10n.myPackages,
        'color': const Color(0xFFF76707),
        'bg': const Color(0xFFFFF4E6),
        'onTap': () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(
              page: ForfaitsActifsScreen())),
      },
      {
        'icon': Icons.send_rounded,
        'label': l10n.creditTransfer,
        'color': const Color(0xFFAE3EC9),
        'bg': const Color(0xFFF8F0FC),
        'onTap': () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(
              page: TransferInputScreen(phoneNumber: _normalPhoneNumber))),
      },
      {
        'icon': Icons.location_on_rounded,
        'label': l10n.ourAgencies,
        'color': const Color(0xFFE03131),
        'bg': const Color(0xFFFFF5F5),
        'onTap': () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(
              page: const AgenciesScreen())),
      },
      {
        'icon': Icons.speed_rounded,
        'label': l10n.speedTest,
        'color': const Color(0xFF1971C2),
        'bg': const Color(0xFFE7F5FF),
        'onTap': () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(
              page: const SpeedtestNativeScreen())),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: ResponsiveSize.getWidth(10),
        mainAxisSpacing: ResponsiveSize.getHeight(10),
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionButton(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          bg: action['bg'] as Color,
          onTap: action['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSize.getHeight(12),
            horizontal: ResponsiveSize.getWidth(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(10)),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: ResponsiveSize.getFontSize(20)),
              ),
              SizedBox(height: ResponsiveSize.getHeight(6)),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(10),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.logout),
          content: Text(l10n.logoutConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performLogout(l10n);
              },
              child: Text(l10n.logoutAction,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(AppLocalizations l10n) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final balanceProvider = context.read<BalanceProvider>();
      final topUpProvider = context.read<TopUpProvider>();

      final success = await authProvider.logout();

      if (success) {
        balanceProvider.reset();
        topUpProvider.reset();
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted && success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.logoutError}: $e')),
        );
      }
    }
  }
}
