# API Activity Endpoints Documentation

## Vue d'ensemble

Cette documentation décrit les endpoints de l'API pour la récupération de l'historique des activités utilisateur et les statistiques d'utilisation. Le système suit automatiquement les actions importantes effectuées par les utilisateurs (achats, transferts, recharges, etc.) mais exclut les consultations simples et les envois de SMS de l'historique récupérable.

**Base URL**: `https://your-domain.com/api/activity`

---

## Endpoints Disponibles

### 1. Récupération de l'historique (GET)

**Endpoint**: `GET /activity/history/{msisdn}`

**Description**: Récupère l'historique des activités d'un utilisateur par son numéro MSISDN.

**Paramètres URL**:
- `msisdn` (string, requis): Numéro de téléphone (8-15 chiffres)

**Paramètres Query**:
- `page` (integer, optionnel): Numéro de page (défaut: 1)
- `per_page` (integer, optionnel): Nombre d'éléments par page (1-100, défaut: 20)
- `days` (integer, optionnel): Période en jours (1-365, défaut: 30)

**Exemple de requête**:
```bash
GET /api/activity/history/77123456?page=1&per_page=10&days=7
```

**Exemple de réponse**:
```json
{
  "success": true,
  "data": [
    {
      "id": 15,
      "action_type": "offer_purchase",
      "action_label": "Achat d'offre",
      "endpoint": "/api/air/purchase",
      "status": "success",
      "amount": 1000.00,
      "currency": "XOF",
      "external_reference": "TXN123456789",
      "created_at": "2025-01-15 14:30:25",
      "request_summary": {
        "offer_id": "OFFER_1GB_500"
      },
      "response_summary": {
        "success": true,
        "message": "Offre souscrite avec succès",
        "new_balance": 2500.00
      }
    },
    {
      "id": 14,
      "action_type": "credit_transfer",
      "action_label": "Transfert de crédit",
      "endpoint": "/api/air/transfer-credit",
      "status": "success",
      "amount": 500.00,
      "currency": "XOF",
      "external_reference": "TXN123456788",
      "created_at": "2025-01-15 10:15:10",
      "request_summary": {
        "amount": 500,
        "to_msisdn": "77987654"
      },
      "response_summary": {
        "success": true,
        "message": "Transfert effectué avec succès"
      }
    }
  ],
  "pagination": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 10,
    "total": 25
  },
  "filters": {
    "msisdn": "77123456",
    "days": 7,
    "per_page": 10
  }
}
```

---

### 2. Récupération de l'historique (POST)

**Endpoint**: `POST /activity/history`

**Description**: Récupère l'historique en passant les paramètres dans le body de la requête.

**Body Parameters**:
- `msisdn` (string, requis): Numéro de téléphone
- `page` (integer, optionnel): Numéro de page (défaut: 1)
- `per_page` (integer, optionnel): Nombre d'éléments par page (défaut: 20)
- `days` (integer, optionnel): Période en jours (défaut: 30)

**Exemple de requête**:
```bash
POST /api/activity/history
Content-Type: application/json

{
  "msisdn": "77123456",
  "page": 1,
  "per_page": 20,
  "days": 30
}
```

**Réponse**: Identique à l'endpoint GET

---

### 3. Statistiques d'activité (GET)

**Endpoint**: `GET /activity/stats/{msisdn}`

**Description**: Récupère les statistiques d'activité d'un utilisateur avec compteurs et taux de succès par type d'action.

**Paramètres URL**:
- `msisdn` (string, requis): Numéro de téléphone

**Paramètres Query**:
- `days` (integer, optionnel): Période d'analyse en jours (défaut: 30)

**Exemple de requête**:
```bash
GET /api/activity/stats/77123456?days=30
```

**Exemple de réponse**:
```json
{
  "success": true,
  "data": [
    {
      "action_type": "offer_purchase",
      "action_label": "Achat d'offre",
      "total_count": 12,
      "success_count": 11,
      "success_rate": 91.67,
      "total_amount": 15000.00
    },
    {
      "action_type": "credit_transfer",
      "action_label": "Transfert de crédit",
      "total_count": 8,
      "success_count": 8,
      "success_rate": 100.00,
      "total_amount": 4500.00
    },
    {
      "action_type": "voucher_refill",
      "action_label": "Rechargement par voucher",
      "total_count": 5,
      "success_count": 5,
      "success_rate": 100.00,
      "total_amount": 2500.00
    }
  ],
  "period_days": 30,
  "msisdn": "77123456"
}
```

---

### 4. Statistiques d'activité (POST)

**Endpoint**: `POST /activity/stats`

**Description**: Récupère les statistiques en passant les paramètres dans le body.

**Body Parameters**:
- `msisdn` (string, requis): Numéro de téléphone
- `days` (integer, optionnel): Période d'analyse en jours (défaut: 30)

**Exemple de requête**:
```bash
POST /api/activity/stats
Content-Type: application/json

{
  "msisdn": "77123456",
  "days": 30
}
```

**Réponse**: Identique à l'endpoint GET

---

## Types d'activités suivies

Le système enregistre automatiquement les types d'activités suivants :

### Actions AIR (Mobile)
- `offer_purchase` - Achat d'offre personnel
- `offer_gift` - Achat d'offre cadeau
- `credit_add` - Ajout de crédit
- `credit_deduct` - Déduction de crédit
- `credit_transfer` - Transfert de crédit
- `voucher_refill` - Rechargement par voucher

### Actions TopUp (Fixe)
- `topup_subscribe_package` - Souscription package TopUp
- `topup_recharge_account` - Recharge compte TopUp
- `topup_update_pin` - Mise à jour PIN TopUp
- `topup_directory_add` - Ajout au répertoire TopUp
- `topup_directory_remove` - Suppression du répertoire TopUp

### Actions Système
- `profile_update` - Mise à jour profil utilisateur

### Actions SMS (Enregistrées mais non récupérables)
- `sms_send` - Envoi SMS
- `otp_send` - Envoi OTP

---

## Codes d'erreur

### Erreurs de validation (422)
```json
{
  "success": false,
  "message": "Données invalides",
  "errors": {
    "msisdn": ["Le numéro MSISDN est requis"],
    "days": ["La période doit être entre 1 et 365 jours"]
  }
}
```

### MSISDN manquant (400)
```json
{
  "success": false,
  "message": "MSISDN requis",
  "error": "missing_msisdn"
}
```

### Erreur serveur (500)
```json
{
  "success": false,
  "message": "Erreur lors de la récupération de l'historique",
  "error": "Database connection failed"
}
```

---

## Notes d'implémentation

### Sécurité
- Les données sensibles (mots de passe, PIN, tokens) sont automatiquement masquées dans les logs
- Seul le MSISDN concerné peut consulter son historique

### Performance
- Index optimisés sur `msisdn` et `created_at`
- Pagination obligatoire pour éviter les surcharges
- Limite maximale de 100 éléments par page

### Filtrage
- Les actions de consultation (balances, offres) ne sont pas enregistrées
- Les envois SMS/OTP sont enregistrés mais exclus de l'historique récupérable
- Période maximale de consultation : 365 jours

### Format des données
- Les montants sont en décimal avec 2 décimales
- Les dates sont au format `Y-m-d H:i:s` (UTC)
- La devise par défaut est `XOF` si non spécifiée

---

## Exemples d'utilisation

### Récupérer l'historique des 7 derniers jours
```bash
curl -X GET "https://api.example.com/api/activity/history/77123456?days=7&per_page=50"
```

### Obtenir les statistiques du mois
```bash
curl -X GET "https://api.example.com/api/activity/stats/77123456?days=30"
```

### Recherche avec pagination
```bash
curl -X POST "https://api.example.com/api/activity/history" \
  -H "Content-Type: application/json" \
  -d '{
    "msisdn": "77123456",
    "page": 2,
    "per_page": 10,
    "days": 15
  }'
```