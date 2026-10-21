import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/services/app_update_service.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/dialogs/app_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/link.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const _store = 'https://play.google.com/store/apps/details?id=exemple';
final _now = DateTime(2026, 10, 21, 12);

AppUpdate? _evaluate({
  String installed = '1.0.0',
  String? min = '',
  String? latest = '',
  String? storeUrl = _store,
  String? dismissedVersion,
  DateTime? dismissedAt,
}) => AppUpdateService.evaluate(
  installed: installed,
  min: min,
  latest: latest,
  storeUrl: storeUrl,
  dismissedVersion: dismissedVersion,
  dismissedAt: dismissedAt,
  now: _now,
);

/// Remplace url_launcher : mémorise les liens ouverts, sans plugin natif.
class _FakeLauncher extends UrlLauncherPlatform {
  _FakeLauncher({this.succeeds = true});

  final bool succeeds;
  final opened = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => succeeds;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return succeeds;
  }
}

void main() {
  group('parseVersion', () {
    test('lit les formats usuels', () {
      expect(AppUpdateService.parseVersion('1.2.3'), [1, 2, 3]);
      expect(AppUpdateService.parseVersion(' 1.2.3 '), [1, 2, 3]);
      expect(AppUpdateService.parseVersion('1.2.3+45'), [1, 2, 3]);
      expect(AppUpdateService.parseVersion('1.2.3-beta'), [1, 2, 3]);
      expect(AppUpdateService.parseVersion('v1.2'), [1, 2]);
      expect(AppUpdateService.parseVersion('10.0.12'), [10, 0, 12]);
    });

    test('rejette ce qui n\'est pas une version', () {
      for (final raw in [null, '', '  ', 'abc', '1.x.0', '1..2', '-1.0.0']) {
        expect(AppUpdateService.parseVersion(raw), isNull, reason: '$raw');
      }
    });
  });

  group('decide', () {
    AppUpdateKind decide(String installed, {String? min, String? latest}) =>
        AppUpdateService.decide(installed: installed, min: min, latest: latest);

    test('en dessous du minimum : obligatoire', () {
      expect(
        decide('1.0.0', min: '1.1.0', latest: '1.2.0'),
        AppUpdateKind.mandatory,
      );
    });

    test('au-dessus du minimum mais sous la dernière : proposée', () {
      expect(
        decide('1.1.0', min: '1.0.0', latest: '1.2.0'),
        AppUpdateKind.recommended,
      );
    });

    test('à jour : rien', () {
      expect(decide('1.2.0', min: '1.0.0', latest: '1.2.0'), AppUpdateKind.none);
      expect(decide('1.3.0', min: '1.0.0', latest: '1.2.0'), AppUpdateKind.none);
    });

    test('comparaison numérique, pas alphabétique', () {
      expect(decide('1.9.0', min: '1.10.0'), AppUpdateKind.mandatory);
      expect(decide('1.10.0', min: '1.9.0'), AppUpdateKind.none);
    });

    test('une partie absente vaut 0', () {
      expect(decide('1.2.0', min: '1.2'), AppUpdateKind.none);
      expect(decide('1.2', min: '1.2.1'), AppUpdateKind.mandatory);
    });

    test('min = latest force tout le monde', () {
      expect(
        decide('1.0.0', min: '1.1.0', latest: '1.1.0'),
        AppUpdateKind.mandatory,
      );
    });

    test('valeurs vides ou illisibles : on laisse passer (fail-open)', () {
      expect(decide('1.0.0', min: '', latest: ''), AppUpdateKind.none);
      expect(decide('1.0.0', min: 'n/a', latest: null), AppUpdateKind.none);
      expect(decide('inconnue', min: '9.0.0', latest: '9.0.0'), AppUpdateKind.none);
    });

    test('un minimum illisible n\'empêche pas la proposition', () {
      expect(
        decide('1.0.0', min: 'n/a', latest: '1.1.0'),
        AppUpdateKind.recommended,
      );
    });
  });

  group('evaluate', () {
    test('sans lien de store : rien, même pour une version obligatoire', () {
      expect(_evaluate(min: '2.0.0', latest: '2.0.0', storeUrl: null), isNull);
    });

    test('obligatoire : renvoie le lien et les nouveautés', () {
      final update = AppUpdateService.evaluate(
        installed: '1.0.0',
        min: '1.1.0',
        latest: '1.2.0',
        storeUrl: _store,
        notes: '  Corrections.  ',
        now: _now,
      );
      expect(update?.kind, AppUpdateKind.mandatory);
      expect(update?.storeUrl, _store);
      expect(update?.latestVersion, '1.2.0');
      expect(update?.notes, 'Corrections.');
    });

    test('proposée repoussée il y a peu : pas redemandée', () {
      expect(
        _evaluate(
          latest: '1.1.0',
          dismissedVersion: '1.1.0',
          dismissedAt: _now.subtract(const Duration(days: 1)),
        ),
        isNull,
      );
    });

    test('proposée repoussée il y a plus de 3 jours : redemandée', () {
      expect(
        _evaluate(
          latest: '1.1.0',
          dismissedVersion: '1.1.0',
          dismissedAt: _now.subtract(const Duration(days: 4)),
        )?.kind,
        AppUpdateKind.recommended,
      );
    });

    test('une version plus récente est proposée sans attendre', () {
      expect(
        _evaluate(
          latest: '1.2.0',
          dismissedVersion: '1.1.0',
          dismissedAt: _now.subtract(const Duration(hours: 1)),
        )?.kind,
        AppUpdateKind.recommended,
      );
    });

    test('un report ne dispense jamais d\'une mise à jour obligatoire', () {
      expect(
        _evaluate(
          min: '1.1.0',
          latest: '1.1.0',
          dismissedVersion: '1.1.0',
          dismissedAt: _now.subtract(const Duration(hours: 1)),
        )?.kind,
        AppUpdateKind.mandatory,
      );
    });
  });

  group('dialogue', () {
    late _FakeLauncher launcher;

    Future<void> openDialog(
      WidgetTester tester,
      AppUpdate update, {
      bool launchSucceeds = true,
      void Function()? onClosed,
    }) async {
      SharedPreferences.setMockInitialValues({});
      launcher = _FakeLauncher(succeeds: launchSucceeds);
      UrlLauncherPlatform.instance = launcher;

      await tester.pumpWidget(
        MaterialApp(
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
              return Scaffold(
                body: TextButton(
                  onPressed:
                      () => AppUpdateDialog.show(
                        context,
                        update,
                      ).then((_) => onClosed?.call()),
                  child: const Text('ouvrir'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
    }

    const mandatory = AppUpdate(
      kind: AppUpdateKind.mandatory,
      latestVersion: '1.2.0',
      storeUrl: _store,
    );
    const recommended = AppUpdate(
      kind: AppUpdateKind.recommended,
      latestVersion: '1.2.0',
      storeUrl: _store,
      notes: 'Nouveau tableau de bord.',
    );

    testWidgets('obligatoire : pas de « Later », retour sans effet', (
      tester,
    ) async {
      var closed = false;
      await openDialog(tester, mandatory, onClosed: () => closed = true);

      expect(find.text('Update required'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(find.text('Later'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Update required'), findsOneWidget);
      expect(closed, isFalse);
    });

    testWidgets('obligatoire : « Update » ouvre le store et reste bloqué', (
      tester,
    ) async {
      var closed = false;
      await openDialog(tester, mandatory, onClosed: () => closed = true);

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(launcher.opened, [_store]);
      expect(find.text('Update required'), findsOneWidget);
      expect(closed, isFalse);
    });

    testWidgets('obligatoire : lien inutilisable → message, toujours bloqué', (
      tester,
    ) async {
      await openDialog(tester, mandatory, launchSucceeds: false);

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(
        find.text(lookupAppLocalizations(const Locale('en')).linkError),
        findsOneWidget,
      );
      expect(find.text('Update required'), findsOneWidget);
    });

    testWidgets('proposée : affiche les nouveautés ; « Later » mémorise', (
      tester,
    ) async {
      var closed = false;
      await openDialog(tester, recommended, onClosed: () => closed = true);

      expect(find.text('New version available'), findsOneWidget);
      expect(find.text('Nouveau tableau de bord.'), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(launcher.opened, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_update_dismissed_version'), '1.2.0');
      expect(prefs.getInt('app_update_dismissed_at'), isNotNull);
    });

    testWidgets('proposée : le retour vaut « Later »', (tester) async {
      var closed = false;
      await openDialog(tester, recommended, onClosed: () => closed = true);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_update_dismissed_version'), '1.2.0');
    });

    testWidgets('proposée : « Update » ouvre le store sans mémoriser de report', (
      tester,
    ) async {
      var closed = false;
      await openDialog(tester, recommended, onClosed: () => closed = true);

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(launcher.opened, [_store]);
      expect(closed, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_update_dismissed_version'), isNull);
    });
  });
}
