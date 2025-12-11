import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/appbar_widget.dart';
import '../../services/user_session.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWidget(
        title: 'Paramètre de connexion',
        showAction: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingL),
                ),
                child: Column(
                  children: [
                    if (_isBiometricSupported) ...[
                      _buildSwitchOption(
                        title: 'Connexion par empreinte digitale',
                        value: _isBiometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                      SizedBox(
                        height: ResponsiveSize.getHeight(AppTheme.spacingM),
                      ),
                    ],
                    _buildSwitchOption(
                      title: 'Connexion par code PIN',
                      value: _isPinEnabled,
                      onChanged: _togglePin,
                    ),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingM),
                    ),
                    _buildSwitchOption(
                      title: 'OTP',
                      value: _isOtpEnabled,
                      onChanged: _toggleOtp,
                    ),
                  ],
                ),
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
