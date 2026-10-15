import 'package:dtservices/models/seasonal_event.dart';
import 'package:dtservices/widgets/seasonal_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

SeasonalEvent _event(SeasonalLoop loop, {int animationId = 1}) =>
    SeasonalEvent.tryParse({
      'id': 7,
      'animations': [
        {
          'id': animationId,
          'placement': 'overlay',
          'animation_url': 'asset:assets/lottie/dt-aid-croissant.json',
          'loop': loop.name,
        },
      ],
    })!;

Widget _host(SeasonalEvent event) => MaterialApp(
  home: SizedBox(
    width: 300,
    height: 300,
    child: SeasonalAnimation(event: event, spec: event.animations.first),
  ),
);

/// Laisse les opérations asynchrones réelles (lecture de fichier,
/// SharedPreferences) se terminer, puis avance l'horloge du test.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('infinite : le décor s\'affiche et reste affiché', (
    tester,
  ) async {
    final event = _event(SeasonalLoop.infinite);
    await tester.runAsync(() => event.animations.first.provider.load());

    await tester.pumpWidget(_host(event));
    await _settle(tester);
    expect(find.byType(Lottie), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(Lottie), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('once : se joue une fois, disparaît, et ne se rejoue pas', (
    tester,
  ) async {
    final event = _event(SeasonalLoop.once);
    await tester.runAsync(() => event.animations.first.provider.load());

    await tester.pumpWidget(_host(event));
    await _settle(tester);
    expect(find.byType(Lottie), findsOneWidget);

    // Fin de l'animation (4 s) : le widget se retire.
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(Lottie), findsNothing);

    // Même événement, nouveau montage (relance de l'app) : déjà vu.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_host(event));
    await _settle(tester);
    expect(find.byType(Lottie), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('once : un autre événement se rejoue', (tester) async {
    final first = _event(SeasonalLoop.once);
    await tester.runAsync(() => first.animations.first.provider.load());
    await tester.pumpWidget(_host(first));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(Lottie), findsNothing);

    final next =
        SeasonalEvent.tryParse({
          'id': 8, // autre fête
          'animations': [
            {
              'id': 1,
              'placement': 'overlay',
              'animation_url': 'asset:assets/lottie/dt-aid-croissant.json',
              'loop': 'once',
            },
          ],
        })!;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_host(next));
    await _settle(tester);
    expect(find.byType(Lottie), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fichier introuvable : rien à l\'écran, aucune erreur', (
    tester,
  ) async {
    final event =
        SeasonalEvent.tryParse({
          'id': 9,
          'animations': [
            {
              'id': 1,
              'placement': 'header_strip',
              'animation_url': 'asset:assets/lottie/n-existe-pas.json',
            },
          ],
        })!;

    await tester.pumpWidget(_host(event));
    await _settle(tester);

    expect(find.byType(Lottie), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
