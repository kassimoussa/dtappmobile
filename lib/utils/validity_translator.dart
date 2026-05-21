import '../generated/l10n/app_localizations.dart';

/// Traduit les labels de validité tels que retournés par l'API (toujours en
/// français) vers la locale active de l'utilisateur.
///
/// Exemples API : "24 Heures", "7 Jours", "30 Jours",
///               "Utilisable du vendredi 07h00 au dimanche 07h00"
String translateValidity(String apiValue, AppLocalizations l10n) {
  final v = apiValue.trim();

  // "N Heures" / "N heure"
  final hoursMatch = RegExp(r'^(\d+)\s*[Hh]eure', caseSensitive: false).firstMatch(v);
  if (hoursMatch != null) {
    final h = int.parse(hoursMatch.group(1)!);
    return l10n.validityHours(h.toString());
  }

  // "N Jours" / "N jour"
  final daysMatch = RegExp(r'^(\d+)\s*[Jj]our', caseSensitive: false).firstMatch(v);
  if (daysMatch != null) {
    final d = int.parse(daysMatch.group(1)!);
    return l10n.validityDays(d);
  }

  // Patterns week-end
  if (RegExp(r'vendredi.*dimanche|week.?end', caseSensitive: false).hasMatch(v)) {
    return l10n.validityWeekendLong;
  }

  // Valeur inconnue → on la retourne telle quelle
  return v;
}
