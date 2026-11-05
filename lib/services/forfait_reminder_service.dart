import 'dart:convert';

import 'package:dtservices/firebase/notification_service.dart';
import 'package:dtservices/generated/l10n/app_localizations.dart';
import 'package:dtservices/models/forfait_actif2.dart';
import 'package:dtservices/services/forfait_reminder_planner.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Prévient l'utilisateur avant l'expiration de ses forfaits, par des
/// notifications locales programmées : elles partent même app fermée.
///
/// Quels forfaits et à quel moment : voir [ForfaitReminderPlanner].
///
/// L'app ne connaît l'état des forfaits que lorsqu'elle les charge. Un forfait
/// renouvelé ailleurs (USSD, SMS) ne se voit donc qu'à la synchronisation
/// suivante, d'où l'actualisation périodique ([refreshEvery]).
class ForfaitReminderService {
  static const _kLastSync = 'forfait_reminders_last_sync';
  static const _kOverrides = 'forfait_reminders_overrides';

  /// Au-delà, [isStale] demande une nouvelle synchronisation.
  static const refreshEvery = Duration(hours: 6);

  /// Vrai si les rappels n'ont pas été synchronisés depuis [refreshEvery].
  static Future<bool> isStale() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastSync);
    if (last == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - last;
    return age >= refreshEvery.inMilliseconds;
  }

  /// Choix de l'utilisateur par produit (`produitId` → rappel actif ou non).
  /// Le choix suit le produit, pas l'achat : il survit à un renouvellement.
  static Future<Map<int, bool>> loadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kOverrides);
      if (raw == null) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          if (int.tryParse(e.key) != null && e.value is bool)
            int.parse(e.key): e.value as bool,
      };
    } catch (e) {
      debugPrint("⚠️ Choix de rappels illisibles: $e");
      return {};
    }
  }

  /// Enregistre le choix de l'utilisateur pour un produit, puis reprogramme les
  /// rappels de [forfaits] (la liste actuellement affichée).
  static Future<void> setOverride(
    int produitId,
    bool enabled,
    List<ForfaitActif2> forfaits,
  ) async {
    try {
      final overrides = await loadOverrides();
      overrides[produitId] = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kOverrides,
        jsonEncode({for (final e in overrides.entries) '${e.key}': e.value}),
      );
    } catch (e) {
      debugPrint("⚠️ Choix de rappel non enregistré: $e");
    }
    await sync(forfaits);
  }

  /// Remplace les rappels programmés par ceux de [forfaits], la liste fraîche
  /// renvoyée par le serveur. Ne lève jamais : un échec ne doit pas gêner
  /// l'écran qui a chargé les forfaits.
  static Future<void> sync(List<ForfaitActif2> forfaits) async {
    try {
      final plan = ForfaitReminderPlanner.plan(
        forfaits,
        overrides: await loadOverrides(),
      );
      final l10n = await _l10n();

      final reminders =
          <({int id, tz.TZDateTime at, String title, String body})>[];
      for (final r in plan) {
        final text = ForfaitReminderPlanner.message(l10n, r);
        reminders.add((id: r.id, at: r.at, title: text.title, body: text.body));
      }
      final scheduled = await NotificationService().replaceForfaitReminders(
        reminders,
      );

      if (scheduled) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kLastSync, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint("⚠️ Synchronisation des rappels d'expiration: $e");
    }
  }

  /// Supprime tous les rappels. À appeler à la déconnexion voulue par
  /// l'utilisateur, pas à la fin d'une session : l'app fermée ou expirée doit
  /// continuer à prévenir. Les choix par forfait sont gardés.
  static Future<void> cancelAll() async {
    await NotificationService().cancelForfaitReminders();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastSync);
    } catch (e) {
      debugPrint("⚠️ Réinitialisation des rappels d'expiration: $e");
    }
  }

  /// Textes dans la langue choisie dans l'app. Pas de BuildContext ici : la
  /// synchronisation peut tourner sans écran.
  static Future<AppLocalizations> _l10n() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'fr';
    return AppLocalizations.delegate.load(Locale(code));
  }
}
