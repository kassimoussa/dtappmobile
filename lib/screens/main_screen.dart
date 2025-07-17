// lib/screens/main_screen.dart
import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import 'home_screen.dart';
import 'topup/topup_home_screen.dart';
import 'my_line_screen.dart';

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

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bientôt disponible'),
          content: Text('$feature sera bientôt disponible dans l\'application.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
          
          // Écran 1: Historique (placeholder)
          _buildPlaceholderScreen(
            title: 'Historique',
            icon: Icons.history,
            description: 'Consultez l\'historique de vos transactions',
            onTap: () => _showComingSoonDialog('Historique des transactions'),
          ),
          
          // Écran 2: TopUp
          const TopUpHomeScreen(),
          
          // Écran 3: Ma ligne (placeholder pour maintenir la navigation)
          _buildPlaceholderScreen(
            title: 'Ma ligne',
            icon: Icons.phone,
            description: 'Gérez votre ligne fixe',
            onTap: () {
              // Navigation vers MyLineScreen comme avant
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyLineScreen(phoneNumber: '77001011'),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildAnimatedBottomNavigationBar(),
    );
  }

  Widget _buildPlaceholderScreen({
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingXL)),
                decoration: BoxDecoration(
                  color: AppTheme.dtBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: ResponsiveSize.getFontSize(64),
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dtBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(AppTheme.spacingL),
                    vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
                  ),
                ),
                child: Text(
                  'Accéder à $title',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                label: 'TopUp',
              ),
              BottomNavigationBarItem(
                icon: _buildAnimatedIcon(Icons.settings_phone, 3),
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