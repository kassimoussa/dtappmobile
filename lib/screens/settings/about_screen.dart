import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/settings_card.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';
import 'terms_of_service_screen.dart';
import '../auth/privacy_policy_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = '${info.version} (${info.buildNumber})');
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          _bgGlow(),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: l10n.about),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                        ResponsiveSize.getWidth(AppTheme.spacingL)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                            height:
                                ResponsiveSize.getHeight(AppTheme.spacingM)),
                        Center(
                          child: Image.asset(
                            'assets/logos/dtlogo-img-wbg.png',
                            height: ResponsiveSize.getHeight(64),
                          ),
                        ),
                        SizedBox(
                            height:
                                ResponsiveSize.getHeight(AppTheme.spacingM)),
                        Center(
                          child: Text(
                            'DT Mobile',
                            style: AppTheme.subheadingStyle.copyWith(
                              fontSize: ResponsiveSize.getFontSize(20),
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.getHeight(4)),
                        Center(
                          child: Text(
                            '${l10n.version} $_version',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: ResponsiveSize.getFontSize(13),
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                            height:
                                ResponsiveSize.getHeight(AppTheme.spacingL)),
                        SettingsCard(
                          children: [
                            SettingsTile(
                              icon: Icons.description_outlined,
                              label: l10n.termsOfService,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TermsOfServiceScreen(),
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              label: l10n.privacyPolicyTitle,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height:
                                ResponsiveSize.getHeight(AppTheme.spacingL)),
                        Center(
                          child: Text(
                            '© ${DateTime.now().year} Djibouti Telecom · ${l10n.rightsReserved}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: ResponsiveSize.getFontSize(12),
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                            height:
                                ResponsiveSize.getHeight(AppTheme.spacingL)),
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

  Widget _bgGlow() => Positioned(
        top: -100,
        left: -100,
        right: -100,
        child: Container(
          height: 350,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppTheme.dtBlueO08, Colors.transparent],
              radius: 0.8,
            ),
          ),
        ),
      );
}
