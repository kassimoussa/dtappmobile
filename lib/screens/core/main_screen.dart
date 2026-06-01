// lib/screens/core/main_screen.dart
import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../widgets/promo_popup_dialog.dart';
import 'home_screen.dart';
import '../topup/home/topup_home_screen.dart';
import '../user/history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconScaleAnimation = _animationController
        .drive(Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)))
        .drive(Tween<double>(begin: 1.0, end: 1.2));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PromoPopupDialog.showIfAvailable(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentNavIndex = index),
        children: const [
          HomeScreen(),
          HistoryScreen(),
          TopUpHomeScreen(),
        ],
      ),
      bottomNavigationBar: _buildAnimatedBottomNavigationBar(),
    );
  }

  Widget _buildAnimatedBottomNavigationBar() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentNavIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.dtBlue,
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveSize.getFontSize(12),
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: ResponsiveSize.getFontSize(11),
            ),
            items: [
              BottomNavigationBarItem(
                icon: _buildAnimatedIcon(Icons.home, 0),
                label: AppLocalizations.of(context)!.navHome,
              ),
              BottomNavigationBarItem(
                icon: _buildAnimatedIcon(Icons.history, 1),
                label: AppLocalizations.of(context)!.navHistory,
              ),
              BottomNavigationBarItem(
                icon: _buildAnimatedIcon(Icons.phone, 2),
                label: AppLocalizations.of(context)!.navMyLine,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon(IconData icon, int index) {
    final isSelected = _currentNavIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(ResponsiveSize.getWidth(isSelected ? 8 : 4)),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.dtBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: ScaleTransition(
        scale: isSelected ? _iconScaleAnimation : const AlwaysStoppedAnimation(1.0),
        child: Icon(
          icon,
          size: ResponsiveSize.getFontSize(isSelected ? 26 : 24),
          color: isSelected ? AppTheme.dtBlue : Colors.grey[600],
        ),
      ),
    );
  }
}

// ─── Cloche avec badge ────────────────────────────────────────────────────────

class _BadgeBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _BadgeBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: AppTheme.dtBlue,
                size: 22,
              ),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
