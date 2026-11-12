import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_theme.dart';
import '../generated/l10n/app_localizations.dart';
import 'receipt_image.dart';

/// Reçu d'une opération, à envoyer par message ou par e-mail, en texte ou en
/// image.
///
/// Le reçu ne contient que ce qui prouve l'opération (type, montants,
/// numéro, date, référence). Le solde de l'utilisateur n'y figure jamais :
/// le reçu est fait pour être montré à quelqu'un d'autre.
class Receipt {
  final String title;
  final List<({String label, String value})> lines;

  const Receipt({required this.title, required this.lines});

  /// Texte du reçu :
  /// ```
  /// Reçu DJIBTEL
  /// Transfert de crédit
  ///
  /// Montant : 1000 DJF
  /// ```
  String toText(AppLocalizations l10n) {
    // Le français met une espace avant « : », pas l'anglais.
    final colon = l10n.localeName.startsWith('fr') ? ' : ' : ': ';
    final buffer =
        StringBuffer()
          ..writeln(l10n.receiptHeader)
          ..writeln(title)
          ..writeln();
    for (final line in lines) {
      buffer.writeln('${line.label}$colon${line.value}');
    }
    return buffer.toString().trimRight();
  }

  /// Image PNG du reçu (voir [ReceiptImage]).
  Future<Uint8List> toImage(AppLocalizations l10n) =>
      ReceiptImage.render(this, header: l10n.receiptHeader);

  /// Propose « image » ou « texte », puis ouvre la feuille de partage du
  /// système. [context] est celui du bouton touché : sur iPad, la feuille de
  /// partage s'ancre à cet endroit.
  Future<void> share(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject();
    final origin =
        box is RenderBox && box.hasSize
            ? box.localToGlobal(Offset.zero) & box.size
            : null;

    final format = await _askFormat(context, l10n);
    if (format == null) return;

    try {
      if (format == _ReceiptFormat.image) {
        final fileName =
            l10n.localeName.startsWith('fr')
                ? 'recu-djibtel.png'
                : 'receipt-djibtel.png';
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                await toImage(l10n),
                mimeType: 'image/png',
                name: fileName,
              ),
            ],
            fileNameOverrides: [fileName],
            subject: '${l10n.receiptHeader} - $title',
            sharePositionOrigin: origin,
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: toText(l10n),
            subject: '${l10n.receiptHeader} - $title',
            sharePositionOrigin: origin,
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.receiptShareError)));
    }
  }

  static Future<_ReceiptFormat?> _askFormat(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showModalBottomSheet<_ReceiptFormat>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    l10n.receiptShareAction,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.image_outlined,
                    color: AppTheme.dtBlue2,
                  ),
                  title: Text(l10n.receiptShareAsImage),
                  onTap:
                      () => Navigator.pop(sheetContext, _ReceiptFormat.image),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.notes_rounded,
                    color: AppTheme.dtBlue2,
                  ),
                  title: Text(l10n.receiptShareAsText),
                  onTap: () => Navigator.pop(sheetContext, _ReceiptFormat.text),
                ),
              ],
            ),
          ),
    );
  }
}

enum _ReceiptFormat { image, text }
