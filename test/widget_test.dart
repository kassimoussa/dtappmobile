import 'package:dtservices/main.dart';
import 'package:dtservices/providers/auth_provider.dart';
import 'package:dtservices/providers/balance_provider.dart';
import 'package:dtservices/providers/language_provider.dart';
import 'package:dtservices/providers/topup_provider.dart';
import 'package:dtservices/providers/transaction_provider.dart';
import 'package:dtservices/screens/auth/splash_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remplace les plugins que MyApp touche au démarrage : sans eux, leurs appels
/// natifs lèvent MissingPluginException dans l'environnement de test.
///
/// permission_handler n'est volontairement pas simulé : l'app ne demande
/// aucune permission au démarrage (l'OTP passe par SMS Retriever, sans
/// permission). Si un appel y était réintroduit, MissingPluginException ferait
/// échouer ce test.
void _mockStartupPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // connectivity_plus : état initial « wifi » puis flux sans événement.
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/connectivity'),
    (call) async => ['wifi'],
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
    (call) async => null,
  );

  addTearDown(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      null,
    );
  });
}

void main() {
  testWidgets('l\'app démarre sur le splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    _mockStartupPlugins();
    // L'app est en portrait uniquement : la fenêtre de test par défaut
    // (800x600, paysage) ferait déborder le splash.
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(412, 915) * 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => BalanceProvider()),
          ChangeNotifierProvider(create: (_) => TopUpProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // Le splash programme des délais (jusqu'à 5 s) : on les laisse expirer,
    // un timer encore en attente à la fin ferait échouer le test.
    await tester.pump(const Duration(seconds: 6));
  });
}
