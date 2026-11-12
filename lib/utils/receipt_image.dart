import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_theme.dart';
import 'receipt.dart';

/// Dessine un [Receipt] en image PNG, à envoyer par messagerie.
///
/// Le reçu est peint directement sur un canevas, sans passer par l'arbre de
/// widgets : l'image est la même quel que soit l'écran, le thème ou la taille
/// de texte choisie dans les réglages du téléphone.
class ReceiptImage {
  /// Largeur logique du reçu ; l'image fait [width] × [scale] pixels.
  static const double width = 360;
  static const double scale = 3;

  static const _logoAsset = 'assets/logos/dtlogo-img-wbg.png';

  static const _margin = 24.0;
  static const _headerHeight = 112.0;
  static const _badgeSize = 52.0;
  static const _rowPadding = 12.0;
  static const _labelWidth = 120.0;
  static const _columnGap = 16.0;
  static const _valueWidth = width - 2 * _margin - _labelWidth - _columnGap;
  static const _footerHeight = 44.0;

  static const _ink = AppTheme.textPrimary;
  static const _muted = AppTheme.textSecondary;
  static const _divider = Color(0xFFE2E8F0);
  static const _success = Color(0xFF2E7D32);

  /// PNG du reçu. [header] est l'en-tête traduit (« Reçu DJIBTEL »).
  static Future<Uint8List> render(
    Receipt receipt, {
    required String header,
  }) async {
    final logo = await _loadLogo();
    try {
      final rows = [
        for (final line in receipt.lines)
          (
            label: _paint(
              line.label,
              fontSize: 13,
              color: _muted,
              maxWidth: _labelWidth,
            ),
            value: _paint(
              line.value,
              fontSize: 14,
              weight: FontWeight.w600,
              color: _ink,
              maxWidth: _valueWidth,
              align: TextAlign.right,
              family: 'Inter',
            ),
          ),
      ];

      final rowHeights = [
        for (final r in rows)
          (r.label.height > r.value.height ? r.label.height : r.value.height) +
              2 * _rowPadding,
      ];
      final bodyTop = _headerHeight + 28 + _badgeSize + 16;
      final height =
          bodyTop +
          rowHeights.fold<double>(0, (a, b) => a + b) +
          12 +
          _footerHeight;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale);

      // Fond et bandeau de marque.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, _headerHeight),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.dtBlue, AppTheme.dtBlue2],
          ).createShader(const Rect.fromLTWH(0, 0, width, _headerHeight)),
      );

      var textLeft = _margin;
      if (logo != null) {
        // Même logo et même présentation qu'à l'accueil : sur une pastille
        // blanche, pour rester lisible sur le bandeau bleu.
        const logoHeight = 68.0;
        final logoWidth = logoHeight * logo.width / logo.height;
        final tile = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            _margin,
            (_headerHeight - (logoHeight + 16)) / 2,
            logoWidth + 20,
            logoHeight + 16,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(tile, Paint()..color = Colors.white);
        canvas.drawImageRect(
          logo,
          Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
          Rect.fromLTWH(tile.left + 10, tile.top + 8, logoWidth, logoHeight),
          Paint()..filterQuality = FilterQuality.high,
        );
        textLeft = tile.right + 16;
      }
      final textWidth = width - textLeft - _margin;
      final headerPainter = _paint(
        header,
        fontSize: 22,
        weight: FontWeight.w700,
        color: Colors.white,
        maxWidth: textWidth,
        family: 'Outfit',
      );
      final titlePainter = _paint(
        receipt.title,
        fontSize: 14,
        weight: FontWeight.w500,
        color: AppTheme.dtYellow,
        maxWidth: textWidth,
        family: 'Outfit',
      );
      final blockHeight = headerPainter.height + 4 + titlePainter.height;
      final blockTop = (_headerHeight - blockHeight) / 2;
      headerPainter.paint(canvas, Offset(textLeft, blockTop));
      titlePainter.paint(
        canvas,
        Offset(textLeft, blockTop + headerPainter.height + 4),
      );

      // Pastille de réussite : un reçu n'existe que pour une opération aboutie.
      const badgeCenter = Offset(
        width / 2,
        _headerHeight + 28 + _badgeSize / 2,
      );
      canvas.drawCircle(
        badgeCenter,
        _badgeSize / 2,
        Paint()..color = _success.withValues(alpha: 0.12),
      );
      canvas.drawCircle(
        badgeCenter,
        _badgeSize / 2 - 8,
        Paint()..color = _success,
      );
      canvas.drawPath(
        Path()
          ..moveTo(badgeCenter.dx - 8, badgeCenter.dy + 0.5)
          ..lineTo(badgeCenter.dx - 2, badgeCenter.dy + 6.5)
          ..lineTo(badgeCenter.dx + 9, badgeCenter.dy - 6),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      // Lignes : libellé à gauche, valeur alignée à droite.
      var y = bodyTop;
      const valueLeft = width - _margin - _valueWidth;
      for (var i = 0; i < rows.length; i++) {
        final rowHeight = rowHeights[i];
        if (i > 0) {
          canvas.drawLine(
            Offset(_margin, y),
            Offset(width - _margin, y),
            Paint()
              ..color = _divider
              ..strokeWidth = 1,
          );
        }
        final label = rows[i].label;
        final value = rows[i].value;
        label.paint(
          canvas,
          Offset(_margin, y + (rowHeight - label.height) / 2),
        );
        value.paint(
          canvas,
          Offset(valueLeft, y + (rowHeight - value.height) / 2),
        );
        y += rowHeight;
      }

      // Pied de page.
      final footerTop = height - _footerHeight;
      canvas.drawRect(
        Rect.fromLTWH(0, footerTop, width, _footerHeight),
        Paint()..color = AppTheme.backgroundGrey,
      );
      final footer = _paint(
        'Djibouti Telecom',
        fontSize: 12,
        weight: FontWeight.w600,
        color: _muted,
        maxWidth: width - 2 * _margin,
        align: TextAlign.center,
      );
      footer.paint(
        canvas,
        Offset(_margin, footerTop + (_footerHeight - footer.height) / 2),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (width * scale).round(),
        (height * scale).ceil(),
      );
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Encodage PNG impossible');
        return data.buffer.asUint8List();
      } finally {
        image.dispose();
        picture.dispose();
      }
    } finally {
      logo?.dispose();
    }
  }

  /// Le logo est un plus : s'il manque, le reçu se fait quand même.
  static Future<ui.Image?> _loadLogo() async {
    try {
      final data = await rootBundle.load(_logoAsset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 356,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  /// Texte mis en page à [maxWidth]. Avec un alignement, la boîte garde cette
  /// largeur pour que l'alignement se fasse dans la colonne.
  static TextPainter _paint(
    String text, {
    required double fontSize,
    required Color color,
    required double maxWidth,
    FontWeight weight = FontWeight.w400,
    TextAlign align = TextAlign.left,
    String family = 'Inter',
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: family,
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: 1.3,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(
      minWidth: align == TextAlign.left ? 0 : maxWidth,
      maxWidth: maxWidth,
    );
  }
}
