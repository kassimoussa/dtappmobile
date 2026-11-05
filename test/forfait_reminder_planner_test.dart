import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:dtservices/services/forfait_reminder_planner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// [dataLeft] : octets restants du compteur internet ; null = forfait sans
/// internet. [voiceLeft] : secondes restantes des compteurs minutes et SMS ;
/// null = forfait sans appels ni SMS.
ForfaitActif2 _forfait(
  String nom,
  String dateFin, {
  int produitId = 1,
  int? dataLeft = 200 * 1024 * 1024,
  int? voiceLeft,
}) => ForfaitActif2(
  id: produitId,
  offreId: produitId,
  nom: nom,
  type: 1,
  typeTexte: 'Internet',
  etat: 1,
  etatTexte: 'Actif',
  produitId: produitId,
  dateDebut: '01/11/2026 08:00:00',
  dateFin: dateFin,
  compteurs: [
    if (dataLeft != null)
      Compteur(
        id: 101, // un compteur dont l'id finit par 01 est l'internet
        valeurUtilisee: 0,
        vuLisible: '0 o',
        valeurRestante: dataLeft,
        vrLisible: dataLeft == 0 ? '0 o' : '200,0 Mo',
        seuils: 200 * 1024 * 1024,
        seuilsLisible: '200,0 Mo',
      ),
    if (voiceLeft != null)
      for (final id in [104, 105]) // minutes (04) et SMS (05)
        Compteur(
          id: id,
          valeurUtilisee: 0,
          vuLisible: '0',
          valeurRestante: voiceLeft,
          vrLisible: '$voiceLeft',
          seuils: 600,
          seuilsLisible: '600',
        ),
  ],
);

tz.TZDateTime _at(int day, int hour, [int minute = 0, int month = 11]) =>
    tz.TZDateTime(
      ForfaitReminderPlanner.location,
      2026,
      month,
      day,
      hour,
      minute,
    );

void main() {
  // 5 novembre 2026, 10:00 à Djibouti.
  tz.TZDateTime now() => _at(5, 10);

  group('parseExpiry', () {
    test('lit la date du serveur comme une heure de Djibouti (UTC+3)', () {
      final expiry = ForfaitReminderPlanner.parseExpiry('12/11/2026 15:47:00');

      expect(expiry, isNotNull);
      expect(expiry!.toUtc(), DateTime.utc(2026, 11, 12, 12, 47));
    });

    test('renvoie null quand le format est inconnu', () {
      expect(ForfaitReminderPlanner.parseExpiry(''), isNull);
      expect(ForfaitReminderPlanner.parseExpiry('2026-11-12'), isNull);
      expect(ForfaitReminderPlanner.parseExpiry('bientôt'), isNull);
    });
  });

  group('quels forfaits', () {
    test(
      "par défaut, les forfaits internet et combo sont suivis, pas les autres",
      () {
        final avecInternet = _forfait('Median', '12/11/2026 15:47:00');
        final combo = _forfait(
          'Combo',
          '12/11/2026 15:47:00',
          dataLeft: null,
          voiceLeft: 600,
        );
        final vide = _forfait('Vide', '12/11/2026 15:47:00', dataLeft: null);

        expect(ForfaitReminderPlanner.isEnabled(avecInternet, {}), isTrue);
        expect(ForfaitReminderPlanner.isEnabled(combo, {}), isTrue);
        expect(ForfaitReminderPlanner.isEnabled(vide, {}), isFalse);
        expect(ForfaitReminderPlanner.plan([combo], now: now()), hasLength(2));
        expect(ForfaitReminderPlanner.plan([vide], now: now()), isEmpty);
      },
    );

    test("le choix de l'utilisateur l'emporte, dans les deux sens", () {
      final avecInternet = _forfait(
        'Median',
        '12/11/2026 15:47:00',
        produitId: 7,
      );
      final sansInternet = _forfait(
        'Voix',
        '12/11/2026 15:47:00',
        produitId: 8,
        dataLeft: null,
      );
      const overrides = {7: false, 8: true};

      expect(
        ForfaitReminderPlanner.isEnabled(avecInternet, overrides),
        isFalse,
      );
      expect(ForfaitReminderPlanner.isEnabled(sansInternet, overrides), isTrue);
      expect(
        ForfaitReminderPlanner.plan(
          [avecInternet, sansInternet],
          overrides: overrides,
          now: now(),
        ).map((r) => r.forfaitName).toSet(),
        {'Voix'},
      );
    });

    test('pas de rappel quand les données sont déjà épuisées', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Median', '12/11/2026 15:47:00', dataLeft: 0),
      ], now: now());

      expect(plan, isEmpty);
    });

    test('un « oui » explicite est honoré même données épuisées', () {
      final plan = ForfaitReminderPlanner.plan(
        [_forfait('Median', '12/11/2026 15:47:00', dataLeft: 0)],
        overrides: const {1: true},
        now: now(),
      );

      expect(plan, hasLength(2));
      expect(plan.first.dataLeft, isNull);
      expect(plan.first.hasData, isTrue);
    });

    test(
      "pas de rappel si un autre forfait avec internet dure plus longtemps",
      () {
        final plan = ForfaitReminderPlanner.plan([
          _forfait('Court', '10/11/2026 15:00:00', produitId: 1),
          _forfait('Long', '20/11/2026 15:00:00', produitId: 2),
        ], now: now());

        expect(plan.map((r) => r.forfaitName).toSet(), {'Long'});
      },
    );

    test("un forfait combo ne couvre pas un forfait internet", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Internet', '10/11/2026 15:00:00', produitId: 1),
        _forfait(
          'Combo',
          '20/11/2026 15:00:00',
          produitId: 2,
          dataLeft: null,
          voiceLeft: 600,
        ),
      ], now: now());

      expect(plan.map((r) => r.forfaitName).toSet(), {'Internet', 'Combo'});
    });

    test("un forfait internet ne couvre pas un forfait combo", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait(
          'Combo',
          '10/11/2026 15:00:00',
          produitId: 1,
          dataLeft: null,
          voiceLeft: 600,
        ),
        _forfait('Internet', '20/11/2026 15:00:00', produitId: 2),
      ], now: now());

      expect(plan.map((r) => r.forfaitName).toSet(), {'Combo', 'Internet'});
    });

    test("un autre forfait combo plus long couvre un forfait combo", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait(
          'Court',
          '10/11/2026 15:00:00',
          produitId: 1,
          dataLeft: null,
          voiceLeft: 600,
        ),
        _forfait(
          'Long',
          '20/11/2026 15:00:00',
          produitId: 2,
          dataLeft: null,
          voiceLeft: 600,
        ),
      ], now: now());

      expect(plan.map((r) => r.forfaitName).toSet(), {'Long'});
    });

    test("un forfait mixte couvre les deux types", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Internet', '10/11/2026 15:00:00', produitId: 1),
        _forfait(
          'Combo',
          '11/11/2026 15:00:00',
          produitId: 2,
          dataLeft: null,
          voiceLeft: 600,
        ),
        _forfait('Mixte', '20/11/2026 15:00:00', produitId: 3, voiceLeft: 600),
      ], now: now());

      expect(plan.map((r) => r.forfaitName).toSet(), {'Mixte'});
    });

    test(
      "un forfait mixte est suivi dès qu'un de ses types n'est pas couvert",
      () {
        final plan = ForfaitReminderPlanner.plan([
          _forfait(
            'Mixte',
            '10/11/2026 15:00:00',
            produitId: 1,
            voiceLeft: 600,
          ),
          _forfait('Internet', '20/11/2026 15:00:00', produitId: 2),
        ], now: now());

        // L'internet est couvert, pas les appels : le rappel reste utile.
        expect(plan.map((r) => r.forfaitName).toSet(), {'Mixte', 'Internet'});
      },
    );

    test("un forfait épuisé ne déclenche pas de rappel combo", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Combo', '10/11/2026 15:00:00', dataLeft: null, voiceLeft: 0),
      ], now: now());

      expect(plan, isEmpty);
    });

    test(
      "un autre forfait du même type suffit, même sans données restantes",
      () {
        final plan = ForfaitReminderPlanner.plan([
          _forfait('Court', '10/11/2026 15:00:00', produitId: 1),
          _forfait('Long', '20/11/2026 15:00:00', produitId: 2, dataLeft: 0),
        ], now: now());

        expect(plan, isEmpty);
      },
    );

    test(
      "un forfait qui expire avant ne couvre pas : le dernier est suivi",
      () {
        final plan = ForfaitReminderPlanner.plan([
          _forfait('Court', '10/11/2026 15:00:00', produitId: 1),
          _forfait('Milieu', '20/11/2026 15:00:00', produitId: 2),
          _forfait('Dernier', '30/11/2026 15:00:00', produitId: 3),
        ], now: now());

        expect(plan.map((r) => r.forfaitName).toSet(), {'Dernier'});
      },
    );

    test('deux forfaits qui expirent ensemble sont suivis tous les deux', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('A', '12/11/2026 15:47:00', produitId: 1),
        _forfait('B', '12/11/2026 15:47:00', produitId: 2),
      ], now: now());

      expect(plan.map((r) => r.forfaitName).toSet(), {'A', 'B'});
    });

    test("un « oui » explicite est honoré même si un autre forfait couvre", () {
      final plan = ForfaitReminderPlanner.plan(
        [
          _forfait('Court', '10/11/2026 15:00:00', produitId: 1),
          _forfait('Long', '20/11/2026 15:00:00', produitId: 2),
        ],
        overrides: const {1: true},
        now: now(),
      );

      expect(plan.where((r) => r.forfaitName == 'Court'), hasLength(2));
    });
  });

  group('quand', () {
    test("prévient 24 h puis 3 h avant l'expiration", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Median', '12/11/2026 15:47:00'),
      ], now: now());

      expect(plan, hasLength(2));
      expect(plan[0].at, _at(11, 15, 47));
      expect(plan[1].at, _at(12, 12, 47));
      expect(plan[0].isFinal, isFalse);
      expect(plan[1].isFinal, isTrue);
    });

    test('ne programme pas un rappel déjà passé', () {
      // Expire dans 10 h : le rappel de 24 h avant est passé, pas celui de 3 h.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Express', '05/11/2026 20:00:00'),
      ], now: now());

      expect(plan, hasLength(1));
      expect(plan.single.at, _at(5, 17));
    });

    test('ne programme rien pour un forfait qui expire dans moins de 3 h', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Express', '05/11/2026 12:00:00'),
      ], now: now());

      expect(plan, isEmpty);
    });

    test('ignore un forfait déjà expiré ou à la date illisible', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Ancien', '01/11/2026 08:00:00', produitId: 1),
        _forfait('Cassé', 'n/a', produitId: 2),
      ], now: now());

      expect(plan, isEmpty);
    });

    test('jamais la nuit : un rappel nocturne part la veille à 21 h 30', () {
      // Expire à 04:00 : 24 h avant = 04:00 (nuit), 3 h avant = 01:00 (nuit).
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Nuit', '12/11/2026 04:00:00'),
      ], now: now());

      expect(plan.map((r) => r.at).toList(), [
        _at(10, 21, 30),
        _at(11, 21, 30),
      ]);
    });

    test('un rappel après 22 h part le soir même à 21 h 30', () {
      // Expire le 13 à 01:30 : 3 h avant = le 12 à 22:30.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Nuit', '13/11/2026 01:30:00'),
      ], now: now());

      expect(plan.last.at, _at(12, 21, 30));
    });

    test("7 h pile reste autorisé, 22 h est déjà la nuit", () {
      final plan = ForfaitReminderPlanner.plan(
        [
          _forfait('Matin', '12/11/2026 10:00:00', produitId: 1),
          _forfait('Soir', '20/11/2026 01:00:00', produitId: 2),
        ],
        overrides: const {1: true, 2: true},
        now: now(),
      );

      expect(plan.map((r) => r.at), contains(_at(12, 7)));
      expect(plan.map((r) => r.at), isNot(contains(_at(19, 22))));
    });

    test("ne dérange pas si le rappel décalé est déjà passé", () {
      // Il est 22:30. Expire à 04:00 le 6 : les deux rappels, ramenés à 21:30,
      // sont derrière nous.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Nuit', '06/11/2026 04:00:00'),
      ], now: _at(5, 22, 30));

      expect(plan, isEmpty);
    });
  });

  group('plan', () {
    test('trie par date et numérote depuis le début de la plage réservée', () {
      final plan = ForfaitReminderPlanner.plan(
        [
          _forfait('Tard', '20/11/2026 10:00:00', produitId: 1),
          _forfait('Tôt', '08/11/2026 10:00:00', produitId: 2),
        ],
        overrides: const {1: true, 2: true},
        now: now(),
      );

      expect(plan.map((r) => r.forfaitName), ['Tôt', 'Tôt', 'Tard', 'Tard']);
      expect(plan.map((r) => r.id), [
        for (var i = 0; i < 4; i++) ForfaitReminderPlanner.idBase + i,
      ]);
      final dates = plan.map((r) => r.at).toList();
      expect(dates, [...dates]..sort());
    });

    test('ne dépasse pas la limite et garde les rappels les plus proches', () {
      final forfaits = [
        for (var day = 1; day <= 28; day++)
          _forfait(
            'F$day',
            '${day.toString().padLeft(2, '0')}/12/2026 10:00:00',
            produitId: day,
          ),
      ];

      final plan = ForfaitReminderPlanner.plan(
        forfaits,
        overrides: {for (var day = 1; day <= 28; day++) day: true},
        now: now(),
      );

      expect(plan, hasLength(ForfaitReminderPlanner.maxReminders));
      expect(plan.first.forfaitName, 'F1');
      expect(plan.last.id, lessThan(ForfaitReminderPlanner.idEnd));
    });
  });

  group('textes', () {
    Future<List<AppLocalizations>> locales() async => [
      await AppLocalizations.delegate.load(const Locale('fr')),
      await AppLocalizations.delegate.load(const Locale('en')),
    ];

    List<ForfaitReminder> plan({int? dataLeft = 200 * 1024 * 1024}) =>
        ForfaitReminderPlanner.plan(
          [_forfait('Median', '12/11/2026 15:47:00', dataLeft: dataLeft)],
          overrides: const {1: true},
          now: now(),
        );

    test("le premier rappel annonce ce qu'il reste", () async {
      final [fr, en] = await locales();
      final early = plan().first;

      expect(
        ForfaitReminderPlanner.message(fr, early).body,
        'Median expire le 12/11/2026 15:47. Il vous reste 200,0 Mo : pensez à le renouveler.',
      );
      expect(
        ForfaitReminderPlanner.message(en, early).body,
        contains('200,0 Mo left'),
      );
    });

    test(
      "le dernier rappel dit que l'internet sera décompté du crédit",
      () async {
        final [fr, en] = await locales();
        final last = plan().last;

        expect(
          ForfaitReminderPlanner.message(fr, last).body,
          contains('crédit'),
        );
        expect(
          ForfaitReminderPlanner.message(en, last).body,
          contains('credit'),
        );
      },
    );

    test(
      "sans internet, aucun propos sur le crédit ni sur les données",
      () async {
        final [fr, _] = await locales();
        final reminders = ForfaitReminderPlanner.plan([
          _forfait(
            'Voix',
            '12/11/2026 15:47:00',
            dataLeft: null,
            voiceLeft: 600,
          ),
        ], now: now());

        for (final r in reminders) {
          final body = ForfaitReminderPlanner.message(fr, r).body;
          expect(body, isNot(contains('crédit')));
          expect(body, isNot(contains('Il vous reste')));
        }
      },
    );

    test('le titre du dernier rappel est plus pressant', () async {
      final [fr, _] = await locales();
      final reminders = plan();

      expect(
        ForfaitReminderPlanner.message(fr, reminders.first).title,
        isNot(ForfaitReminderPlanner.message(fr, reminders.last).title),
      );
    });
  });
}
