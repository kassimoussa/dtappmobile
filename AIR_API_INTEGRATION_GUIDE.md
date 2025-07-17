# Guide d'Intégration Détaillé - AIR API

## Vue d'ensemble

L'API AIR est conçue pour la gestion des comptes mobiles prépayés de télécommunications à Djibouti. Elle permet de consulter les soldes, gérer les offres (packages), effectuer des recharges de crédit, des transferts et des achats d'offres via une interface REST qui communique avec un système AIR (Account Information and Refill) backend.

**Base URL**: `https://your-domain.com/api/air`

## Architecture Système

### Backend AIR
- **Serveur**: Configuration via `config/services.php`
- **Authentification**: Username/Password dans les headers
- **Endpoint**: `/Air` (configurable)
- **Timeout**: 60 secondes
- **Code pays**: 253 (Djibouti)
- **Protocole**: XML-RPC sur HTTP

### Validation des Numéros Mobile (MSISDN)
- **Format local**: 8 chiffres commençant par `77` (exemple: `77123456`)
- **Format international**: 11 chiffres commençant par `25377` (exemple: `25377123456`)
- **Regex local**: `^77\d{6}$`
- **Regex international**: `^25377\d{6}$`

### Offres Disponibles
- **10**: Classic (500 DJF, 30 jours)
- **11**: Median (1000 DJF, 30 jours)
- **12**: Premium (2000 DJF, 30 jours)
- **13**: Express (200 DJF, 1 jour)
- **15**: Découverte (500 DJF, 3 jours)
- **16**: Evasion (1000 DJF, 7 jours)
- **17**: Confort (3000 DJF, 30 jours)
- **29**: Sensation (1000 DJF, 30 jours)

## Configuration des Headers

### Headers Requis
```http
Content-Type: application/json
Accept: application/json
```

### Headers Optionnels pour Debug
```http
X-Debug: true
X-Request-ID: unique-request-id
```

## Structure des Réponses

### Réponse de Succès
```json
{
    "success": true,
    "message": "Opération réussie",
    "data": {
        // Données spécifiques à l'endpoint
    },
    "details": {
        "msisdn": "77123456",
        "request_time": "2024-01-15T10:30:00Z",
        "backend_api": "AIR",
        "operation_type": "balance_query"
    }
}
```

### Réponse d'Erreur
```json
{
    "erreur": "Description de l'erreur",
    "message": "Message utilisateur",
    "code_reponse": 102,
    "details": {
        "msisdn": "77123456",
        "error_source": "AIR_SERVICE",
        "timestamp": "2024-01-15T10:30:00Z"
    }
}
```

### Codes de Statut HTTP
- **200**: Succès
- **400**: Requête invalide (offre non définie)
- **402**: Limite de crédit dépassée
- **403**: Compte non actif, permission refusée
- **404**: Abonné/offre/produit non trouvé
- **413**: Résultat hors limites
- **500**: Erreur serveur interne
- **501**: Fonctionnalité non disponible

## Endpoints Détaillés

### 1. Consultation du Solde et Dates

#### Endpoint
```http
GET /api/air/balance/{msisdn}
```

#### Paramètres
- `msisdn`: Numéro mobile (format local ou international)

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Solde récupéré avec succès",
    "msisdn": "77123456",
    "balance": {
        "current_balance": 2500.50,
        "formatted_balance": "2 500.50 DJF",
        "currency": "DJF",
        "last_update": "2024-01-15T10:30:00Z"
    },
    "dates": {
        "account_expiry": "2024-06-15T23:59:59Z",
        "last_recharge": "2024-01-10T14:20:00Z",
        "service_fee_date": "2024-01-31T23:59:59Z"
    },
    "account_status": {
        "status": "active",
        "can_make_calls": true,
        "can_receive_calls": true,
        "can_use_data": true
    },
    "details": {
        "msisdn": "77123456",
        "request_time": "2024-01-15T10:30:00Z",
        "backend_api": "AIR"
    }
}
```

#### Erreurs Possibles
```json
{
    "erreur": "Abonné non trouvé",
    "message": "Le numéro 77123456 n'existe pas dans le système",
    "code_reponse": 102,
    "details": {
        "msisdn": "77123456",
        "error_type": "SUBSCRIBER_NOT_FOUND"
    }
}
```

### 2. Consultation des Offres Disponibles

#### Endpoint
```http
GET /api/air/offers/{msisdn}
```

#### Paramètres
- `msisdn`: Numéro mobile (format local ou international)

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Offres récupérées avec succès",
    "msisdn": "77123456",
    "offers": [
        {
            "offer_id": 10,
            "name": "Classic",
            "description": "Offre Classic avec données et voix",
            "price": 500.00,
            "formatted_price": "500.00 DJF",
            "validity_days": 30,
            "validity_formatted": "30 jours",
            "offer_type": "timer",
            "counters": {
                "voice_minutes": 120,
                "data_mb": 1024,
                "sms_count": 100
            },
            "formatted_counters": {
                "voice": "120 minutes",
                "data": "1 Go",
                "sms": "100 SMS"
            },
            "is_available": true,
            "can_afford": true,
            "features": [
                "120 minutes d'appels",
                "1 Go de données",
                "100 SMS",
                "Validité 30 jours"
            ]
        },
        {
            "offer_id": 13,
            "name": "Express",
            "description": "Offre Express quotidienne",
            "price": 200.00,
            "formatted_price": "200.00 DJF",
            "validity_days": 1,
            "validity_formatted": "1 jour",
            "offer_type": "timer",
            "counters": {
                "voice_minutes": 30,
                "data_mb": 256,
                "sms_count": 25
            },
            "formatted_counters": {
                "voice": "30 minutes",
                "data": "256 Mo",
                "sms": "25 SMS"
            },
            "is_available": true,
            "can_afford": true,
            "features": [
                "30 minutes d'appels",
                "256 Mo de données",
                "25 SMS",
                "Validité 1 jour"
            ]
        }
    ],
    "current_balance": 2500.50,
    "formatted_balance": "2 500.50 DJF",
    "total_offers": 2,
    "affordable_offers": 2,
    "summary": {
        "total_offers": 8,
        "available_offers": 2,
        "affordable_offers": 2,
        "price_range": {
            "min": 200.00,
            "max": 3000.00,
            "min_formatted": "200.00 DJF",
            "max_formatted": "3 000.00 DJF"
        }
    },
    "details": {
        "msisdn": "77123456",
        "request_time": "2024-01-15T10:30:00Z",
        "backend_api": "AIR"
    }
}
```

#### Types d'Offres
- **timer**: Offres avec durée limitée
- **counter**: Offres avec compteurs (usage)
- **combo**: Offres combinées (timer + counter)

### 3. Achat d'Offre (Personnel)

#### Endpoint
```http
POST /api/air/purchase/{msisdn}
POST /api/air/purchase
```

#### Paramètres
```json
{
    "msisdn": "77123456",    // Numéro mobile
    "offer_id": 10           // ID de l'offre à acheter
}
```

#### Validation
- `msisdn`: Format mobile valide
- `offer_id`: ID valide (10,11,12,13,15,16,17,29)

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Offre achetée avec succès",
    "msisdn": "77123456",
    "offer_purchased": {
        "offer_id": 10,
        "offer_name": "Classic",
        "price_paid": 500.00,
        "formatted_price": "500.00 DJF",
        "validity_days": 30,
        "activation_date": "2024-01-15T10:30:00Z",
        "expiry_date": "2024-02-14T10:30:00Z"
    },
    "account_impact": {
        "balance_before": 2500.50,
        "price_deducted": 500.00,
        "balance_after": 2000.50,
        "formatted_balance_after": "2 000.50 DJF"
    },
    "details": {
        "msisdn": "77123456",
        "offer_id": 10,
        "offer_name": "Classic",
        "offer_price": 500.00,
        "offer_price_formatted": "500.00 DJF",
        "days_validity": 30,
        "offer_type": 2,
        "purchase_time": "2024-01-15T10:30:00Z",
        "transaction_steps": {
            "1_deduction_prix": "Succès",
            "2_assignation_offre": "Succès"
        }
    }
}
```

#### Erreurs Possibles
```json
{
    "erreur": "Solde insuffisant",
    "message": "Votre solde est insuffisant pour acheter cette offre",
    "code_reponse": 123,
    "details": {
        "msisdn": "77123456",
        "offer_id": 10,
        "offer_price_required": 500.00,
        "current_balance": 300.00,
        "missing_amount": 200.00
    }
}
```

### 4. Achat d'Offre Cadeau

#### Endpoint
```http
POST /api/air/gift/{msisdn}
POST /api/air/gift
```

#### Paramètres
```json
{
    "msisdn": "77123456",              // Numéro du payeur
    "beneficiary_msisdn": "77654321",  // Numéro du bénéficiaire
    "offer_id": 10                     // ID de l'offre à offrir
}
```

#### Validation
- `msisdn`: Format mobile valide (payeur)
- `beneficiary_msisdn`: Format mobile valide (bénéficiaire, différent du payeur)
- `offer_id`: ID valide (10,11,12,13,15,16,17,29)

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Offre offerte avec succès",
    "transaction_type": "gift_purchase",
    "payer": {
        "msisdn": "77123456",
        "balance_before": 2500.50,
        "price_deducted": 500.00,
        "balance_after": 2000.50,
        "formatted_balance_after": "2 000.50 DJF"
    },
    "beneficiary": {
        "msisdn": "77654321",
        "offer_received": {
            "offer_id": 10,
            "offer_name": "Classic",
            "validity_days": 30,
            "activation_date": "2024-01-15T10:30:00Z",
            "expiry_date": "2024-02-14T10:30:00Z"
        }
    },
    "details": {
        "payer_msisdn": "77123456",
        "beneficiary_msisdn": "77654321",
        "offer_id": 10,
        "offer_name": "Classic",
        "offer_price": 500.00,
        "offer_price_formatted": "500.00 DJF",
        "days_validity": 30,
        "offer_type": 2,
        "purchase_time": "2024-01-15T10:30:00Z",
        "transaction_type": "gift_purchase",
        "transaction_steps": {
            "1_deduction_prix_payeur": "Succès",
            "2_assignation_offre_beneficiaire": "Succès"
        },
        "message_friendly": "Offre Classic offerte avec succès à 77654321"
    }
}
```

### 5. Recharge de Crédit

#### Endpoint
```http
POST /api/air/credit/add/{msisdn}
POST /api/air/credit/add
```

#### Paramètres
```json
{
    "msisdn": "77123456",    // Numéro mobile
    "amount": 1000.0         // Montant à ajouter (en DJF)
}
```

#### Validation
- `msisdn`: Format mobile valide
- `amount`: Nombre positif, entre 1 et 100,000 DJF

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Crédit ajouté avec succès",
    "msisdn": "77123456",
    "credit_added": {
        "amount": 1000.0,
        "formatted_amount": "1 000.00 DJF",
        "currency": "DJF",
        "transaction_time": "2024-01-15T10:30:00Z"
    },
    "account_impact": {
        "balance_before": 2500.50,
        "amount_added": 1000.0,
        "balance_after": 3500.50,
        "formatted_balance_after": "3 500.50 DJF"
    },
    "details": {
        "msisdn": "77123456",
        "amount_added": 1000.0,
        "amount_added_formatted": "1 000.00 DJF",
        "amount_in_centimes": 100000,
        "topup_time": "2024-01-15T10:30:00Z",
        "transaction_type": "credit_recharge"
    }
}
```

### 6. Déduction de Crédit

#### Endpoint
```http
POST /api/air/credit/deduct/{msisdn}
POST /api/air/credit/deduct
```

#### Paramètres
```json
{
    "msisdn": "77123456",    // Numéro mobile
    "amount": 500.0          // Montant à déduire (en DJF)
}
```

#### Validation
- `msisdn`: Format mobile valide
- `amount`: Nombre positif, entre 1 et 100,000 DJF

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Crédit déduit avec succès",
    "msisdn": "77123456",
    "credit_deducted": {
        "amount": 500.0,
        "formatted_amount": "500.00 DJF",
        "currency": "DJF",
        "transaction_time": "2024-01-15T10:30:00Z"
    },
    "account_impact": {
        "balance_before": 2500.50,
        "amount_deducted": 500.0,
        "balance_after": 2000.50,
        "formatted_balance_after": "2 000.50 DJF"
    },
    "details": {
        "msisdn": "77123456",
        "amount_deducted": 500.0,
        "amount_deducted_formatted": "500.00 DJF",
        "amount_in_centimes": -50000,
        "deduction_time": "2024-01-15T10:30:00Z",
        "transaction_type": "credit_deduction"
    }
}
```

### 7. Transfert de Crédit

#### Endpoint
```http
POST /api/air/transfer-credit
```

#### Paramètres
```json
{
    "sender_msisdn": "77123456",      // Numéro de l'expéditeur
    "receiver_msisdn": "77654321",    // Numéro du destinataire
    "amount": 100.0                   // Montant à transférer (en DJF)
}
```

#### Validation
- `sender_msisdn`: Format mobile valide
- `receiver_msisdn`: Format mobile valide (différent de l'expéditeur)
- `amount`: Nombre positif, minimum 50 DJF, multiple de 5 DJF

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Transfert de crédit effectué avec succès",
    "transfer_info": {
        "sender_msisdn": "77123456",
        "receiver_msisdn": "77654321",
        "amount": 100.0,
        "formatted_amount": "100.00 DJF",
        "currency": "DJF",
        "transaction_time": "2024-01-15T10:30:00Z",
        "transaction_id": "TRF20240115103000123"
    },
    "sender_impact": {
        "balance_before": 2500.50,
        "amount_sent": 100.0,
        "balance_after": 2400.50,
        "formatted_balance_after": "2 400.50 DJF"
    },
    "receiver_impact": {
        "balance_before": 800.0,
        "amount_received": 100.0,
        "balance_after": 900.0,
        "formatted_balance_after": "900.00 DJF"
    },
    "verification_steps": {
        "sender_existence": "Vérifié",
        "receiver_existence": "Vérifié",
        "sender_balance": "Suffisant",
        "transfer_execution": "Succès"
    }
}
```

#### Erreurs Possibles
```json
{
    "erreur": "Solde insuffisant pour le transfert",
    "message": "Votre solde est insuffisant pour effectuer ce transfert",
    "etape": "verification_solde_expediteur",
    "details": {
        "sender_msisdn": "77123456",
        "receiver_msisdn": "77654321",
        "amount_requested": 100.0,
        "current_balance": 50.0,
        "missing_amount": 50.0
    }
}
```

### 8. Recharge par Voucher (Refill)

#### Endpoint
```http
POST /api/air/refill/voucher/{msisdn}
POST /api/air/refill/voucher
```

#### Paramètres
```json
{
    "msisdn": "77123456",           // Numéro mobile
    "voucher_code": "1234567890"    // Code voucher
}
```

#### Validation
- `msisdn`: Format mobile valide
- `voucher_code`: Code alphanumérique

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Recharge par voucher effectuée avec succès",
    "msisdn": "77123456",
    "voucher_info": {
        "voucher_code": "1234567890",
        "voucher_value": 500.0,
        "formatted_value": "500.00 DJF",
        "currency": "DJF",
        "recharge_time": "2024-01-15T10:30:00Z"
    },
    "account_impact": {
        "balance_before": 2500.50,
        "voucher_value": 500.0,
        "balance_after": 3000.50,
        "formatted_balance_after": "3 000.50 DJF"
    },
    "details": {
        "msisdn": "77123456",
        "voucher_code": "1234567890",
        "recharge_time": "2024-01-15T10:30:00Z",
        "transaction_type": "voucher_recharge"
    }
}
```

## Codes d'Erreur Spécifiques

### Codes de Réponse AIR
- **0**: Succès
- **100**: Erreur générale
- **102**: Abonné non trouvé
- **123**: Limite de crédit maximale dépassée
- **126**: Compte non actif
- **137**: Mise à jour du solde non autorisée
- **165**: Offre non trouvée
- **214**: Offre non définie
- **247**: Produit non trouvé
- **260**: Fonctionnalité non disponible
- **264**: Résultat hors limites
- **266**: Permission refusée

### Mapping HTTP Status
- **0**: HTTP 200 (OK)
- **100**: HTTP 500 (Internal Server Error)
- **102**: HTTP 404 (Not Found)
- **123**: HTTP 402 (Payment Required)
- **126**: HTTP 403 (Forbidden)
- **137**: HTTP 403 (Forbidden)
- **165**: HTTP 404 (Not Found)
- **214**: HTTP 400 (Bad Request)
- **247**: HTTP 404 (Not Found)
- **260**: HTTP 501 (Not Implemented)
- **264**: HTTP 413 (Payload Too Large)
- **266**: HTTP 403 (Forbidden)

## Structure des Données

### Objet Balance
```json
{
    "current_balance": 2500.50,
    "formatted_balance": "2 500.50 DJF",
    "currency": "DJF",
    "last_update": "2024-01-15T10:30:00Z"
}
```

### Objet Offer
```json
{
    "offer_id": 10,
    "name": "Classic",
    "description": "Offre Classic avec données et voix",
    "price": 500.00,
    "formatted_price": "500.00 DJF",
    "validity_days": 30,
    "validity_formatted": "30 jours",
    "offer_type": "timer",
    "counters": {
        "voice_minutes": 120,
        "data_mb": 1024,
        "sms_count": 100
    },
    "formatted_counters": {
        "voice": "120 minutes",
        "data": "1 Go",
        "sms": "100 SMS"
    },
    "is_available": true,
    "can_afford": true,
    "features": [
        "120 minutes d'appels",
        "1 Go de données",
        "100 SMS",
        "Validité 30 jours"
    ]
}
```

### Objet Account Impact
```json
{
    "balance_before": 2500.50,
    "amount_processed": 500.00,
    "balance_after": 2000.50,
    "formatted_balance_after": "2 000.50 DJF"
}
```

## Gestion des Erreurs

### Erreurs de Validation
```json
{
    "erreur": "Données invalides",
    "message": "Les données fournies ne respectent pas les règles de validation",
    "errors": {
        "msisdn": [
            "Le numéro doit être au format local (8 chiffres commençant par 77) ou international (11 chiffres commençant par 25377)"
        ],
        "offer_id": [
            "L'ID de l'offre n'est pas valide. Offres disponibles: 10 (Classic), 11 (Median), 12 (Premium), 13 (Express), 15 (Découverte), 16 (Evasion), 17 (Confort), 29 (Sensation)"
        ]
    }
}
```

### Erreurs AIR
```json
{
    "erreur": "Compte non actif",
    "message": "Le compte mobile n'est pas actif",
    "code_reponse": 126,
    "details": {
        "msisdn": "77123456",
        "error_type": "ACCOUNT_INACTIVE",
        "backend_api": "AIR"
    }
}
```

### Erreurs Système
```json
{
    "erreur": "Erreur serveur",
    "message": "Une erreur est survenue lors du traitement de la requête",
    "details": {
        "msisdn": "77123456",
        "backend_api": "AIR"
    }
}
```

## Exemples d'Intégration Mobile

### Classe Service Flutter/Dart
```dart
class AirApiService {
    final String baseUrl;
    final http.Client client;
    
    AirApiService({
        required this.baseUrl,
        http.Client? client,
    }) : client = client ?? http.Client();
    
    Future<BalanceResponse> getBalance({
        required String msisdn,
    }) async {
        final response = await client.get(
            Uri.parse('$baseUrl/air/balance/$msisdn'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
        );
        
        if (response.statusCode == 200) {
            return BalanceResponse.fromJson(jsonDecode(response.body));
        } else {
            throw AirApiException.fromResponse(response);
        }
    }
    
    Future<OffersResponse> getOffers({
        required String msisdn,
    }) async {
        final response = await client.get(
            Uri.parse('$baseUrl/air/offers/$msisdn'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
        );
        
        if (response.statusCode == 200) {
            return OffersResponse.fromJson(jsonDecode(response.body));
        } else {
            throw AirApiException.fromResponse(response);
        }
    }
    
    Future<PurchaseResponse> purchaseOffer({
        required String msisdn,
        required int offerId,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/air/purchase'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'msisdn': msisdn,
                'offer_id': offerId,
            }),
        );
        
        if (response.statusCode == 200) {
            return PurchaseResponse.fromJson(jsonDecode(response.body));
        } else {
            throw AirApiException.fromResponse(response);
        }
    }
    
    Future<GiftResponse> purchaseGift({
        required String payerMsisdn,
        required String beneficiaryMsisdn,
        required int offerId,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/air/gift'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'msisdn': payerMsisdn,
                'beneficiary_msisdn': beneficiaryMsisdn,
                'offer_id': offerId,
            }),
        );
        
        if (response.statusCode == 200) {
            return GiftResponse.fromJson(jsonDecode(response.body));
        } else {
            throw AirApiException.fromResponse(response);
        }
    }
    
    Future<CreditResponse> addCredit({
        required String msisdn,
        required double amount,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/air/credit/add'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'msisdn': msisdn,
                'amount': amount,
            }),
        );
        
        if (response.statusCode == 200) {
            return CreditResponse.fromJson(jsonDecode(response.body));
        } else {
            throw AirApiException.fromResponse(response);
        }
    }
    
    Future<TransferResponse> transferCredit({
        required String senderMsisdn,
        required String receiverMsisdn,
        required double amount,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/air/transfer-credit'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'sender_msisdn': senderMsisdn,
                'receiver_msisdn': receiverMsisdn,
                'amount': amount,
            }),
        );
        
        if (response.statusCode == 200) {
            return TransferResponse.fromJson(jsonDecode(response.body));
        } else {
            throw AirApiException.fromResponse(response);
        }
    }
    
    Future<RefillResponse> refillByVoucher({
        required String msisdn,
        required String voucherCode,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/air/refill/voucher'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'msisdn': msisdn,
                'voucher_code': voucherCode,
            }),
        );
        
        if (response.statusCode == 200) {
            return RefillResponse.fromJson(jsonDecode(response.body));
        } else {
            throw AirApiException.fromResponse(response);
        }
    }
}

// Modèles de données
class BalanceResponse {
    final bool success;
    final String message;
    final String msisdn;
    final Balance balance;
    final AccountDates dates;
    final AccountStatus accountStatus;
    
    BalanceResponse({
        required this.success,
        required this.message,
        required this.msisdn,
        required this.balance,
        required this.dates,
        required this.accountStatus,
    });
    
    factory BalanceResponse.fromJson(Map<String, dynamic> json) {
        return BalanceResponse(
            success: json['success'],
            message: json['message'],
            msisdn: json['msisdn'],
            balance: Balance.fromJson(json['balance']),
            dates: AccountDates.fromJson(json['dates']),
            accountStatus: AccountStatus.fromJson(json['account_status']),
        );
    }
}

class Balance {
    final double currentBalance;
    final String formattedBalance;
    final String currency;
    final String lastUpdate;
    
    Balance({
        required this.currentBalance,
        required this.formattedBalance,
        required this.currency,
        required this.lastUpdate,
    });
    
    factory Balance.fromJson(Map<String, dynamic> json) {
        return Balance(
            currentBalance: json['current_balance'].toDouble(),
            formattedBalance: json['formatted_balance'],
            currency: json['currency'],
            lastUpdate: json['last_update'],
        );
    }
}

class OffersResponse {
    final bool success;
    final String message;
    final String msisdn;
    final List<Offer> offers;
    final double currentBalance;
    final String formattedBalance;
    final int totalOffers;
    final int affordableOffers;
    final OffersSummary summary;
    
    OffersResponse({
        required this.success,
        required this.message,
        required this.msisdn,
        required this.offers,
        required this.currentBalance,
        required this.formattedBalance,
        required this.totalOffers,
        required this.affordableOffers,
        required this.summary,
    });
    
    factory OffersResponse.fromJson(Map<String, dynamic> json) {
        return OffersResponse(
            success: json['success'],
            message: json['message'],
            msisdn: json['msisdn'],
            offers: (json['offers'] as List)
                .map((item) => Offer.fromJson(item))
                .toList(),
            currentBalance: json['current_balance'].toDouble(),
            formattedBalance: json['formatted_balance'],
            totalOffers: json['total_offers'],
            affordableOffers: json['affordable_offers'],
            summary: OffersSummary.fromJson(json['summary']),
        );
    }
}

class Offer {
    final int offerId;
    final String name;
    final String description;
    final double price;
    final String formattedPrice;
    final int validityDays;
    final String validityFormatted;
    final String offerType;
    final Map<String, dynamic> counters;
    final Map<String, String> formattedCounters;
    final bool isAvailable;
    final bool canAfford;
    final List<String> features;
    
    Offer({
        required this.offerId,
        required this.name,
        required this.description,
        required this.price,
        required this.formattedPrice,
        required this.validityDays,
        required this.validityFormatted,
        required this.offerType,
        required this.counters,
        required this.formattedCounters,
        required this.isAvailable,
        required this.canAfford,
        required this.features,
    });
    
    factory Offer.fromJson(Map<String, dynamic> json) {
        return Offer(
            offerId: json['offer_id'],
            name: json['name'],
            description: json['description'],
            price: json['price'].toDouble(),
            formattedPrice: json['formatted_price'],
            validityDays: json['validity_days'],
            validityFormatted: json['validity_formatted'],
            offerType: json['offer_type'],
            counters: json['counters'],
            formattedCounters: Map<String, String>.from(json['formatted_counters']),
            isAvailable: json['is_available'],
            canAfford: json['can_afford'],
            features: List<String>.from(json['features']),
        );
    }
}

// Gestion des erreurs
class AirApiException implements Exception {
    final String error;
    final String message;
    final int? codeReponse;
    final int statusCode;
    final Map<String, dynamic>? details;
    
    AirApiException({
        required this.error,
        required this.message,
        this.codeReponse,
        required this.statusCode,
        this.details,
    });
    
    factory AirApiException.fromResponse(http.Response response) {
        final body = jsonDecode(response.body);
        return AirApiException(
            error: body['erreur'] ?? 'Erreur inconnue',
            message: body['message'] ?? 'Une erreur est survenue',
            codeReponse: body['code_reponse'],
            statusCode: response.statusCode,
            details: body['details'],
        );
    }
    
    @override
    String toString() {
        return 'AirApiException: $error - $message (HTTP $statusCode)';
    }
}
```

### Classe Service React Native/TypeScript
```typescript
interface AirApiConfig {
    baseUrl: string;
    timeout?: number;
}

interface Balance {
    current_balance: number;
    formatted_balance: string;
    currency: string;
    last_update: string;
}

interface AccountDates {
    account_expiry: string;
    last_recharge: string;
    service_fee_date: string;
}

interface AccountStatus {
    status: string;
    can_make_calls: boolean;
    can_receive_calls: boolean;
    can_use_data: boolean;
}

interface BalanceResponse {
    success: boolean;
    message: string;
    msisdn: string;
    balance: Balance;
    dates: AccountDates;
    account_status: AccountStatus;
}

interface Offer {
    offer_id: number;
    name: string;
    description: string;
    price: number;
    formatted_price: string;
    validity_days: number;
    validity_formatted: string;
    offer_type: string;
    counters: {
        voice_minutes: number;
        data_mb: number;
        sms_count: number;
    };
    formatted_counters: {
        voice: string;
        data: string;
        sms: string;
    };
    is_available: boolean;
    can_afford: boolean;
    features: string[];
}

interface OffersResponse {
    success: boolean;
    message: string;
    msisdn: string;
    offers: Offer[];
    current_balance: number;
    formatted_balance: string;
    total_offers: number;
    affordable_offers: number;
    summary: {
        total_offers: number;
        available_offers: number;
        affordable_offers: number;
        price_range: {
            min: number;
            max: number;
            min_formatted: string;
            max_formatted: string;
        };
    };
}

interface PurchaseResponse {
    success: boolean;
    message: string;
    msisdn: string;
    offer_purchased: {
        offer_id: number;
        offer_name: string;
        price_paid: number;
        formatted_price: string;
        validity_days: number;
        activation_date: string;
        expiry_date: string;
    };
    account_impact: {
        balance_before: number;
        price_deducted: number;
        balance_after: number;
        formatted_balance_after: string;
    };
}

interface TransferResponse {
    success: boolean;
    message: string;
    transfer_info: {
        sender_msisdn: string;
        receiver_msisdn: string;
        amount: number;
        formatted_amount: string;
        currency: string;
        transaction_time: string;
        transaction_id: string;
    };
    sender_impact: {
        balance_before: number;
        amount_sent: number;
        balance_after: number;
        formatted_balance_after: string;
    };
    receiver_impact: {
        balance_before: number;
        amount_received: number;
        balance_after: number;
        formatted_balance_after: string;
    };
}

class AirApiService {
    private baseUrl: string;
    private timeout: number;
    
    constructor(config: AirApiConfig) {
        this.baseUrl = config.baseUrl;
        this.timeout = config.timeout || 30000;
    }
    
    private async request<T>(
        endpoint: string,
        method: 'GET' | 'POST' = 'GET',
        body?: any
    ): Promise<T> {
        const url = `${this.baseUrl}${endpoint}`;
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.timeout);
        
        try {
            const response = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                body: body ? JSON.stringify(body) : undefined,
                signal: controller.signal,
            });
            
            clearTimeout(timeoutId);
            
            const responseData = await response.json();
            
            if (!response.ok) {
                throw new AirApiError(
                    responseData.erreur || 'Erreur inconnue',
                    responseData.message || 'Une erreur est survenue',
                    response.status,
                    responseData.code_reponse,
                    responseData.details
                );
            }
            
            return responseData as T;
        } catch (error) {
            clearTimeout(timeoutId);
            if (error instanceof AirApiError) {
                throw error;
            }
            throw new AirApiError(
                'Erreur réseau',
                'Impossible de communiquer avec le serveur',
                0,
                undefined,
                { originalError: error }
            );
        }
    }
    
    async getBalance(msisdn: string): Promise<BalanceResponse> {
        return this.request<BalanceResponse>(`/air/balance/${msisdn}`);
    }
    
    async getOffers(msisdn: string): Promise<OffersResponse> {
        return this.request<OffersResponse>(`/air/offers/${msisdn}`);
    }
    
    async purchaseOffer(msisdn: string, offerId: number): Promise<PurchaseResponse> {
        return this.request<PurchaseResponse>('/air/purchase', 'POST', {
            msisdn,
            offer_id: offerId,
        });
    }
    
    async purchaseGift(
        payerMsisdn: string,
        beneficiaryMsisdn: string,
        offerId: number
    ): Promise<any> {
        return this.request<any>('/air/gift', 'POST', {
            msisdn: payerMsisdn,
            beneficiary_msisdn: beneficiaryMsisdn,
            offer_id: offerId,
        });
    }
    
    async addCredit(msisdn: string, amount: number): Promise<any> {
        return this.request<any>('/air/credit/add', 'POST', {
            msisdn,
            amount,
        });
    }
    
    async deductCredit(msisdn: string, amount: number): Promise<any> {
        return this.request<any>('/air/credit/deduct', 'POST', {
            msisdn,
            amount,
        });
    }
    
    async transferCredit(
        senderMsisdn: string,
        receiverMsisdn: string,
        amount: number
    ): Promise<TransferResponse> {
        return this.request<TransferResponse>('/air/transfer-credit', 'POST', {
            sender_msisdn: senderMsisdn,
            receiver_msisdn: receiverMsisdn,
            amount,
        });
    }
    
    async refillByVoucher(msisdn: string, voucherCode: string): Promise<any> {
        return this.request<any>('/air/refill/voucher', 'POST', {
            msisdn,
            voucher_code: voucherCode,
        });
    }
}

class AirApiError extends Error {
    constructor(
        public error: string,
        public message: string,
        public statusCode: number,
        public codeReponse?: number,
        public details?: any
    ) {
        super(message);
        this.name = 'AirApiError';
    }
}

// Utilitaires de validation
class AirValidation {
    static validateMsisdn(msisdn: string): boolean {
        const localRegex = /^77\d{6}$/;
        const internationalRegex = /^25377\d{6}$/;
        return localRegex.test(msisdn) || internationalRegex.test(msisdn);
    }
    
    static validateOfferId(offerId: number): boolean {
        const validOffers = [10, 11, 12, 13, 15, 16, 17, 29];
        return validOffers.includes(offerId);
    }
    
    static validateAmount(amount: number, min: number = 1, max: number = 100000): boolean {
        return amount >= min && amount <= max;
    }
    
    static validateTransferAmount(amount: number): boolean {
        return amount >= 50 && (amount * 100) % 500 === 0; // Multiple de 5 DJF
    }
    
    static formatMsisdn(msisdn: string): string {
        if (msisdn.length === 8) {
            return msisdn.replace(/(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4');
        }
        if (msisdn.length === 11) {
            return msisdn.replace(/(\d{3})(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4 $5');
        }
        return msisdn;
    }
    
    static getOfferName(offerId: number): string {
        const offerNames = {
            10: 'Classic',
            11: 'Median',
            12: 'Premium',
            13: 'Express',
            15: 'Découverte',
            16: 'Evasion',
            17: 'Confort',
            29: 'Sensation'
        };
        return offerNames[offerId] || `Offre ${offerId}`;
    }
}

// Utilisation
const airService = new AirApiService({
    baseUrl: 'https://your-domain.com/api',
    timeout: 30000,
});

// Exemple d'utilisation
async function handleGetBalance() {
    try {
        const msisdn = '77123456';
        
        // Validation côté client
        if (!AirValidation.validateMsisdn(msisdn)) {
            console.error('Numéro de téléphone invalide');
            return;
        }
        
        const response = await airService.getBalance(msisdn);
        
        console.log('Solde actuel:', response.balance.formatted_balance);
        console.log('Statut du compte:', response.account_status.status);
        console.log('Expiration:', response.dates.account_expiry);
        
    } catch (error) {
        if (error instanceof AirApiError) {
            console.error('API Error:', error.error);
            console.error('Message:', error.message);
            console.error('Code réponse:', error.codeReponse);
            console.error('Status Code:', error.statusCode);
        } else {
            console.error('Unexpected error:', error);
        }
    }
}

async function handlePurchaseOffer() {
    try {
        const msisdn = '77123456';
        const offerId = 10;
        
        // Validation côté client
        if (!AirValidation.validateMsisdn(msisdn)) {
            console.error('Numéro de téléphone invalide');
            return;
        }
        
        if (!AirValidation.validateOfferId(offerId)) {
            console.error('ID offre invalide');
            return;
        }
        
        const response = await airService.purchaseOffer(msisdn, offerId);
        
        console.log('Offre achetée:', response.offer_purchased.offer_name);
        console.log('Prix payé:', response.offer_purchased.formatted_price);
        console.log('Nouveau solde:', response.account_impact.formatted_balance_after);
        
    } catch (error) {
        if (error instanceof AirApiError) {
            console.error('API Error:', error.error);
            if (error.codeReponse === 123) {
                console.log('Solde insuffisant pour acheter cette offre');
            }
        } else {
            console.error('Unexpected error:', error);
        }
    }
}

async function handleTransferCredit() {
    try {
        const senderMsisdn = '77123456';
        const receiverMsisdn = '77654321';
        const amount = 100;
        
        // Validation côté client
        if (!AirValidation.validateMsisdn(senderMsisdn) || 
            !AirValidation.validateMsisdn(receiverMsisdn)) {
            console.error('Numéro de téléphone invalide');
            return;
        }
        
        if (!AirValidation.validateTransferAmount(amount)) {
            console.error('Montant de transfert invalide (minimum 50 DJF, multiple de 5)');
            return;
        }
        
        if (senderMsisdn === receiverMsisdn) {
            console.error('L\'expéditeur et le destinataire doivent être différents');
            return;
        }
        
        const response = await airService.transferCredit(senderMsisdn, receiverMsisdn, amount);
        
        console.log('Transfert réussi:', response.transfer_info.formatted_amount);
        console.log('Nouveau solde expéditeur:', response.sender_impact.formatted_balance_after);
        console.log('Nouveau solde destinataire:', response.receiver_impact.formatted_balance_after);
        
    } catch (error) {
        if (error instanceof AirApiError) {
            console.error('API Error:', error.error);
            if (error.details?.etape === 'verification_solde_expediteur') {
                console.log('Solde insuffisant pour effectuer le transfert');
            }
        } else {
            console.error('Unexpected error:', error);
        }
    }
}
```

## Bonnes Pratiques d'Intégration

### 1. Validation Côté Client
```javascript
// Validation des numéros mobiles
function validateMsisdn(msisdn) {
    const localRegex = /^77\d{6}$/;
    const internationalRegex = /^25377\d{6}$/;
    return localRegex.test(msisdn) || internationalRegex.test(msisdn);
}

// Validation des IDs d'offre
function validateOfferId(offerId) {
    const validOffers = [10, 11, 12, 13, 15, 16, 17, 29];
    return validOffers.includes(offerId);
}

// Validation des montants
function validateAmount(amount, min = 1, max = 100000) {
    return typeof amount === 'number' && amount >= min && amount <= max;
}

// Validation des transferts
function validateTransferAmount(amount) {
    return amount >= 50 && (amount * 100) % 500 === 0;
}
```

### 2. Gestion des Timeouts
```javascript
// Timeouts recommandés par type d'opération
const TIMEOUTS = {
    balance_query: 15000,        // 15 secondes
    offers_query: 20000,         // 20 secondes
    offer_purchase: 45000,       // 45 secondes
    credit_operations: 30000,    // 30 secondes
    transfer_operations: 60000,  // 60 secondes
    voucher_refill: 30000,       // 30 secondes
};
```

### 3. Retry Logic
```javascript
async function withRetry(operation, maxRetries = 3, delay = 1000) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await operation();
        } catch (error) {
            if (i === maxRetries - 1) throw error;
            
            // Retry seulement pour les erreurs réseau ou serveur
            if (error.statusCode >= 500 || error.statusCode === 0) {
                await new Promise(resolve => setTimeout(resolve, delay * (i + 1)));
            } else {
                throw error;
            }
        }
    }
}
```

### 4. Gestion des États
```javascript
// États pour les opérations
const OPERATION_STATES = {
    IDLE: 'idle',
    LOADING: 'loading',
    SUCCESS: 'success',
    ERROR: 'error',
    RETRY: 'retry'
};

// Gestion des offres en cache
class OfferCache {
    constructor(ttl = 300000) { // 5 minutes
        this.cache = new Map();
        this.ttl = ttl;
    }
    
    set(msisdn, offers) {
        const expiry = Date.now() + this.ttl;
        this.cache.set(msisdn, { offers, expiry });
    }
    
    get(msisdn) {
        const entry = this.cache.get(msisdn);
        if (entry && entry.expiry > Date.now()) {
            return entry.offers;
        }
        this.cache.delete(msisdn);
        return null;
    }
    
    clear() {
        this.cache.clear();
    }
}
```

### 5. Formatage des Données
```javascript
// Utilitaires de formatage
class AirFormatter {
    static formatAmount(amount) {
        return new Intl.NumberFormat('fr-DJ', {
            style: 'currency',
            currency: 'DJF',
            minimumFractionDigits: 2
        }).format(amount);
    }
    
    static formatMsisdn(msisdn) {
        if (msisdn.length === 8) {
            return msisdn.replace(/(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4');
        }
        if (msisdn.length === 11) {
            return msisdn.replace(/(\d{3})(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4 $5');
        }
        return msisdn;
    }
    
    static formatValidity(days) {
        if (days === 1) return '1 jour';
        if (days < 7) return `${days} jours`;
        if (days === 7) return '1 semaine';
        if (days < 30) return `${Math.round(days / 7)} semaines`;
        if (days === 30) return '1 mois';
        return `${Math.round(days / 30)} mois`;
    }
    
    static formatData(megabytes) {
        if (megabytes < 1024) return `${megabytes} Mo`;
        return `${(megabytes / 1024).toFixed(1)} Go`;
    }
    
    static formatVoice(minutes) {
        if (minutes < 60) return `${minutes} min`;
        const hours = Math.floor(minutes / 60);
        const remainingMin = minutes % 60;
        return remainingMin > 0 ? `${hours}h ${remainingMin}min` : `${hours}h`;
    }
}
```

## Monitoring et Debugging

### 1. Logging
```javascript
class AirLogger {
    constructor(level = 'info') {
        this.level = level;
    }
    
    log(level, message, data = null) {
        if (this.shouldLog(level)) {
            const timestamp = new Date().toISOString();
            const logEntry = {
                timestamp,
                level,
                message,
                data,
                service: 'air-api'
            };
            
            console.log(JSON.stringify(logEntry));
        }
    }
    
    shouldLog(level) {
        const levels = ['debug', 'info', 'warn', 'error'];
        return levels.indexOf(level) >= levels.indexOf(this.level);
    }
    
    debug(message, data) { this.log('debug', message, data); }
    info(message, data) { this.log('info', message, data); }
    warn(message, data) { this.log('warn', message, data); }
    error(message, data) { this.log('error', message, data); }
}
```

### 2. Métriques
```javascript
class AirMetrics {
    constructor() {
        this.metrics = {
            requests: 0,
            successes: 0,
            errors: 0,
            responseTime: [],
            errorsByCode: {},
            operationsByType: {}
        };
    }
    
    recordRequest(operation, responseTime, success, error = null) {
        this.metrics.requests++;
        this.metrics.responseTime.push(responseTime);
        
        // Enregistrer par type d'opération
        this.metrics.operationsByType[operation] = 
            (this.metrics.operationsByType[operation] || 0) + 1;
        
        if (success) {
            this.metrics.successes++;
        } else {
            this.metrics.errors++;
            if (error) {
                const errorCode = error.codeReponse || 'unknown';
                this.metrics.errorsByCode[errorCode] = 
                    (this.metrics.errorsByCode[errorCode] || 0) + 1;
            }
        }
    }
    
    getMetrics() {
        const avgResponseTime = this.metrics.responseTime.length > 0 
            ? this.metrics.responseTime.reduce((a, b) => a + b, 0) / this.metrics.responseTime.length
            : 0;
            
        return {
            ...this.metrics,
            successRate: this.metrics.requests > 0 
                ? (this.metrics.successes / this.metrics.requests) * 100 
                : 0,
            averageResponseTime: avgResponseTime
        };
    }
}
```

## Tests et Validation

### 1. Test d'Intégration
```javascript
// Test de base de l'API
async function testAirApi() {
    const service = new AirApiService({
        baseUrl: 'https://your-domain.com/api',
        timeout: 30000
    });
    
    const testCases = [
        {
            name: 'Get Balance',
            test: () => service.getBalance('77123456')
        },
        {
            name: 'Get Offers',
            test: () => service.getOffers('77123456')
        },
        {
            name: 'Purchase Offer',
            test: () => service.purchaseOffer('77123456', 10)
        },
        {
            name: 'Add Credit',
            test: () => service.addCredit('77123456', 100)
        },
        {
            name: 'Transfer Credit',
            test: () => service.transferCredit('77123456', '77654321', 50)
        }
    ];
    
    const results = [];
    
    for (const testCase of testCases) {
        try {
            const startTime = Date.now();
            const result = await testCase.test();
            const endTime = Date.now();
            
            results.push({
                name: testCase.name,
                success: true,
                responseTime: endTime - startTime,
                result
            });
        } catch (error) {
            results.push({
                name: testCase.name,
                success: false,
                error: error.message,
                codeReponse: error.codeReponse
            });
        }
    }
    
    return results;
}
```

### 2. Validation des Données
```javascript
// Validation des réponses
function validateBalanceResponse(response) {
    const required = ['success', 'message', 'msisdn', 'balance'];
    
    for (const field of required) {
        if (!(field in response)) {
            throw new Error(`Missing required field: ${field}`);
        }
    }
    
    if (!response.balance.current_balance || typeof response.balance.current_balance !== 'number') {
        throw new Error('Invalid balance format');
    }
    
    return true;
}

function validateOffersResponse(response) {
    const required = ['success', 'message', 'msisdn', 'offers'];
    
    for (const field of required) {
        if (!(field in response)) {
            throw new Error(`Missing required field: ${field}`);
        }
    }
    
    if (!Array.isArray(response.offers)) {
        throw new Error('offers must be an array');
    }
    
    for (const offer of response.offers) {
        const offerRequired = ['offer_id', 'name', 'price', 'validity_days'];
        for (const field of offerRequired) {
            if (!(field in offer)) {
                throw new Error(`Missing required offer field: ${field}`);
            }
        }
    }
    
    return true;
}
```

## Cas d'Usage Avancés

### 1. Gestion Intelligente des Offres
```javascript
// Suggestion d'offres basée sur l'utilisation
async function suggestOffers(msisdn, userProfile) {
    try {
        const balance = await airService.getBalance(msisdn);
        const offers = await airService.getOffers(msisdn);
        
        // Filtrer les offres selon le profil utilisateur
        const suitableOffers = offers.offers.filter(offer => {
            // Vérifier si l'utilisateur peut se permettre l'offre
            if (!offer.can_afford) return false;
            
            // Suggérer selon le profil
            if (userProfile.usage === 'light' && offer.validity_days <= 7) return true;
            if (userProfile.usage === 'medium' && offer.validity_days <= 30) return true;
            if (userProfile.usage === 'heavy' && offer.validity_days === 30) return true;
            
            return false;
        });
        
        // Trier par rapport qualité-prix
        const sortedOffers = suitableOffers.sort((a, b) => {
            const aValue = (a.counters.data_mb + a.counters.voice_minutes) / a.price;
            const bValue = (b.counters.data_mb + b.counters.voice_minutes) / b.price;
            return bValue - aValue;
        });
        
        return {
            balance: balance.balance,
            recommended_offers: sortedOffers.slice(0, 3),
            total_affordable: suitableOffers.length
        };
        
    } catch (error) {
        console.error('Error suggesting offers:', error);
        throw error;
    }
}
```

### 2. Workflow de Recharge Intelligente
```javascript
// Workflow de recharge avec optimisation
async function smartRecharge(msisdn, targetAmount, preferredMethod = 'credit') {
    try {
        const balance = await airService.getBalance(msisdn);
        const currentBalance = balance.balance.current_balance;
        
        if (currentBalance >= targetAmount) {
            return {
                success: true,
                message: 'Solde suffisant',
                current_balance: currentBalance,
                target_amount: targetAmount,
                action_needed: false
            };
        }
        
        const amountNeeded = targetAmount - currentBalance;
        
        let rechargeResult;
        if (preferredMethod === 'credit') {
            rechargeResult = await airService.addCredit(msisdn, amountNeeded);
        } else if (preferredMethod === 'voucher') {
            // Logique pour voucher
            throw new Error('Voucher recharge not implemented in this example');
        }
        
        return {
            success: true,
            message: 'Recharge effectuée avec succès',
            recharge_method: preferredMethod,
            amount_recharged: amountNeeded,
            new_balance: rechargeResult.account_impact.balance_after,
            target_reached: true
        };
        
    } catch (error) {
        console.error('Error in smart recharge:', error);
        throw error;
    }
}
```

### 3. Système de Notifications
```javascript
// Système de notifications pour les événements
class AirNotificationManager {
    constructor() {
        this.subscribers = new Map();
    }
    
    subscribe(eventType, callback) {
        if (!this.subscribers.has(eventType)) {
            this.subscribers.set(eventType, []);
        }
        this.subscribers.get(eventType).push(callback);
    }
    
    notify(eventType, data) {
        if (this.subscribers.has(eventType)) {
            this.subscribers.get(eventType).forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error('Notification callback error:', error);
                }
            });
        }
    }
    
    // Notifications spécifiques
    notifyLowBalance(msisdn, balance) {
        this.notify('low_balance', { msisdn, balance });
    }
    
    notifyOfferExpiring(msisdn, offer, daysLeft) {
        this.notify('offer_expiring', { msisdn, offer, daysLeft });
    }
    
    notifyTransferSuccess(transfer) {
        this.notify('transfer_success', transfer);
    }
    
    notifyPurchaseSuccess(purchase) {
        this.notify('purchase_success', purchase);
    }
}

// Utilisation
const notifications = new AirNotificationManager();

notifications.subscribe('low_balance', (data) => {
    console.log(`⚠️ Solde faible pour ${data.msisdn}: ${data.balance.formatted_balance}`);
});

notifications.subscribe('purchase_success', (data) => {
    console.log(`✅ Achat réussi: ${data.offer_name} pour ${data.msisdn}`);
});
```

---

## Support et Maintenance

### Version API
- **Version actuelle**: Laravel 12.x
- **Backend AIR**: AIR System v2.0
- **Compatibilité**: Rétrocompatible avec les versions précédentes

### Limites et Quotas
- **Timeout par requête**: 60 secondes
- **Requêtes simultanées**: 10 par utilisateur
- **Taille maximale de réponse**: 1 MB
- **Montant maximum crédit**: 100,000 DJF
- **Montant minimum transfert**: 50 DJF

### Contact Support
- **Documentation technique**: Voir `CLAUDE.md`
- **Support API**: support-api@your-domain.com
- **Issues GitHub**: https://github.com/your-org/dtapi/issues

---

*Ce guide doit être mis à jour régulièrement en fonction des évolutions de l'API AIR.*