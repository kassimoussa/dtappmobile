import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/services/recent_recipients_service.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:dtservices/widgets/recent_recipients_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedRecipient _r(
  String number,
  int usedAt, {
  bool fav = false,
  String? name,
}) => SavedRecipient(number: number, usedAt: usedAt, favorite: fav, name: name);

void main() {
  group('RecipientBook.normalize', () {
    test('ramène les écritures usuelles à 8 chiffres', () {
      expect(RecipientBook.normalize('77123456'), '77123456');
      expect(RecipientBook.normalize('77 12 34 56'), '77123456');
      expect(RecipientBook.normalize('+253 77 12 34 56'), '77123456');
      expect(RecipientBook.normalize('25377123456'), '77123456');
    });

    test('refuse ce qui n\'est pas un numéro local', () {
      expect(RecipientBook.normalize(''), isNull);
      expect(RecipientBook.normalize('771234'), isNull);
      expect(RecipientBook.normalize('771234567'), isNull);
      expect(RecipientBook.normalize('abc'), isNull);
    });
  });

  group('RecipientBook', () {
    test('trie les favoris d\'abord, puis du plus récent au plus ancien', () {
      final sorted = RecipientBook.sorted([
        _r('77000001', 10),
        _r('77000002', 30),
        _r('77000003', 5, fav: true),
        _r('77000004', 20, fav: true),
      ]);
      expect(sorted.map((r) => r.number), [
        '77000004',
        '77000003',
        '77000002',
        '77000001',
      ]);
    });

    test('un numéro déjà connu remonte sans doublon et garde son favori', () {
      final list = RecipientBook.record(
        [_r('77000001', 10, fav: true, name: 'Ali'), _r('77000002', 20)],
        '77000001',
        now: 99,
      );
      expect(list, hasLength(2));
      final ali = list.firstWhere((r) => r.number == '77000001');
      expect(ali.usedAt, 99);
      expect(ali.favorite, isTrue);
      expect(ali.name, 'Ali', reason: 'sans nom fourni, l\'ancien est gardé');
    });

    test('un nouveau nom remplace l\'ancien', () {
      final list = RecipientBook.record(
        [_r('77000001', 10, name: 'Ali')],
        '77000001',
        name: ' Ali Hassan ',
        now: 99,
      );
      expect(list.single.name, 'Ali Hassan');
    });

    test(
      'ne garde que ${RecipientBook.maxRecents} récents, les plus récents',
      () {
        var list = <SavedRecipient>[];
        for (var i = 0; i < 12; i++) {
          list = RecipientBook.record(
            list,
            '7700${i.toString().padLeft(4, '0')}',
            now: i,
          );
        }
        expect(list, hasLength(RecipientBook.maxRecents));
        expect(list.first.number, '77000011');
        expect(list.any((r) => r.number == '77000000'), isFalse);
      },
    );

    test('les favoris ne sont pas chassés par les récents', () {
      var list = RecipientBook.record([], '77111111', now: 0);
      list = RecipientBook.setFavorite(list, '77111111', true);
      for (var i = 1; i <= 20; i++) {
        list = RecipientBook.record(
          list,
          '7722${i.toString().padLeft(4, '0')}',
          now: i,
        );
      }
      expect(list.any((r) => r.number == '77111111' && r.favorite), isTrue);
      expect(
        list.where((r) => !r.favorite),
        hasLength(RecipientBook.maxRecents),
      );
    });

    test('retire un destinataire', () {
      final list = RecipientBook.remove([
        _r('77000001', 1),
        _r('77000002', 2),
      ], '77000001');
      expect(list.map((r) => r.number), ['77000002']);
    });
  });

  group('RecentRecipientsService', () {
    const owner = '77999999';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('enregistre puis relit un destinataire', () async {
      await RecentRecipientsService.record('77 12 34 56', owner: owner);
      final list = await RecentRecipientsService.load(owner: owner);
      expect(list.single.number, '77123456');
    });

    test('ignore son propre numéro et les numéros invalides', () async {
      await RecentRecipientsService.record(owner, owner: owner);
      await RecentRecipientsService.record('1234', owner: owner);
      expect(await RecentRecipientsService.load(owner: owner), isEmpty);
    });

    test('la liste est propre à chaque compte', () async {
      await RecentRecipientsService.record('77123456', owner: owner);
      expect(await RecentRecipientsService.load(owner: '77888888'), isEmpty);
    });

    test('le nom du contact n\'est écrit qu\'à l\'enregistrement', () async {
      RecentRecipientsService.noteContactName('+253 77 12 34 56', 'Amina');
      expect(await RecentRecipientsService.load(owner: owner), isEmpty);

      await RecentRecipientsService.record('77123456', owner: owner);
      final list = await RecentRecipientsService.load(owner: owner);
      expect(list.single.name, 'Amina');
    });

    test('favori puis suppression', () async {
      await RecentRecipientsService.record('77123456', owner: owner);
      await RecentRecipientsService.record('77654321', owner: owner);
      await RecentRecipientsService.setFavorite('77123456', true, owner: owner);

      var list = await RecentRecipientsService.load(owner: owner);
      expect(list.first.number, '77123456');
      expect(list.first.favorite, isTrue);

      await RecentRecipientsService.remove('77123456', owner: owner);
      list = await RecentRecipientsService.load(owner: owner);
      expect(list.map((r) => r.number), ['77654321']);
    });

    test('un contenu illisible donne une liste vide, pas une erreur', () async {
      SharedPreferences.setMockInitialValues({
        'recent_recipients_$owner': '{pas du json',
      });
      expect(await RecentRecipientsService.load(owner: owner), isEmpty);

      SharedPreferences.setMockInitialValues({
        'recent_recipients_$owner': '[{"n":"abc"},42,{"n":"77123456","t":5}]',
      });
      final list = await RecentRecipientsService.load(owner: owner);
      expect(list.map((r) => r.number), ['77123456']);
    });
  });

  group('RecentRecipientsBar', () {
    Future<void> pumpBar(
      WidgetTester tester,
      ValueChanged<String> onSelected,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RecentRecipientsBar(onSelected: onSelected)),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await UserSession.createSession('77999999');
    });

    testWidgets('invisible tant que la liste est vide', (tester) async {
      await pumpBar(tester, (_) {});
      expect(find.text('Récents et favoris'), findsNothing);
    });

    testWidgets('toucher un destinataire renvoie son numéro', (tester) async {
      await tester.runAsync(() => RecentRecipientsService.record('77123456'));
      String? picked;
      await pumpBar(tester, (n) => picked = n);

      expect(find.text('Récents et favoris'), findsOneWidget);
      expect(find.text('77 12 34 56'), findsOneWidget);

      await tester.tap(find.text('77 12 34 56'));
      expect(picked, '77123456');
    });

    testWidgets('l\'étoile passe un destinataire en favori', (tester) async {
      await tester.runAsync(() async {
        await RecentRecipientsService.record('77111111');
        // L'ordre se fait à la milliseconde : deux appels collés seraient à égalité.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await RecentRecipientsService.record('77222222');
      });
      await pumpBar(tester, (_) {});

      // Le plus récent (77 22 22 22) est en tête.
      expect(
        tester.getTopLeft(find.text('77 22 22 22')).dx,
        lessThan(tester.getTopLeft(find.text('77 11 11 11')).dx),
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      // Étoile du second chip (77 11 11 11).
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.star_border_rounded).last);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      // Le favori passe devant.
      expect(
        tester.getTopLeft(find.text('77 11 11 11')).dx,
        lessThan(tester.getTopLeft(find.text('77 22 22 22')).dx),
      );
    });
  });
}
