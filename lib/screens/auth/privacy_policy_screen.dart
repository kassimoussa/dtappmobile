import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_size.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  /// [mustAccept] : true = l'user doit scroller + accepter.
  /// false = lecture libre depuis les paramètres.
  final bool mustAccept;

  const PrivacyPolicyScreen({super.key, this.mustAccept = false});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    if (widget.mustAccept) {
      _scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (_hasScrolledToBottom) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 60) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.privacyPolicyTitle,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        automaticallyImplyLeading: !widget.mustAccept,
      ),
      body: Column(
        children: [
          if (widget.mustAccept)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.dtBlue.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppTheme.dtBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.privacyPolicyScrollInfo,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: ResponsiveSize.getFontSize(12),
                        color: AppTheme.dtBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveSize.getWidth(20),
                vertical: ResponsiveSize.getHeight(20),
              ),
              child: isEn
                  ? _PolicyContentEn(lastUpdated: l10n.privacyPolicyLastUpdated)
                  : _PolicyContentFr(lastUpdated: l10n.privacyPolicyLastUpdated),
            ),
          ),
          if (widget.mustAccept)
            _AcceptBar(
              l10n: l10n,
              enabled: _hasScrolledToBottom,
              onAccept: () => Navigator.of(context).pop(true),
              onDecline: () => Navigator.of(context).pop(false),
            ),
        ],
      ),
    );
  }
}

// ─── Barre d'acceptation ──────────────────────────────────────────────────────

class _AcceptBar extends StatelessWidget {
  final AppLocalizations l10n;
  final bool enabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _AcceptBar({
    required this.l10n,
    required this.enabled,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.privacyPolicyScrollToAccept,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.privacyPolicyDeclineBtn,
                      style: const TextStyle(
                          fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: enabled ? onAccept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dtBlue,
                    disabledBackgroundColor: Colors.grey[200],
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.grey[400],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.privacyPolicyAcceptBtn,
                      style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers de mise en page ──────────────────────────────────────────────────

Widget _header(String title, String subtitle) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppTheme.textSecondary)),
      ],
    );

Widget _meta(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.dtBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.dtBlue,
                fontWeight: FontWeight.w500)),
      ),
    );

Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.dtBlue)),
    );

Widget _body(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.6)),
    );

Widget _bullet(String text) => Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                    color: AppTheme.dtBlue, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.6)),
          ),
        ],
      ),
    );

Widget _footer() => Column(children: [
      const SizedBox(height: 32),
      Divider(color: Colors.grey[200]),
      const SizedBox(height: 16),
      Center(
        child: Text('© ${DateTime.now().year} Djibouti Telecom',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 12, color: Colors.grey[400])),
      ),
      const SizedBox(height: 8),
    ]);

// ─── Contenu FRANÇAIS ─────────────────────────────────────────────────────────

class _PolicyContentFr extends StatelessWidget {
  final String lastUpdated;
  const _PolicyContentFr({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('Politique de confidentialité', 'DJIBTEL — Djibouti Telecom'),
      _meta(lastUpdated),
      const SizedBox(height: 20),
      _section('1. Introduction'),
      _body('Djibouti Telecom (« nous ») s\'engage à protéger la vie privée des utilisateurs de l\'application DJIBTEL. Ce document explique, simplement, quelles informations nous recueillons, à quoi elles servent et ce que vous pouvez décider.'),
      _section('2. Ce que nous recueillons'),
      _bullet('Votre numéro de téléphone — pour vous identifier avec le code reçu par SMS, puis avec votre code secret.'),
      _bullet('Votre nom et votre e-mail — seulement si vous choisissez de les renseigner dans votre profil.'),
      _bullet('Vos numéros de ligne fixe ou internet — quand vous consultez ou rechargez ces lignes.'),
      _bullet('Le numéro du destinataire — quand vous transférez du crédit, achetez un forfait ou rechargez pour quelqu\'un d\'autre.'),
      _bullet('Votre solde, vos forfaits et vos opérations — ils viennent de nos systèmes pour être affichés dans l\'application, et sont gardés un court moment sur votre téléphone pour un affichage plus rapide.'),
      _bullet('Des informations sur votre téléphone — marque, modèle, version du système et de l\'application, ainsi qu\'un numéro qui identifie l\'appareil. Elles nous servent à repérer les connexions inhabituelles sur votre compte.'),
      _bullet('Un identifiant de notification — attribué à votre téléphone pour pouvoir lui envoyer les notifications de l\'application.'),
      _bullet('Une clé de connexion temporaire — enregistrée sur votre téléphone, elle vous évite de vous identifier à chaque écran.'),
      _section('3. Ce qui ne quitte jamais votre téléphone'),
      _body('Certaines autorisations servent uniquement à vous simplifier la vie. Ces informations restent sur votre appareil et ne nous sont pas envoyées :'),
      _bullet('Vos contacts — si vous préférez choisir un destinataire dans votre répertoire plutôt que taper son numéro. Seul le numéro que vous sélectionnez sert à l\'opération ; nous ne recevons ni ne conservons votre répertoire.'),
      _bullet('Votre position — utilisée seulement quand vous ouvrez la carte des agences, pour vous situer et vous indiquer les plus proches.'),
      _bullet('Vos SMS — l\'application repère le message contenant votre code de connexion pour le saisir à votre place. Aucun autre message n\'est lu.'),
      _bullet('Votre empreinte ou votre visage — la vérification est faite par votre téléphone lui-même. L\'application apprend seulement si elle a réussi ou échoué ; elle n\'a jamais accès à votre empreinte ni à votre visage.'),
      _body('Nous ne recueillons aucune donnée bancaire : l\'application n\'accepte pas de carte, vos opérations sont réglées avec votre solde.'),
      _section('4. À quoi cela sert'),
      _bullet('Vérifier que c\'est bien vous, et protéger votre compte et vos paiements.'),
      _bullet('Réaliser les opérations que vous demandez : forfaits, recharges, transferts, gestion de vos lignes fixes.'),
      _bullet('Vous montrer votre solde, vos forfaits, votre historique et vos statistiques.'),
      _bullet('Vous prévenir de vos opérations et vous informer des offres de Djibouti Telecom.'),
      _bullet('Détecter les fraudes et les utilisations abusives.'),
      _bullet('Améliorer le fonctionnement de l\'application et la qualité du service.'),
      _bullet('Respecter les obligations prévues par la loi à Djibouti.'),
      _section('5. Pourquoi nous avons le droit de les traiter'),
      _body('Parce que c\'est nécessaire pour vous fournir le service prévu par votre abonnement, parce que vous nous avez donné votre accord lors de la première utilisation, parce que nous devons protéger votre compte contre la fraude, et parce que la loi djiboutienne nous l\'impose dans certains cas.'),
      _section('6. Qui d\'autre y a accès'),
      _body('Vos informations ne sont ni vendues, ni louées, et ne servent pas à vous cibler avec de la publicité. Elles ne sont partagées qu\'avec :'),
      _bullet('les services de Djibouti Telecom nécessaires pour exécuter vos opérations ;'),
      _bullet('Google, qui achemine les notifications jusqu\'à votre téléphone et affiche la carte des agences ;'),
      _bullet('le prestataire des serveurs utilisés par le test de débit, qui voit l\'adresse de votre connexion internet pendant la durée du test ;'),
      _bullet('les autorités, uniquement sur demande de la justice.'),
      _section('7. Combien de temps nous les gardons'),
      _body('Vous êtes déconnecté automatiquement après 5 minutes sans activité, et vos informations de connexion sont alors effacées de votre téléphone. L\'identifiant de notification est conservé même après déconnexion, pour continuer à vous avertir de vos opérations ; il est supprimé si vous désactivez les notifications. Le code secret enregistré pour la validation par empreinte ou par visage reste dans l\'espace protégé de votre téléphone tant que vous n\'avez pas désactivé cette option. Vos données de compte et vos opérations sont conservées pendant la durée de votre abonnement, puis archivées comme la loi l\'exige.'),
      _section('8. Comment nous les protégeons'),
      _body('Les échanges entre l\'application et nos serveurs sont chiffrés, c\'est-à-dire illisibles pour un tiers qui les intercepterait. L\'accès est protégé par le code reçu par SMS, puis par votre code secret ou votre empreinte. Votre connexion se ferme d\'elle-même après un moment d\'inactivité, le nombre d\'essais est limité en cas de code erroné, et votre code secret est rangé dans l\'espace protégé prévu par votre téléphone.'),
      _section('9. Vos droits'),
      _bullet('Consulter, corriger ou faire effacer vos informations — votre nom et votre e-mail se modifient directement dans votre profil.'),
      _bullet('Vous opposer à un traitement, ou demander une copie de vos informations.'),
      _bullet('Revenir sur votre accord à tout moment : vous pouvez refuser l\'accès aux contacts, à la position et aux notifications dans les réglages de votre téléphone. Le reste de l\'application continue de fonctionner.'),
      _body('Pour exercer ces droits : developer@djibtel.dj'),
      _section('10. Modifications'),
      _body('Toute modification substantielle vous sera notifiée via l\'application. L\'utilisation continue vaut acceptation.'),
      _section('11. Contact'),
      _body('Djibouti Telecom — Boulevard de la République, Djibouti\nTél. : +253 21 35 07 90 — developer@djibtel.dj'),
      _footer(),
    ]);
  }
}

// ─── Contenu ANGLAIS ──────────────────────────────────────────────────────────

class _PolicyContentEn extends StatelessWidget {
  final String lastUpdated;
  const _PolicyContentEn({required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header('Privacy Policy', 'DJIBTEL — Djibouti Telecom'),
      _meta(lastUpdated),
      const SizedBox(height: 20),
      _section('1. Introduction'),
      _body('Djibouti Telecom ("we") is committed to protecting the privacy of DJIBTEL users. This document explains, in plain terms, what information we collect, what it is used for, and what you can decide.'),
      _section('2. What We Collect'),
      _bullet('Your phone number — to identify you with the code received by SMS, then with your secret code.'),
      _bullet('Your name and email — only if you choose to add them to your profile.'),
      _bullet('Your fixed or internet line numbers — when you check or top up those lines.'),
      _bullet('The recipient\'s number — when you transfer credit, buy a package or top up for someone else.'),
      _bullet('Your balance, packages and operations — these come from our systems to be shown in the application, and are kept briefly on your phone so screens load faster.'),
      _bullet('Information about your phone — brand, model, system and application version, plus a number identifying the device. We use it to spot unusual sign-ins on your account.'),
      _bullet('A notification identifier — given to your phone so the application can send it notifications.'),
      _bullet('A temporary sign-in key — stored on your phone so you do not have to identify yourself on every screen.'),
      _section('3. What Never Leaves Your Phone'),
      _body('Some permissions exist purely to make your life easier. This information stays on your device and is not sent to us:'),
      _bullet('Your contacts — if you would rather pick a recipient from your address book than type the number. Only the number you select is used for the operation; we neither receive nor keep your address book.'),
      _bullet('Your location — used only when you open the branch map, to place you and point out the nearest branches.'),
      _bullet('Your text messages — the application spots the message containing your sign-in code and fills it in for you. No other message is read.'),
      _bullet('Your fingerprint or face — the check is performed by your phone itself. The application only learns whether it succeeded or failed; it never has access to your fingerprint or your face.'),
      _body('We collect no banking details: the application accepts no cards, your operations are paid for with your balance.'),
      _section('4. What It Is Used For'),
      _bullet('Checking that it really is you, and protecting your account and your payments.'),
      _bullet('Carrying out the operations you ask for: packages, top-ups, transfers, managing your fixed lines.'),
      _bullet('Showing you your balance, packages, history and statistics.'),
      _bullet('Telling you about your operations and about Djibouti Telecom offers.'),
      _bullet('Detecting fraud and abusive use.'),
      _bullet('Improving how the application works and the quality of the service.'),
      _bullet('Meeting the obligations set out by Djiboutian law.'),
      _section('5. Why We Are Allowed To Process It'),
      _body('Because it is necessary to provide the service covered by your subscription, because you gave us your agreement the first time you used the application, because we must protect your account against fraud, and because Djiboutian law requires it in certain cases.'),
      _section('6. Who Else Has Access'),
      _body('Your information is neither sold nor rented, and is not used to target you with advertising. It is only shared with:'),
      _bullet('the Djibouti Telecom services needed to carry out your operations;'),
      _bullet('Google, which delivers notifications to your phone and displays the branch map;'),
      _bullet('the provider of the servers used by the speed test, which sees your internet connection\'s address for the duration of the test;'),
      _bullet('the authorities, only upon request from the courts.'),
      _section('7. How Long We Keep It'),
      _body('You are signed out automatically after 5 minutes without activity, and your sign-in details are then erased from your phone. The notification identifier is kept even after you sign out, so you can still be told about your operations; it is deleted if you turn notifications off. The secret code saved for fingerprint or face validation stays in your phone\'s protected storage until you disable that option. Your account data and operations are kept for the duration of your subscription, then archived as the law requires.'),
      _section('8. How We Protect It'),
      _body('Exchanges between the application and our servers are encrypted, meaning unreadable to anyone who might intercept them. Access is protected by the code received by SMS, then by your secret code or your fingerprint. Your session closes on its own after a while without activity, the number of attempts is limited if a code is wrong, and your secret code is kept in the protected storage your phone provides.'),
      _section('9. Your Rights'),
      _bullet('See, correct or have your information erased — your name and email can be changed directly in your profile.'),
      _bullet('Object to a use of your information, or ask for a copy of it.'),
      _bullet('Change your mind at any time: you can decline access to contacts, location and notifications in your phone settings. The rest of the application keeps working.'),
      _body('To exercise these rights: developer@djibtel.dj'),
      _section('10. Changes'),
      _body('Any significant change will be notified via the application. Continued use constitutes acceptance.'),
      _section('11. Contact'),
      _body('Djibouti Telecom — Boulevard de la République, Djibouti\nTel: +253 21 35 07 90 — developer@djibtel.dj'),
      _footer(),
    ]);
  }
}
