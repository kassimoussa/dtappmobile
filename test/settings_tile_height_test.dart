import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/providers/auth_provider.dart';
import 'package:dtservices/providers/language_provider.dart';
import 'package:dtservices/screens/auth/pin/pin_management_screen.dart';
import 'package:dtservices/screens/settings/connection_settings_screen.dart';
import 'package:dtservices/screens/settings/language_selection_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biométrie disponible, pour que l'écran de connexion affiche toutes ses
/// lignes sans passer par le plugin natif.
class _FakeLocalAuth extends LocalAuthPlatform {
  @override
  Future<bool> deviceSupportsBiometrics() async => true;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => [
    BiometricType.face,
  ];
}

/// Hauteur des lignes d'une carte de réglages, pour un écran donné.
Future<List<double>> _tileHeights(
  WidgetTester tester,
  Size size,
  TargetPlatform platform,
  Widget screen,
) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = size * 2.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  LocalAuthPlatform.instance = _FakeLocalAuth();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        // Libellés courts : en français, « Changer le code PIN » passe sur
        // deux lignes avec la police de substitution des tests et fausse la
        // mesure.
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
            return screen;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return [
    for (final tile in find.byType(SettingsTile).evaluate())
      tester.getSize(find.byWidget(tile.widget)).height,
  ];
}

void main() {
  const devices = <String, Size>{
    'petit Android 360x640': Size(360, 640),
    'iPhone X 375x812': Size(375, 812),
    'Pixel 412x915': Size(412, 915),
  };

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final MapEntry(key: name, value: size) in devices.entries) {
      testWidgets('lignes de même hauteur : PIN, langue et connexion '
          '($name, ${platform.name})', (tester) async {
        final pin = await _tileHeights(
          tester,
          size,
          platform,
          const PinManagementScreen(),
        );
        final language = await _tileHeights(
          tester,
          size,
          platform,
          const LanguageSelectionScreen(),
        );
        final connection = await _tileHeights(
          tester,
          size,
          platform,
          const ConnectionSettingsScreen(),
        );

        expect(pin, hasLength(2));
        expect(language, hasLength(2));
        expect(connection, hasLength(3));
        expect(
          {
            ...pin,
            ...language,
            ...connection,
          }.map((h) => h.toStringAsFixed(1)).toSet(),
          hasLength(1),
          reason: 'PIN: $pin, langue: $language, connexion: $connection',
        );
      });
    }
  }
}
