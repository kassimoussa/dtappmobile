import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/user_session.dart';
import '../../generated/l10n/app_localizations.dart';

class ConnectionSettingsScreen extends StatefulWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  State<ConnectionSettingsScreen> createState() =>
      _ConnectionSettingsScreenState();
}

class _ConnectionSettingsScreenState extends State<ConnectionSettingsScreen> {
  bool _isBiometricSupported = false;
  bool _isBiometricEnabled = false;
  bool _isPinEnabled = true;
  bool _isOtpEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final localAuth = LocalAuthentication();
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    final biometricEnabled = await UserSession.isBiometricEnabled();
    final pinEnabled = await UserSession.isPinEnabled();
    final otpEnabled = await UserSession.isOtpEnabled();

    if (mounted) {
      setState(() {
        _isBiometricSupported = canCheckBiometrics && isDeviceSupported;
        _isBiometricEnabled = biometricEnabled;
        _isPinEnabled = pinEnabled;
        _isOtpEnabled = otpEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() {
      _isBiometricEnabled = value;
    });
    await UserSession.setBiometricEnabled(value);
  }

  Future<void> _togglePin(bool value) async {
    setState(() {
      _isPinEnabled = value;
    });
    await UserSession.setPinEnabled(value);
  }

  Future<void> _toggleOtp(bool value) async {
    setState(() {
      _isOtpEnabled = value;
    });
    await UserSession.setOtpEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

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
              decoration: BoxDecoration(
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
                _buildGlassAppBar(context, l10n.connectionSettings),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: EdgeInsets.all(
                            ResponsiveSize.getWidth(AppTheme.spacingL),
                          ),
                          child: Column(
                            children: [
                              if (_isBiometricSupported) ...[
                                _buildSwitchOption(
                                  title: l10n.biometricLogin,
                                  value: _isBiometricEnabled,
                                  onChanged: _toggleBiometric,
                                ),
                                SizedBox(
                                  height: ResponsiveSize.getHeight(AppTheme.spacingM),
                                ),
                              ],
                              _buildSwitchOption(
                                title: l10n.pinLogin,
                                value: _isPinEnabled,
                                onChanged: _togglePin,
                              ),
                              SizedBox(
                                height: ResponsiveSize.getHeight(AppTheme.spacingM),
                              ),
                              _buildSwitchOption(
                                title: l10n.otpLogin,
                                value: _isOtpEnabled,
                                onChanged: _toggleOtp,
                              ),
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

  Widget _buildGlassAppBar(BuildContext context, String title) {
    return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(
            color: AppTheme.white95,
            border: Border(bottom: BorderSide(color: AppTheme.dtBlueO10, width: 0.5)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.white50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.dtBlue,
          ),
        ],
      ),
    );
  }
}
