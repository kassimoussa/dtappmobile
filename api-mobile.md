# Documentation API — Application Mobile

**Base URL :** `https://votre-domaine.com/api`  
**Format :** JSON uniquement (`Content-Type: application/json`)  
**Authentification :** Bearer token (voir section Auth)

---

## Authentification

### Comment ça fonctionne

Toutes les routes protégées nécessitent un `session_token` obtenu après connexion (OTP ou PIN).

Envoyer le token dans le header HTTP :

```
Authorization: Bearer <session_token>
```

Ou dans le body JSON :

```json
{ "session_token": "<session_token>" }
```

Les sessions expirent **30 jours** après la connexion. Au-delà, l'API retourne `401` et l'app doit re-demander un OTP.

---

## Flux de première connexion (OTP)

```
1. POST /api/mobile/fcm/register-token   ← enregistrer token FCM avant tout
2. POST /api/sms/otp/send                ← recevoir le code SMS
3. POST /api/sms/otp/verify              ← valider le code → obtenir session_token
4. POST /api/mobile/set-pin              ← définir un PIN (1ère fois seulement)
```

## Flux de connexion suivante (PIN)

```
1. POST /api/mobile/login-pin            ← session_token retourné immédiatement
```

## Flux de réinitialisation du PIN

```
1. POST /api/sms/otp/send                ← envoyer OTP au numéro
2. POST /api/sms/otp/verify              ← valider OTP → obtenir session_token
3. POST /api/mobile/reset-pin            ← nouveau PIN (session_token requis)
```

---

## Routes publiques (pas d'auth)

### Vérifier le statut d'un numéro mobile
```
POST /api/mobile/check-status
```
```json
{ "msisdn": "77000001" }
```

### Configuration de l'app
```
GET /api/mobile/config
```

### Enregistrer token FCM (avant connexion)
```
POST /api/mobile/fcm/register-token
```
```json
{
  "phone_number": "77000001",
  "fcm_token": "token_firebase_ici",
  "device_type": "android",
  "device_name": "Samsung Galaxy S21"
}
```

### Envoyer un OTP
```
POST /api/sms/otp/send
```
Limité à **3 requêtes/minute** par IP.
```json
{
  "to": "77000001",
  "from": "DTELECOM"
}
```

### Vérifier un OTP → obtenir session_token
```
POST /api/sms/otp/verify
```
Limité à **5 tentatives/minute** par IP.
```json
{
  "to": "77000001",
  "otp": "123456",
  "device_type": "android",
  "device_info": {
    "device_id": "unique-device-id",
    "model": "Samsung Galaxy S21"
  }
}
```
**Réponse :**
```json
{
  "status": "success",
  "data": {
    "session_token": "abc123...",
    "expires_at": "2026-06-20T10:00:00Z",
    "user": {
      "id": 1,
      "phone_number": "77000001",
      "is_new_user": false
    }
  }
}
```

### Connexion par PIN
```
POST /api/mobile/login-pin
```
Limité à **5 tentatives/minute** par IP. Compte verrouillé 5 minutes après 5 échecs.
```json
{
  "phone_number": "77000001",
  "pin": "1234",
  "device_type": "android",
  "device_info": { "device_id": "unique-device-id" }
}
```

### Bannières promotionnelles
```
GET /api/banners
GET /api/popup
GET /api/offers
```

### Agences
```
GET /api/agencies
GET /api/agencies/{id}
```

---

## Routes protégées (Authorization: Bearer requis)

> Toutes les requêtes suivantes nécessitent le header `Authorization: Bearer <session_token>`

---

### Profil et session

#### Obtenir le profil
```
POST /api/mobile/profile
```
*(body vide, le token dans le header suffit)*

#### Modifier le profil
```
POST /api/mobile/update-profile
```
```json
{
  "name": "Kassim Ali",
  "email": "kassim@example.com"
}
```

#### Déconnexion
```
POST /api/mobile/logout
```

---

### Gestion du PIN

#### Définir le PIN (première fois)
```
POST /api/mobile/set-pin
```
```json
{
  "pin": "1234",
  "pin_confirmation": "1234"
}
```

#### Modifier le PIN
```
POST /api/mobile/change-pin
```
```json
{
  "old_pin": "1234",
  "new_pin": "5678",
  "new_pin_confirmation": "5678"
}
```

#### Réinitialiser le PIN (après OTP)
```
POST /api/mobile/reset-pin
```
```json
{
  "phone_number": "77000001",
  "new_pin": "5678",
  "new_pin_confirmation": "5678"
}
```
*(le token OTP obtenu via `otp/verify` doit être dans le header Authorization)*

---

### Tokens FCM

#### Mettre à jour le token FCM
```
POST /api/mobile/fcm/update-token
```
```json
{
  "fcm_token": "nouveau_token_firebase",
  "device_type": "ios"
}
```

#### Supprimer le token FCM (déconnexion appareil)
```
POST /api/mobile/fcm/clear-token
```

---

### Compte mobile (AIR)

#### Solde et dates
```
GET /api/air/balance/{msisdn}
```
Exemple : `GET /api/air/balance/77000001`

#### Offres disponibles
```
GET /api/air/offers/{msisdn}
```

#### Acheter une offre (pour soi)
```
POST /api/air/purchase
POST /api/air/purchase/{msisdn}
```
```json
{
  "offer_id": "OFFRE_DATA_1GB",
  "msisdn": "77000001"
}
```

#### Offrir une offre (cadeau)
```
POST /api/air/gift
POST /api/air/gift/{msisdn_payeur}
```
```json
{
  "offer_id": "OFFRE_DATA_1GB",
  "msisdn": "77000001",
  "beneficiary_msisdn": "77000002"
}
```

#### Transférer du crédit
```
POST /api/air/transfer-credit
```
```json
{
  "from_msisdn": "77000001",
  "to_msisdn": "77000002",
  "amount": 500
}
```

---

### Recharge (voucher)

#### Recharger son propre compte
```
POST /api/air/refill/voucher
POST /api/air/refill/voucher/{msisdn}
```
```json
{
  "voucher_code": "1234567890123456",
  "msisdn": "77000001"
}
```

#### Recharger un autre compte (cadeau)
```
POST /api/air/refill/gift
POST /api/air/refill/gift/{msisdn_payeur}
```
```json
{
  "voucher_code": "1234567890123456",
  "beneficiary_msisdn": "77000002"
}
```

#### Vérifier un voucher (sans recharger)
```
POST /api/air/refill/voucher/check
```
```json
{ "voucher_code": "1234567890123456" }
```

#### Historique des recharges
```
GET /api/air/refill/history/{msisdn}
```

---

### Ligne fixe (TopUp)

#### Soldes d'une ligne fixe
```
POST /api/topup/balances
```
```json
{ "isdn": "21352000001" }
```

#### Statut d'éligibilité recharge
```
GET  /api/topup/status/{isdn}
POST /api/topup/status
```

#### Packages disponibles
```
POST /api/topup/packages
```
```json
{ "phone_number": "77000001" }
```

#### Souscrire à un package
```
POST /api/topup/subscribe-package
```

#### Recharger la ligne fixe
```
POST /api/topup/recharge-account
```

#### Répertoire personnel
```
GET  /api/topup/numbers/{msisdn}
POST /api/topup/numbers
POST /api/topup/directory/add
DELETE /api/topup/directory/remove
```

---

### Factures

#### Factures par numéro de téléphone
```
GET  /api/invoice/phone/{msisdn}
POST /api/invoice/phone
```

#### Facture par numéro de facture
```
GET  /api/invoice/number/{invoiceNumber}
POST /api/invoice/number
```

---

### Historique des activités

#### Historique mobile
```
GET  /api/activity/history/{msisdn}
POST /api/activity/history
```
Paramètres optionnels : `?status=success|failed|error&per_page=20`

#### Historique ligne fixe
```
GET  /api/activity/history/fixed-line/{fixedLineNumber}
POST /api/activity/history/fixed-line
```

#### Statistiques
```
GET  /api/activity/stats/{msisdn}
POST /api/activity/stats
```

---

### SMS direct (app autorisée uniquement)

```
POST /api/sms/sms/send
```
```json
{
  "to": "77000001",
  "from": "DTELECOM",
  "text": "Votre message ici"
}
```

---

## Codes de réponse

| Code | Signification |
|------|---------------|
| `200` | Succès |
| `400` | Données invalides (ex: PIN déjà configuré) |
| `401` | Token manquant, invalide ou session expirée |
| `403` | Compte désactivé ou accès refusé |
| `404` | Ressource introuvable |
| `422` | Validation échouée (champs manquants) |
| `429` | Trop de requêtes (rate limit atteint) |
| `500` | Erreur serveur |

## Structure de réponse

```json
{
  "status": "success | error",
  "message": "Description humaine",
  "data": { ... }
}
```

En cas d'erreur de validation (422) :
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "phone_number": ["Le numéro de téléphone est obligatoire"]
  }
}
```

---

## Notes importantes

- **Sessions expirées** : Si l'API retourne `401`, l'app doit relancer le flux OTP.
- **Verrouillage PIN** : 5 erreurs de PIN consécutives → compte verrouillé 5 minutes. La réponse `429` inclut `remaining_seconds`.
- **Format MSISDN** : accepté en format local (`77000001`) ou international (`25377000001`).
- **FCM** : Enregistrer le token FCM avant toute connexion pour recevoir les notifications de transactions.
