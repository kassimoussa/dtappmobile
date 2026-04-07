// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/custom_route_transitions.dart';
import 'connection_method_screen.dart';
import '../../generated/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _savedPhoneNumber;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _checkSavedPhoneNumber();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  Future<void> _checkSavedPhoneNumber() async {
    try {
      final phoneNumber = await UserService.getPhoneNumber();
      if (phoneNumber != null && phoneNumber.isNotEmpty && mounted) {
        setState(() {
          _savedPhoneNumber = phoneNumber;
          _phoneController.text = phoneNumber;
        });
      }
    } catch (e) {
      debugPrint('Erreur récupération numéro sauvegardé: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = _phoneController.text;
    await UserService.savePhoneNumber(phoneNumber);

    if (!mounted) return;

    Navigator.of(context).push(
      CustomRouteTransitions.fadeScaleRoute(
        page: ConnectionMethodScreen(phoneNumber: phoneNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return Column(
            children: [
              // Zone bleue avec logo
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + ResponsiveSize.getHeight(32),
                    bottom: ResponsiveSize.getHeight(40),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.dtBlue, AppTheme.dtBlue2],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.dtBlue.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Logo dans container blanc
                      Container(
                        width: ResponsiveSize.getWidth(100),
                        height: ResponsiveSize.getWidth(100),
                        padding: EdgeInsets.all(ResponsiveSize.getWidth(14)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(22)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/djibtelogo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(14)),
                      Text(
                        'DTServices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveSize.getFontSize(20),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Formulaire
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildForm(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(28),
        vertical: ResponsiveSize.getHeight(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              l10n.welcome,
              style: TextStyle(
                color: AppTheme.dtBlue,
                fontSize: ResponsiveSize.getFontSize(26),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(4)),
            Text(
              l10n.loginPrompt,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: ResponsiveSize.getFontSize(14),
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(28)),

            // Numéro sauvegardé (chip discret)
            if (_savedPhoneNumber != null && _savedPhoneNumber!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.history, size: 14, color: Colors.grey[400]),
                  SizedBox(width: ResponsiveSize.getWidth(6)),
                  Text(
                    l10n.savedPhoneNumber,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: ResponsiveSize.getFontSize(12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveSize.getHeight(8)),
            ],

            // Champ téléphone
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(14)),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(18),
                  color: AppTheme.dtBlue,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  prefixIcon: SizedBox(
                    width: ResponsiveSize.getWidth(72),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSize.getWidth(10),
                          vertical: ResponsiveSize.getHeight(6),
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.dtBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
                        ),
                        child: Text(
                          '+253',
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(14),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dtBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  border: InputBorder.none,
                  hintText: '77 XX XX XX',
                  hintStyle: TextStyle(
                    color: Colors.grey[350],
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.normal,
                    letterSpacing: 1.0,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: ResponsiveSize.getHeight(18),
                    horizontal: ResponsiveSize.getWidth(8),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.phoneValidationError;
                  }
                  if (value.length != 8) {
                    return l10n.phoneLengthError;
                  }
                  if (!value.startsWith('77') &&
                      !value.startsWith('78') &&
                      !value.startsWith('70') &&
                      !value.startsWith('75') &&
                      !value.startsWith('76') &&
                      !value.startsWith('33')) {
                    return l10n.phoneStartError;
                  }
                  return null;
                },
              ),
            ),

            // Message d'erreur
            if (authProvider.errorMessage != null) ...[
              SizedBox(height: ResponsiveSize.getHeight(12)),
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 16),
                  SizedBox(width: ResponsiveSize.getWidth(6)),
                  Expanded(
                    child: Text(
                      authProvider.errorMessage!,
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: ResponsiveSize.getFontSize(13),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: ResponsiveSize.getHeight(32)),

            // Bouton Continuer
            SizedBox(
              width: double.infinity,
              height: ResponsiveSize.getHeight(56),
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(14)),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: authProvider.isLoading
                        ? null
                        : LinearGradient(
                            colors: [AppTheme.dtBlue, AppTheme.dtBlue2],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                    color: authProvider.isLoading ? Colors.grey[300] : null,
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(14)),
                    boxShadow: authProvider.isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: AppTheme.dtBlue.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: authProvider.isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
                            ),
                          )
                        : Text(
                            l10n.continueAction,
                            style: TextStyle(
                              color: AppTheme.dtYellow,
                              fontSize: ResponsiveSize.getFontSize(17),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(24)),

            // Footer branding
            Center(
              child: Text(
                '© Djibouti Telecom',
                style: TextStyle(
                  color: Colors.grey[350],
                  fontSize: ResponsiveSize.getFontSize(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
