// lib/widgets/swipeable_account_cards.dart
import 'package:dtapp3/extensions/color_extensions.dart';
import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart'; 

class AccountCardData {
  final IconData icon;
  final String label;
  final String balance;
  final String suffix;
  final Color cardColor;
  final Color? accentColor;

  AccountCardData({
    required this.icon,
    required this.label,
    required this.balance,
    required this.suffix,
    this.cardColor = const Color(0xFF002464),
    this.accentColor,
  });
}

class SwipeableAccountCards extends StatefulWidget {
  final List<AccountCardData> cards;
  final bool isLoading;
  final bool showBalance;
  final Function() onToggleVisibility;
  
  const SwipeableAccountCards({
    super.key,
    required this.cards,
    this.isLoading = false,
    required this.showBalance,
    required this.onToggleVisibility,
  });

  @override
  State<SwipeableAccountCards> createState() => _SwipeableAccountCardsState();
}

class _SwipeableAccountCardsState extends State<SwipeableAccountCards> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentCardIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    
    // Animation pour la transition entre les cartes
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.01).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Column(
      children: [
        SizedBox(
          height: ResponsiveSize.getHeight(195), // Hauteur fixe pour les cartes
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            onPageChanged: (index) {
              setState(() {
                _currentCardIndex = index;
              });
              // Jouer l'animation à chaque changement de page
              _animationController.reset();
              _animationController.forward();
            },
            itemBuilder: (context, index) {
              final card = widget.cards[index];
              // On utilise une animation différente selon qu'il s'agit de la carte actuelle ou non
              final isCurrentCard = index == _currentCardIndex;
              
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isCurrentCard ? _scaleAnimation.value : 0.9,
                    child: Transform.rotate(
                      angle: isCurrentCard ? _rotateAnimation.value : 0,
                      child: _buildAccountCard(card),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
        // Indicateurs de page
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.cards.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.getWidth(AppTheme.spacingXS),
              ),
              height: ResponsiveSize.getHeight(8),
              width: _currentCardIndex == index 
                  ? ResponsiveSize.getWidth(24) 
                  : ResponsiveSize.getWidth(8),
              decoration: BoxDecoration(
                color: _currentCardIndex == index 
                    ? AppTheme.dtYellow 
                    : Colors.grey.withOpacityValue(0.3),
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAccountCard(AccountCardData card) {
    return GestureDetector(
      onTap: () {
        // Animation simple au tap
        _animationController.reset();
        _animationController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
          vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
        ),
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        decoration: BoxDecoration(
          color: card.cardColor,
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
          boxShadow: [
            BoxShadow(
              color: card.cardColor.withOpacityValue(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  card.icon,
                  color: Colors.white,
                  size: ResponsiveSize.getFontSize(24),
                ),
                GestureDetector(
                  onTap: widget.isLoading ? null : widget.onToggleVisibility,
                  child: widget.isLoading
                      ? SizedBox(
                          width: ResponsiveSize.getWidth(20),
                          height: ResponsiveSize.getHeight(20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              card.accentColor ?? AppTheme.dtYellow,
                            ),
                          ),
                        )
                      : Icon(
                          widget.showBalance ? Icons.visibility : Icons.visibility_off,
                          color: card.accentColor ?? AppTheme.dtYellow,
                          size: ResponsiveSize.getFontSize(22),
                        ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.showBalance ? card.balance : '******',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveSize.getFontSize(28),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.showBalance && card.suffix.isNotEmpty) ...[
                      SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                      Text(
                        card.suffix,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveSize.getFontSize(16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Text(
              card.label,
              style: TextStyle(
                color: Colors.white.withOpacityValue(0.7),
                fontSize: ResponsiveSize.getFontSize(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}