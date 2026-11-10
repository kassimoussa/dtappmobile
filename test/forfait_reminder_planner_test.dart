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
      "tous les forfaits sont suivis par défaut, quel que soit leur type",
      () {
        final forfaits = [
          _forfait('Internet', '12/11/2026 15:47:00', produitId: 1),
          _forfait(
            'Combo',
            '12/11/2026 15:47:00',
            produitId: 2,
            dataLeft: null,
            voiceLeft: 600,
          ),
          _forfait(
            'Mixte',
            '12/11/2026 15:47:00',
            produitId: 3,
            voiceLeft: 600,
          ),
          _forfait(
            'Sans compteur',
            '12/11/2026 15:47:00',
            produitId: 4,
            dataLeft: null,
          ),
          _forfait('Épuisé', '12/11/2026 15:47:00', produitId: 5, dataLeft: 0),
        ];

        for (final forfait in forfaits) {
          expect(ForfaitReminderPlanner.isEnabled(forfait, {}), isTrue);
          expect(
            ForfaitReminderPlanner.plan([forfait], now: now()),
            hasLength(ForfaitReminderPlanner.leadTimes.length),
            reason: forfait.nom,
          );
        }
      },
    );

    test("un autre forfait valide ne supprime pas le rappel", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Court', '10/11/2026 15:00:00', produitId: 1),
        _forfait('Long', '20/11/2026 15:00:00', produitId: 2),
        _forfait(
          'Combo',
          '25/11/2026 15:00:00',
          produitId: 3,
          dataLeft: null,
          voiceLeft: 600,
        ),
      ], now: now());

      expect(plan.map((r) => r.forfaitName).toSet(), {
        'Court',
        'Long',
        'Combo',
      });
    });

    test('deux forfaits qui expirent ensemble sont suivis tous les deux', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('A', '12/11/2026 15:47:00', produitId: 1),
        _forfait('B', '12/11/2026 15:47:00', produitId: 2),
      ], now: now());

      expect(plan.map((r) => r.forfaitName).toSet(), {'A', 'B'});
    });

    test("l'utilisateur peut couper le rappel d'un forfait", () {
      final plan = ForfaitReminderPlanner.plan(
        [
          _forfait('Median', '12/11/2026 15:47:00', produitId: 7),
          _forfait('Express', '12/11/2026 15:47:00', produitId: 8),
        ],
        overrides: const {7: false},
        now: now(),
      );

      expect(
        ForfaitReminderPlanner.isEnabled(
          _forfait('x', '', produitId: 7),
          const {7: false},
        ),
        isFalse,
      );
      expect(plan.map((r) => r.forfaitName).toSet(), {'Express'});
    });

    test('un forfait épuisé est suivi', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Median', '12/11/2026 15:47:00', dataLeft: 0),
      ], now: now());

      expect(plan, hasLength(ForfaitReminderPlanner.leadTimes.length));
    });
  });

  group('quand', () {
    test("prévient 24 h, 3 h, 1 h, 30 min puis 10 min avant l'expiration", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Median', '12/11/2026 15:47:00'),
      ], now: now());

      expect(plan.map((r) => r.at).toList(), [
        _at(11, 15, 47),
        _at(12, 12, 47),
        _at(12, 14, 47),
        _at(12, 15, 17),
        _at(12, 15, 37),
      ]);
      // Le ton devient pressant à partir de 1 h.
      expect(plan.map((r) => r.isFinal).toList(), [
        false,
        false,
        true,
        true,
        true,
      ]);
    });

    test('ne programme pas un rappel déjà passé', () {
      // Expire dans 10 h : le rappel de 24 h avant est passé.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Express', '05/11/2026 20:00:00'),
      ], now: now());

      expect(plan.map((r) => r.at).toList(), [
        _at(5, 17),
        _at(5, 19),
        _at(5, 19, 30),
        _at(5, 19, 50),
      ]);
    });

    test('un forfait qui expire dans 2 h garde ses derniers rappels', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Express', '05/11/2026 12:00:00'),
      ], now: now());

      expect(plan.map((r) => r.at).toList(), [
        _at(5, 11),
        _at(5, 11, 30),
        _at(5, 11, 50),
      ]);
    });

    test('un forfait qui expire dans 20 min a quand même un rappel', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Express', '05/11/2026 10:20:00'),
      ], now: now());

      expect(plan.map((r) => r.at).toList(), [_at(5, 10, 10)]);
      expect(plan.single.isFinal, isTrue);
    });

    test(
      'ne programme rien pour un forfait qui expire dans moins de 10 min',
      () {
        final plan = ForfaitReminderPlanner.plan([
          _forfait('Express', '05/11/2026 10:08:00'),
        ], now: now());

        expect(plan, isEmpty);
      },
    );

    test('ignore un forfait déjà expiré ou à la date illisible', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Ancien', '01/11/2026 08:00:00', produitId: 1),
        _forfait('Cassé', 'n/a', produitId: 2),
      ], now: now());

      expect(plan, isEmpty);
    });

    test('jamais la nuit : un rappel nocturne part la veille à 21 h 30', () {
      // Expire à 04:00 : 24 h avant, 3 h avant (01:00), 1 h, 30 min et 10 min
      // avant (de 03:00 à 03:50) tombent tous la nuit.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Nuit', '12/11/2026 04:00:00'),
      ], now: now());

      expect(plan.map((r) => r.at).toList(), [
        _at(10, 21, 30),
        _at(11, 21, 30),
      ]);
    });

    test("des rappels ramenés à la même heure par la nuit n'en font qu'un", () {
      // Les rappels de 3 h, 1 h, 30 min et 10 min tombent tous à 21 h 30 le
      // 11 : seul le plus éloigné part.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Nuit', '12/11/2026 04:00:00'),
      ], now: now());

      expect(plan.last.at, _at(11, 21, 30));
      expect(plan.last.lead, const Duration(hours: 3));
      expect(plan.last.isFinal, isFalse);
    });

    test('un rappel après 22 h part le soir même à 21 h 30', () {
      // Expire le 13 à 01:30 : 3 h avant = le 12 à 22:30.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Nuit', '13/11/2026 01:30:00'),
      ], now: now());

      expect(plan.last.at, _at(12, 21, 30));
    });

    test("7 h pile reste autorisé, 22 h est déjà la nuit", () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Matin', '12/11/2026 10:00:00', produitId: 1),
        _forfait('Soir', '20/11/2026 01:00:00', produitId: 2),
      ], now: now());

      expect(plan.map((r) => r.at), contains(_at(12, 7)));
      expect(plan.map((r) => r.at), isNot(contains(_at(19, 22))));
    });

    test("ne dérange pas si le rappel décalé est déjà passé", () {
      // Il est 22:30. Expire à 04:00 le 6 : les rappels, ramenés à 21:30 ou
      // déjà passés, sont derrière nous.
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Nuit', '06/11/2026 04:00:00'),
      ], now: _at(5, 22, 30));

      expect(plan, isEmpty);
    });
  });

  group('plan', () {
    test('trie par date et numérote depuis le début de la plage réservée', () {
      final plan = ForfaitReminderPlanner.plan([
        _forfait('Tard', '20/11/2026 10:00:00', produitId: 1),
        _forfait('Tôt', '09/11/2026 10:00:00', produitId: 2),
      ], now: now());

      expect(plan.map((r) => r.forfaitName), [
        ...List.filled(5, 'Tôt'),
        ...List.filled(5, 'Tard'),
      ]);
      expect(plan.map((r) => r.id), [
        for (var i = 0; i < 10; i++) ForfaitReminderPlanner.idBase + i,
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

      final plan = ForfaitReminderPlanner.plan(forfaits, now: now());

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

    List<ForfaitReminder> plan() => ForfaitReminderPlanner.plan([
      _forfait('Median', '12/11/2026 15:47:00'),
    ], now: now());

    test("le texte dit seulement quel forfait expire, et quand", () async {
      final [fr, en] = await locales();

      for (final r in plan()) {
        expect(
          ForfaitReminderPlanner.message(fr, r).body,
          'Median expire le 12/11/2026 15:47.',
        );
        expect(
          ForfaitReminderPlanner.message(en, r).body,
          'Median expires on 12/11/2026 15:47.',
        );
      }
    });

    test('le titre est plus pressant à partir de 1 h', () async {
      final [fr, _] = await locales();
      final titles = [
        for (final r in plan()) ForfaitReminderPlanner.message(fr, r).title,
      ];

      expect(titles, [
        fr.forfaitReminderTitle,
        fr.forfaitReminderTitle,
        fr.forfaitReminderTitleFinal,
        fr.forfaitReminderTitleFinal,
        fr.forfaitReminderTitleFinal,
      ]);
    });
  });
}
