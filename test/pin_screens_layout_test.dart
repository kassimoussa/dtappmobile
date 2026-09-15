import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/providers/auth_provider.dart';
import 'package:dtservices/screens/auth/pin/change_pin_screen.dart';
import 'package:dtservices/screens/auth/pin/pin_login_screen.dart';
import 'package:dtservices/screens/auth/pin/pin_setup_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/pin_verification_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Écrans testés : taille logique, marges système haut/bas (dp).
const _devices = <String, (Size, double, double)>{
  'petit Android 360x640': (Size(360, 640), 24, 48),
  'iPhone SE 375x667': (Size(375, 667), 20, 0),
  'iPhone X 375x812': (Size(375, 812), 44, 34),
  'Pixel 412x915': (Size(412, 915), 24, 24),
};

Future<void> _pumpOn(
  WidgetTester tester,
  (Size, double, double) device,
  Widget home,
) async {
  final (size, top, bottom) = device;
  const ratio = 2.0;
  tester.view.devicePixelRatio = ratio;
  tester.view.physicalSize = size * ratio;
  tester.view.padding = FakeViewPadding(
    top: top * ratio,
    bottom: bottom * ratio,
  );
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        locale: const Locale('fr'),
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
            return home;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Le clavier doit être entièrement visible, au-dessus de la barre système,
/// sans avoir à faire défiler l'écran.
void _expectKeyboardVisible(
  WidgetTester tester,
  (Size, double, double) device,
) {
  final (size, _, bottom) = device;
  final visibleBottom = size.height - bottom;

  for (final key in [
    find.text('1'),
    find.text('0'),
    find.byIcon(Icons.backspace_outlined),
  ]) {
    final rect = tester.getRect(key);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(visibleBottom));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in _devices.entries) {
    group(entry.key, () {
      testWidgets('création du PIN', (tester) async {
        await _pumpOn(tester, entry.value, PinSetupScreen(onPinSet: () {}));
        _expectKeyboardVisible(tester, entry.value);
      });

      testWidgets('connexion par PIN', (tester) async {
        await _pumpOn(
          tester,
          entry.value,
          const PinLoginScreen(phoneNumber: '77 12 34 56'),
        );
        _expectKeyboardVisible(tester, entry.value);
        final (size, _, bottom) = entry.value;
        final forgot = tester.getRect(find.byType(TextButton));
        expect(forgot.bottom, lessThanOrEqualTo(size.height - bottom));
      });

      testWidgets('modification du PIN', (tester) async {
        await _pumpOn(tester, entry.value, const ChangePinScreen());
        _expectKeyboardVisible(tester, entry.value);
      });

      testWidgets('vérification du PIN (bottom sheet)', (tester) async {
        await _pumpOn(
          tester,
          entry.value,
          Builder(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed:
                          () => PinVerificationBottomSheet.show(
                            context,
                            phoneNumber: '77123456',
                            title: 'Confirmez votre code PIN',
                            message:
                                'Saisissez votre code pour valider le transfert',
                          ),
                      child: const Text('ouvrir'),
                    ),
                  ),
                ),
          ),
        );
        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        _expectKeyboardVisible(tester, entry.value);
      });
    });
  }
}
