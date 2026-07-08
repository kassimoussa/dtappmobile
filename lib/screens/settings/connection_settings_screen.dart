import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/settings_card.dart';
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
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final localAuth = LocalAuthentication();
    final canCheckBiometrics = await localAuth.canCheckBiometrics;
    final isDeviceSupported = await localAuth.isDeviceSupported();

    final phoneNumber = await UserSession.getPhoneNumber();
    final biometricEnabled = phoneNumber == null
        ? false
        : await UserSession.isBiometricEnabled(phoneNumber);
    final pinEnabled = await UserSession.isPinEnabled();
    final otpEnabled = await UserSession.isOtpEnabled();

    if (mounted) {
      setState(() {
        _phoneNumber = phoneNumber;
        _isBiometricSupported = canCheckBiometrics && isDeviceSupported;
        _isBiometricEnabled = biometricEnabled;
        _isPinEnabled = pinEnabled;
        _isOtpEnabled = otpEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final phoneNumber = _phoneNumber;
    if (phoneNumber == null) return;
    setState(() {
      _isBiometricEnabled = value;
    });
    await UserSession.setBiometricEnabled(phoneNumber, value);
    if (!value) {
      await UserSession.deleteSecurePin(phoneNumber);
    }
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
                GlassAppBar(title: l10n.connectionSettings),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(
                            ResponsiveSize.getWidth(AppTheme.spacingL),
                          ),
                          child: SettingsCard(
                            children: [
                              if (_isBiometricSupported)
                                _buildSwitchOption(
                                  title: l10n.biometricLogin,
                                  value: _isBiometricEnabled,
                                  onChanged: _toggleBiometric,
                                ),
                              _buildSwitchOption(
                                title: l10n.pinLogin,
                                value: _isPinEnabled,
                                onChanged: _togglePin,
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


  Widget _buildSwitchOption({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsTile(
      label: title,
      onTap: () => onChanged(!value),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.dtBlue,
      ),
    );
  }
}
