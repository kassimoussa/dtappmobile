import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/providers/topup_provider.dart';
import 'package:dtservices/screens/core/home_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/banner_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Écrans testés : taille logique, marges système haut/bas (dp).
const _devices = <String, (Size, double, double)>{
  'petit Android 360x640': (Size(360, 640), 24, 24),
  'iPhone SE 375x667': (Size(375, 667), 20, 0),
  'Android 16:9 411x731': (Size(411, 731), 24, 24),
  'iPhone X 375x812': (Size(375, 812), 44, 34),
  'Pixel 412x915': (Size(412, 915), 24, 24),
};

/// Hauteur de la bannière une fois chargée (voir BannerSlider). En test les
/// bannières ne se chargent pas : on vérifie la place qu'elle occupera.
double get _bannerHeight => ResponsiveSize.getHeight(100);

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

/// Réplique de la barre de navigation de MainScreen (même hauteur)
Widget _navigationBar() {
  BottomNavigationBarItem item(IconData icon, String label, double padding) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(padding)),
        child: Icon(icon, size: ResponsiveSize.getFontSize(26)),
      ),
      label: label,
    );
  }

  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: ResponsiveSize.getFontSize(12),
    ),
    unselectedLabelStyle: TextStyle(fontSize: ResponsiveSize.getFontSize(11)),
    items: [
      item(Icons.home, 'Accueil', 8),
      item(Icons.history, 'Historique', 4),
      item(Icons.phone, 'Ma ligne', 4),
    ],
  );
}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Outfit', [
      'assets/fonts/Outfit-Regular.ttf',
      'assets/fonts/Outfit-Medium.ttf',
      'assets/fonts/Outfit-SemiBold.ttf',
      'assets/fonts/Outfit-Bold.ttf',
    ]);
  });

  for (final entry in _devices.entries) {
    testWidgets('${entry.key} : la bannière reste au-dessus de la navigation', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'user_phone_number': '77615516',
        'last_activity_time': DateTime.now().millisecondsSinceEpoch,
      });

      final (size, top, bottom) = entry.value;
      const ratio = 2.0;
      final insets = FakeViewPadding(top: top * ratio, bottom: bottom * ratio);
      tester.view.devicePixelRatio = ratio;
      tester.view.physicalSize = size * ratio;
      tester.view.padding = insets;
      tester.view.viewPadding = insets;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => BalanceProvider()),
            ChangeNotifierProvider(create: (_) => TopUpProvider()),
          ],
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Inter'),
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
                return Scaffold(
                  body: const HomeScreen(),
                  bottomNavigationBar: _navigationBar(),
                );
              },
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final navigationTop =
          tester.getRect(find.byType(BottomNavigationBar)).top;
      final bannerTop = tester.getRect(find.byType(BannerSlider)).top;
      expect(bannerTop + _bannerHeight, lessThanOrEqualTo(navigationTop));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    });
  }
}
