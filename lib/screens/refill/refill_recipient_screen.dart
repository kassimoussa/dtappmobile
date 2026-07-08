import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/routes/custom_route_transitions.dart';
import 'package:dtservices/screens/refill/refill_code_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/phone_number_selector.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';

class RefillRecipientScreen extends StatefulWidget {
  final String? phoneNumber;
  final VoidCallback? onRefreshSolde;

  const RefillRecipientScreen({
    super.key,
    this.phoneNumber,
    this.onRefreshSolde,
  });

  @override
  State<RefillRecipientScreen> createState() => _RefillRecipientScreenState();
}

class _RefillRecipientScreenState extends State<RefillRecipientScreen>
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

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
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
        _phoneController.text.trim(),
      );

      // Navigation vers l'écran de recharge pour autre numéro
      Navigator.push(
        context,
        CustomRouteTransitions.slideRightRoute(
          page: RefillCodeScreen(
            phoneNumber: cleanPhoneNumber,
            onRefreshSolde: widget.onRefreshSolde,
            isGift: true,
          ),
        ),
      );

    }
  }

  void _navigateToMyNumber() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: RefillCodeScreen(
          phoneNumber: widget.phoneNumber!,
          onRefreshSolde: widget.onRefreshSolde,
          isGift: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
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
                GlassAppBar(title: AppLocalizations.of(context)!.refillTitle),
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            kToolbarHeight,
                      ),
                      child: Column(
                        children: [
                          // Contenu principal
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre principal
                                Text(
                                  AppLocalizations.of(context)!.recipientSelectionTitle,
                                  style: TextStyle(
                                    fontSize: ResponsiveSize.getFontSize(20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: ResponsiveSize.getHeight(24)),
            
                                // Options de destinataire
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: _buildOptionCard(
                                          context,
                                          AppLocalizations.of(context)!.myNumber,
                                          AppTheme.dtBlue2,
                                          Icons.arrow_upward,
                                          onTap: _navigateToMyNumber,
                                        ),
                                      ),
                                      SizedBox(width: ResponsiveSize.getWidth(16)),
                                      Expanded(
                                        child: _buildOptionCard(
                                          context,
                                          AppLocalizations.of(context)!.otherNumber,
                                          AppTheme.dtBlue2,
                                          Icons.arrow_outward,
                                          onTap: _showPhoneInputSection,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
            
                          // Section de saisie du numéro en bas (animée)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _showPhoneInput ? null : 0,
                            child:
                                _showPhoneInput
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
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(
                                              ResponsiveSize.getWidth(20),
                                            ),
                                            topRight: Radius.circular(
                                              ResponsiveSize.getWidth(20),
                                            ),
                                          ),
                                        ),
                                        child: Form(
                                          key: _formKey,
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              ResponsiveSize.getWidth(24),
                                            ),
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
                                                SizedBox(
                                                  height: ResponsiveSize.getHeight(16),
                                                ),
            
                                                // Titre avec bouton fermer
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.enterNumberTitle,
                                                      style: TextStyle(
                                                        fontSize:
                                                            ResponsiveSize.getFontSize(18),
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.dtBlue,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: _hidePhoneInputSection,
                                                      icon: Icon(
                                                        Icons.close,
                                                        color: Colors.grey[600],
                                                        size: ResponsiveSize.getFontSize(
                                                          24,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: ResponsiveSize.getHeight(8),
                                                ),
            
                                                // Widget sélecteur de numéro
                                                PhoneNumberSelector(
                                                  controller: _phoneController,
                                                  labelText:
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.enterNumberLabel,
                                                  hintText: '77 XX XX XX',
                                                  validator:
                                                      DjiboutiPhoneValidator
                                                          .validatePhoneNumber,
                                                  onChanged: (value) {
                                                    setState(() {});
                                                  },
                                                ),
            
                                                SizedBox(
                                                  height: ResponsiveSize.getHeight(12),
                                                ),
            
                                                // Note d'information
                                                Container(
                                                  padding: EdgeInsets.all(
                                                    ResponsiveSize.getWidth(12),
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.dtBlueO10,
                                                    borderRadius: BorderRadius.circular(
                                                      ResponsiveSize.getWidth(8),
                                                    ),
                                                    border: Border.all(
                                                      color: AppTheme.dtBlue.withValues(
                                                        alpha: 0.3,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.info_outline,
                                                        color: AppTheme.dtBlue,
                                                        size: ResponsiveSize.getFontSize(
                                                          16,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: ResponsiveSize.getWidth(8),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.djiboutiNumberRequired,
                                                          style: TextStyle(
                                                            fontSize:
                                                                ResponsiveSize.getFontSize(
                                                                  12,
                                                                ),
                                                            color: AppTheme.dtBlue,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
            
                                                SizedBox(
                                                  height: ResponsiveSize.getHeight(24),
                                                ),
            
                                                // Bouton de continuation
                                                DtButton.primary(
                                                  label: AppLocalizations.of(context)!.continueAction,
                                                  icon: Icons.arrow_forward,
                                                  onPressed: _phoneController.text.isNotEmpty ? _validateAndContinue : null,
                                                ),
            
                                                // Espace pour le safe area
                                                SizedBox(
                                                  height:
                                                      MediaQuery.of(
                                                        context,
                                                      ).padding.bottom +
                                                      8,
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
                    ),
                  ),
                ),
              ],
            ),
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
                    decoration: const BoxDecoration(
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
              AppLocalizations.of(context)!.buyFor,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(4)),
            Text(
              title,
              textAlign: TextAlign.center,
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
