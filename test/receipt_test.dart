import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/models/activity.dart';
import 'package:dtservices/utils/receipt.dart';
import 'package:dtservices/utils/receipt_image.dart';
import 'package:dtservices/widgets/activity_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const receipt = Receipt(
    title: 'Transfert de crédit',
    lines: [
      (label: 'Montant', value: '1000 DJF'),
      (label: 'Vers', value: '+253 77123456'),
    ],
  );

  test('texte du reçu en français : espace avant les deux-points', () {
    final l10n = lookupAppLocalizations(const Locale('fr'));
    expect(
      receipt.toText(l10n),
      'Reçu DJIBTEL\n'
      'Transfert de crédit\n'
      '\n'
      'Montant : 1000 DJF\n'
      'Vers : +253 77123456',
    );
  });

  test('texte du reçu en anglais : deux-points collés', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      receipt.toText(l10n),
      'DJIBTEL receipt\n'
      'Transfert de crédit\n'
      '\n'
      'Montant: 1000 DJF\n'
      'Vers: +253 77123456',
    );
  });

  test('sans ligne, le reçu garde son en-tête', () {
    final l10n = lookupAppLocalizations(const Locale('fr'));
    expect(
      const Receipt(title: 'Achat de forfait', lines: []).toText(l10n),
      'Reçu DJIBTEL\nAchat de forfait',
    );
  });

  group('image du reçu', () {
    Future<ui.Image> decode(Uint8List png) async {
      final codec = await ui.instantiateImageCodec(png);
      return (await codec.getNextFrame()).image;
    }

    test(
      'PNG valide, de largeur fixe, quelle que soit la taille d\'écran',
      () async {
        final png = await receipt.toImage(
          lookupAppLocalizations(const Locale('fr')),
        );
        expect(png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);

        final image = await decode(png);
        expect(image.width, (ReceiptImage.width * ReceiptImage.scale).round());
        expect(image.height, greaterThan(image.width ~/ 2));
      },
    );

    test('l\'image grandit avec le nombre de lignes', () async {
      final few = await decode(
        await ReceiptImage.render(receipt, header: 'Reçu DJIBTEL'),
      );
      final many = await decode(
        await ReceiptImage.render(
          Receipt(
            title: receipt.title,
            lines: [
              ...receipt.lines,
              (label: 'Date', value: '12/11/2026 14:30'),
              (label: 'Transaction', value: 'TX-42'),
            ],
          ),
          header: 'Reçu DJIBTEL',
        ),
      );
      expect(many.height, greaterThan(few.height));
    });

    test('une valeur longue passe à la ligne au lieu de déborder', () async {
      final short = await decode(
        await ReceiptImage.render(
          const Receipt(
            title: 'Forfait',
            lines: [(label: 'Forfait', value: '5 Go')],
          ),
          header: 'Reçu DJIBTEL',
        ),
      );
      final long = await decode(
        await ReceiptImage.render(
          Receipt(
            title: 'Forfait',
            lines: [(label: 'Forfait', value: 'Internet 10 Go ' * 6)],
          ),
          header: 'Reçu DJIBTEL',
        ),
      );
      expect(long.width, short.width);
      expect(long.height, greaterThan(short.height));
    });

    test('un reçu sans ligne se dessine quand même', () async {
      final png = await ReceiptImage.render(
        const Receipt(title: 'Achat de forfait', lines: []),
        header: 'Reçu DJIBTEL',
      );
      expect(
        (await decode(png)).width,
        (ReceiptImage.width * ReceiptImage.scale).round(),
      );
    });
  });

  group('ActivityDetailSheet', () {
    Future<void> pumpSheet(WidgetTester tester, String status) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActivityDetailSheet(
              activity: Activity(
                transactionNo: 'TX-42',
                actionType: 'credit_transfer',
                actionLabel: 'Transfert',
                endpoint: '/transfer',
                status: status,
                amount: 1000,
                currency: 'DJF',
                createdAt: DateTime(2026, 11, 12, 14, 30),
                beneficiaryMsisdn: '25377123456',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opération réussie : détails et bouton de partage', (
      tester,
    ) async {
      await pumpSheet(tester, 'success');
      expect(find.text('TX-42'), findsOneWidget);
      expect(find.text('77123456'), findsOneWidget);
      expect(find.text('Partager le reçu'), findsOneWidget);
    });

    testWidgets('le bouton propose image ou texte', (tester) async {
      await pumpSheet(tester, 'success');
      await tester.ensureVisible(find.text('Partager le reçu'));
      await tester.tap(find.text('Partager le reçu'));
      await tester.pumpAndSettle();

      expect(find.text('Partager en image'), findsOneWidget);
      expect(find.text('Partager en texte'), findsOneWidget);

      // Refuser le choix ferme la feuille sans rien partager ni échouer.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Partager en image'), findsNothing);
    });

    testWidgets('opération échouée : pas de reçu à partager', (tester) async {
      await pumpSheet(tester, 'failed');
      expect(find.text('TX-42'), findsOneWidget);
      expect(find.text('Partager le reçu'), findsNothing);
    });
  });
}
