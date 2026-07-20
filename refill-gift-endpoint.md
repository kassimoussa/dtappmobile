# Recharge cadeau — `POST /api/air/refill/gift`

Ce document décrit l'endpoint à utiliser pour **recharger le compte d'un autre abonné**
(« recharge pour autre ») à partir d'un code voucher.

> ⚠️ **Ne pas utiliser `/api/air/refill/voucher` pour recharger un autre numéro.**
> Cet endpoint est réservé à la recharge de **son propre** numéro : il applique un
> contrôle de propriété (`authorizeMsisdnOwnership`) qui rejette toute cible différente
> du titulaire du token avec un **403 « Accès non autorisé à ce numéro »**.
> Pour recharger quelqu'un d'autre, c'est **`/api/air/refill/gift`** qui autorise sur le
> **payeur** (toi) et cible le **bénéficiaire**.

## Quel endpoint pour quel usage ?

| Cas d'usage | Endpoint | Numéro autorisé (token) | Cible de la recharge |
|---|---|---|---|
| Recharger **mon** numéro | `POST /api/air/refill/voucher` | `msisdn` (= moi) | `msisdn` |
| Recharger **un autre** numéro | `POST /api/air/refill/gift` | `msisdn` (= payeur = moi) | `beneficiary_msisdn` |

## Authentification

Endpoint protégé — mêmes middlewares que le reste de l'API mobile :

- `AuthMobileSession` (`auth.mobile`) : requiert un token de session mobile valide.
- `UserActivityMiddleware` (`activity.log`) : journalise l'activité.

Le token doit appartenir au **payeur** (`msisdn`). Envoyer le token dans l'en-tête
`Authorization: Bearer <token>` comme pour les autres appels mobiles.

## Routes disponibles

Les deux variantes pointent vers `RefillController@refillByVoucherForOther` :

| Méthode | Route | Nom |
|---|---|---|
| POST | `/api/air/refill/gift` | `refill.gift.post` |
| POST | `/api/air/refill/gift/{msisdn?}` | `refill.gift` |

Avec la variante `/{msisdn}`, le numéro du payeur est pris depuis l'URL s'il n'est pas
déjà dans le corps. Le plus simple est de tout passer dans le corps JSON.

## Corps de la requête

```json
{
  "msisdn": "77000112",
  "beneficiary_msisdn": "77166677",
  "voucher_code": "578312349229",
  "refill_type": 2,
  "selected_option": 1,
  "request_details": true,
  "request_account_before": true,
  "request_account_after": true
}
```

### Règles de validation

| Champ | Obligatoire | Règle |
|---|---|---|
| `msisdn` | oui | MSISDN valide : 8 chiffres `77XXXXXX` **ou** 11 chiffres `25377XXXXXX` (= payeur). Peut aussi venir de l'URL. |
| `beneficiary_msisdn` | oui | Même format MSISDN, **et différent** de `msisdn` (`different:msisdn`). |
| `voucher_code` | oui | Exactement **12 chiffres** (`^[0-9]{12}$`). |
| `refill_type` | non (défaut `2`) | Entier `0`–`3`. |
| `selected_option` | non (défaut `1`) | Entier `1`–`10`. |
| `request_details` | non (défaut `true`) | Booléen. |
| `request_account_before` | non (défaut `true`) | Booléen. |
| `request_account_after` | non (défaut `true`) | Booléen. |

Types de rechargement (`refill_type`) : `0` normal, `1` avec bonus,
`2` automatique (défaut), `3` spécial.

Un échec de validation renvoie **422** avec les messages d'erreur par champ.

## Réponse en cas de succès (`200`)

En plus des données brutes renvoyées par le service AIR, la réponse est enrichie :

```json
{
  "code_reponse": 0,
  "currency": "DJF",
  "account_before": { "balance": "..." },
  "account_after":  { "balance": "..." },
  "balance_evolution": {
    "before": 0,
    "after": 50000,
    "increase": 50000,
    "increase_formatted": "500.00 DJF"
  },
  "date_extensions": {
    "supervision_days": 0,
    "service_fee_days": 0
  },
  "details": {
    "payer_msisdn": "77000112",
    "beneficiary_msisdn": "77166677",
    "voucher_code_masked": "5783****9229",
    "refill_type": 2,
    "refill_type_name": "Rechargement automatique",
    "selected_option": 1,
    "refill_time": "2026-07-19T12:00:00.000000Z",
    "transaction_type": "voucher_gift_refill",
    "message_friendly": "Recharge cadeau de 5783****9229 effectuée pour 77166677"
  },
  "sms_notifications": {
    "payer": "SMS de confirmation envoyé au payeur",
    "beneficiary": "SMS de notification envoyé au bénéficiaire"
  }
}
```

Effets de bord d'une recharge cadeau réussie :

- **SMS** de confirmation au payeur et de notification au bénéficiaire (les montants
  sont masqués/formatés). Un échec d'envoi SMS n'échoue pas la recharge : il est
  seulement journalisé (`Log::warning`) et reflété dans `sms_notifications`.
- **Notifications FCM** : `voucher_refill` au payeur, `voucher_gift_received` au bénéficiaire.
- **Journal d'activité** côté bénéficiaire (`VOUCHER_GIFT_RECEIVED`).
- Le **code voucher est masqué** partout (`5783****9229`) dans les logs et réponses.

## Codes d'erreur

### Autorisation / validation (avant appel au service)

| Statut | Corps | Cause |
|---|---|---|
| `403` | `{"erreur":"Accès non autorisé","message":"Accès non autorisé à ce numéro"}` | Le token ne correspond pas au `msisdn` payeur. |
| `422` | erreurs de validation par champ | Corps invalide (voucher ≠ 12 chiffres, MSISDN invalide, bénéficiaire = payeur, etc.). |

> Remarque : le **403 d'autorisation n'est pas écrit dans `laravel.log`** (il est renvoyé
> directement). Seules les erreurs serveur du bloc `catch (\Exception)` sont journalisées.

### Codes retournés par le service AIR (`code_reponse`)

Mappés vers le statut HTTP par `getHttpStatusFromRefillCode()` :

| `code_reponse` | HTTP | Signification |
|---|---|---|
| 0 | 200 | Succès |
| 100 | 500 | Erreur générale |
| 102 | 404 | Abonné non trouvé |
| 103 | 403 | Compte barré du rechargement |
| 104 | 503 | Temporairement bloqué |
| 107 | 409 | Voucher déjà utilisé par le même abonné |
| 108 | 409 | Voucher déjà utilisé par un autre abonné |
| 109 | 503 | Voucher indisponible |
| 110 | 410 | Voucher expiré |
| 111 | 404 | Voucher volé ou manquant |
| 112 | 422 | Voucher endommagé |
| 113 | 202 | Voucher en attente |
| 114 | 415 | Type de voucher non accepté |
| 115 | 403 | Rechargement non accepté |
| 119 | 400 | Code d'activation invalide |
| 120 | 422 | Profil de rechargement invalide |
| 126 | 403 | Compte non actif |
| *(autre)* | 500 | Code non mappé |

En cas d'erreur serveur inattendue : **500** avec
`{"erreur":"Erreur serveur","message":"…","details":{…}}` (le `message` détaillé n'est
présent que si `APP_DEBUG=true`).

## Exemple curl

```bash
curl -X POST https://mydtapp.djiboutitelecom.dj/api/air/refill/gift \
  -H "Authorization: Bearer <TOKEN_DU_PAYEUR>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "msisdn": "77000112",
    "beneficiary_msisdn": "77166677",
    "voucher_code": "578312349229"
  }'
```

## À retenir pour l'app mobile

Le flux « recharge pour autre » doit appeler **`/api/air/refill/gift`** avec :

- `msisdn` = numéro du **payeur** (titulaire du token),
- `beneficiary_msisdn` = numéro **destinataire** (≠ payeur).

Appeler `/api/air/refill/voucher` avec le numéro d'un tiers renverra toujours **403**,
car cet endpoint n'autorise que la recharge de son propre numéro.
