import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Rappel à envoyer avant l'expiration d'un forfait.
class ForfaitReminder {
  final int id;
  final tz.TZDateTime at;
  final String forfaitName;
  final tz.TZDateTime expiresAt;

  /// Délai « théorique » avant l'expiration (24 h, 3 h, 1 h, 30 min, 10 min) :
  /// le rappel peut partir plus tôt si l'heure tombe la nuit.
  final Duration lead;

  const ForfaitReminder({
    required this.id,
    required this.at,
    required this.forfaitName,
    required this.expiresAt,
    required this.lead,
  });

  /// Rappel de dernière minute (1 h ou moins avant) : le ton est plus pressant.
  bool get isFinal => lead <= ForfaitReminderPlanner.finalWithin;
}

/// Calcule les rappels d'expiration à programmer. Fonction pure : aucune
/// notification n'est envoyée ici, voir `ForfaitReminderService`.
///
/// - Tous les forfaits sont suivis, quel que soit leur type ou ce qu'il leur
///   reste. L'utilisateur peut couper le rappel d'un forfait (voir
///   `overrides`) ;
/// - plusieurs rappels par forfait, voir [leadTimes] ;
/// - jamais la nuit : un rappel qui tomberait entre [quietFromHour] et
///   [quietUntilHour] part la veille au soir ;
/// - le texte dit ce qui est en jeu (voir [message]).
class ForfaitReminderPlanner {
  /// Délais avant l'expiration auxquels l'utilisateur est prévenu, du plus
  /// éloigné au plus proche. Le plus proche sert aux forfaits découverts tard :
  /// un forfait qui expire dans 20 min n'aurait sinon aucun rappel.
  static const leadTimes = [
    Duration(hours: 24),
    Duration(hours: 3),
    Duration(hours: 1),
    Duration(minutes: 30),
    Duration(minutes: 10),
  ];

  /// À partir de ce délai, le rappel est « final » (voir
  /// `ForfaitReminder.isFinal`).
  static const finalWithin = Duration(hours: 1);

  /// Plage d'identifiants de notification réservée aux rappels. Les autres
  /// notifications locales ont pour identifiant un horodatage en secondes
  /// (> 1 milliard) : la plage ne peut pas les recouper, ce qui permet
  /// d'annuler « tous les rappels » sans retenir leurs identifiants.
  static const idBase = 7000000;
  static const idEnd = 8000000;

  /// iOS garde au plus 64 notifications en attente, toutes sources confondues :
  /// on s'en tient aux plus proches.
  static const maxReminders = 40;

  /// Heures (de Djibouti) pendant lesquelles on ne notifie pas. Un rappel qui y
  /// tombe est avancé à 21 h 30 la veille au soir.
  static const quietFromHour = 22;
  static const quietUntilHour = 7;

  // Les dates du serveur sont à l'heure de Djibouti, quel que soit le fuseau de
  // l'appareil : un voyageur doit être prévenu à l'heure réelle d'expiration.
  static const _locationName = 'Africa/Djibouti';
  static final _serverFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final _displayFormat = DateFormat('dd/MM/yyyy HH:mm');

  static bool _tzReady = false;

  static tz.Location get location {
    if (!_tzReady) {
      tz_data.initializeTimeZones();
      _tzReady = true;
    }
    return tz.getLocation(_locationName);
  }

  /// Lit `date_fin` ("15/05/2025 19:04:28", heure de Djibouti). Renvoie null
  /// si le format n'est pas reconnu.
  static tz.TZDateTime? parseExpiry(String dateFin) {
    try {
      final d = _serverFormat.parseStrict(dateFin.trim());
      return tz.TZDateTime(
        location,
        d.year,
        d.month,
        d.day,
        d.hour,
        d.minute,
        d.second,
      );
    } on FormatException {
      return null;
    }
  }

  /// Le rappel est-il actif pour ce forfait ? Actif par défaut ; le choix de
  /// l'utilisateur ([overrides], par produit) l'emporte. Sert aussi à l'état de
  /// la cloche.
  static bool isEnabled(ForfaitActif2 forfait, Map<int, bool> overrides) =>
      overrides[forfait.produitId] ?? true;

  /// Rappels à programmer pour [forfaits], triés par date.
  ///
  /// [overrides] : choix explicite par produit (`produitId` → actif ou non).
  static List<ForfaitReminder> plan(
    Iterable<ForfaitActif2> forfaits, {
    Map<int, bool> overrides = const {},
    tz.TZDateTime? now,
  }) {
    final current = now ?? tz.TZDateTime.now(location);

    final due = <ForfaitReminder>[];
    for (final forfait in forfaits) {
      if (!isEnabled(forfait, overrides)) continue;
      final expiresAt = parseExpiry(forfait.dateFin);
      if (expiresAt == null) continue;

      final sentAt = <int>{};
      for (final lead in leadTimes) {
        final at = _outsideQuietHours(expiresAt.subtract(lead));
        // Passé, ou décalé avant maintenant : l'utilisateur est dans l'app à ce
        // moment-là, on ne le dérange pas.
        if (!at.isAfter(current)) continue;
        // Plusieurs rappels ramenés à la même heure par la nuit : un seul part
        // (le plus éloigné, puisque [leadTimes] va du plus loin au plus près).
        if (!sentAt.add(at.millisecondsSinceEpoch)) continue;
        due.add(
          ForfaitReminder(
            id: 0,
            at: at,
            forfaitName: forfait.nom,
            expiresAt: expiresAt,
            lead: lead,
          ),
        );
      }
    }

    due.sort((a, b) => a.at.compareTo(b.at));
    return [
      for (var i = 0; i < due.length && i < maxReminders; i++)
        ForfaitReminder(
          id: idBase + i,
          at: due[i].at,
          forfaitName: due[i].forfaitName,
          expiresAt: due[i].expiresAt,
          lead: due[i].lead,
        ),
    ];
  }

  /// Avance à 21 h 30 la veille au soir un instant tombant dans la nuit.
  static tz.TZDateTime _outsideQuietHours(tz.TZDateTime at) {
    if (at.hour >= quietUntilHour && at.hour < quietFromHour) return at;
    final evening =
        at.hour >= quietFromHour ? at : at.subtract(const Duration(days: 1));
    return tz.TZDateTime(
      location,
      evening.year,
      evening.month,
      evening.day,
      21,
      30,
    );
  }

  /// Titre et texte de [reminder] dans la langue de [l10n]. Le titre est plus
  /// pressant pour les rappels de dernière minute ; le texte dit seulement quel
  /// forfait expire, et quand.
  static ({String title, String body}) message(
    AppLocalizations l10n,
    ForfaitReminder reminder,
  ) {
    return (
      title:
          reminder.isFinal
              ? l10n.forfaitReminderTitleFinal
              : l10n.forfaitReminderTitle,
      body: l10n.forfaitReminderBody(
        reminder.forfaitName,
        _displayFormat.format(reminder.expiresAt),
      ),
    );
  }
}
