# Historique des activités — Référence des réponses

Documentation de référence pour les réponses des endpoints d'historique des
activités. Complète `docs/api-mobile.md` (section *Historique des activités*)
en détaillant le contenu variable du champ `metadata` selon le type d'activité
(`action_type`), ainsi que les cas d'erreur.

Code source concerné :
- `app/Http/Controllers/Api/ActivityController.php`
- `app/Services/ActivityLoggerService.php`
- `app/Models/UserActivity.php`
- `app/Enums/ActivityType.php`

---

## 1. Endpoints

| Méthode | URL | Description |
|---|---|---|
| GET / POST | `/api/activity/history/{msisdn}` | Historique des activités d'un numéro mobile |
| GET / POST | `/api/activity/history/fixed-line/{fixedLineNumber}` | Historique des activités liées à une ligne fixe |
| GET / POST | `/api/activity/stats/{msisdn}` | Statistiques agrégées par type d'activité |

Tous ces endpoints sont protégés par le middleware `auth.mobile`.

---

## 2. Structure générale (`/history` et `/history/fixed-line`)

```json
{
  "success": true,
  "data": [ /* tableau d'activités, voir section 3 */ ],
  "pagination": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 58
  },
  "filters": {
    "msisdn": "77000001",
    "days": 30,
    "per_page": 20
  }
}
```

> Pour `/history/fixed-line`, `filters` contient `fixed_line_number` au lieu
> de `msisdn`.

### Paramètres de requête

| Paramètre | Type | Défaut | Description |
|---|---|---|---|
| `page` | int | 1 | Numéro de page |
| `per_page` | int | 20 | Taille de page (max 100) |
| `days` | int | 30 | Période en jours (max 365) |
| `status` | string | — | Filtre `success` \| `failed` \| `error` \| `pending` (uniquement sur `/history`) |

---

## 3. Champs communs d'un élément `data[]`

```json
{
  "id": 101,
  "action_type": "offer_purchase",
  "action_label": "Achat de forfait",
  "status": "success",
  "amount": 500.00,
  "currency": "DJF",
  "old_balance": 2000.00,
  "new_balance": 1500.00,
  "beneficiary_msisdn": null,
  "external_reference": "REF-2026-001",
  "description": "Achat de forfait : Forfait Data 1GB",
  "metadata": { /* variable selon action_type, voir section 4 */ },
  "created_at": "2026-05-21 10:00:00"
}
```

| Champ | Type | Description |
|---|---|---|
| `id` | int | Identifiant de l'activité |
| `action_type` | string | Valeur de l'enum `ActivityType` (voir section 4) |
| `action_label` | string | Libellé FR lisible (`ActivityType::getLabel()`) |
| `status` | string | `success`, `failed` ou `error` |
| `amount` | float\|null | Montant de l'opération |
| `currency` | string\|null | Devise (`DJF` par défaut) |
| `old_balance` | float\|null | Solde avant l'opération |
| `new_balance` | float\|null | Solde après l'opération |
| `beneficiary_msisdn` | string\|null | Bénéficiaire (cadeaux, transferts) |
| `external_reference` | string\|null | Référence de transaction externe |
| `description` | string | Description lisible générée |
| `metadata` | object | Détails spécifiques au type d'activité |
| `created_at` | string | Date au format `Y-m-d H:i:s` |

### Valeurs de `status`

| Valeur | Origine |
|---|---|
| `success` | Code HTTP de la requête source < 400 |
| `failed` | Code HTTP entre 400 et 499 |
| `error` | Code HTTP >= 500 |

Lorsque `status` vaut `failed` ou `error`, `metadata` contient en plus :

```json
{
  "error_code": "401",
  "error_message": "Solde insuffisant"
}
```

---

## 4. Variantes de `metadata` par `action_type`

Le contenu de `metadata` dépend du type d'activité
(`App\Enums\ActivityType` / `ActivityLoggerService::buildMetadata`).
Les clés à valeur `null` sont retirées (`array_filter`).

### 4.1 `offer_purchase` — Achat de forfait

```json
"metadata": {
  "offer_id": "DATA_1GB",
  "offer_name": "Forfait Data 1GB",
  "validity_days": 30
}
```

### 4.2 `offer_gift` — Achat de forfait cadeau

```json
"metadata": {
  "offer_id": "DATA_1GB",
  "offer_name": "Forfait Data 1GB",
  "validity_days": 30
}
```
> `beneficiary_msisdn` (champ racine) contient le numéro du destinataire.

### 4.3 `credit_add` — Ajout de crédit

```json
"metadata": {}
```
> Aucune métadonnée spécifique : `amount`, `old_balance`, `new_balance` suffisent.

### 4.4 `credit_deduct` — Déduction de crédit

```json
"metadata": {}
```

### 4.5 `credit_transfer` — Transfert de crédit

```json
"metadata": {
  "to_msisdn": "77000099"
}
```

### 4.6 `credit_received` — Crédit reçu (côté bénéficiaire)

Généré via `logForBeneficiary` après un `credit_transfer` réussi.

```json
"metadata": {
  "sender_msisdn": "77000001"
}
```
> `description` : `"Crédit reçu : 1000.00 DJF de 77000001"`. `old_balance`
> est toujours `null` (non calculé côté bénéficiaire).

### 4.7 `offer_received` — Forfait reçu (côté bénéficiaire)

Généré via `logForBeneficiary` après un `offer_gift` réussi.

```json
"metadata": {
  "offer_id": "DATA_1GB",
  "offer_name": "Forfait Data 1GB",
  "validity_days": 30,
  "sender_msisdn": "77000001"
}
```

### 4.8 `voucher_refill` — Rechargement par voucher

```json
"metadata": {
  "voucher_serial": "1234********5678",
  "refill_type": "personal",
  "selected_option": "OPTION_1",
  "voucher_value": 1000
}
```
> `voucher_serial` est masqué (`maskVoucher`) : 4 premiers / 4 derniers
> caractères visibles, le reste remplacé par `*`.

### 4.9 `voucher_gift_refill` — Recharge cadeau par voucher

```json
"metadata": {
  "voucher_serial": "1234********5678",
  "refill_type": "gift",
  "selected_option": "OPTION_1",
  "voucher_value": 1000
}
```
> `beneficiary_msisdn` (champ racine) contient le numéro du destinataire.

### 4.10 `voucher_gift_received` — Recharge cadeau reçue (côté bénéficiaire)

Généré via `logForBeneficiary` après un `voucher_gift_refill` réussi.

```json
"metadata": {
  "voucher_serial": "1234********5678",
  "sender_msisdn": "77000001"
}
```

### 4.11 `topup_subscribe_package` — Souscription package TopUp

```json
"metadata": {
  "fixed_line_number": "21352000001",
  "package_id": "PKG_INTERNET_10H",
  "package_name": "Internet 10h"
}
```

### 4.12 `topup_recharge_account` — Recharge compte TopUp

```json
"metadata": {
  "fixed_line_number": "21352000001",
  "recharge_type": "voucher"
}
```

### 4.13 `topup_update_pin` — Mise à jour PIN TopUp

```json
"metadata": {}
```

### 4.14 `topup_directory_add` — Ajout au répertoire TopUp

```json
"metadata": {
  "fixed_line_number": "21352000001",
  "contact_name": "Bureau",
  "contact_number": "21352000099"
}
```

### 4.15 `topup_directory_remove` — Suppression du répertoire TopUp

```json
"metadata": {
  "fixed_line_number": "21352000001",
  "contact_name": "Bureau",
  "contact_number": "21352000099"
}
```

### 4.16 `profile_update`, `pin_set`, `pin_change`, `pin_reset`

Aucune métadonnée spécifique n'est construite pour ces types.

```json
"metadata": {}
```

> Note : `sms_send` et `otp_send` existent dans l'enum `ActivityType` mais
> sont exclus de l'historique (`scopeExcludingSms`, `isVisibleInHistory()`).

---

## 5. Exemple complet — activité en échec

```json
{
  "id": 110,
  "action_type": "voucher_refill",
  "action_label": "Rechargement par voucher",
  "status": "failed",
  "amount": null,
  "currency": "DJF",
  "old_balance": null,
  "new_balance": null,
  "beneficiary_msisdn": null,
  "external_reference": null,
  "description": "Rechargement par voucher — Voucher invalide ou déjà utilisé",
  "metadata": {
    "voucher_serial": "1234********5678",
    "refill_type": "personal",
    "error_code": "453",
    "error_message": "Voucher invalide ou déjà utilisé"
  },
  "created_at": "2026-05-21 11:32:00"
}
```

---

## 6. Endpoint `/api/activity/stats/{msisdn}`

```json
{
  "success": true,
  "data": [
    {
      "action_type": "offer_purchase",
      "action_label": "Achat de forfait",
      "total_count": 5,
      "success_count": 5,
      "success_rate": 100.0,
      "total_amount": 2500.00
    },
    {
      "action_type": "voucher_refill",
      "action_label": "Rechargement par voucher",
      "total_count": 3,
      "success_count": 2,
      "success_rate": 66.67,
      "total_amount": 2000.00
    }
  ],
  "period_days": 30,
  "msisdn": "77000001"
}
```

| Champ | Description |
|---|---|
| `total_count` | Nombre total d'activités de ce type sur la période |
| `success_count` | Nombre d'activités avec `status = success` |
| `success_rate` | `success_count / total_count * 100`, arrondi à 2 décimales |
| `total_amount` | Somme des `amount` non nuls |

---

## 7. Exemple consolidé — toutes les activités possibles pour un mobile donné

Réponse type de `GET /api/activity/history/77000001?per_page=20&days=30`
illustrant, dans un seul payload, une entrée pour **chaque type d'activité**
pouvant apparaître pour un numéro mobile (ordre du plus récent au plus
ancien). La dernière entrée illustre le cas `failed`.

```json
{
  "success": true,
  "data": [
    {
      "id": 119,
      "action_type": "offer_purchase",
      "action_label": "Achat de forfait",
      "status": "success",
      "amount": 500.00,
      "currency": "DJF",
      "old_balance": 2500.00,
      "new_balance": 2000.00,
      "beneficiary_msisdn": null,
      "external_reference": "OFFER_DATA_1GB",
      "description": "Achat de forfait : Forfait Data 1GB",
      "metadata": {
        "offer_id": "DATA_1GB",
        "offer_name": "Forfait Data 1GB",
        "validity_days": 30
      },
      "created_at": "2026-06-13 09:00:00"
    },
    {
      "id": 118,
      "action_type": "offer_gift",
      "action_label": "Achat de forfait cadeau",
      "status": "success",
      "amount": 500.00,
      "currency": "DJF",
      "old_balance": 3000.00,
      "new_balance": 2500.00,
      "beneficiary_msisdn": "77000099",
      "external_reference": "OFFER_DATA_1GB",
      "description": "Achat de forfait cadeau pour 77000099",
      "metadata": {
        "offer_id": "DATA_1GB",
        "offer_name": "Forfait Data 1GB",
        "validity_days": 30
      },
      "created_at": "2026-06-12 18:30:00"
    },
    {
      "id": 117,
      "action_type": "credit_add",
      "action_label": "Ajout de crédit",
      "status": "success",
      "amount": 1000.00,
      "currency": "DJF",
      "old_balance": 2000.00,
      "new_balance": 3000.00,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Ajout de crédit",
      "metadata": {},
      "created_at": "2026-06-12 12:00:00"
    },
    {
      "id": 116,
      "action_type": "credit_deduct",
      "action_label": "Déduction de crédit",
      "status": "success",
      "amount": 200.00,
      "currency": "DJF",
      "old_balance": 3200.00,
      "new_balance": 3000.00,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Déduction de crédit",
      "metadata": {},
      "created_at": "2026-06-11 08:15:00"
    },
    {
      "id": 115,
      "action_type": "credit_transfer",
      "action_label": "Transfert de crédit",
      "status": "success",
      "amount": 1000.00,
      "currency": "DJF",
      "old_balance": 4200.00,
      "new_balance": 3200.00,
      "beneficiary_msisdn": "77000050",
      "external_reference": null,
      "description": "Transfert de crédit de 1000 DJF vers 77000050",
      "metadata": {
        "to_msisdn": "77000050"
      },
      "created_at": "2026-06-10 17:45:00"
    },
    {
      "id": 114,
      "action_type": "credit_received",
      "action_label": "Crédit reçu",
      "status": "success",
      "amount": 500.00,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": 4200.00,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Crédit reçu : 500.00 DJF de 77000020",
      "metadata": {
        "sender_msisdn": "77000020"
      },
      "created_at": "2026-06-10 16:00:00"
    },
    {
      "id": 113,
      "action_type": "offer_received",
      "action_label": "Forfait reçu",
      "status": "success",
      "amount": 500.00,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Forfait reçu de 77000020",
      "metadata": {
        "offer_id": "DATA_1GB",
        "offer_name": "Forfait Data 1GB",
        "validity_days": 30,
        "sender_msisdn": "77000020"
      },
      "created_at": "2026-06-09 14:20:00"
    },
    {
      "id": 112,
      "action_type": "voucher_refill",
      "action_label": "Rechargement par voucher",
      "status": "success",
      "amount": 1000.00,
      "currency": "DJF",
      "old_balance": 2700.00,
      "new_balance": 3700.00,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Rechargement par voucher — voucher 1234********5678",
      "metadata": {
        "voucher_serial": "1234********5678",
        "refill_type": "personal",
        "selected_option": "OPTION_1",
        "voucher_value": 1000
      },
      "created_at": "2026-06-08 10:05:00"
    },
    {
      "id": 111,
      "action_type": "voucher_gift_refill",
      "action_label": "Recharge cadeau par voucher",
      "status": "success",
      "amount": 500.00,
      "currency": "DJF",
      "old_balance": 4200.00,
      "new_balance": 3700.00,
      "beneficiary_msisdn": "77000088",
      "external_reference": null,
      "description": "Recharge cadeau par voucher pour 77000088",
      "metadata": {
        "voucher_serial": "5678********1234",
        "refill_type": "gift",
        "selected_option": "OPTION_2",
        "voucher_value": 500
      },
      "created_at": "2026-06-07 09:30:00"
    },
    {
      "id": 110,
      "action_type": "voucher_gift_received",
      "action_label": "Recharge cadeau reçue",
      "status": "success",
      "amount": 500.00,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": 1500.00,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Recharge cadeau reçue de 77000077",
      "metadata": {
        "voucher_serial": "5678********1234",
        "sender_msisdn": "77000077"
      },
      "created_at": "2026-06-06 11:10:00"
    },
    {
      "id": 109,
      "action_type": "topup_subscribe_package",
      "action_label": "Souscription package TopUp",
      "status": "success",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Souscription package TopUp",
      "metadata": {
        "fixed_line_number": "21352000001",
        "package_id": "PKG_INTERNET_10H",
        "package_name": "Internet 10h"
      },
      "created_at": "2026-06-05 15:40:00"
    },
    {
      "id": 108,
      "action_type": "topup_recharge_account",
      "action_label": "Recharge compte TopUp",
      "status": "success",
      "amount": 1000.00,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Recharge compte TopUp",
      "metadata": {
        "fixed_line_number": "21352000001",
        "recharge_type": "voucher"
      },
      "created_at": "2026-06-04 13:25:00"
    },
    {
      "id": 107,
      "action_type": "topup_update_pin",
      "action_label": "Mise à jour PIN TopUp",
      "status": "success",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Mise à jour PIN TopUp",
      "metadata": {},
      "created_at": "2026-06-03 08:50:00"
    },
    {
      "id": 106,
      "action_type": "topup_directory_add",
      "action_label": "Ajout au répertoire TopUp",
      "status": "success",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Ajout au répertoire TopUp",
      "metadata": {
        "fixed_line_number": "21352000001",
        "contact_name": "Bureau",
        "contact_number": "21352000099"
      },
      "created_at": "2026-06-02 16:15:00"
    },
    {
      "id": 105,
      "action_type": "topup_directory_remove",
      "action_label": "Suppression du répertoire TopUp",
      "status": "success",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Suppression du répertoire TopUp",
      "metadata": {
        "fixed_line_number": "21352000001",
        "contact_name": "Ancien contact",
        "contact_number": "21352000088"
      },
      "created_at": "2026-06-01 10:00:00"
    },
    {
      "id": 104,
      "action_type": "profile_update",
      "action_label": "Mise à jour profil",
      "status": "success",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Mise à jour profil",
      "metadata": {},
      "created_at": "2026-05-31 09:20:00"
    },
    {
      "id": 103,
      "action_type": "pin_set",
      "action_label": "Configuration du code PIN",
      "status": "success",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Configuration du code PIN",
      "metadata": {},
      "created_at": "2026-05-30 12:00:00"
    },
    {
      "id": 102,
      "action_type": "pin_change",
      "action_label": "Modification du code PIN",
      "status": "success",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Modification du code PIN",
      "metadata": {},
      "created_at": "2026-05-29 18:40:00"
    },
    {
      "id": 101,
      "action_type": "pin_reset",
      "action_label": "Réinitialisation du code PIN",
      "status": "failed",
      "amount": null,
      "currency": "DJF",
      "old_balance": null,
      "new_balance": null,
      "beneficiary_msisdn": null,
      "external_reference": null,
      "description": "Réinitialisation du code PIN — Code de vérification invalide",
      "metadata": {
        "error_code": "422",
        "error_message": "Code de vérification invalide"
      },
      "created_at": "2026-05-28 07:55:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 20,
    "total": 19
  },
  "filters": {
    "msisdn": "77000001",
    "days": 30,
    "per_page": 20
  }
}
```

---

## 8. Réponses d'erreur

### 400 — Paramètre requis manquant

```json
{ "success": false, "message": "MSISDN requis" }
```
> `"Numéro fixe requis"` pour `/history/fixed-line`.

### 422 — Erreur de validation

```json
{
  "success": false,
  "errors": {
    "per_page": ["The per page field must not be greater than 100."]
  }
}
```

### 500 — Erreur serveur

```json
{ "success": false, "message": "Erreur serveur" }
```
