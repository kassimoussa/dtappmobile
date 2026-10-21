import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../services/app_update_service.dart';
import '../dt_button.dart';

/// Dialogue de mise à jour de l'app.
///
///  - [AppUpdateKind.mandatory] : non fermable (ni retour, ni toucher en
///    dehors), un seul bouton. [show] ne se termine jamais : l'appelant n'a
///    pas à laisser l'utilisateur entrer dans l'app.
///  - [AppUpdateKind.recommended] : « Plus tard » mémorise le report (voir
///    [AppUpdateService.markDismissed]) ; [show] se termine à la fermeture.
class AppUpdateDialog extends StatefulWidget {
  final AppUpdate update;

  const AppUpdateDialog({super.key, required this.update});

  static Future<void> show(BuildContext context, AppUpdate update) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(update: update),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _linkFailed = false;

  bool get _mandatory => widget.update.kind == AppUpdateKind.mandatory;

  Future<void> _openStore() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(widget.update.storeUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Échec géré ci-dessous : message dans le dialogue.
    }
    if (!mounted) return;
    if (!opened) {
      setState(() => _linkFailed = true);
    } else if (!_mandatory) {
      // Le dialogue obligatoire reste en place : au retour de l'utilisateur
      // sans mise à jour, il est toujours bloqué.
      Navigator.of(context).pop();
    }
  }

  Future<void> _later() async {
    await AppUpdateService.markDismissed(widget.update);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final update = widget.update;

    return PopScope(
      // Le retour matériel ne ferme jamais directement : il vaut « Plus tard »
      // pour une mise à jour proposée, et ne fait rien pour une obligatoire.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_mandatory) _later();
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 48,
                color: AppTheme.dtBlue,
              ),
              const SizedBox(height: 16),
              Text(
                _mandatory
                    ? l10n.updateRequiredTitle
                    : l10n.updateAvailableTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _mandatory
                    ? l10n.updateRequiredMessage
                    : l10n.updateAvailableMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              if (update.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.updateWhatsNew,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(update.notes, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
              if (_linkFailed) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.linkError,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.red[700]),
                ),
              ],
              const SizedBox(height: 24),
              DtButton.primary(label: l10n.updateNow, onPressed: _openStore),
              if (!_mandatory) ...[
                const SizedBox(height: 8),
                DtButton.text(label: l10n.later, onPressed: _later),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
