import '../generated/l10n/app_localizations.dart';

/// Traduit l'état d'un forfait tel que retourné par l'API (toujours en
/// français) vers la locale active de l'utilisateur.
///
/// Exemples API : "Activée", "Suspendue", "Expirée", "Désactivée",
///               "En attente"
String translateForfaitState(String apiValue, AppLocalizations l10n) {
  final v = apiValue.trim();

  // "Désactivée" avant "Activée" : les deux contiennent "activ"
  if (RegExp(r'^(d[ée]sactiv|inactiv)', caseSensitive: false).hasMatch(v)) {
    return l10n.forfaitStateInactive;
  }

  if (RegExp(r'^activ', caseSensitive: false).hasMatch(v)) {
    return l10n.forfaitStateActive;
  }

  if (RegExp(r'^suspend', caseSensitive: false).hasMatch(v)) {
    return l10n.forfaitStateSuspended;
  }

  if (RegExp(r'^expir', caseSensitive: false).hasMatch(v)) {
    return l10n.forfaitStateExpired;
  }

  if (RegExp(r'^en\s+attente', caseSensitive: false).hasMatch(v)) {
    return l10n.forfaitStatePending;
  }

  // Valeur inconnue → on la retourne telle quelle
  return v;
}
