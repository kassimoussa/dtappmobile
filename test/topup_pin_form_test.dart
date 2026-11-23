import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/providers/topup_provider.dart';
import 'package:dtservices/screens/topup/home/topup_home_screen.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  Map<String, Object> disk = const {},
}) async {
  SharedPreferences.setMockInitialValues({});
  await UserSession.clearSession();
  SharedPreferences.setMockInitialValues(disk);
  await UserSession.createSession('25377000000', sessionToken: 'tok-a');

  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(375 * 2, 812 * 2);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TopUpProvider()),
        ChangeNotifierProvider(create: (_) => BalanceProvider()),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TopUpHomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _numberField => find.byType(TextFormField).at(0);
Finder get _pinField => find.byType(TextFormField).at(1);
Finder get _submit => find.text('Consulter');

String _pinText(WidgetTester tester) =>
    tester
        .widget<EditableText>(
          find.descendant(of: _pinField, matching: find.byType(EditableText)),
        )
        .controller
        .text;

/// Remplit le formulaire et appuie sur « Consulter » avec un faux backend.
Future<void> _submitWith(
  WidgetTester tester,
  http.Response Function(http.Request) backend, {
  String pin = '1234',
}) async {
  await tester.enterText(_numberField, '21364425');
  await tester.enterText(_pinField, pin);
  await http.runWithClient(() async {
    await tester.tap(_submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }, () => MockClient((request) async => backend(request)));
}

void main() {
  testWidgets('le champ PIN est masqué, sans copier-coller ni suggestions', (
    tester,
  ) async {
    await _pumpScreen(tester);

    final editable = tester.widget<EditableText>(
      find.descendant(of: _pinField, matching: find.byType(EditableText)),
    );

    expect(editable.obscureText, isTrue);
    expect(editable.enableInteractiveSelection, isFalse);
    expect(editable.enableSuggestions, isFalse);
    expect(editable.autocorrect, isFalse);
    expect(find.text('Code PIN de la ligne'), findsOneWidget);
  });

  testWidgets('seuls les chiffres sont acceptés, 12 au plus', (tester) async {
    await _pumpScreen(tester);

    await tester.enterText(_pinField, 'ab12 34-5678901234');

    expect(_pinText(tester), '123456789012');
  });

  testWidgets('la dernière ligne utilisée préremplit le numéro, pas le PIN', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      disk: {
        'topup_fixed_number': '21364425',
        'topup_mobile_number': '25377000000',
      },
    );

    final number = tester.widget<EditableText>(
      find.descendant(of: _numberField, matching: find.byType(EditableText)),
    );
    expect(number.controller.text, '21364425');
    expect(_pinText(tester), isEmpty);
    // Aucun soldes affichés : la ligne n'est pas ouverte.
    expect(find.text('Actions rapides'), findsNothing);
  });

  testWidgets('PIN vérifié il y a peu : la ligne s\'ouvre sans le redemander', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      disk: {
        'topup_fixed_number': '21364425',
        'topup_mobile_number': '25377000000',
        'topup_verified_at':
            DateTime.now()
                .subtract(const Duration(days: 5))
                .millisecondsSinceEpoch,
      },
    );

    expect(find.text('Code PIN de la ligne'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('PIN vérifié il y a plus de 30 jours : il est redemandé', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      disk: {
        'topup_fixed_number': '21364425',
        'topup_mobile_number': '25377000000',
        'topup_verified_at':
            DateTime.now()
                .subtract(const Duration(days: 31))
                .millisecondsSinceEpoch,
      },
    );

    expect(find.text('Code PIN de la ligne'), findsOneWidget);
  });

  testWidgets('PIN vide ou trop court : message, aucune requête', (
    tester,
  ) async {
    await _pumpScreen(tester);
    var requests = 0;

    await _submitWith(tester, (_) {
      requests++;
      return http.Response('{}', 500);
    }, pin: '12');

    expect(
      find.text('Le code PIN contient de 3 à 12 chiffres'),
      findsOneWidget,
    );
    expect(requests, 0);
  });

  testWidgets(
    'mauvais PIN : message sous le champ, PIN effacé, pas de blocage',
    (tester) async {
      await _pumpScreen(tester);

      await _submitWith(
        tester,
        (_) => http.Response(
          '{"verified":false,"message":"Numéro ou PIN incorrect."}',
          401,
        ),
      );

      expect(
        find.textContaining('Numéro ou code PIN incorrect'),
        findsOneWidget,
      );
      expect(_pinText(tester), isEmpty);
      // Le bouton reste utilisable : l'utilisateur peut réessayer.
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton).first)
            .onPressed,
        isNotNull,
      );
      // Toujours sur l'écran, donc pas déconnecté.
      expect(find.byType(TopUpHomeScreen), findsOneWidget);
      expect(await UserSession.getSessionToken(), 'tok-a');
    },
  );

  testWidgets('modifier la saisie efface le message d\'erreur', (tester) async {
    await _pumpScreen(tester);
    await _submitWith(
      tester,
      (_) => http.Response('{"verified":false,"message":"x"}', 401),
    );
    expect(find.textContaining('Numéro ou code PIN incorrect'), findsOneWidget);

    await tester.enterText(_pinField, '1');
    await tester.pump();

    expect(find.textContaining('Numéro ou code PIN incorrect'), findsNothing);
  });

  testWidgets('verrou : décompte affiché et bouton bloqué jusqu\'à la fin', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await _submitWith(
      tester,
      (_) => http.Response(
        '{"verified":false,"message":"Trop de tentatives.","retry_after":3}',
        429,
      ),
    );

    expect(
      find.text('Trop de tentatives. Réessayez dans 0:03.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.byType(ElevatedButton).first)
          .onPressed,
      isNull,
    );

    await tester.pump(const Duration(seconds: 3));

    expect(find.textContaining('Trop de tentatives'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(find.byType(ElevatedButton).first)
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'service indisponible : ce n\'est pas présenté comme un PIN faux',
    (tester) async {
      await _pumpScreen(tester);

      await _submitWith(
        tester,
        (_) => http.Response('{"verified":false,"message":"indispo"}', 503),
      );

      expect(
        find.text('Service momentanément indisponible. Réessayez.'),
        findsOneWidget,
      );
      expect(find.textContaining('incorrect'), findsNothing);
    },
  );

  testWidgets(
    'l\'aide « PIN oublié » est dans une bulle, pas affichée en permanence',
    (tester) async {
      await _pumpScreen(tester);
      const help =
          'Code PIN oublié ? Contactez le service client de Djibouti Telecom.';
      expect(find.text(help), findsNothing);

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(help), findsOneWidget);

      // La bulle se retire seule.
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.text(help), findsNothing);
    },
  );
}
