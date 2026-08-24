import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';

/// Conditions d'utilisation.
///
/// Le texte décrit les fonctionnalités réellement présentes dans l'application
/// (OTP, PIN/biométrie, forfaits, recharge par code, transfert de crédit,
/// gestion de la ligne fixe, agences, test de débit). Toute évolution de ces
/// fonctionnalités doit être répercutée ici, ainsi que dans la Politique de
/// confidentialité.
///
/// ⚠️ À faire relire par le service juridique de Djibouti Telecom avant
/// publication d'une nouvelle version.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  /// Date de dernière révision du texte : à mettre à jour à chaque
  /// modification de fond (et non à chaque build, contrairement à un
  /// `DateTime.now()` qui donnerait une date fausse).
  static const String _lastUpdatedFr = '2 août 2026';
  static const String _lastUpdatedEn = 'August 2, 2026';

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
        _p('Dernière mise à jour : $_lastUpdatedFr. En téléchargeant et en utilisant l’application DJIBTEL, éditée par Djibouti Telecom, vous acceptez les présentes conditions d’utilisation.'),
        _h('1. Objet et acceptation'),
        _p('DJIBTEL vous permet de gérer votre ligne mobile prépayée Djibouti Telecom ainsi que vos lignes fixes et internet depuis votre téléphone. L’utilisation de l’application vaut acceptation pleine et entière des présentes conditions. Si vous n’y adhérez pas, veuillez ne pas utiliser l’application.'),
        _h('2. Accès et éligibilité'),
        _p('L’application est réservée aux clients disposant d’une ligne mobile Djibouti Telecom. La première connexion s’effectue avec votre numéro et un code de vérification reçu par SMS ; vous pouvez ensuite vous connecter avec un code secret ou avec votre empreinte ou votre visage, selon vos réglages.'),
        _p('Vous déclarez être titulaire du numéro utilisé, ou être autorisé à l’utiliser. Les fonctionnalités disponibles dépendent de votre offre et de l’état de votre ligne : une ligne suspendue ne donne accès qu’à la consultation.'),
        _h('3. Services proposés'),
        _p('Selon votre offre, l’application vous permet notamment de : consulter votre solde, votre validité et vos forfaits actifs ; acheter des forfaits pour votre ligne ou pour un autre numéro Djibouti Telecom ; recharger une ligne à l’aide d’un code de recharge ; transférer du crédit à un autre abonné ; consulter, recharger et souscrire des offres pour vos lignes fixes et internet ; consulter votre historique et vos statistiques d’utilisation ; localiser les agences Djibouti Telecom ; mesurer le débit de votre connexion ; recevoir des notifications relatives à vos opérations.'),
        _p('Djibouti Telecom peut faire évoluer, suspendre ou retirer tout ou partie de ces fonctionnalités, notamment pour des raisons techniques, commerciales ou réglementaires.'),
        _h('4. Sécurité de votre compte'),
        _p('Les opérations qui engagent de l’argent sont protégées par votre code secret ou par votre empreinte ou votre visage, selon ce que vous avez choisi dans « Paramètres de paiement ». Toute opération validée de cette façon depuis votre téléphone est considérée comme effectuée par vous.'),
        _p('Vous êtes responsable de la confidentialité de votre code secret, du code reçu par SMS et de l’accès à votre téléphone. Ne communiquez jamais ces codes à personne, y compris à quelqu’un se présentant comme un agent de Djibouti Telecom. En cas de perte, de vol ou d’utilisation par un tiers, prévenez immédiatement Djibouti Telecom.'),
        _p('Par sécurité, votre session est automatiquement fermée après 5 minutes d’inactivité et une nouvelle authentification vous est alors demandée.'),
        _h('5. Débits et tarifs'),
        _p('Les achats, recharges et transferts réalisés dans l’application sont débités de votre solde prépayé, en francs Djibouti (DJF). L’application ne collecte aucun moyen de paiement bancaire et n’effectue aucun paiement par carte.'),
        _p('Le montant affiché sur l’écran de confirmation est celui qui sera débité ; les tarifs applicables sont ceux en vigueur chez Djibouti Telecom. Une opération ne peut aboutir que si votre solde est suffisant.'),
        _h('6. Vérification du destinataire et remboursements'),
        _p('Avant de confirmer un transfert de crédit, une recharge ou un achat de forfait pour un tiers, vérifiez attentivement le numéro du destinataire. Ces opérations sont exécutées immédiatement et sont irréversibles : une opération confirmée vers un numéro erroné ne peut être ni annulée ni remboursée.'),
        _p('Les montants engagés ne sont pas remboursables, sauf échec technique dûment constaté par Djibouti Telecom ou disposition légale contraire.'),
        _h('7. Usage acceptable'),
        _p('Vous vous engagez à utiliser l’application de bonne foi et conformément à la loi. Sont notamment interdits : l’usage frauduleux de codes de recharge, la revente non autorisée de services, l’utilisation de programmes automatiques pour enchaîner les opérations, ainsi que toute tentative de contourner la sécurité de l’application. Djibouti Telecom peut suspendre votre accès en cas d’usage abusif ou frauduleux.'),
        _h('8. Test de débit'),
        _p('Le test de débit utilise des serveurs de mesure extérieurs à Djibouti Telecom et consomme des données décomptées de votre forfait ou de votre solde. Les résultats sont donnés à titre indicatif : ils dépendent de la couverture, de votre téléphone, de l’heure et de l’état du réseau, et ne constituent pas un engagement sur la qualité de votre connexion.'),
        _h('9. Disponibilité et responsabilité'),
        _p('L’application est fournie « en l’état ». Son fonctionnement dépend de votre connexion, du réseau mobile et des systèmes de Djibouti Telecom, et peut être interrompu pour maintenance. Djibouti Telecom s’efforce d’en assurer la continuité mais ne garantit ni une disponibilité ininterrompue, ni l’absence d’erreurs.'),
        _p('Les informations affichées (solde, forfaits, historique, statistiques) peuvent connaître un léger décalage de mise à jour ; en cas de différence, seules les données enregistrées par Djibouti Telecom font foi. Djibouti Telecom ne saurait être tenu responsable des dommages indirects liés à l’utilisation de l’application.'),
        _h('10. Propriété intellectuelle'),
        _p('L’application, ses marques, logos, contenus et éléments graphiques sont la propriété de Djibouti Telecom. Toute reproduction, modification ou diffusion sans autorisation écrite préalable est interdite.'),
        _h('11. Données personnelles'),
        _p('Les données traitées dans le cadre de l’application, leurs finalités et vos droits sont décrits dans la Politique de confidentialité, accessible depuis la rubrique « À propos ».'),
        _h('12. Modification et fin d’utilisation'),
        _p('Les présentes conditions peuvent être mises à jour ; toute évolution substantielle vous sera signalée dans l’application. L’utilisation continue après notification vaut acceptation.'),
        _p('Vous pouvez cesser d’utiliser l’application et la désinstaller à tout moment. La désinstallation n’entraîne pas la résiliation de votre abonnement Djibouti Telecom.'),
        _h('13. Droit applicable et contact'),
        _p('Les présentes conditions sont régies par le droit djiboutien ; tout litige relève de la compétence des tribunaux de Djibouti.'),
        _p('Djibouti Telecom — Boulevard de la République, Djibouti\nTél. : +253 21 35 07 90 — developer@djibtel.dj'),
      ];

  List<Widget> _english() => [
        _p('Last updated: $_lastUpdatedEn. By downloading and using the DJIBTEL application, published by Djibouti Telecom, you agree to these terms of service.'),
        _h('1. Purpose and acceptance'),
        _p('DJIBTEL lets you manage your Djibouti Telecom prepaid mobile line as well as your fixed and internet lines from your phone. Using the application constitutes full acceptance of these terms. If you do not agree, please do not use the application.'),
        _h('2. Access and eligibility'),
        _p('The application is reserved for customers with a Djibouti Telecom mobile line. Your first sign-in uses your number and a verification code received by SMS; you can then sign in with a secret code, or with your fingerprint or face, depending on your settings.'),
        _p('You declare that you own the number used, or are authorised to use it. Available features depend on your plan and on the status of your line: a suspended line only gives access to consultation.'),
        _h('3. Services offered'),
        _p('Depending on your plan, the application allows you to: check your balance, validity and active packages; buy packages for your line or for another Djibouti Telecom number; top up a line using a refill code; transfer credit to another subscriber; check, top up and subscribe to offers for your fixed and internet lines; review your history and usage statistics; locate Djibouti Telecom branches; measure your connection speed; and receive notifications about your operations.'),
        _p('Djibouti Telecom may modify, suspend or withdraw all or part of these features, in particular for technical, commercial or regulatory reasons.'),
        _h('4. Account security'),
        _p('Operations involving money are protected by your secret code, or by your fingerprint or face, according to what you chose in “Payment settings”. Any operation validated this way from your phone is considered to have been carried out by you.'),
        _p('You are responsible for keeping your secret code, the code received by SMS and access to your phone confidential. Never share these codes with anyone, including someone claiming to be a Djibouti Telecom agent. In case of loss, theft or use by someone else, notify Djibouti Telecom immediately.'),
        _p('For security reasons, your session is automatically closed after 5 minutes of inactivity and you are then asked to authenticate again.'),
        _h('5. Charges and pricing'),
        _p('Purchases, top-ups and transfers made in the application are debited from your prepaid balance, in Djiboutian francs (DJF). The application collects no bank payment details and processes no card payments.'),
        _p('The amount shown on the confirmation screen is the amount that will be debited; applicable prices are those in force at Djibouti Telecom. An operation can only succeed if your balance is sufficient.'),
        _h('6. Recipient verification and refunds'),
        _p('Before confirming a credit transfer, a top-up or a package purchase for a third party, carefully check the recipient number. These operations are executed immediately and are irreversible: an operation confirmed to a wrong number can neither be cancelled nor refunded.'),
        _p('Amounts spent are non-refundable, except in the event of a technical failure duly established by Djibouti Telecom or where required by law.'),
        _h('7. Acceptable use'),
        _p('You undertake to use the application in good faith and in compliance with the law. The following are prohibited in particular: fraudulent use of refill codes, unauthorised resale of services, using automated programs to run operations in bulk, and any attempt to bypass the security of the application. Djibouti Telecom may suspend your access in case of abusive or fraudulent use.'),
        _h('8. Speed test'),
        _p('The speed test uses measurement servers outside Djibouti Telecom and consumes data charged against your package or balance. Results are given for information only: they depend on coverage, your phone, the time of day and network conditions, and are not a commitment on the quality of your connection.'),
        _h('9. Availability and liability'),
        _p('The application is provided “as is”. Its operation depends on your connection, the mobile network and Djibouti Telecom systems, and may be interrupted for maintenance. Djibouti Telecom strives to ensure continuity but guarantees neither uninterrupted availability nor the absence of errors.'),
        _p('Information displayed (balance, packages, history, statistics) may be slightly delayed; in case of a difference, only the data recorded by Djibouti Telecom is authoritative. Djibouti Telecom shall not be liable for indirect damages related to the use of the application.'),
        _h('10. Intellectual property'),
        _p('The application, its trademarks, logos, content and graphic elements are the property of Djibouti Telecom. Any reproduction, modification or distribution without prior written authorisation is prohibited.'),
        _h('11. Personal data'),
        _p('The data processed through the application, the purposes of processing and your rights are described in the Privacy Policy, available from the “About” section.'),
        _h('12. Changes and termination of use'),
        _p('These terms may be updated; any substantial change will be signalled within the application. Continued use after notification constitutes acceptance.'),
        _p('You may stop using the application and uninstall it at any time. Uninstalling does not terminate your Djibouti Telecom subscription.'),
        _h('13. Governing law and contact'),
        _p('These terms are governed by Djiboutian law; any dispute falls within the jurisdiction of the courts of Djibouti.'),
        _p('Djibouti Telecom — Boulevard de la République, Djibouti\nTel: +253 21 35 07 90 — developer@djibtel.dj'),
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
