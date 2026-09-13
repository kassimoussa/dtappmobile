import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/consent_service.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/dt_button.dart';
import '../../widgets/glass_app_bar.dart';
import '../settings/terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

/// Écran de ré-acceptation, affiché après authentification quand un document
/// juridique a été révisé.
///
/// Bloquant par construction : ni bouton retour, ni geste arrière. On en sort
/// en acceptant (`pop(true)`) ou en refusant (`pop(false)`) — dans ce dernier
/// cas l'appelant ferme la session.
///
/// La première acceptation, elle, se fait à la connexion via la case à cocher
/// de [LoginScreen] : cet écran ne sert qu'aux révisions.
class ConsentScreen extends StatefulWidget {
  /// Documents à faire accepter, tels que renvoyés par
  /// [ConsentService.pendingDocuments].
  final List<String> documents;

  const ConsentScreen({super.key, required this.documents});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;
  bool _busy = false;

  Future<void> _decide(String action) async {
    if (_busy) return;
    setState(() => _busy = true);

    await ConsentService.record(
      docs: widget.documents,
      action: action,
      locale: Localizations.localeOf(context).languageCode,
    );

    if (!mounted) return;
    Navigator.of(context).pop(action == ConsentService.actionAccepted);
  }

  String _documentLabel(AppLocalizations l10n, String doc) =>
      doc == ConsentService.privacyDoc
          ? l10n.privacyPolicyLinkText
          : l10n.termsOfService;

  void _openDocument(String doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => doc == ConsentService.privacyDoc
            ? const PrivacyPolicyScreen()
            : const TermsOfServiceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    // Refuser doit être un geste délibéré : pas de sortie par le bouton
    // système, qui laisserait l'utilisateur dans l'app sans consentement.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGrey,
        body: Stack(
          children: [
            _bgGlow(),
            SafeArea(
              child: Column(
                children: [
                  GlassAppBar(
                    title: l10n.consentUpdatedTitle,
                    showBack: false,
                  ),
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
                          children: [
                            Text(
                              l10n.consentUpdatedIntro,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: ResponsiveSize.getFontSize(14),
                                height: 1.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            SizedBox(height: ResponsiveSize.getHeight(20)),
                            for (final doc in widget.documents)
                              _DocumentRow(
                                label: _documentLabel(l10n, doc),
                                action: l10n.consentReadDocument,
                                onTap: () => _openDocument(doc),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _DecisionBar(
                    l10n: l10n,
                    documents: widget.documents,
                    accepted: _accepted,
                    busy: _busy,
                    onToggle: (v) => setState(() => _accepted = v),
                    onAccept: () => _decide(ConsentService.actionAccepted),
                    onDecline: () => _decide(ConsentService.actionDeclined),
                  ),
                ],
              ),
            ),
          ],
        ),
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

/// Ligne « document → le lire », une par document à accepter.
class _DocumentRow extends StatelessWidget {
  final String label;
  final String action;
  final VoidCallback onTap;

  const _DocumentRow({
    required this.label,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.description_outlined,
                size: 20, color: AppTheme.dtBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveSize.getFontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    action,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveSize.getFontSize(12),
                      color: AppTheme.dtBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Case à cocher unique couvrant tous les documents, puis Accepter / Refuser.
class _DecisionBar extends StatelessWidget {
  final AppLocalizations l10n;
  final List<String> documents;
  final bool accepted;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _DecisionBar({
    required this.l10n,
    required this.documents,
    required this.accepted,
    required this.busy,
    required this.onToggle,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final label = documents.length > 1
        ? l10n.consentCheckboxBoth
        : '${l10n.iAcceptThe}${documents.first == ConsentService.privacyDoc ? l10n.privacyPolicyLinkText : l10n.termsOfService}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          GestureDetector(
            onTap: busy ? null : () => onToggle(!accepted),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: accepted,
                    onChanged: busy ? null : (v) => onToggle(v ?? false),
                    activeColor: AppTheme.dtBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: ResponsiveSize.getFontSize(13),
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DtButton.primary(
            label: l10n.privacyPolicyAcceptBtn,
            loading: busy,
            onPressed: accepted && !busy ? onAccept : null,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onDecline,
            child: Text(
              l10n.privacyPolicyDeclineBtn,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: ResponsiveSize.getFontSize(13),
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            l10n.consentDeclineNotice,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: ResponsiveSize.getFontSize(11),
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
