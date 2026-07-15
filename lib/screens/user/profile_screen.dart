// lib/screens/user/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/settings_card.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import '../settings/notification_preferences_screen.dart'; // masqué temporairement
// import '../settings/help_support_screen.dart'; // masqué temporairement
import '../settings/terms_of_service_screen.dart';
import '../settings/about_screen.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/profile_service.dart';
import '../../generated/l10n/app_localizations.dart';
import '../settings/language_selection_screen.dart';
import '../settings/connection_settings_screen.dart';
import '../auth/pin/pin_management_screen.dart';
import '../auth/pin/pin_setup_screen.dart';
import 'edit_profile_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/topup_provider.dart';
import '../../providers/transaction_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = ProfileService.cachedProfile == null;
  String? _errorMessage;

  // Données utilisateur
  String? _phoneNumber;
  String? _currentName;
  String? _currentEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final cached = ProfileService.cachedProfile;

    if (cached != null) {
      // Affiche immédiatement les données en cache, rafraîchit en arrière-plan
      final userData = cached['user'];
      setState(() {
        _phoneNumber = userData['phone_number'];
        _currentName = userData['name'];
        _currentEmail = userData['email'];
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Charger les données du profil
      final profileData = await ProfileService.getUserProfile();

      if (profileData != null && mounted) {
        final userData = profileData['user'];

        setState(() {
          _phoneNumber = userData['phone_number'];
          _currentName = userData['name'];
          _currentEmail = userData['email'];
          _isLoading = false;
        });
      } else if (cached == null && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (cached == null && mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.profileLoadError;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

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
                GlassAppBar(title: l10n.myProfile),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(
                            ResponsiveSize.getWidth(AppTheme.spacingL),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProfileHeader(),
                              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                              _buildPreferencesSection(l10n, authProvider),
                              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                              _buildSupportSection(l10n),
                              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                              _buildLogoutButton(l10n),
                              if (_errorMessage != null) ...[
                                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                                _buildErrorMessage(),
                              ],
                            ],
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


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.dtBlue),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            AppLocalizations.of(context)!.loadingProfile,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte identité compacte : avatar + nom/numéro/email sur une ligne,
  /// bouton d'édition intégré. Remplace l'ancien en-tête vertical et la
  /// section "Infos personnelles" qui dupliquait le nom.
  Widget _buildProfileHeader() {
    final l10n = AppLocalizations.of(context)!;
    final hasName = _currentName?.isNotEmpty == true;

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveSize.getWidth(28),
            backgroundColor: AppTheme.dtBlue,
            child: Text(
              hasName
                  ? _currentName!.substring(0, 1).toUpperCase()
                  : _phoneNumber?.substring(_phoneNumber!.length - 4) ?? '?',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(hasName ? 22 : 14),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtYellow,
              ),
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? _currentName! : l10n.defaultUser,
                  style: AppTheme.subheadingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(17),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveSize.getHeight(2)),
                Text(
                  _phoneNumber ?? '',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (_currentEmail?.isNotEmpty == true) ...[
                  SizedBox(height: ResponsiveSize.getHeight(2)),
                  Text(
                    _currentEmail!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveSize.getFontSize(13),
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
          Material(
            color: AppTheme.dtBlueO10,
            borderRadius: BorderRadius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusM),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(
                ResponsiveSize.getWidth(AppTheme.radiusM),
              ),
              onTap: _openEditProfile,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(10)),
                child: Icon(
                  Icons.edit_rounded,
                  color: AppTheme.dtBlue,
                  size: ResponsiveSize.getFontSize(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: _currentName,
          initialEmail: _currentEmail,
        ),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  Widget _buildPreferencesSection(AppLocalizations l10n, AuthProvider authProvider) {
    return SettingsCard(
      // title: l10n.preferences, // masqué temporairement
      children: [
        SettingsTile(
          icon: Icons.settings,
          label: l10n.connectionSettings,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConnectionSettingsScreen(),
              ),
            );
          },
        ),
        SettingsTile(
          icon: authProvider.hasPin ? Icons.lock_outline : Icons.lock_open_rounded,
          label: authProvider.hasPin ? l10n.managePin : l10n.setupPinTitle,
          iconColor: authProvider.hasPin ? null : AppTheme.dtBlue,
          labelColor: authProvider.hasPin ? null : AppTheme.dtBlue,
          fontWeight: authProvider.hasPin ? FontWeight.normal : FontWeight.w600,
          onTap: () {
            if (authProvider.hasPin) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PinManagementScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PinSetupScreen(
                    onPinSet: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.pinSetupSuccess),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
        ),
        SettingsTile(
          icon: Icons.language,
          label: l10n.changeLanguage,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LanguageSelectionScreen(),
              ),
            );
          },
        ),
        // Notifications — masqué temporairement
        /*
        SettingsTile(
          icon: Icons.notifications_none_rounded,
          label: l10n.notifications,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationPreferencesScreen(),
              ),
            );
          },
        ),
        */
      ],
    );
  }

  Widget _buildSupportSection(AppLocalizations l10n) {
    return SettingsCard(
      // title: l10n.supportSection, // masqué temporairement
      children: [
        // Aide & support — masqué temporairement
        /*
        SettingsTile(
          icon: Icons.help_outline_rounded,
          label: l10n.helpSupport,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          ),
        ),
        */
        SettingsTile(
          icon: Icons.description_outlined,
          label: l10n.termsOfService,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
          ),
        ),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          label: l10n.about,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutScreen()),
          ),
        ),
        SettingsTile(
          icon: Icons.share_outlined,
          label: l10n.shareApp,
          onTap: () => _shareApp(l10n),
        ),
        SettingsTile(
          icon: Icons.star_outline_rounded,
          label: l10n.rateApp,
          onTap: () => _rateApp(l10n),
        ),
      ],
    );
  }

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.djiboutitelecom.dtappmobile';

  Future<void> _shareApp(AppLocalizations l10n) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: '${l10n.shareAppMessage} $_playStoreUrl'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.linkError)));
      }
    }
  }

  Future<void> _rateApp(AppLocalizations l10n) async {
    final uri = Uri.parse(_playStoreUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.linkError)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.linkError)));
      }
    }
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusS),
        ),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          SizedBox(width: ResponsiveSize.getWidth(8)),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return SettingsCard(
      children: [
        SettingsTile(
          icon: Icons.logout_rounded,
          label: l10n.logoutAction,
          iconColor: Colors.red[600],
          labelColor: Colors.red[600],
          fontWeight: FontWeight.w600,
          trailing: SettingsChevron(color: Colors.red[300]),
          onTap: () => _showLogoutDialog(l10n),
        ),
      ],
    );
  }

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(AppTheme.spacingXL),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusL),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: ResponsiveSize.getWidth(64),
                  height: ResponsiveSize.getWidth(64),
                  decoration: const BoxDecoration(
                    color: AppTheme.dtBlueO10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppTheme.dtBlue,
                    size: ResponsiveSize.getFontSize(30),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                Text(
                  l10n.logout,
                  textAlign: TextAlign.center,
                  style: AppTheme.subheadingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(20),
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
                Text(
                  l10n.logoutConfirmation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                DtButton.danger(
                  label: l10n.logoutAction,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _performLogout(l10n);
                  },
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                DtButton.text(
                  label: l10n.cancel,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performLogout(AppLocalizations l10n) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.dtBlue)),
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final balanceProvider = context.read<BalanceProvider>();
      final topUpProvider = context.read<TopUpProvider>();
      final transactionProvider = context.read<TransactionProvider>();

      final success = await authProvider.logout();

      if (success) {
        balanceProvider.reset();
        topUpProvider.reset();
        transactionProvider.reset();
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted && success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.logoutError)),
        );
      }
    }
  }
}
