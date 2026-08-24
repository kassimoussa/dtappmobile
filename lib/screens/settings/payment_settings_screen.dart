import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/settings_card.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../enums/payment_auth_method.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_session.dart';
import '../../utils/responsive_size.dart';

/// Choix de la méthode d'authentification exigée pour valider un paiement.
/// Contrairement à l'écran des paramètres de connexion, les options sont
/// exclusives : un paiement ne peut être validé que d'une seule façon.
class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  PaymentAuthMethod _method = PaymentAuthMethod.biometric;
  bool _isBiometricSupported = false;
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
    final method = phoneNumber == null
        ? PaymentAuthMethod.biometric
        : await UserSession.getPaymentAuthMethod(phoneNumber);

    if (mounted) {
      setState(() {
        _phoneNumber = phoneNumber;
        _isBiometricSupported = canCheckBiometrics && isDeviceSupported;
        _method = method;
        _isLoading = false;
      });
    }
  }

  Future<void> _select(PaymentAuthMethod method) async {
    final phoneNumber = _phoneNumber;
    if (phoneNumber == null || method == _method) return;

    // Tout ce qui touche au context est lu avant le moindre await.
    final l10n = AppLocalizations.of(context)!;
    final hasPin = context.read<AuthProvider>().hasPin;
    final messenger = ScaffoldMessenger.of(context);

    // Sans PIN configuré, ce choix rendrait tout paiement impossible.
    if (method == PaymentAuthMethod.pin && !hasPin) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.paymentAuthPinUnavailable)),
      );
      return;
    }

    setState(() => _method = method);
    await UserSession.setPaymentAuthMethod(phoneNumber, method);
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
                GlassAppBar(title: l10n.paymentSettings),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(
                            ResponsiveSize.getWidth(AppTheme.spacingL),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: ResponsiveSize.getWidth(
                                    AppTheme.spacingXS,
                                  ),
                                  bottom: ResponsiveSize.getHeight(
                                    AppTheme.spacingM,
                                  ),
                                ),
                                child: Text(
                                  l10n.paymentAuthIntro,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: ResponsiveSize.getFontSize(13),
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              SettingsCard(
                                children: [
                                  if (_isBiometricSupported)
                                    _buildOption(
                                      method: PaymentAuthMethod.biometric,
                                      title: l10n.paymentAuthBiometric,
                                      description: l10n.paymentAuthBiometricDesc,
                                    ),
                                  _buildOption(
                                    method: PaymentAuthMethod.pin,
                                    title: l10n.paymentAuthPin,
                                    description: l10n.paymentAuthPinDesc,
                                  ),
                                ],
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

  /// Ligne d'option à choix exclusif. Reprend les métriques de [SettingsTile],
  /// qui n'accepte pas de sous-titre.
  Widget _buildOption({
    required PaymentAuthMethod method,
    required String title,
    required String description,
  }) {
    final selected = _method == method;

    return InkWell(
      onTap: () => _select(method),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveSize.getHeight(AppTheme.spacingS + 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveSize.getFontSize(15),
                      color: Colors.black87,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXS)),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveSize.getFontSize(12.5),
                      color: Colors.grey[600],
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppTheme.dtBlue : Colors.grey[400],
              size: ResponsiveSize.getFontSize(22),
            ),
          ],
        ),
      ),
    );
  }
}
