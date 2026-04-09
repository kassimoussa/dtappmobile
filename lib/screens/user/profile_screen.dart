// lib/screens/user/profile_screen.dart
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/profile_service.dart';
import '../../widgets/appbar_widget.dart';
import '../../extensions/color_extensions.dart';
import '../../generated/l10n/app_localizations.dart';
import '../settings/language_selection_screen.dart';
import '../settings/connection_settings_screen.dart';
import '../auth/pin/pin_management_screen.dart';
import 'edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/topup_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (mounted) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: l10n.myProfile,
        showAction: false,
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : SingleChildScrollView(
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingL),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingL),
                    ),
                    _buildPersonalInfoSection(),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingL),
                    ),
                    _buildPreferencesSection(l10n),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingL),
                    ),
                    _buildLogoutButton(l10n),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingL),
                    ),
                    if (_errorMessage != null) ...[
                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingM),
                      ),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.dtBlue),
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

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: AppTheme.dtBlue.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: AppTheme.dtBlue.withOpacityValue(0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: ResponsiveSize.getWidth(40),
            backgroundColor: AppTheme.dtBlue,
            child: Text(
              _currentName?.isNotEmpty == true
                  ? _currentName!.substring(0, 1).toUpperCase()
                  : _phoneNumber?.substring(_phoneNumber!.length - 4) ?? '?',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(24),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtYellow,
              ),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            _currentName?.isNotEmpty == true
                ? _currentName!
                : AppLocalizations.of(context)!.defaultUser,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(20),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            _phoneNumber ?? '',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSection(
      title: l10n.personalInfo,
      action: IconButton(
        icon: Icon(Icons.edit, color: AppTheme.dtBlue),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EditProfileScreen(
                    initialName: _currentName,
                    initialEmail: _currentEmail,
                  ),
            ),
          );

          if (result == true) {
            _loadUserProfile();
          }
        },
      ),
      children: [
        _buildInfoRow(
          l10n.nameLabel,
          _currentName?.isNotEmpty == true ? _currentName! : l10n.notAvailable,
        ),
        _buildInfoRow(
          l10n.emailLabel,
          _currentEmail?.isNotEmpty == true
              ? _currentEmail!
              : l10n.notAvailable,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.preferences,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConnectionSettingsScreen(),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.grey[600],
                  size: ResponsiveSize.getFontSize(24),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                Expanded(
                  child: Text(
                    l10n.connectionSettings,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
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
        ),
        Divider(height: 1, color: Colors.grey[200]),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PinManagementScreen(),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Colors.grey[600],
                  size: ResponsiveSize.getFontSize(24),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                Expanded(
                  child: Text(
                    l10n.managePin,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
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
        ),
        Divider(height: 1, color: Colors.grey[200]),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LanguageSelectionScreen(),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  color: Colors.grey[600],
                  size: ResponsiveSize.getFontSize(24),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                Expanded(
                  child: Text(
                    l10n.changeLanguage,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
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
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action != null) action,
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
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
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(l10n),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red[600],
                size: ResponsiveSize.getFontSize(24),
              ),
              SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
              Expanded(
                child: Text(
                  l10n.logoutAction,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    color: Colors.red[600],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.red[300],
                size: ResponsiveSize.getFontSize(16),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.logout, style: AppTheme.subheadingStyle),
          content: Text(l10n.logoutConfirmation, style: AppTheme.bodyStyle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: AppTheme.primaryButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.red.shade600),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performLogout(l10n);
              },
              child: Text(l10n.logoutAction),
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
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.dtBlue)),
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
