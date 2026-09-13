import 'package:flutter/material.dart';

import '../../services/consent_service.dart';
import 'consent_screen.dart';

/// Portillon de consentement, à franchir entre une authentification réussie et
/// l'entrée dans l'app.
///
/// Il fait trois choses, dans cet ordre :
///  1. transmet au serveur le consentement donné avant la connexion — c'est le
///     seul moment où une session existe pour le porter ;
///  2. prend en compte le bloc `legal` de la réponse de connexion, le serveur
///     faisant autorité sur ce qu'il a réellement enregistré ;
///  3. si un document révisé reste à accepter, affiche [ConsentScreen].
///
/// Renvoie `false` uniquement si l'utilisateur a refusé : l'appelant doit alors
/// fermer la session et revenir au login.
class ConsentGate {
  ConsentGate._();

  static Future<bool> enforce(
    BuildContext context, {
    dynamic legalBlock,
  }) async {
    ConsentService.applyServerPending(legalBlock);
    await ConsentService.flushPending();

    // `refresh` : une révision publiée pendant que l'app tournait doit être
    // prise en compte maintenant, pas au prochain lancement.
    final pending = await ConsentService.pendingDocuments(refresh: true);
    if (pending.isEmpty) return true;
    if (!context.mounted) return true;

    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ConsentScreen(documents: pending),
      ),
    );
    return accepted ?? false;
  }
}
