import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/screens/core/main_screen.dart';
import 'package:dtservices/screens/topup/recharge/topup_recharge_screen.dart';
import 'package:dtservices/screens/topup/recharge/topup_recharge_success_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Solde fixe, pour ne pas dépendre de l'API ni de la session.
class _FakeBalanceProvider extends BalanceProvider {
  @override
  double get solde => 1234;
}

/// La police de substitution des tests (Ahem, un carré par caractère) est bien
/// plus large que la vraie : les lignes « libellé / valeur » débordent, ce qui
/// n'arrive pas sur un appareil. On ignore ces seuls débordements, le reste
/// des erreurs fait toujours échouer le test.
void _ignoreTestFontOverflows() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _pumpSuccessScreen(
  WidgetTester tester, {
  Map<String, dynamic>? accountImpact,
}) async {
  _ignoreTestFontOverflows();
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(412, 915) * 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider<BalanceProvider>(
      create: (_) => _FakeBalanceProvider(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            ResponsiveSize.init(context);
            return TopUpRechargeSuccessScreen(
              amount: 500,
              mobileNumber: '25377000000',
              fixedNumber: '25321000000',
              transactionId: 'tx-1',
              accountImpact: accountImpact,
            );
          },
        ),
      ),
    ),
  );
  // Pas de pumpAndSettle : le compte à rebours de redirection tourne.
  await tester.pump(const Duration(milliseconds: 1500));
}

Future<void> _tapNewRecharge(WidgetTester tester) async {
  final button = find.text(
    lookupAppLocalizations(const Locale('en')).newRecharge,
  );
  // Le bouton est en bas d'un contenu défilant.
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  // Le compte à rebours est annulé et le formulaire n'anime rien en boucle :
  // l'écran finit par se stabiliser.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('« Nouvelle recharge » rouvre le formulaire, solde du serveur', (
    tester,
  ) async {
    await _pumpSuccessScreen(
      tester,
      accountImpact: {'mobile_balance_after': 2500, 'fixed_balance_after': 800},
    );

    await _tapNewRecharge(tester);

    final form = tester.widget<TopUpRechargeScreen>(
      find.byType(TopUpRechargeScreen),
    );
    expect(form.fixedNumber, '25321000000');
    expect(form.mobileNumber, '25377000000');
    expect(form.soldeActuel, 2500);
    expect(find.byType(TopUpRechargeSuccessScreen), findsNothing);
  });

  testWidgets('sans account_impact : solde du BalanceProvider', (tester) async {
    await _pumpSuccessScreen(tester);

    await _tapNewRecharge(tester);

    final form = tester.widget<TopUpRechargeScreen>(
      find.byType(TopUpRechargeScreen),
    );
    expect(form.soldeActuel, 1234);
  });

  testWidgets('le compte à rebours ne renvoie pas à l\'accueil ensuite', (
    tester,
  ) async {
    await _pumpSuccessScreen(tester);

    await _tapNewRecharge(tester);
    // Bien au-delà des 5 s du compte à rebours.
    await tester.pump(const Duration(seconds: 10));

    expect(find.byType(TopUpRechargeScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
  });
}
