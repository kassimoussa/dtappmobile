// lib/utils/safe_link.dart

/// Lien reçu du serveur (bannière, popup promotionnel) à ouvrir hors de l'app.
///
/// Seul l'HTTPS passe : un lien `tel:`, `sms:`, `intent:` ou le schéma d'une
/// autre application ouvrirait, d'un simple toucher, une action que
/// l'utilisateur n'a pas demandée. Renvoie `null` pour tout le reste, y
/// compris un lien vide ou sans hôte.
///
/// Les identifiants dans l'adresse (`https://djiboutitelecom.dj@autre.com`)
/// sont refusés : l'hôte réel est celui qui suit le `@`, ce qui trompe l'œil.
Uri? parseWebLink(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty) return null;
  return uri;
}
