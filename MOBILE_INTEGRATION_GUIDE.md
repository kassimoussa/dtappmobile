# Guide d'Intégration Mobile - dtapi

Ce document fournit un guide complet pour l'intégration des APIs dtapi dans une application mobile.

## Vue d'ensemble

L'API dtapi est une API REST Laravel qui fournit des services de télécommunications mobiles incluant :
- Gestion des comptes mobiles (AIR)
- Rechargement de lignes fixes (TopUp)
- Envoi de SMS et vérification OTP
- Gestion des factures

**Base URL** : `https://your-domain.com/api`

## Configuration Requise

### Headers HTTP Standards
```
Content-Type: application/json
Accept: application/json
```

### Authentification (Optionnelle)
```
Authorization: Bearer {token}
```
*Note : La plupart des endpoints ne requièrent pas d'authentification actuellement*

## Structure des Réponses

### Réponse de Succès
```json
{
    "data": {
        // Données de réponse
    },
    "details": {
        "msisdn": "77123456",
        "request_time": "2024-01-01T10:00:00Z",
        "backend_api": "Air SOAP",
        "transaction_type": "credit_recharge"
    }
}
```

### Réponse d'Erreur
```json
{
    "erreur": "Description de l'erreur",
    "message": "Message utilisateur",
    "details": {
        "msisdn": "77123456",
        "additional_context": "..."
    }
}
```

### Codes de Statut HTTP
- `200` : Succès
- `400` : Erreur de validation
- `402` : Paiement requis
- `403` : Compte non actif
- `404` : Abonné non trouvé
- `409` : Opération déjà effectuée
- `500` : Erreur serveur

## Validation des Numéros de Téléphone (MSISDN)

### Formats Supportés
- **Format local** : 8 chiffres (77XXXXXX)
- **Format international** : 11 chiffres (25377XXXXXX)

### Règles de Validation
```javascript
// Regex pour validation côté mobile
const msisdnRegex = /^(77|78|70|75|76|33)[0-9]{6}$|^25(377|378|370|375|376|333)[0-9]{6}$/;
```

## APIs Détaillées

### 1. SMS / OTP API

#### Envoyer un SMS
```http
POST /api/sms/sms/send
```

**Paramètres :**
```json
{
    "from": "77123456",
    "to": "77987654",
    "text": "Votre message"
}
```

**Réponse :**
```json
{
    "message": "SMS envoyé avec succès",
    "message_id": "MSG_123456"
}
```

#### Envoyer un OTP
```http
POST /api/sms/otp/send
```

**Paramètres :**
```json
{
    "msisdn": "77123456"
}
```

**Réponse :**
```json
{
    "message": "OTP envoyé",
    "otp_id": "OTP_123456"
}
```

#### Vérifier un OTP
```http
POST /api/sms/otp/verify
```

**Paramètres :**
```json
{
    "msisdn": "77123456",
    "otp": "123456"
}
```

**Réponse :**
```json
{
    "valid": true,
    "message": "OTP valide"
}
```

### 2. AIR API (Comptes Mobiles)

#### Obtenir le Solde et les Dates
```http
GET /api/air/balance/{msisdn}
```

**Réponse :**
```json
{
    "balance": {
        "main_balance": 1500.50,
        "currency": "XOF",
        "expiry_date": "2024-02-15T23:59:59Z"
    },
    "account_info": {
        "msisdn": "77123456",
        "status": "active",
        "service_class": "prepaid"
    }
}
```

#### Obtenir les Offres Disponibles
```http
GET /api/air/offers/{msisdn}
```

**Réponse :**
```json
{
    "offers": [
        {
            "id": 10,
            "nom": "Forfait Internet 1GB",
            "type": {
                "id": 1,
                "libelle": "Data"
            },
            "prix": 500,
            "validite": {
                "debut": "2024-01-01T00:00:00Z",
                "fin": "2024-01-31T23:59:59Z"
            },
            "counters": [
                {
                    "type": "data",
                    "total": 1073741824,
                    "used": 536870912,
                    "remaining": 536870912,
                    "percentage": 50
                }
            ]
        }
    ]
}
```

#### Acheter une Offre (Personnel)
```http
POST /api/air/purchase/{msisdn}
```

**Paramètres :**
```json
{
    "offer_id": 10,
    "amount": 500
}
```

**Réponse :**
```json
{
    "success": true,
    "transaction_id": "TXN_123456",
    "message": "Offre achetée avec succès",
    "balance_after": 1000.50
}
```

#### Acheter une Offre (Cadeau)
```http
POST /api/air/gift/{msisdn}
```

**Paramètres :**
```json
{
    "offer_id": 10,
    "amount": 500,
    "recipient_msisdn": "77987654"
}
```

#### Ajouter du Crédit
```http
POST /api/air/credit/add/{msisdn}
```

**Paramètres :**
```json
{
    "amount": 1000,
    "currency": "XOF"
}
```

#### Déduire du Crédit
```http
POST /api/air/credit/deduct/{msisdn}
```

**Paramètres :**
```json
{
    "amount": 500,
    "currency": "XOF"
}
```

#### Transférer du Crédit
```http
POST /api/air/transfer-credit
```

**Paramètres :**
```json
{
    "from_msisdn": "77123456",
    "to_msisdn": "77987654",
    "amount": 500
}
```

### 3. AIR Refill API (Rechargement par Voucher)

#### Rechargement par Voucher
```http
POST /api/air/refill/voucher/{msisdn}
```

**Paramètres :**
```json
{
    "voucher_number": "1234567890123456",
    "voucher_pin": "1234"
}
```

**Réponse :**
```json
{
    "success": true,
    "amount_added": 1000,
    "new_balance": 2500.50,
    "transaction_id": "VCH_123456"
}
```

#### Vérifier un Voucher
```http
POST /api/air/refill/voucher/check/{msisdn}
```

**Paramètres :**
```json
{
    "voucher_number": "1234567890123456"
}
```

**Réponse :**
```json
{
    "valid": true,
    "value": 1000,
    "currency": "XOF",
    "status": "unused"
}
```

#### Historique des Rechargements
```http
GET /api/air/refill/history/{msisdn}
```

**Réponse :**
```json
{
    "history": [
        {
            "date": "2024-01-15T10:30:00Z",
            "type": "voucher",
            "amount": 1000,
            "voucher_number": "****1234",
            "status": "success"
        }
    ]
}
```

### 4. TopUp API (Lignes Fixes)

#### Obtenir les Soldes
```http
POST /api/topup/balances
```

**Paramètres :**
```json
{
    "msisdn": "77123456",
    "isdn": "338123456"
}
```

**Réponse :**
```json
{
    "balances": {
        "main_balance": 5000.00,
        "bonus_balance": 500.00,
        "currency": "XOF"
    }
}
```

#### Obtenir les Numéros du Répertoire
```http
GET /api/topup/numbers/{msisdn}
```

**Réponse :**
```json
{
    "numbers": [
        {
            "isdn": "338123456",
            "name": "Ligne Domicile",
            "type": "fixed"
        }
    ]
}
```

#### Souscrire à un Package
```http
POST /api/topup/subscribe-package
```

**Paramètres :**
```json
{
    "msisdn": "77123456",
    "isdn": "338123456",
    "package_id": "PKG_001",
    "pin": "1234"
}
```

#### Recharger un Compte
```http
POST /api/topup/recharge-account
```

**Paramètres :**
```json
{
    "msisdn": "77123456",
    "isdn": "338123456",
    "amount": 1000,
    "pin": "1234"
}
```

### 5. Invoice API (Factures)

#### Obtenir les Factures par Téléphone
```http
GET /api/invoice/phone/{msisdn}
```

**Réponse :**
```json
{
    "invoices": [
        {
            "invoice_number": "INV_123456",
            "amount": 25000,
            "due_date": "2024-02-15",
            "status": "unpaid",
            "customer_info": {
                "name": "John Doe",
                "msisdn": "77123456"
            }
        }
    ]
}
```

#### Obtenir une Facture par Numéro
```http
GET /api/invoice/number/{invoiceNumber}
```

**Réponse :**
```json
{
    "invoice": {
        "invoice_number": "INV_123456",
        "amount": 25000,
        "due_date": "2024-02-15",
        "status": "unpaid",
        "details": {
            "consumption": 15000,
            "taxes": 2500,
            "fees": 500
        }
    }
}
```

## Gestion des Erreurs

### Erreurs de Validation
```json
{
    "erreur": "Validation échouée",
    "message": "Le numéro de téléphone est invalide",
    "errors": {
        "msisdn": ["Le format du numéro est incorrect"]
    }
}
```

### Erreurs Métier
```json
{
    "erreur": "Solde insuffisant",
    "message": "Vous n'avez pas assez de crédit pour cette opération",
    "details": {
        "current_balance": 100,
        "required_amount": 500
    }
}
```

## Bonnes Pratiques d'Intégration

### 1. Gestion des Timeouts
- Définir des timeouts appropriés (15-30 secondes)
- Implémenter des mécanismes de retry pour les échecs réseau

### 2. Validation Côté Client
- Valider les MSISDNs avant l'envoi
- Vérifier les montants et formats requis

### 3. Gestion des États
- Stocker les états des transactions en cours
- Gérer les opérations asynchrones (OTP, etc.)

### 4. Sécurité
- Utiliser HTTPS uniquement
- Ne pas stocker les PINs en plain text
- Implémenter des mécanismes de rate limiting

### 5. UX/UI
- Afficher des messages d'erreur utilisateur-friendly
- Implémenter des indicateurs de chargement
- Permettre l'annulation d'opérations longues

## Exemples d'Intégration

### Exemple Flutter/Dart
```dart
class DtApiService {
    final String baseUrl = 'https://your-domain.com/api';
    
    Future<Map<String, dynamic>> getBalance(String msisdn) async {
        final response = await http.get(
            Uri.parse('$baseUrl/air/balance/$msisdn'),
            headers: {'Accept': 'application/json'}
        );
        
        if (response.statusCode == 200) {
            return jsonDecode(response.body);
        } else {
            throw Exception('Erreur API: ${response.statusCode}');
        }
    }
}
```

### Exemple React Native
```javascript
class DtApiService {
    constructor(baseUrl = 'https://your-domain.com/api') {
        this.baseUrl = baseUrl;
    }
    
    async getBalance(msisdn) {
        const response = await fetch(`${this.baseUrl}/air/balance/${msisdn}`, {
            headers: { 'Accept': 'application/json' }
        });
        
        if (response.ok) {
            return await response.json();
        } else {
            throw new Error(`API Error: ${response.status}`);
        }
    }
}
```

## Tests et Débogage

### Endpoint de Test
```http
GET /api/invoice/test
```

### Logs et Monitoring
- Toutes les requêtes SOAP sont loggées
- Utiliser les champs `details` pour le débogage
- Surveiller les codes de statut HTTP

## Support et Maintenance

### Versions API
- Version actuelle : Laravel 12.x
- Rétrocompatibilité maintenue

### Contact
- Documentation technique : Voir CLAUDE.md
- Issues : Créer un ticket dans le système de gestion

---

*Ce guide doit être mis à jour régulièrement en fonction des évolutions de l'API.*