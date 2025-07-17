// lib/screens/forfait_recipient_screen.dart
import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/routes/custom_route_transitions.dart';
import 'package:dtapp3/screens/achat_forfait/forfait_categories_screen.dart'; 
import 'package:dtapp3/utils/responsive_size.dart';
import 'package:dtapp3/widgets/appbar_widget.dart';
import 'package:dtapp3/widgets/phone_number_selector.dart';
import 'package:dtapp3/enums/purchase_enums.dart';
import 'package:flutter/material.dart';

class ForfaitRecipientScreen extends StatefulWidget {
  final String? phoneNumber;
  final double soldeActuel;
  final VoidCallback? onRefreshSolde;

  const ForfaitRecipientScreen({
    super.key,
    this.phoneNumber,
    required this.soldeActuel,
    this.onRefreshSolde,
  });

  @override
  State<ForfaitRecipientScreen> createState() => _ForfaitRecipientScreenState();
}

class _ForfaitRecipientScreenState extends State<ForfaitRecipientScreen>
    with SingleTickerProviderStateMixin {
  bool _showPhoneInput = false;
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showPhoneInputSection() {
    setState(() {
      _showPhoneInput = true;
    });
    _animationController.forward();
  }

  void _hidePhoneInputSection() {
    _animationController.reverse().then((_) {
      setState(() {
        _showPhoneInput = false;
      });
    });
    _phoneController.clear();
  }

  void _validateAndContinue() {
    if (_formKey.currentState!.validate()) {
      // Nettoyer le numéro (enlever les espaces)
      final cleanPhoneNumber = DjiboutiPhoneValidator.cleanPhoneNumber(
        _phoneController.text.trim()
      );
      
      // Navigation vers l'écran de catégories pour autre numéro
      Navigator.push(
        context,
        CustomRouteTransitions.slideRightRoute(
          page: ForfaitCategoriesScreen(
            phoneNumber: cleanPhoneNumber,
            soldeActuel: widget.soldeActuel,
            onRefreshSolde: widget.onRefreshSolde,
            purchaseMode: PurchaseMode.gift,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Achat de forfait', 
        showAction: false,
        showCancelToHome: true, // Affiche le bouton Annuler
      ),
      body: Column(
        children: [
          // Contenu principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre principal
                  Text(
                    'Choisir le destinataire',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(24)),

                  // Options de destinataire
                  Row(
                    children: [
                      Expanded(
                        child: _buildOptionCard(
                          context,
                          'Mon numéro',
                          AppTheme.dtBlue2,
                          Icons.arrow_upward,
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomRouteTransitions.slideRightRoute(
                                page: ForfaitCategoriesScreen(
                                  phoneNumber: widget.phoneNumber,
                                  soldeActuel: widget.soldeActuel,
                                  onRefreshSolde: widget.onRefreshSolde,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.getWidth(16)),
                      Expanded(
                        child: _buildOptionCard(
                          context,
                          'Autre numéro',
                          AppTheme.dtBlue2,
                          Icons.arrow_outward,
                          onTap: _showPhoneInputSection,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Section de saisie du numéro en bas (animée)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showPhoneInput ? null : 0,
            child: _showPhoneInput
                ? AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1.0),
                          end: Offset.zero,
                        ).animate(_slideAnimation),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(ResponsiveSize.getWidth(20)),
                          topRight: Radius.circular(ResponsiveSize.getWidth(20)),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Padding(
                          padding: EdgeInsets.all(ResponsiveSize.getWidth(24)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar pour indiquer que c'est draggable
                              Center(
                                child: Container(
                                  width: ResponsiveSize.getWidth(40),
                                  height: ResponsiveSize.getHeight(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveSize.getWidth(2),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: ResponsiveSize.getHeight(16)),

                              // Titre avec bouton fermer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Saisir le numéro',
                                    style: TextStyle(
                                      fontSize: ResponsiveSize.getFontSize(18),
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.dtBlue,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _hidePhoneInputSection,
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.grey[600],
                                      size: ResponsiveSize.getFontSize(24),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: ResponsiveSize.getHeight(8)),

                              // Widget sélecteur de numéro
                              PhoneNumberSelector(
                                controller: _phoneController,
                                labelText: 'Entrez le numéro de téléphone',
                                hintText: '77 XX XX XX',
                                validator: DjiboutiPhoneValidator.validatePhoneNumber,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),

                              SizedBox(height: ResponsiveSize.getHeight(12)),

                              // Note d'information
                              Container(
                                padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
                                decoration: BoxDecoration(
                                  color: AppTheme.dtBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveSize.getWidth(8),
                                  ),
                                  border: Border.all(
                                    color: AppTheme.dtBlue.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: AppTheme.dtBlue,
                                      size: ResponsiveSize.getFontSize(16),
                                    ),
                                    SizedBox(width: ResponsiveSize.getWidth(8)),
                                    Expanded(
                                      child: Text(
                                        'Numéro mobile valide à Djibouti requis',
                                        style: TextStyle(
                                          fontSize: ResponsiveSize.getFontSize(12),
                                          color: AppTheme.dtBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: ResponsiveSize.getHeight(24)),

                              // Bouton de continuation
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _phoneController.text.isNotEmpty
                                      ? _validateAndContinue
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.dtBlue2,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[300],
                                    disabledForegroundColor: Colors.grey[600],
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveSize.getHeight(16),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        ResponsiveSize.getWidth(12),
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continuer',
                                        style: TextStyle(
                                          fontSize: ResponsiveSize.getFontSize(16),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveSize.getWidth(8)),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: ResponsiveSize.getFontSize(18),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Espace pour le safe area
                              SizedBox(
                                height: MediaQuery.of(context).padding.bottom + 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    Color iconColor,
    IconData cardIcon, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(20)),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dtYellow),
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: ResponsiveSize.getWidth(60),
                  height: ResponsiveSize.getHeight(60),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: AppTheme.dtYellow),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(10),
                    ),
                  ),
                  child: Icon(
                    Icons.smartphone,
                    size: ResponsiveSize.getFontSize(30),
                    color: AppTheme.dtBlue2,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveSize.getWidth(4)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.dtBlue2,
                    ),
                    child: Icon(
                      cardIcon,
                      color: AppTheme.dtYellow,
                      size: ResponsiveSize.getFontSize(18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              'Acheter pour',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(4)),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}