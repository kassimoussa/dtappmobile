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
        child: Text('© 2025 Djibouti Telecom',
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
      _body('Djibouti Telecom (« nous », « notre ») s\'engage à protéger la vie privée des utilisateurs de l\'application mobile DJIBTEL. La présente Politique décrit les données que nous collectons, leur utilisation et vos droits.'),
      _section('2. Données collectées'),
      _bullet('Numéro de téléphone — pour l\'authentification par OTP.'),
      _bullet('Solde et historique de transactions — affichés dans l\'app, non stockés de façon permanente.'),
      _bullet('Token FCM — identifiant de notification push lié à votre appareil.'),
      _bullet('Données de session — token temporaire conservé localement.'),
      _bullet('Informations sur l\'appareil — modèle, OS, à des fins de diagnostic.'),
      _section('3. Finalités du traitement'),
      _bullet('Authentification et sécurisation de votre compte.'),
      _bullet('Affichage de votre solde, forfaits et historique.'),
      _bullet('Envoi de notifications push liées à vos opérations.'),
      _bullet('Amélioration des performances et de la qualité de service.'),
      _bullet('Respect des obligations légales en vigueur à Djibouti.'),
      _section('4. Base légale'),
      _body('Le traitement repose sur l\'exécution du contrat de service, votre consentement explicite recueilli lors de la première utilisation, et les obligations légales de Djibouti Telecom.'),
      _section('5. Partage des données'),
      _body('Vos données ne sont ni vendues ni louées. Elles peuvent être partagées uniquement avec les infrastructures de Djibouti Telecom, les autorités sur réquisition judiciaire, et Firebase (Google) pour les notifications push.'),
      _section('6. Conservation'),
      _body('Les données de session expirent après 10 minutes d\'inactivité ou à la déconnexion. Les données de compte sont conservées pendant la durée de l\'abonnement puis archivées conformément à la loi.'),
      _section('7. Sécurité'),
      _body('Nous mettons en œuvre des mesures adaptées : chiffrement HTTPS, authentification OTP, expiration automatique des sessions.'),
      _section('8. Vos droits'),
      _bullet('Droit d\'accès, de rectification et d\'effacement.'),
      _bullet('Droit d\'opposition et à la portabilité.'),
      _body('Contact : privacy@djiboutitelecom.dj'),
      _section('9. Modifications'),
      _body('Toute modification substantielle vous sera notifiée via l\'application. L\'utilisation continue vaut acceptation.'),
      _section('10. Contact'),
      _body('Djibouti Telecom — Boulevard de la République, Djibouti\nTél. : +253 21 35 07 90 — privacy@djiboutitelecom.dj'),
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
      _body('Djibouti Telecom ("we", "our") is committed to protecting the privacy of DJIBTEL mobile application users. This Policy describes the data we collect, how we use it, and your rights.'),
      _section('2. Data Collected'),
      _bullet('Phone number — used for OTP authentication.'),
      _bullet('Balance and transaction history — displayed in the app, not permanently stored.'),
      _bullet('FCM token — push notification identifier linked to your device.'),
      _bullet('Session data — temporary token stored locally.'),
      _bullet('Device information — model, OS, for diagnostic purposes.'),
      _section('3. Purposes of Processing'),
      _bullet('Authentication and security of your account.'),
      _bullet('Display of your balance, packages, and history.'),
      _bullet('Sending push notifications related to your operations.'),
      _bullet('Improving performance and service quality.'),
      _bullet('Compliance with legal obligations in Djibouti.'),
      _section('4. Legal Basis'),
      _body('Processing is based on the execution of the service contract, your explicit consent collected at first use, and the legal obligations of Djibouti Telecom.'),
      _section('5. Data Sharing'),
      _body('Your data is neither sold nor rented. It may only be shared with Djibouti Telecom\'s infrastructure, authorities upon judicial request, and Firebase (Google) for push notifications.'),
      _section('6. Retention'),
      _body('Session data expires after 10 minutes of inactivity or upon logout. Account data is retained for the duration of the subscription, then archived in accordance with the law.'),
      _section('7. Security'),
      _body('We implement appropriate measures: HTTPS encryption, OTP authentication, automatic session expiration.'),
      _section('8. Your Rights'),
      _bullet('Right of access, rectification, and erasure.'),
      _bullet('Right to object and to data portability.'),
      _body('Contact: privacy@djiboutitelecom.dj'),
      _section('9. Changes'),
      _body('Any significant change will be notified via the application. Continued use constitutes acceptance.'),
      _section('10. Contact'),
      _body('Djibouti Telecom — Boulevard de la République, Djibouti\nTel: +253 21 35 07 90 — privacy@djiboutitelecom.dj'),
      _footer(),
    ]);
  }
}
