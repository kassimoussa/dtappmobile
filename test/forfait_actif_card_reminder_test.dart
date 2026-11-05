import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:dtservices/widgets/cards/forfait_actif_card2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les tests dessinent le texte avec une police aux lettres carrées, bien plus
/// larges que les vraies : une fenêtre large évite un faux débordement. Le
/// rendu sur un écran étroit se vérifie sur un appareil.
const kWideTestView = 1200.0;

final _forfait = ForfaitActif2(
  id: 1,
  offreId: 1,
  nom: 'Forfait Internet Illimité Premium Plus',
  type: 1,
  typeTexte: 'Internet',
  etat: 1,
  etatTexte: 'Actif',
  produitId: 1,
  dateDebut: '01/11/2026 08:00:00',
  dateFin: '12/11/2026 15:47:00',
  compteurs: const [],
);

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  bool reminderOn = false,
  VoidCallback? onToggle,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ForfaitActifCard2(
            forfait: _forfait,
            reminderOn: reminderOn,
            onReminderToggle: onToggle,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets("pas de cloche sans rappel à proposer", (tester) async {
    await _pump(tester, width: kWideTestView);

    expect(find.byIcon(Icons.notifications_active_rounded), findsNothing);
    expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
  });

  testWidgets("la cloche reflète l'état du rappel", (tester) async {
    await _pump(
      tester,
      width: kWideTestView,
      reminderOn: true,
      onToggle: () {},
    );
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    await _pump(
      tester,
      width: kWideTestView,
      reminderOn: false,
      onToggle: () {},
    );
    expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
  });

  testWidgets("toucher la cloche bascule le rappel sans ouvrir le forfait", (
    tester,
  ) async {
    var toggles = 0;
    await _pump(
      tester,
      width: kWideTestView,
      reminderOn: true,
      onToggle: () => toggles++,
    );

    await tester.tap(find.byIcon(Icons.notifications_active_rounded));
    await tester.pump();

    expect(toggles, 1);
    expect(find.byType(ForfaitActifCard2), findsOneWidget);
  });
}
