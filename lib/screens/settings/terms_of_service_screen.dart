import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';

/// Conditions d'utilisation.
///
/// ⚠️ Le texte ci-dessous est un MODÈLE générique fourni à titre indicatif ;
/// il doit être relu et validé par le service juridique de Djibouti Telecom
/// avant publication.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
                GlassAppBar(title: l10n.termsOfService),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                        ResponsiveSize.getWidth(AppTheme.spacingL)),
                    child: Container(
                      padding: EdgeInsets.all(
                          ResponsiveSize.getWidth(AppTheme.spacingL)),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: isEn ? _english() : _french(),
                      ),
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

  List<Widget> _french() => [
        _p('Dernière mise à jour : ${DateTime.now().year}. En téléchargeant et en utilisant l’application DT Mobile de Djibouti Telecom, vous acceptez les présentes conditions d’utilisation.'),
        _h('1. Acceptation'),
        _p('L’utilisation de l’application vaut acceptation pleine et entière des présentes conditions. Si vous n’y adhérez pas, veuillez ne pas utiliser l’application.'),
        _h('2. Service'),
        _p('L’application permet de gérer votre ligne : consultation du solde, achat de forfaits, recharges, transferts de crédit et services associés. Les services disponibles peuvent varier selon votre offre et votre statut d’abonné.'),
        _h('3. Compte et code PIN'),
        _p('Vous êtes responsable de la confidentialité de votre code PIN et des opérations effectuées depuis votre appareil. Prévenez immédiatement le service client en cas d’utilisation non autorisée.'),
        _h('4. Crédit, forfaits et facturation'),
        _p('Les achats et transferts sont débités de votre solde ou facturés conformément à votre offre. Les montants engagés ne sont pas remboursables, sauf disposition légale contraire.'),
        _h('5. Disponibilité et responsabilité'),
        _p('L’application est fournie « en l’état ». Djibouti Telecom s’efforce d’assurer sa continuité mais ne peut garantir une disponibilité ininterrompue ni l’absence d’erreurs, et ne saurait être tenu responsable des dommages indirects liés à son utilisation.'),
        _h('6. Modifications'),
        _p('Les présentes conditions peuvent être mises à jour. Toute évolution vous sera notifiée dans l’application ou par un autre moyen approprié.'),
        _h('7. Contact'),
        _p('Pour toute question relative aux présentes conditions, contactez le service client via la rubrique Aide & support.'),
      ];

  List<Widget> _english() => [
        _p('Last updated: ${DateTime.now().year}. By downloading and using the DT Mobile application by Djibouti Telecom, you agree to these terms of service.'),
        _h('1. Acceptance'),
        _p('Using the application constitutes full acceptance of these terms. If you do not agree, please do not use the application.'),
        _h('2. Service'),
        _p('The application lets you manage your line: check your balance, buy packages, top up, transfer credit and use related services. Available services may vary depending on your plan and subscriber status.'),
        _h('3. Account and PIN'),
        _p('You are responsible for keeping your PIN confidential and for operations performed from your device. Notify customer service immediately in case of unauthorized use.'),
        _h('4. Credit, packages and billing'),
        _p('Purchases and transfers are debited from your balance or billed according to your plan. Amounts spent are non-refundable unless required by law.'),
        _h('5. Availability and liability'),
        _p('The application is provided “as is”. Djibouti Telecom strives to ensure continuity but cannot guarantee uninterrupted, error-free availability, and shall not be liable for indirect damages related to its use.'),
        _h('6. Changes'),
        _p('These terms may be updated. Any change will be notified within the application or by other appropriate means.'),
        _h('7. Contact'),
        _p('For any question regarding these terms, contact customer service through the Help & support section.'),
      ];

  Widget _h(String text) => Padding(
        padding: EdgeInsets.only(
          top: ResponsiveSize.getHeight(AppTheme.spacingM),
          bottom: ResponsiveSize.getHeight(AppTheme.spacingXS),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.w700,
            color: AppTheme.dtBlue,
          ),
        ),
      );

  Widget _p(String text) => Padding(
        padding: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingS)),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: ResponsiveSize.getFontSize(14),
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
      );
}
