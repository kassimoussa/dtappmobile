import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/settings_card.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // TODO: remplacer par les vraies coordonnées du service client DT.
  static const String _supportPhone = '1500';
  static const String _supportEmail = 'developer@djibtel.dj';

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          _bgGlow(),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: l10n.helpSupport),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SettingsCard(
                          title: l10n.contactTitle,
                          children: [
                            SettingsTile(
                              icon: Icons.headset_mic_rounded,
                              label: l10n.callCustomerService,
                              iconColor: AppTheme.dtBlue,
                              trailing: Text(
                                _supportPhone,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: ResponsiveSize.getFontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.dtBlue,
                                ),
                              ),
                              onTap: () => _launch(context, l10n,
                                  Uri(scheme: 'tel', path: _supportPhone)),
                            ),
                            SettingsTile(
                              icon: Icons.mail_outline_rounded,
                              label: l10n.emailSupport,
                              iconColor: AppTheme.dtBlue,
                              onTap: () => _launch(context, l10n,
                                  Uri(scheme: 'mailto', path: _supportEmail)),
                            ),
                          ],
                        ),
                        SizedBox(
                            height:
                                ResponsiveSize.getHeight(AppTheme.spacingM)),
                        _FaqCard(title: l10n.faqTitle, items: _faq(isEn)),
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

  Future<void> _launch(
      BuildContext context, AppLocalizations l10n, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.linkError)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.linkError)));
      }
    }
  }

  List<(String, String)> _faq(bool isEn) {
    if (isEn) {
      return const [
        (
          'How do I check my balance?',
          'On the home screen, your balance and active packages are shown at the top. Pull down to refresh.'
        ),
        (
          'How do I top up my credit?',
          'Go to Top-up, enter your recharge voucher code and confirm. Your balance updates immediately.'
        ),
        (
          'How do I buy a package?',
          'Open Packages, pick the offer that suits you and confirm with your balance or PIN.'
        ),
        (
          'How do I transfer credit?',
          'Use Credit transfer, enter the recipient number and the amount, then confirm.'
        ),
        (
          'I forgot my PIN, what do I do?',
          'From Profile > Manage PIN you can reset it after verifying your identity by OTP.'
        ),
      ];
    }
    return const [
      (
        'Comment consulter mon solde ?',
        'Sur l’écran d’accueil, votre solde et vos forfaits actifs s’affichent en haut. Tirez vers le bas pour rafraîchir.'
      ),
      (
        'Comment recharger mon crédit ?',
        'Allez dans Recharge, saisissez le code de votre recharge et validez. Votre solde est mis à jour immédiatement.'
      ),
      (
        'Comment acheter un forfait ?',
        'Ouvrez Forfaits, choisissez l’offre qui vous convient et validez avec votre solde ou votre code PIN.'
      ),
      (
        'Comment transférer du crédit ?',
        'Utilisez Transfert de crédit, indiquez le numéro du destinataire et le montant, puis confirmez.'
      ),
      (
        'J’ai oublié mon code PIN, que faire ?',
        'Depuis Profil > Gestion du code PIN, vous pouvez le réinitialiser après vérification de votre identité par OTP.'
      ),
    ];
  }
}

class _FaqCard extends StatelessWidget {
  final String title;
  final List<(String, String)> items;
  const _FaqCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
            ),
            child: Text(
              title,
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: ResponsiveSize.getFontSize(16),
              ),
            ),
          ),
          ...items.map(
            (qa) => Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.only(
                  bottom: ResponsiveSize.getHeight(AppTheme.spacingS),
                ),
                iconColor: AppTheme.dtBlue,
                collapsedIconColor: Colors.grey,
                title: Text(
                  qa.$1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: ResponsiveSize.getFontSize(14.5),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      qa.$2,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: ResponsiveSize.getFontSize(13.5),
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
