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

  /// Délai « théorique » avant l'expiration (24 h, 3 h) : le rappel peut partir
  /// plus tôt si l'heure tombe la nuit.
  final Duration lead;

  /// Le forfait donne accès à internet : après son expiration, la connexion est
  /// décomptée du crédit.
  final bool hasData;

  /// Données restantes, lisibles ("120,0 Mo"). Null s'il n'en reste pas ou si
  /// le forfait n'a pas d'internet.
  final String? dataLeft;

  const ForfaitReminder({
    required this.id,
    required this.at,
    required this.forfaitName,
    required this.expiresAt,
    required this.lead,
    required this.hasData,
    required this.dataLeft,
  });

  /// Dernier rappel avant l'expiration : le ton est plus pressant.
  bool get isFinal => lead == ForfaitReminderPlanner.leadTimes.last;
}

/// Ce qu'un forfait donne à consommer : un forfait n'en couvre un autre que s'il
/// fournit le même service.
enum _Service { data, voice }

/// Calcule les rappels d'expiration à programmer. Fonction pure : aucune
/// notification n'est envoyée ici, voir `ForfaitReminderService`.
///
/// Un rappel « intelligent » ne dérange que lorsqu'il sert :
/// - par défaut, seuls les forfaits avec internet ou avec appels/SMS sont
///   suivis : c'est leur expiration qui fait fondre le crédit. L'utilisateur
///   peut en décider autrement forfait par forfait (voir `overrides`) ;
/// - par défaut aussi, pas de rappel si l'utilisateur a un autre forfait du
///   même type qui dure plus longtemps : un forfait internet est couvert par un
///   autre forfait internet, un forfait d'appels/SMS par un autre forfait
///   d'appels/SMS. Un forfait d'un autre type ne couvre rien. Le rappel viendra
///   avec le dernier forfait de chaque type à expirer. Pas de rappel non plus
///   si le forfait est déjà épuisé (le crédit est déjà entamé : un rappel
///   d'expiration n'apprendrait rien) ;
/// - jamais la nuit : un rappel qui tomberait entre [quietFromHour] et
///   [quietUntilHour] part la veille au soir ;
/// - le texte dit ce qui est en jeu (voir [message]).
class ForfaitReminderPlanner {
  /// Délais avant l'expiration auxquels l'utilisateur est prévenu.
  static const leadTimes = [Duration(hours: 24), Duration(hours: 3)];

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

  /// Le forfait donne accès à internet.
  static bool hasData(ForfaitActif2 forfait) => forfait.dataCompteur != null;

  /// Le forfait comprend des appels ou des SMS.
  static bool hasVoice(ForfaitActif2 forfait) =>
      forfait.minutesCompteur != null || forfait.smsCompteur != null;

  /// Le rappel est-il actif pour ce forfait ? Le choix de l'utilisateur
  /// ([overrides], par produit) l'emporte ; sinon, actif pour les forfaits avec
  /// internet ou avec appels/SMS. Sert aussi à l'état de la cloche.
  static bool isEnabled(ForfaitActif2 forfait, Map<int, bool> overrides) =>
      overrides[forfait.produitId] ?? (hasData(forfait) || hasVoice(forfait));

  /// Rappels à programmer pour [forfaits], triés par date.
  ///
  /// [overrides] : choix explicite par produit (`produitId` → actif ou non).
  /// Un « oui » explicite est honoré tel quel, sans les filtres ci-dessus.
  static List<ForfaitReminder> plan(
    Iterable<ForfaitActif2> forfaits, {
    Map<int, bool> overrides = const {},
    tz.TZDateTime? now,
  }) {
    final current = now ?? tz.TZDateTime.now(location);

    final known = <({ForfaitActif2 forfait, tz.TZDateTime expiresAt})>[];
    for (final forfait in forfaits) {
      final expiresAt = parseExpiry(forfait.dateFin);
      if (expiresAt == null) continue;
      known.add((forfait: forfait, expiresAt: expiresAt));
    }

    final due = <ForfaitReminder>[];
    for (final item in known) {
      final forfait = item.forfait;
      final explicit = overrides[forfait.produitId];
      if (explicit == false) continue;
      if (explicit == null && !_worthWarning(item, known)) continue;

      final data = forfait.dataCompteur;
      for (final lead in leadTimes) {
        final at = _outsideQuietHours(item.expiresAt.subtract(lead));
        // Passé, ou décalé avant maintenant : l'utilisateur est dans l'app à ce
        // moment-là, on ne le dérange pas.
        if (!at.isAfter(current)) continue;
        due.add(
          ForfaitReminder(
            id: 0,
            at: at,
            forfaitName: forfait.nom,
            expiresAt: item.expiresAt,
            lead: lead,
            hasData: data != null,
            dataLeft:
                data != null && data.valeurRestante > 0 ? data.vrLisible : null,
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
          hasData: due[i].hasData,
          dataLeft: due[i].dataLeft,
        ),
    ];
  }

  /// Vrai si l'expiration de [item] laisserait l'utilisateur sans l'un des
  /// services qu'il lui reste à consommer (internet, appels/SMS) : aucun autre
  /// forfait fournissant ce service ne dure plus longtemps.
  ///
  /// « Valide » se juge à l'heure de l'expiration de [item], pas à l'heure
  /// actuelle : un forfait qui expire avant ne couvre rien. Sinon, avec deux
  /// forfaits, aucun des deux ne déclencherait de rappel.
  static bool _worthWarning(
    ({ForfaitActif2 forfait, tz.TZDateTime expiresAt}) item,
    List<({ForfaitActif2 forfait, tz.TZDateTime expiresAt})> all,
  ) {
    return _remaining(item.forfait).any(
      (service) =>
          !all.any(
            (other) =>
                !identical(other.forfait, item.forfait) &&
                other.expiresAt.isAfter(item.expiresAt) &&
                _provided(other.forfait).contains(service),
          ),
    );
  }

  /// Services que fournit [forfait], épuisés ou non. Un forfait mixte (internet
  /// et appels) en fournit deux.
  static Set<_Service> _provided(ForfaitActif2 forfait) => {
    if (hasData(forfait)) _Service.data,
    if (hasVoice(forfait)) _Service.voice,
  };

  /// Services de [forfait] dont il reste quelque chose à consommer.
  static Set<_Service> _remaining(ForfaitActif2 forfait) => {
    if ((forfait.dataCompteur?.valeurRestante ?? 0) > 0) _Service.data,
    if ((forfait.minutesCompteur?.valeurRestante ?? 0) > 0 ||
        (forfait.smsCompteur?.valeurRestante ?? 0) > 0)
      _Service.voice,
  };

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

  /// Titre et texte de [reminder] dans la langue de [l10n]. Le premier rappel
  /// donne ce qu'il reste ; le dernier dit ce qui se passe sans nouveau forfait.
  static ({String title, String body}) message(
    AppLocalizations l10n,
    ForfaitReminder reminder,
  ) {
    final name = reminder.forfaitName;
    final date = _displayFormat.format(reminder.expiresAt);

    if (reminder.isFinal) {
      return (
        title: l10n.forfaitReminderTitleFinal,
        body:
            reminder.hasData
                ? l10n.forfaitReminderFinalData(name, date)
                : l10n.forfaitReminderFinal(name, date),
      );
    }
    final left = reminder.dataLeft;
    return (
      title: l10n.forfaitReminderTitle,
      body:
          left != null
              ? l10n.forfaitReminderEarlyData(name, date, left)
              : l10n.forfaitReminderEarly(name, date),
    );
  }
}
