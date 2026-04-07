// lib/screens/auth/connection_method_screen.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../routes/custom_route_transitions.dart';
import '../../services/user_session.dart';
import '../../extensions/color_extensions.dart';
import 'otp_screen.dart';
import 'pin/pin_login_screen.dart';
import 'pin/pin_reset_screen.dart';
import '../core/main_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/mobile_status_service.dart';

/// Écran intermédiaire de sélection de méthode de connexion
/// Affiche les options disponibles : PIN, OTP, Biométrie
class ConnectionMethodScreen extends StatefulWidget {
  final String phoneNumber;

  const ConnectionMethodScreen({super.key, required this.phoneNumber});

  @override
  State<ConnectionMethodScreen> createState() => _ConnectionMethodScreenState();
}

class _ConnectionMethodScreenState extends State<ConnectionMethodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Méthode de connexion disponible
  String _primaryMethod = 'otp'; // otp, pin, biometric
  bool _isBiometricSupported = false;
  bool _hasPin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Configuration des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadConnectionMethods();

    // Démarrer l'animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Charge les méthodes de connexion disponibles
  Future<void> _loadConnectionMethods() async {
    try {
      // 1. Vérifier le statut du numéro via l'API
      debugPrint('📞 Vérification du statut du numéro via API...');
      final statusData = await MobileStatusService.checkStatus(
        widget.phoneNumber,
      );

      if (!mounted) return;

      // Vérifier si le numéro est valide
      if (!MobileStatusService.isValidNumber(statusData)) {
        // Numéro non trouvé dans AIR
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(
          l10n.invalidNumber,
          statusData['message'] ?? l10n.numberNotFound,
        );
        setState(() => _isLoading = false);
        return;
      }

      // 2. Mettre à jour le cache local avec les données de l'API
      final hasPinFromApi = statusData['has_pin'] ?? false;
      await UserSession.setPinConfigured(hasPinFromApi);
      debugPrint('✅ PIN status from API: $hasPinFromApi');

      // 3. Vérifier les préférences locales
      final pinEnabled = await UserSession.isPinEnabled();

      // 4. Vérifier si la biométrie est disponible
      final localAuth = LocalAuthentication();
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      final biometricEnabled = await UserSession.isBiometricEnabled();

      if (!mounted) return;

      setState(() {
        _hasPin = hasPinFromApi && pinEnabled;
        _isBiometricSupported =
            canCheckBiometrics && isDeviceSupported && biometricEnabled;

        // Déterminer la méthode principale
        if (_isBiometricSupported && biometricEnabled && _hasPin) {
          _primaryMethod = 'biometric';
        } else if (_hasPin && pinEnabled) {
          _primaryMethod = 'pin';
        } else {
          _primaryMethod = 'otp';
        }

        _isLoading = false;
      });

      debugPrint('🔐 Méthode de connexion principale: $_primaryMethod');
    } catch (e) {
      debugPrint('❌ Erreur chargement méthodes connexion: $e');
      if (mounted) {
        setState(() {
          _primaryMethod = 'otp';
          _isLoading = false;
        });
      }
    }
  }

  /// Affiche un dialog d'erreur
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer le dialog
                  Navigator.of(context).pop(); // Retourner à l'écran précédent
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dtBlue,
                  foregroundColor: AppTheme.dtYellow,
                ),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
    );
  }

  /// Connexion avec la méthode principale
  Future<void> _connectWithPrimaryMethod() async {
    if (_primaryMethod == 'biometric') {
      await _connectWithBiometric();
    } else if (_primaryMethod == 'pin') {
      _navigateToPinLogin();
    } else {
      await _connectWithOtp();
    }
  }

  /// Connexion avec biométrie
  Future<void> _connectWithBiometric() async {
    try {
      final localAuth = LocalAuthentication();

      final didAuthenticate = await localAuth.authenticate(
        localizedReason: AppLocalizations.of(context)!.biometricAuthPrompt,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!mounted) return;

      if (didAuthenticate) {
        // Authentification biométrique réussie -> Connexion automatique avec PIN stocké
        await _autoLoginWithStoredPin();
      }
    } catch (e) {
      debugPrint('Erreur authentification biométrique: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.biometricAuthError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Connexion automatique avec le PIN stocké après validation biométrique
  Future<void> _autoLoginWithStoredPin() async {
    // Récupérer le PIN stocké de manière sécurisée
    final storedPin = await UserSession.getSecurePin(widget.phoneNumber);

    if (storedPin == null || storedPin.isEmpty) {
      // Pas de PIN stocké, rediriger vers l'écran PIN pour saisie manuelle
      debugPrint('⚠️ Aucun PIN stocké, redirection vers saisie manuelle');
      _navigateToPinLogin();
      return;
    }

    // Afficher un indicateur de chargement
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.dtYellow),
      ),
    );

    try {
      // Connexion avec le PIN stocké
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loginWithPin(widget.phoneNumber, storedPin);

      if (!mounted) return;

      // Fermer le dialog de chargement
      Navigator.of(context).pop();

      if (success) {
        // Connexion réussie -> Naviguer vers MainScreen
        debugPrint('✅ Connexion biométrique automatique réussie');
        Navigator.of(context).pushAndRemoveUntil(
          CustomRouteTransitions.slideRightRoute(page: const MainScreen()),
          (route) => false,
        );
      } else {
        // PIN invalide (peut-être changé côté serveur)
        // Supprimer le PIN stocké et rediriger vers saisie manuelle
        debugPrint('❌ PIN stocké invalide, suppression et redirection');
        await UserSession.deleteSecurePin(widget.phoneNumber);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pleaseReenterPin),
              backgroundColor: Colors.orange,
            ),
          );
        }

        _navigateToPinLogin();
      }
    } catch (e) {
      debugPrint('Erreur connexion automatique: $e');

      if (!mounted) return;

      // Fermer le dialog si encore visible
      Navigator.of(context).pop();

      // Fallback vers saisie manuelle
      _navigateToPinLogin();
    }
  }

  /// Connexion avec PIN
  void _navigateToPinLogin() {
    Navigator.of(context).push(
      CustomRouteTransitions.fadeScaleRoute(
        page: PinLoginScreen(phoneNumber: widget.phoneNumber),
      ),
    );
  }

  /// Connexion avec OTP
  Future<void> _connectWithOtp() async {
    final authProvider = context.read<AuthProvider>();

    // Envoyer l'OTP
    final success = await authProvider.sendOtp(widget.phoneNumber);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).push(
        CustomRouteTransitions.fadeScaleRoute(
          page: OTPScreen(phone: widget.phoneNumber),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                AppLocalizations.of(context)!.otpSendError,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Affiche le modal de sélection de méthode
  void _showMethodSelectionModal() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusL),
                ),
                topRight: Radius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusL),
                ),
              ),
            ),
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barre de glissement
                Container(
                  width: ResponsiveSize.getWidth(40),
                  height: ResponsiveSize.getHeight(4),
                  margin: EdgeInsets.only(
                    bottom: ResponsiveSize.getHeight(AppTheme.spacingL),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  l10n.chooseConnectionMethod,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

                // Biométrie
                if (_isBiometricSupported)
                  _buildMethodOption(
                    icon: Icons.fingerprint,
                    title: l10n.biometricLogin,
                    onTap: () {
                      Navigator.pop(context);
                      _connectWithBiometric();
                    },
                  ),

                // PIN
                if (_hasPin)
                  _buildMethodOption(
                    icon: Icons.pin,
                    title: l10n.pinLogin,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPinLogin();
                    },
                  ),

                // OTP
                _buildMethodOption(
                  icon: Icons.sms,
                  title: l10n.smsCodeOtp,
                  onTap: () {
                    Navigator.pop(context);
                    _connectWithOtp();
                  },
                ),

                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              ],
            ),
          ),
    );
  }

  /// Option de méthode dans le modal
  Widget _buildMethodOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        ResponsiveSize.getWidth(AppTheme.radiusM),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        margin: EdgeInsets.only(
          bottom: ResponsiveSize.getHeight(AppTheme.spacingS),
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusM),
          ),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
              decoration: BoxDecoration(
                color: AppTheme.dtBlue.withOpacityValue(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.dtBlue,
                size: ResponsiveSize.getFontSize(24),
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: ResponsiveSize.getFontSize(16),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir le texte du bouton principal
  String _getPrimaryButtonText() {
    switch (_primaryMethod) {
      case 'biometric':
        return AppLocalizations.of(context)!.loginWithFingerprint;
      case 'pin':
        return AppLocalizations.of(context)!.loginWithPin;
      default:
        return AppLocalizations.of(context)!.loginWithSms;
    }
  }

  /// Obtenir l'icône du bouton principal
  IconData _getPrimaryButtonIcon() {
    switch (_primaryMethod) {
      case 'biometric':
        return Icons.fingerprint;
      case 'pin':
        return Icons.pin;
      default:
        return Icons.sms;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.dtBlue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.dtBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                ResponsiveSize.getWidth(AppTheme.spacingL),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      ResponsiveSize.getWidth(AppTheme.spacingL) * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: ResponsiveSize.getHeight(20)),

                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/djibtelogo.png',
                          width: ResponsiveSize.getWidth(120),
                          height: ResponsiveSize.getHeight(120),
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingXL),
                      ),

                      // Salutation
                      Text(
                        l10n.hello,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(28),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingS),
                      ),

                      // Numéro de téléphone
                      Text(
                        widget.phoneNumber,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(18),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(
                          AppTheme.spacingXL * 2,
                        ),
                      ),

                      // Bouton de connexion principal
                      ElevatedButton.icon(
                        onPressed: _connectWithPrimaryMethod,
                        icon: Icon(
                          _getPrimaryButtonIcon(),
                          size: ResponsiveSize.getFontSize(24),
                        ),
                        label: Text(
                          _getPrimaryButtonText(),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.dtBlue,
                          foregroundColor: AppTheme.dtYellow,
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveSize.getHeight(16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveSize.getWidth(AppTheme.radiusM),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingL),
                      ),

                      // Bouton autre méthode
                      OutlinedButton(
                        onPressed: _showMethodSelectionModal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dtBlue,
                          side: BorderSide(color: AppTheme.dtBlue, width: 2),
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveSize.getHeight(14),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveSize.getWidth(AppTheme.radiusM),
                            ),
                          ),
                        ),
                        child: Text(
                          l10n.otherConnectionMethod,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingM),
                      ),

                      // Bouton PIN oublié
                      if (_hasPin)
                        TextButton(
                          onPressed: () {
                            // Naviguer vers l'écran de réinitialisation du PIN
                            Navigator.of(context).push(
                              CustomRouteTransitions.fadeScaleRoute(
                                page: PinResetScreen(
                                  phoneNumber: widget.phoneNumber,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            l10n.forgotPin,
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(16),
                              color: AppTheme.dtBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
