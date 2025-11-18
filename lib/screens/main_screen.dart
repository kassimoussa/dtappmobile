// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../providers/user_session_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/forfait_provider.dart';
import '../providers/profile_provider.dart';
import 'home_screen.dart';
import 'topup/home/topup_home_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // ✅ INITIALISER LES PROVIDERS AU DÉMARRAGE
    _initializeProviders();
  }

  /// Initialise tous les providers au démarrage de MainScreen
  /// Précharge les données pour une meilleure expérience utilisateur
  void _initializeProviders() {
    Future.microtask(() {
      // Initialiser la session
      final sessionProvider = Provider.of<UserSessionProvider>(context, listen: false);
      sessionProvider.initSession();

      // Si l'utilisateur est authentifié, précharger les données
      if (sessionProvider.isAuthenticated) {
        final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
        final forfaitProvider = Provider.of<ForfaitProvider>(context, listen: false);
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

        // Précharger en parallèle pour une meilleure performance
        Future.wait([
          balanceProvider.fetchBalance(),
          forfaitProvider.fetchForfaits(),
          profileProvider.fetchProfile(),
        ]);

        debugPrint('✅ Providers initialisés et données préchargées');
      }
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

    setState(() {
      _currentNavIndex = index;
    });

    // Animation fluide vers la page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Animation de l'indicateur
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
        onPageChanged: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        children: [
          // Écran 0: Accueil
          const HomeScreen(),
          
          // Écran 1: Historique
          const HistoryScreen(),
          
          // Écran 2: TopUp
          const TopUpHomeScreen(),
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
                color: Colors.black.withOpacity(0.1),
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
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: _buildAnimatedIcon(Icons.history, 1),
                label: 'Historique',
              ),
              BottomNavigationBarItem(
                icon: _buildAnimatedIcon(Icons.phone, 2),
                label: 'Ma ligne',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon(IconData icon, int index) {
    final isSelected = _currentNavIndex == index;
    final animation = _animationController.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: Curves.elasticOut),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(ResponsiveSize.getWidth(isSelected ? 8 : 4)),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.dtBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
      ),
      child: ScaleTransition(
        scale: isSelected 
            ? animation.drive(Tween<double>(begin: 1.0, end: 1.2))
            : const AlwaysStoppedAnimation(1.0),
        child: Icon(
          icon,
          size: ResponsiveSize.getFontSize(isSelected ? 26 : 24),
          color: isSelected ? AppTheme.dtBlue : Colors.grey[600],
        ),
      ),
    );
  }
}