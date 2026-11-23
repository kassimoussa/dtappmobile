# Guide d'intégration mobile — PIN des lignes fixes (vérifier / changer)

Destiné à l'agent Claude Code qui travaille sur le **code de l'application mobile** (poste du développeur).
Ce guide décrit deux nouveaux endpoints de l'API `dtapi` et la manière de les intégrer proprement.
Il remplace, pour le changement de PIN, ce que `docs/api-pin-verify-integration-mobile.md` ne couvrait pas ;
pour `/api/fix/pin/verify` les deux documents sont cohérents.

> **Avant de coder :** lis le code existant de l'app (couche réseau/HTTP, gestion de session et de
> déconnexion, écrans « ligne fixe » / TopUp, écran de changement de PIN du compte mobile, gestion des
> erreurs, localisation FR/EN) et **réutilise ses conventions** (client HTTP, state management, widgets,
> clés de traduction). Ne crée pas de seconde pile réseau. Si le framework n'est pas Flutter, adapte les
> exemples Dart ci-dessous.

---

## 1. Contexte

L'API expose maintenant deux endpoints qui parlent à l'OCS de Djibouti Telecom pour les **lignes fixes**
(le serveur fait le travail, l'app ne contacte jamais l'OCS) :

| Endpoint | Rôle |
|---|---|
| `POST /api/fix/pin/verify` | Vérifie qu'un couple (numéro fixe, PIN) est valide |
| `POST /api/fix/pin/change` | Change le PIN d'une ligne fixe (ancien PIN requis) |

- Base URL : `https://mydtapp.djiboutitelecom.dj`
- **Lignes fixes uniquement** : 8 chiffres commençant par `21` (capitale) ou `27` (régions), ex. `21364425`,
  ou le format international `25321XXXXXX` / `25327XXXXXX`. Les numéros mobiles (`77…`) sont refusés (422).
  Le serveur ajoute lui-même l'indicatif `253` : l'app peut envoyer le format local.
- **À ne pas confondre** avec les endpoints existants du **compte mobile** : `POST /api/mobile/login-pin`
  et `POST /api/mobile/change-pin` (PIN à 4 chiffres du compte mobile, corps différents). Les nouveaux
  endpoints concernent le PIN de la **ligne fixe** côté OCS. Ne touche pas aux écrans/flux existants du PIN mobile.

## 2. Authentification et en-têtes

Session mobile obligatoire (le token obtenu au login), comme les autres routes protégées :

```
Authorization: Bearer <session_token>
Content-Type: application/json
Accept: application/json
```

⚠️ **Les PIN sont toujours des chaînes JSON** (`"0123"`), jamais des entiers : un entier perd ses zéros de
tête et est rejeté (422). Même chose pour `cli`.

## 3. `POST /api/fix/pin/verify`

Requête :

```json
{ "cli": "21364425", "pin": "1234" }
```

| Champ | Règle |
|---|---|
| `cli` | string, 8 à 20 caractères parmi `0-9 + espace ( ) . -`, doit être une ligne fixe 21/27 |
| `pin` | string, 3 à 12 chiffres |

Réponses :

| Cas | HTTP | Corps |
|---|---|---|
| PIN correct | 200 | `{"verified": true}` |
| Numéro ou PIN incorrect | 401 | `{"verified": false, "message": "Numéro ou PIN incorrect."}` |
| Format invalide | 422 | `{"verified": false, "message": "Format du numéro ou du PIN invalide."}` |
| OCS indisponible | 503 | `{"verified": false, "message": "Service momentanément indisponible. Réessayez."}` |
| Verrou anti brute-force | 429 | `{"verified": false, "message": "Trop de tentatives. Réessayez plus tard.", "retry_after": 840}` |

## 4. `POST /api/fix/pin/change`

Requête :

```json
{
  "cli": "21364425",
  "current_pin": "1234",
  "new_pin": "9082",
  "new_pin_confirmation": "9082"
}
```

| Champ | Règle |
|---|---|
| `cli` | comme ci-dessus |
| `current_pin` | string, 3 à 12 chiffres — l'ancien PIN, **revérifié côté serveur** à chaque appel |
| `new_pin` | string, 3 à 12 chiffres, **différent** de `current_pin`, doit correspondre à `new_pin_confirmation` |
| `new_pin_confirmation` | string, identique à `new_pin` (nom de champ imposé par le serveur) |

Réponses (toutes ont la clé `changed`) :

| Cas | HTTP | Corps |
|---|---|---|
| PIN changé | 200 | `{"changed": true}` |
| Numéro ou PIN actuel incorrect | 401 | `{"changed": false, "message": "Numéro ou PIN actuel incorrect."}` |
| Format invalide | 422 | `{"changed": false, "message": "Format du numéro ou des PIN invalide."}` |
| Nouveau PIN = ancien | 422 | `{"changed": false, "message": "Le nouveau PIN doit être différent de l'actuel."}` |
| Confirmation différente | 422 | `{"changed": false, "message": "La confirmation du nouveau PIN ne correspond pas."}` |
| PIN refusé par la politique OCS | 422 | `{"changed": false, "message": "<message FR>"}` — voir ci-dessous |
| OCS indisponible / résultat incertain | 503 | `{"changed": false, "message": "Service momentanément indisponible. Vérifiez votre PIN avant de réessayer."}` |
| Verrou anti brute-force | 429 | `{"changed": false, "message": "Trop de tentatives. Réessayez plus tard.", "retry_after": 840}` |

Messages de politique de PIN possibles (422, affichables tels quels) :
- « Le nouveau PIN est trop court. » / « Le nouveau PIN est trop long. »
- « Le PIN ne doit pas correspondre aux 4 derniers chiffres du numéro. »
- « Le PIN ne doit pas être composé uniquement de chiffres identiques. »
- « Le PIN ne doit pas être une suite de chiffres consécutifs. »

La longueur min/max exacte de l'OCS est inconnue : n'impose **pas** de longueur stricte à 4 chiffres côté
app, valide seulement « chiffres, 3 à 12 » et laisse le serveur trancher via les messages ci-dessus.
Le message du serveur est la source de vérité : affiche-le (ou mappe-le vers une clé de traduction si
l'app est multilingue, avec le texte serveur en repli).

### ⚠️ Cas du 503 sur `/api/fix/pin/change` (résultat incertain)

Un 503 peut signifier « l'OCS est injoignable » **ou** « la requête a été envoyée mais on n'a pas pu
confirmer le résultat » : le PIN a peut-être changé. Le serveur a déjà tenté une vérification avec le
nouveau PIN avant de répondre 503. Comportement conseillé :

1. Afficher le message du serveur (« Vérifiez votre PIN avant de réessayer »).
2. **Ne pas relancer automatiquement** `/api/fix/pin/change`, ne pas faire de retry silencieux.
3. Laisser l'utilisateur réessayer lui-même plus tard. Si son ancien PIN est alors refusé (401), lui
   suggérer d'essayer avec le **nouveau** PIN qu'il vient de saisir : le changement a probablement abouti.

## 5. Distinguer les deux sortes de 401

Un 401 peut venir de la **session mobile** (token absent, invalide, expiré) ou d'un **mauvais PIN**.
Les corps diffèrent :

| Origine | Corps |
|---|---|
| Mauvais PIN (verify) | `{"verified": false, "message": …}` |
| Mauvais PIN (change) | `{"changed": false, "message": …}` |
| Session invalide / expirée | `{"status": "error", "message": "Session invalide ou expirée"}` |

**Règle :** sur un 401, tester la présence de la clé `verified` (verify) ou `changed` (change).
- Clé présente → mauvais PIN : **ne pas déconnecter** l'utilisateur, laisser réessayer.
- Clé absente → session expirée : appliquer le comportement habituel de déconnexion/reconnexion de l'app.

Ne jamais déconnecter sur un 401 sans avoir testé cette clé.

## 6. Verrou anti brute-force et limites

- **5 échecs maximum par numéro sur 15 minutes**, partagés entre `/api/fix/pin/verify` et `/api/fix/pin/change`
  (l'ancien PIN de `change` est testé comme un PIN de `verify`) et indépendants de l'appareil ou de la
  façon d'écrire le numéro. Au-delà : 429 avec `retry_after` (secondes), l'OCS n'est pas contacté.
- Un PIN correct (verify) ou un changement réussi remet le compteur à zéro.
- Seuls les 401 (mauvais PIN) consomment un essai ; 422 et 503 non.
- Le serveur ne renvoie pas le nombre d'essais restants : prévenir l'utilisateur après un 401, et afficher
  un décompte à partir de `retry_after` sur un 429.
- Limite par IP : `verify` 10 requêtes/min, `change` 5 requêtes/min. Au-delà : 429 **sans** clé
  `verified`/`changed` (corps générique Laravel, en-tête `Retry-After`) → « Trop de requêtes, réessayez dans un instant ».

## 7. Récapitulatif des comportements à implémenter

| HTTP | `/fix/pin/verify` | `/fix/pin/change` |
|---|---|---|
| 200 | Poursuivre le parcours | Succès : message de confirmation, retour à l'écran précédent |
| 401 + clé | « Numéro ou PIN incorrect », réessayer | « Numéro ou PIN actuel incorrect », réessayer |
| 401 sans clé | Session expirée → déconnexion | idem |
| 422 | Corriger la saisie | Afficher `message` à côté du champ concerné |
| 429 | Bloquer le bouton + décompte `retry_after` | idem |
| 503 / timeout / réseau | « Service indisponible », réessayer ; **ne pas** considérer le PIN comme faux | voir § 4 (résultat incertain) |

## 8. Bonnes pratiques côté app

- Timeout client d'environ **20 s** (le serveur attend jusqu'à 10 s l'OCS, et jusqu'à 3 appels OCS pour un changement).
- **Désactiver le bouton pendant la requête** : chaque double envoi avec un mauvais PIN consomme deux essais,
  et un double envoi de `change` ne doit jamais partir.
- Pour `change` : valider localement (confirmation identique, nouveau PIN ≠ ancien, chiffres uniquement)
  avant d'appeler l'API, mais sans dupliquer la politique OCS.
- **Ne jamais stocker, logger ni envoyer en analytics/crash reporting un PIN** (ancien ou nouveau), ni le
  corps des requêtes. Champs de saisie masqués, pas de copier/coller, vider les champs après la réponse
  (succès comme échec). Vérifier que les intercepteurs de logs HTTP du projet ne les impriment pas.
- Ne pas mettre le PIN dans l'URL ni dans l'historique de navigation d'une WebView.
- Le serveur ne renvoie jamais d'identifiant d'abonné ni de détail d'erreur OCS : ne pas en attendre.
- Après un changement réussi, si l'app mémorise une quelconque preuve de vérification de la ligne fixe
  (cache, flag), l'invalider.

## 9. Exemples

### cURL

```bash
curl -X POST https://mydtapp.djiboutitelecom.dj/api/fix/pin/change \
  -H "Authorization: Bearer $SESSION_TOKEN" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"cli":"21364425","current_pin":"1234","new_pin":"9082","new_pin_confirmation":"9082"}'
```

### Dart / Flutter

```dart
sealed class PinChangeOutcome {}
class PinChanged extends PinChangeOutcome {}
class PinWrongCurrent extends PinChangeOutcome {}
class PinRejected extends PinChangeOutcome { final String message; PinRejected(this.message); }
class PinLocked extends PinChangeOutcome { final int? retryAfter; PinLocked(this.retryAfter); }
class PinUncertain extends PinChangeOutcome { final String message; PinUncertain(this.message); }
class SessionExpired extends PinChangeOutcome {}

Future<PinChangeOutcome> changeFixedLinePin({
  required String cli,
  required String currentPin, // String !
  required String newPin,     // String !
}) async {
  final res = await http
      .post(
        Uri.parse('$baseUrl/api/fix/pin/change'),
        headers: {
          'Authorization': 'Bearer $sessionToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'cli': cli,
          'current_pin': currentPin,
          'new_pin': newPin,
          'new_pin_confirmation': newPin,
        }),
      )
      .timeout(const Duration(seconds: 20));

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final hasKey = body.containsKey('changed');

  if (res.statusCode == 401 && !hasKey) return SessionExpired(); // → déconnexion
  switch (res.statusCode) {
    case 200:
      return PinChanged();
    case 401:
      return PinWrongCurrent();
    case 422:
      return PinRejected(body['message'] as String? ?? 'PIN invalide.');
    case 429:
      return PinLocked(body['retry_after'] as int?);
    default: // 503, timeout géré par l'appelant
      return PinUncertain(body['message'] as String? ??
          'Service momentanément indisponible. Vérifiez votre PIN avant de réessayer.');
  }
}
// Un TimeoutException / SocketException doit aussi être traité comme PinUncertain.
```

## 9 bis. Où brancher dans l'app

Propose d'abord (sans tout implémenter) l'emplacement logique, puis fais-le après validation :
- **Vérification** : à l'endroit où l'app doit s'assurer que l'utilisateur possède le PIN de sa ligne fixe
  (ex. avant une action sensible TopUp, ou à l'ajout d'une ligne fixe).
- **Changement** : un écran « Changer le PIN de ma ligne fixe » (numéro, PIN actuel, nouveau PIN,
  confirmation), accessible depuis la section ligne fixe / TopUp ou les paramètres de sécurité.

Comme le serveur n'associe pas l'utilisateur mobile à une ligne fixe, **c'est l'app qui fournit `cli`** : si
l'app connaît déjà la ligne fixe de l'utilisateur (TopUp), pré-remplis le champ ; sinon laisse-le saisir.

## 10. État de validation côté serveur (à connaître en recette)

- `/api/fix/pin/verify` : validé en réel (PIN correct → 200, mauvais PIN → 401).
- `/api/fix/pin/change` : **les tests serveur passent mais l'appel réel de changement n'a pas encore été
  validé** sur l'OCS (réponse de succès et politique de PIN exacte non observées). Faire la première
  recette sur une ligne de test dont on accepte de changer le PIN, avec un seul essai, et ne pas
  déployer l'écran en production avant cette validation.
- Tant que l'OCS n'est pas joignable, les deux endpoints répondent 503.

## 11. Compte rendu attendu

À la fin, résume : fichiers créés/modifiés dans l'app, écrans/flux branchés, conventions réutilisées,
ce que tu n'as pas pu déterminer (ex. où brancher la vérification), et comment tester (y compris le cas
401 session expirée vs mauvais PIN, le 429 et le 503).
