# Guide d'Intégration Détaillé - TopUp API

## Vue d'ensemble

L'API TopUp est conçue pour la gestion des lignes fixes de télécommunications à Djibouti. Elle permet de consulter les soldes, gérer les packages, effectuer des recharges et administrer les répertoires personnels via une interface REST qui communique avec un système SOAP backend.

**Base URL**: `https://your-domain.com/api/topup`

## ⚠️ Modifications Récentes

### Version 2.1.0 (Janvier 2025)

**Changements des Action Types :**
- **Souscription package** : `action_type` 44 → **4**
- **Recharge compte** : `action_type` 55 → **5**

**Validation des Package Codes :**
- **Ancienne validation** : Majuscules uniquement (`/^[A-Z0-9_]+$/`)
- **Nouvelle validation** : Majuscules ET minuscules (`/^[A-Za-z0-9_]+$/`)
- **Exemples acceptés** : `NEW_GIGASUP_50Go`, `ETUDIANT_5M_MOIS`, `Data_Package_5GB`

**Réponses API :**
- **Champ renommé** : `data_quantity_mb` → `data_quantity_gb`
- **Correction unités** : Les valeurs de données sont maintenant correctement exprimées en GB
- **Formatage amélioré** : `formatted_data` affiche maintenant les bonnes unités (Go/Mo)

**Migration :**
```diff
// Ancien code
- "action_type": 44  // Package subscription
- "action_type": 55  // Account recharge
- "data_quantity_mb": 150  // Trompeur (était en GB)

// Nouveau code
+ "action_type": 4   // Package subscription
+ "action_type": 5   // Account recharge
+ "data_quantity_gb": 150  // Correct (en GB)
```

## Architecture Système

### Backend SOAP
- **URL**: `http://10.39.230.58:8700/soap/queueSoapService`
- **Authentification**: SOAP Header (username: `apigwdj`, password: `ApiDjtGw2020#`)
- **Timeout**: 60 secondes
- **Namespace**: `http://web.Top_Up_Djib.djibouti.com/`

### Validation des Numéros

#### Numéros Mobiles (MSISDN)
- **Format local**: 8 chiffres commençant par `77` (exemple: `77123456`)
- **Format international**: 11 chiffres commençant par `25377` (exemple: `25377123456`)
- **Regex**: `^(77|25377)[0-9]{6}$`

#### Numéros Fixes (ISDN)
- **Format local**: 8 chiffres commençant par `21` (exemple: `21123456`)
- **Format international**: 11 chiffres commençant par `25321` (exemple: `25321123456`)
- **Regex**: `^(21|25321)[0-9]{6}$`

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
        "mobile_msisdn": "77123456",
        "fixed_isdn": "21123456",
        "request_time": "2024-01-15T10:30:00Z",
        "backend_api": "TopUp SOAP",
        "operation_type": "balance_query"
    }
}
```

### Réponse d'Erreur
```json
{
    "erreur": "Description de l'erreur",
    "message": "Message utilisateur",
    "returnCode": "1",
    "details": {
        "mobile_msisdn": "77123456",
        "fixed_isdn": "21123456",
        "error_source": "SOAP_SERVICE",
        "timestamp": "2024-01-15T10:30:00Z"
    }
}
```

### Codes de Statut HTTP
- **200**: Succès
- **400**: Requête invalide (action type inexistant)
- **401**: Erreur d'authentification (login/PIN incorrect)
- **403**: Accès interdit (numéro bloqué/suspendu)
- **404**: Ressource non trouvée (numéro/package inexistant)
- **410**: Ressource expirée (numéro expiré)
- **422**: Entité non traitable (numéro postpaid non éligible)
- **500**: Erreur serveur interne
- **503**: Service indisponible (problème de connexion base de données)

## Endpoints Détaillés

### 1. Consultation des Soldes

#### Endpoint
```http
POST /api/topup/balances
```

#### Paramètres
```json
{
    "msisdn": "77123456",    // Numéro mobile initiateur
    "isdn": "21123456"       // Numéro fixe à consulter
}
```

#### Validation
- `msisdn`: Obligatoire, format mobile valide
- `isdn`: Obligatoire, format fixe valide

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Soldes récupérés avec succès",
    "mobile_msisdn": "77123456",
    "fixed_isdn": "21123456",
    "balances": [
        {
            "name": "Solde Principal",
            "type": "money",
            "value": 1500.0,
            "formatted_value": "1 500 DJF",
            "unit": "DJF",
            "expire_date": "2025-07-08 08:41:07",
            "expire_date_formatted": "08/07/2025 08:41:07",
            "expiration_status": {
                "status": "active",
                "priority": 0,
                "message": "Expire dans 25 jours"
            },
            "raw_type": "COMMON"
        },
        {
            "name": "Données Prépayées",
            "type": "data",
            "value": 1073741824,
            "formatted_value": "1 Go",
            "unit": "bytes",
            "expire_date": "2025-02-15 23:59:59",
            "expire_date_formatted": "15/02/2025 23:59:59",
            "expiration_status": {
                "status": "warning",
                "priority": 1,
                "message": "Expire dans 3 jours"
            },
            "raw_type": "DATA_PREPAID"
        },
        {
            "name": "Minutes Locales",
            "type": "voice",
            "value": 7200,
            "formatted_value": "02:00:00",
            "unit": "seconds",
            "expire_date": "2025-02-01 23:59:59",
            "expire_date_formatted": "01/02/2025 23:59:59",
            "expiration_status": {
                "status": "critical",
                "priority": 2,
                "message": "Expire dans 8 heures"
            },
            "raw_type": "VOICE_LOCAL"
        }
    ],
    "total_balances": 3,
    "summary": {
        "total_balances": 3,
        "money_total": 1500.0,
        "money_total_formatted": "1 500 DJF",
        "data_total_bytes": 1073741824,
        "data_total_formatted": "1 Go",
        "voice_total_seconds": 7200,
        "voice_total_formatted": "02:00:00"
    },
    "details": {
        "mobile_msisdn": "77123456",
        "fixed_isdn": "21123456",
        "request_time": "2024-01-15T10:30:00Z",
        "total_balances": 3,
        "backend_api": "TopUp SOAP"
    }
}
```

#### Types de Soldes
- **COMMON**: Solde principal (argent)
- **DATA_PREPAID**: Données prépayées (octets)
- **VOICE_LOCAL**: Minutes locales (secondes)
- **VOICE_NATIONAL**: Minutes nationales (secondes)
- **VOICE_INTERNATIONAL**: Minutes internationales (secondes)

#### Statuts d'Expiration
- **active**: Plus de 7 jours restants (priorité 0)
- **warning**: 1-7 jours restants (priorité 1)
- **critical**: Moins de 24 heures (priorité 2)
- **expired**: Expiré (priorité 3)

#### Erreurs Possibles
```json
{
    "erreur": "Numéro fixe inexistant",
    "message": "Le numéro 21123456 n'existe pas dans le système",
    "returnCode": "1",
    "details": {
        "mobile_msisdn": "77123456",
        "fixed_isdn": "21123456",
        "error_type": "NUMBER_NOT_FOUND"
    }
}
```

### 2. Répertoire Personnel

#### Endpoint
```http
GET /api/topup/numbers/{msisdn}
POST /api/topup/numbers
```

#### Paramètres
- **GET**: `msisdn` dans l'URL
- **POST**: `msisdn` dans le body JSON

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Répertoire récupéré avec succès",
    "msisdn": "77123456",
    "numbers": [
        {
            "isdn": "21123456",
            "formatted_number": "21 12 34 56",
            "number_type": "fixe",
            "can_recharge": true,
            "added_date": "2025-01-15",
            "status": {
                "eligible": true,
                "status_text": "Actif",
                "last_check": "2025-01-15T10:30:00Z"
            }
        },
        {
            "isdn": "21987654",
            "formatted_number": "21 98 76 54",
            "number_type": "fixe",
            "can_recharge": false,
            "added_date": "2025-01-10",
            "status": {
                "eligible": false,
                "status_text": "Suspendu",
                "last_check": "2025-01-15T10:30:00Z"
            }
        }
    ],
    "total_numbers": 2,
    "summary": {
        "total_numbers": 2,
        "mobile_numbers": 0,
        "fixed_numbers": 2,
        "rechargeable_numbers": 1,
        "blocked_numbers": 1,
        "unknown_numbers": 0
    },
    "details": {
        "msisdn": "77123456",
        "request_time": "2024-01-15T10:30:00Z",
        "total_numbers": 2,
        "backend_api": "TopUp SOAP"
    }
}
```

### 3. Vérification du Statut de Recharge

#### Endpoint
```http
GET /api/topup/status/{isdn}
POST /api/topup/status
```

#### Paramètres
- **GET**: `isdn` dans l'URL
- **POST**: `isdn` dans le body JSON

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Statut de recharge vérifié avec succès",
    "fixed_isdn": "21123456",
    "return_code": "0",
    "description": "Success",
    "status": {
        "eligible": true,
        "status_text": "Éligible pour recharge",
        "status_code": "ELIGIBLE",
        "can_recharge": true,
        "can_get_packages": true,
        "reason": "Le numéro est actif et peut être rechargé"
    },
    "details": {
        "fixed_isdn": "21123456",
        "request_time": "2024-01-15T10:30:00Z",
        "backend_api": "TopUp SOAP"
    }
}
```

#### Codes de Statut
- **0**: Éligible pour recharge
- **1**: Numéro inexistant
- **2**: Numéro bloqué/suspendu
- **3**: Numéro postpaid (non éligible)
- **5**: Numéro expiré
- **453**: Aucun package disponible

#### Erreurs Possibles
```json
{
    "erreur": "Numéro postpaid non éligible",
    "message": "Les numéros postpaid ne peuvent pas être rechargés via cette API",
    "returnCode": "3",
    "status": {
        "eligible": false,
        "status_text": "Postpaid - Non éligible",
        "status_code": "POSTPAID_NOT_ELIGIBLE",
        "can_recharge": false,
        "can_get_packages": false,
        "reason": "Les comptes postpaid ne sont pas supportés"
    }
}
```

### 4. Consultation des Packages

#### Endpoint
```http
POST /api/topup/packages
```

#### Paramètres
```json
{
    "msisdn": "77123456",    // Numéro mobile initiateur
    "isdn": "21123456",      // Numéro fixe cible
    "type": 1                // Type de package (voir ci-dessous)
}
```

#### Types de Packages
- **1**: Pack Voix
- **2**: Pack Data
- **3**: Pack Combo (Voix + Data)
- **4**: Pack Data Supplémentaire
- **5**: Pack Combo Supplémentaire
- **6**: Pack Voix Supplémentaire

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Packages récupérés avec succès",
    "msisdn": "77123456",
    "isdn": "21123456",
    "type": 1,
    "packages": [
        {
            "package_code": "EMPLOYE_2M",
            "description": "Package Employé 2 mois",
            "price": 2000.0,
            "formatted_price": "2 000 DJF",
            "validity_days": 60,
            "formatted_validity": "2 mois",
            "data_unlimited": false,
            "data_quantity_gb": 1024,
            "data_quantity_bytes": 1073741824,
            "voice_quantity_minutes": 120,
            "voice_quantity_seconds": 7200,
            "formatted_data": "1 Go",
            "formatted_voice": "02:00:00",
            "category": "combo",
            "is_affordable": true,
            "features": [
                "1 Go de données",
                "120 minutes d'appels",
                "Validité 2 mois"
            ]
        },
        {
            "package_code": "DATA_500MB",
            "description": "Pack Data 500 MB",
            "price": 500.0,
            "formatted_price": "500 DJF",
            "validity_days": 30,
            "formatted_validity": "1 mois",
            "data_unlimited": false,
            "data_quantity_gb": 500,
            "data_quantity_bytes": 524288000,
            "voice_quantity_minutes": 0,
            "voice_quantity_seconds": 0,
            "formatted_data": "500 Mo",
            "formatted_voice": "0 sec",
            "category": "data",
            "is_affordable": true,
            "features": [
                "500 Mo de données",
                "Validité 1 mois"
            ]
        }
    ],
    "total_packages": 2,
    "summary": {
        "total_packages": 2,
        "categories": {
            "combo": 1,
            "data": 1,
            "voice": 0
        },
        "price_range": {
            "min": 500.0,
            "max": 2000.0,
            "average": 1250.0,
            "min_formatted": "500 DJF",
            "max_formatted": "2 000 DJF",
            "average_formatted": "1 250 DJF"
        },
        "validity_range": {
            "min_days": 30,
            "max_days": 60,
            "min_formatted": "1 mois",
            "max_formatted": "2 mois"
        }
    },
    "details": {
        "msisdn": "77123456",
        "isdn": "21123456",
        "type": 1,
        "request_time": "2024-01-15T10:30:00Z",
        "total_packages": 2,
        "backend_api": "TopUp SOAP"
    }
}
```

### 5. Souscription à un Package

#### Endpoint
```http
POST /api/topup/subscribe-package
```

#### Paramètres
```json
{
    "msisdn": "77123456",           // Numéro mobile initiateur
    "isdn": "21123456",             // Numéro fixe cible
    "package_code": "EMPLOYE_2M",   // Code du package
    "pincode": "1234",              // Code PIN (optionnel, défaut: "0000")
    "transaction_id": "dtapp1642345678123456"  // ID de transaction (optionnel)
}
```

#### Validation
- `msisdn`: Format mobile valide
- `isdn`: Format fixe valide
- `package_code`: Chaîne alphanumériques (majuscules/minuscules) avec underscores
- `pincode`: 4 chiffres (optionnel)
- `transaction_id`: Doit commencer par "dtapp" (optionnel, généré automatiquement)

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Package souscrit avec succès",
    "transaction_id": "dtapp1642345678123456",
    "command_executed": true,
    "package_info": {
        "package_code": "EMPLOYE_2M",
        "description": "Package Employé 2 mois",
        "price": 2000.0,
        "formatted_price": "2 000 DJF"
    },
    "account_impact": {
        "balance_before": 3000.0,
        "amount_deducted": 2000.0,
        "balance_after": 1000.0,
        "formatted_balance_after": "1 000 DJF"
    },
    "details": {
        "msisdn": "77123456",
        "isdn": "21123456",
        "package_code": "EMPLOYE_2M",
        "command_content": "21123456#EMPLOYE_2M",
        "action_type": 4,
        "execution_time": "2024-01-15T10:30:00Z",
        "backend_api": "TopUp SOAP"
    }
}
```

#### Erreurs Possibles
```json
{
    "erreur": "Solde insuffisant",
    "message": "Votre solde est insuffisant pour souscrire à ce package",
    "returnCode": "400",
    "transaction_id": "dtapp1642345678123456",
    "package_info": {
        "package_code": "EMPLOYE_2M",
        "required_amount": 2000.0,
        "current_balance": 500.0,
        "missing_amount": 1500.0
    }
}
```

### 6. Recharge de Compte

#### Endpoint
```http
POST /api/topup/recharge-account
```

#### Paramètres
```json
{
    "msisdn": "77123456",    // Numéro mobile initiateur
    "isdn": "21123456",      // Numéro fixe à recharger
    "amount": 1000,          // Montant à transférer (en DJF)
    "pincode": "1234",       // Code PIN (optionnel, défaut: "0000")
    "transaction_id": "dtapp1642345678123456"  // ID de transaction (optionnel)
}
```

#### Validation
- `amount`: Nombre positif, minimum 100 DJF, maximum 50000 DJF

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Recharge effectuée avec succès",
    "transaction_id": "dtapp1642345678123456",
    "command_executed": true,
    "transfer_info": {
        "amount": 1000.0,
        "formatted_amount": "1 000 DJF",
        "currency": "DJF",
        "transfer_type": "mobile_to_fixed"
    },
    "account_impact": {
        "mobile_balance_before": 5000.0,
        "mobile_balance_after": 4000.0,
        "fixed_balance_before": 500.0,
        "fixed_balance_after": 1500.0,
        "formatted_mobile_after": "4 000 DJF",
        "formatted_fixed_after": "1 500 DJF"
    },
    "details": {
        "msisdn": "77123456",
        "isdn": "21123456",
        "amount": 1000.0,
        "formatted_amount": "1 000 DJF",
        "command_content": "21123456#1000",
        "action_type": 5,
        "execution_time": "2024-01-15T10:30:00Z",
        "backend_api": "TopUp SOAP"
    }
}
```

### 7. Mise à Jour du Code PIN

#### Endpoint
```http
PUT /api/topup/update-pin
```

#### Paramètres
```json
{
    "msisdn": "77123456",     // Numéro mobile
    "old_pin": "1234",        // Ancien code PIN
    "new_pin": "5678",        // Nouveau code PIN
    "transaction_id": "dtapp1642345678123456"  // ID de transaction (optionnel)
}
```

#### Validation
- `old_pin`: 4 chiffres exactement
- `new_pin`: 4 chiffres exactement, différent de l'ancien

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Code PIN mis à jour avec succès",
    "transaction_id": "dtapp1642345678123456",
    "command_executed": true,
    "security_info": {
        "pin_changed": true,
        "change_date": "2024-01-15T10:30:00Z",
        "security_level": "enhanced"
    },
    "details": {
        "msisdn": "77123456",
        "pin_updated": true,
        "action_type": 1,
        "execution_time": "2024-01-15T10:30:00Z",
        "backend_api": "TopUp SOAP"
    }
}
```

### 8. Gestion du Répertoire

#### Ajouter un Numéro
```http
POST /api/topup/directory/add
```

#### Supprimer un Numéro
```http
DELETE /api/topup/directory/remove
```

#### Paramètres
```json
{
    "msisdn": "77123456",     // Numéro mobile propriétaire
    "isdn": "21123456",       // Numéro fixe à ajouter/supprimer
    "pincode": "1234",        // Code PIN (optionnel, défaut: "0000")
    "transaction_id": "dtapp1642345678123456"  // ID de transaction (optionnel)
}
```

#### Réponse de Succès (Ajout)
```json
{
    "success": true,
    "message": "Numéro ajouté au répertoire avec succès",
    "transaction_id": "dtapp1642345678123456",
    "command_executed": true,
    "directory_info": {
        "operation": "add",
        "isdn_added": "21123456",
        "formatted_number": "21 12 34 56",
        "total_numbers_after": 3
    },
    "details": {
        "msisdn": "77123456",
        "isdn_added": "21123456",
        "operation": "add_to_directory",
        "action_type": 2,
        "execution_time": "2024-01-15T10:30:00Z",
        "backend_api": "TopUp SOAP"
    }
}
```

#### Réponse de Succès (Suppression)
```json
{
    "success": true,
    "message": "Numéro supprimé du répertoire avec succès",
    "transaction_id": "dtapp1642345678123456",
    "command_executed": true,
    "directory_info": {
        "operation": "remove",
        "isdn_removed": "21123456",
        "formatted_number": "21 12 34 56",
        "total_numbers_after": 2
    },
    "details": {
        "msisdn": "77123456",
        "isdn_removed": "21123456",
        "operation": "remove_from_directory",
        "action_type": 3,
        "execution_time": "2024-01-15T10:30:00Z",
        "backend_api": "TopUp SOAP"
    }
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
            "Le numéro mobile doit commencer par 77 ou 25377 et contenir 8 ou 11 chiffres"
        ],
        "isdn": [
            "Le numéro de ligne fixe doit commencer par 21 ou 25321 et contenir 8 ou 11 chiffres"
        ]
    },
    "details": {
        "endpoint": "topup/balances",
        "method": "POST",
        "timestamp": "2024-01-15T10:30:00Z"
    }
}
```

### Erreurs SOAP
```json
{
    "erreur": "Erreur SOAP",
    "message": "Impossible de communiquer avec le service backend",
    "returnCode": "SOAP_FAULT",
    "soap_fault": {
        "fault_code": "Server",
        "fault_string": "Connection timeout",
        "fault_detail": "Le service backend ne répond pas"
    },
    "details": {
        "error_source": "SOAP_SERVICE",
        "backend_url": "http://10.39.230.58:8700/soap/queueSoapService",
        "timeout": 60
    }
}
```

### Erreurs Métier
```json
{
    "erreur": "Opération non autorisée",
    "message": "Le numéro fixe est suspendu et ne peut pas être rechargé",
    "returnCode": "2",
    "status": {
        "eligible": false,
        "status_text": "Numéro suspendu",
        "status_code": "NUMBER_BLOCKED",
        "can_recharge": false,
        "reason": "Le numéro a été suspendu par l'opérateur"
    }
}
```

## Exemples d'Intégration Mobile

### Classe Service Flutter/Dart
```dart
class TopUpApiService {
    final String baseUrl;
    final http.Client client;
    
    TopUpApiService({
        required this.baseUrl,
        http.Client? client,
    }) : client = client ?? http.Client();
    
    Future<TopUpBalanceResponse> getBalances({
        required String msisdn,
        required String isdn,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/topup/balances'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'msisdn': msisdn,
                'isdn': isdn,
            }),
        );
        
        if (response.statusCode == 200) {
            return TopUpBalanceResponse.fromJson(jsonDecode(response.body));
        } else {
            throw TopUpApiException.fromResponse(response);
        }
    }
    
    Future<TopUpPackageResponse> getPackages({
        required String msisdn,
        required String isdn,
        required int type,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/topup/packages'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'msisdn': msisdn,
                'isdn': isdn,
                'type': type,
            }),
        );
        
        if (response.statusCode == 200) {
            return TopUpPackageResponse.fromJson(jsonDecode(response.body));
        } else {
            throw TopUpApiException.fromResponse(response);
        }
    }
    
    Future<TopUpCommandResponse> subscribePackage({
        required String msisdn,
        required String isdn,
        required String packageCode,
        String? pincode,
        String? transactionId,
    }) async {
        final body = {
            'msisdn': msisdn,
            'isdn': isdn,
            'package_code': packageCode,
        };
        
        if (pincode != null) body['pincode'] = pincode;
        if (transactionId != null) body['transaction_id'] = transactionId;
        
        final response = await client.post(
            Uri.parse('$baseUrl/topup/subscribe-package'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode(body),
        );
        
        if (response.statusCode == 200) {
            return TopUpCommandResponse.fromJson(jsonDecode(response.body));
        } else {
            throw TopUpApiException.fromResponse(response);
        }
    }
    
    Future<TopUpCommandResponse> rechargeAccount({
        required String msisdn,
        required String isdn,
        required double amount,
        String? pincode,
        String? transactionId,
    }) async {
        final body = {
            'msisdn': msisdn,
            'isdn': isdn,
            'amount': amount,
        };
        
        if (pincode != null) body['pincode'] = pincode;
        if (transactionId != null) body['transaction_id'] = transactionId;
        
        final response = await client.post(
            Uri.parse('$baseUrl/topup/recharge-account'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode(body),
        );
        
        if (response.statusCode == 200) {
            return TopUpCommandResponse.fromJson(jsonDecode(response.body));
        } else {
            throw TopUpApiException.fromResponse(response);
        }
    }
}

// Modèles de données
class TopUpBalanceResponse {
    final bool success;
    final String message;
    final String mobileMsisdn;
    final String fixedIsdn;
    final List<Balance> balances;
    final int totalBalances;
    final BalanceSummary summary;
    
    TopUpBalanceResponse({
        required this.success,
        required this.message,
        required this.mobileMsisdn,
        required this.fixedIsdn,
        required this.balances,
        required this.totalBalances,
        required this.summary,
    });
    
    factory TopUpBalanceResponse.fromJson(Map<String, dynamic> json) {
        return TopUpBalanceResponse(
            success: json['success'],
            message: json['message'],
            mobileMsisdn: json['mobile_msisdn'],
            fixedIsdn: json['fixed_isdn'],
            balances: (json['balances'] as List)
                .map((item) => Balance.fromJson(item))
                .toList(),
            totalBalances: json['total_balances'],
            summary: BalanceSummary.fromJson(json['summary']),
        );
    }
}

class Balance {
    final String name;
    final String type;
    final double value;
    final String formattedValue;
    final String unit;
    final String expireDate;
    final String expireDateFormatted;
    final ExpirationStatus expirationStatus;
    final String rawType;
    
    Balance({
        required this.name,
        required this.type,
        required this.value,
        required this.formattedValue,
        required this.unit,
        required this.expireDate,
        required this.expireDateFormatted,
        required this.expirationStatus,
        required this.rawType,
    });
    
    factory Balance.fromJson(Map<String, dynamic> json) {
        return Balance(
            name: json['name'],
            type: json['type'],
            value: json['value'].toDouble(),
            formattedValue: json['formatted_value'],
            unit: json['unit'],
            expireDate: json['expire_date'],
            expireDateFormatted: json['expire_date_formatted'],
            expirationStatus: ExpirationStatus.fromJson(json['expiration_status']),
            rawType: json['raw_type'],
        );
    }
}

class ExpirationStatus {
    final String status;
    final int priority;
    final String message;
    
    ExpirationStatus({
        required this.status,
        required this.priority,
        required this.message,
    });
    
    factory ExpirationStatus.fromJson(Map<String, dynamic> json) {
        return ExpirationStatus(
            status: json['status'],
            priority: json['priority'],
            message: json['message'],
        );
    }
}

// Gestion des erreurs
class TopUpApiException implements Exception {
    final String error;
    final String message;
    final String? returnCode;
    final int statusCode;
    final Map<String, dynamic>? details;
    
    TopUpApiException({
        required this.error,
        required this.message,
        this.returnCode,
        required this.statusCode,
        this.details,
    });
    
    factory TopUpApiException.fromResponse(http.Response response) {
        final body = jsonDecode(response.body);
        return TopUpApiException(
            error: body['erreur'] ?? 'Erreur inconnue',
            message: body['message'] ?? 'Une erreur est survenue',
            returnCode: body['returnCode'],
            statusCode: response.statusCode,
            details: body['details'],
        );
    }
    
    @override
    String toString() {
        return 'TopUpApiException: $error - $message (HTTP $statusCode)';
    }
}
```

### Classe Service React Native/TypeScript
```typescript
interface TopUpApiConfig {
    baseUrl: string;
    timeout?: number;
}

interface TopUpBalance {
    name: string;
    type: string;
    value: number;
    formatted_value: string;
    unit: string;
    expire_date: string;
    expire_date_formatted: string;
    expiration_status: {
        status: string;
        priority: number;
        message: string;
    };
    raw_type: string;
}

interface TopUpBalanceResponse {
    success: boolean;
    message: string;
    mobile_msisdn: string;
    fixed_isdn: string;
    balances: TopUpBalance[];
    total_balances: number;
    summary: {
        total_balances: number;
        money_total: number;
        money_total_formatted: string;
        data_total_bytes: number;
        data_total_formatted: string;
        voice_total_seconds: number;
        voice_total_formatted: string;
    };
}

interface TopUpPackage {
    package_code: string;
    description: string;
    price: number;
    formatted_price: string;
    validity_days: number;
    formatted_validity: string;
    data_unlimited: boolean;
    data_quantity_gb: number;
    data_quantity_bytes: number;
    voice_quantity_minutes: number;
    voice_quantity_seconds: number;
    formatted_data: string;
    formatted_voice: string;
    category: string;
    is_affordable: boolean;
    features: string[];
}

interface TopUpPackageResponse {
    success: boolean;
    message: string;
    msisdn: string;
    isdn: string;
    type: number;
    packages: TopUpPackage[];
    total_packages: number;
    summary: {
        total_packages: number;
        categories: Record<string, number>;
        price_range: {
            min: number;
            max: number;
            average: number;
            min_formatted: string;
            max_formatted: string;
            average_formatted: string;
        };
    };
}

class TopUpApiService {
    private baseUrl: string;
    private timeout: number;
    
    constructor(config: TopUpApiConfig) {
        this.baseUrl = config.baseUrl;
        this.timeout = config.timeout || 30000;
    }
    
    private async request<T>(
        endpoint: string,
        method: 'GET' | 'POST' | 'PUT' | 'DELETE' = 'GET',
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
                throw new TopUpApiError(
                    responseData.erreur || 'Erreur inconnue',
                    responseData.message || 'Une erreur est survenue',
                    response.status,
                    responseData.returnCode,
                    responseData.details
                );
            }
            
            return responseData as T;
        } catch (error) {
            clearTimeout(timeoutId);
            if (error instanceof TopUpApiError) {
                throw error;
            }
            throw new TopUpApiError(
                'Erreur réseau',
                'Impossible de communiquer avec le serveur',
                0,
                undefined,
                { originalError: error }
            );
        }
    }
    
    async getBalances(msisdn: string, isdn: string): Promise<TopUpBalanceResponse> {
        return this.request<TopUpBalanceResponse>('/topup/balances', 'POST', {
            msisdn,
            isdn,
        });
    }
    
    async getMyNumbers(msisdn: string): Promise<any> {
        return this.request<any>('/topup/numbers', 'POST', { msisdn });
    }
    
    async getStatusForRecharge(isdn: string): Promise<any> {
        return this.request<any>('/topup/status', 'POST', { isdn });
    }
    
    async getPackages(
        msisdn: string,
        isdn: string,
        type: number
    ): Promise<TopUpPackageResponse> {
        return this.request<TopUpPackageResponse>('/topup/packages', 'POST', {
            msisdn,
            isdn,
            type,
        });
    }
    
    async subscribePackage(params: {
        msisdn: string;
        isdn: string;
        package_code: string;
        pincode?: string;
        transaction_id?: string;
    }): Promise<any> {
        return this.request<any>('/topup/subscribe-package', 'POST', params);
    }
    
    async rechargeAccount(params: {
        msisdn: string;
        isdn: string;
        amount: number;
        pincode?: string;
        transaction_id?: string;
    }): Promise<any> {
        return this.request<any>('/topup/recharge-account', 'POST', params);
    }
    
    async updatePin(params: {
        msisdn: string;
        old_pin: string;
        new_pin: string;
        transaction_id?: string;
    }): Promise<any> {
        return this.request<any>('/topup/update-pin', 'PUT', params);
    }
    
    async addToDirectory(params: {
        msisdn: string;
        isdn: string;
        pincode?: string;
        transaction_id?: string;
    }): Promise<any> {
        return this.request<any>('/topup/directory/add', 'POST', params);
    }
    
    async removeFromDirectory(params: {
        msisdn: string;
        isdn: string;
        pincode?: string;
        transaction_id?: string;
    }): Promise<any> {
        return this.request<any>('/topup/directory/remove', 'DELETE', params);
    }
}

class TopUpApiError extends Error {
    constructor(
        public error: string,
        public message: string,
        public statusCode: number,
        public returnCode?: string,
        public details?: any
    ) {
        super(message);
        this.name = 'TopUpApiError';
    }
}

// Utilisation
const topUpService = new TopUpApiService({
    baseUrl: 'https://your-domain.com/api',
    timeout: 30000,
});

// Exemple d'utilisation
async function handleGetBalances() {
    try {
        const response = await topUpService.getBalances('77123456', '21123456');
        console.log('Balances:', response.balances);
        console.log('Total:', response.summary.money_total_formatted);
    } catch (error) {
        if (error instanceof TopUpApiError) {
            console.error('API Error:', error.error, error.message);
            console.error('Return Code:', error.returnCode);
            console.error('Status Code:', error.statusCode);
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
    const regex = /^(77|25377)[0-9]{6}$/;
    return regex.test(msisdn);
}

// Validation des numéros fixes
function validateIsdn(isdn) {
    const regex = /^(21|25321)[0-9]{6}$/;
    return regex.test(isdn);
}

// Validation du code PIN
function validatePin(pin) {
    const regex = /^[0-9]{4}$/;
    return regex.test(pin);
}

// Validation du transaction ID
function validateTransactionId(transactionId) {
    const regex = /^dtapp[a-zA-Z0-9]+$/;
    return regex.test(transactionId) && transactionId.length >= 8 && transactionId.length <= 50;
}
```

### 2. Gestion des Timeouts
```javascript
// Timeouts recommandés par type d'opération
const TIMEOUTS = {
    balance_query: 15000,      // 15 secondes
    package_query: 20000,      // 20 secondes
    command_execution: 45000,  // 45 secondes
    status_check: 10000,       // 10 secondes
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
// États pour les opérations asynchrones
const OPERATION_STATES = {
    IDLE: 'idle',
    LOADING: 'loading',
    SUCCESS: 'success',
    ERROR: 'error',
    RETRY: 'retry'
};

// Gestion des transactions
class TransactionManager {
    constructor() {
        this.transactions = new Map();
    }
    
    generateTransactionId() {
        const timestamp = Date.now().toString();
        const random = Math.random().toString(36).substr(2, 9);
        return `dtapp${timestamp}${random}`;
    }
    
    trackTransaction(id, operation, params) {
        this.transactions.set(id, {
            id,
            operation,
            params,
            status: OPERATION_STATES.LOADING,
            startTime: Date.now(),
            attempts: 0
        });
    }
    
    updateTransaction(id, status, result = null, error = null) {
        const transaction = this.transactions.get(id);
        if (transaction) {
            transaction.status = status;
            transaction.result = result;
            transaction.error = error;
            transaction.endTime = Date.now();
        }
    }
    
    getTransaction(id) {
        return this.transactions.get(id);
    }
}
```

### 5. Sécurité
```javascript
// Gestion sécurisée des PINs
class SecurePinManager {
    constructor() {
        this.pinCache = new Map();
    }
    
    storePin(msisdn, pin, ttl = 300000) { // 5 minutes
        const expiry = Date.now() + ttl;
        this.pinCache.set(msisdn, { pin, expiry });
        
        // Auto-cleanup
        setTimeout(() => {
            this.clearPin(msisdn);
        }, ttl);
    }
    
    getPin(msisdn) {
        const entry = this.pinCache.get(msisdn);
        if (entry && entry.expiry > Date.now()) {
            return entry.pin;
        }
        this.clearPin(msisdn);
        return null;
    }
    
    clearPin(msisdn) {
        this.pinCache.delete(msisdn);
    }
    
    clearAllPins() {
        this.pinCache.clear();
    }
}
```

## Monitoring et Debugging

### 1. Logging
```javascript
class TopUpLogger {
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
                service: 'topup-api'
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
class TopUpMetrics {
    constructor() {
        this.metrics = {
            requests: 0,
            successes: 0,
            errors: 0,
            responseTime: [],
            errorsByType: {}
        };
    }
    
    recordRequest(operation, responseTime, success, error = null) {
        this.metrics.requests++;
        this.metrics.responseTime.push(responseTime);
        
        if (success) {
            this.metrics.successes++;
        } else {
            this.metrics.errors++;
            if (error) {
                const errorType = error.returnCode || 'unknown';
                this.metrics.errorsByType[errorType] = 
                    (this.metrics.errorsByType[errorType] || 0) + 1;
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
async function testTopUpApi() {
    const service = new TopUpApiService({
        baseUrl: 'https://your-domain.com/api',
        timeout: 30000
    });
    
    const testCases = [
        {
            name: 'Get Balances',
            test: () => service.getBalances('77123456', '21123456')
        },
        {
            name: 'Get My Numbers',
            test: () => service.getMyNumbers('77123456')
        },
        {
            name: 'Get Status',
            test: () => service.getStatusForRecharge('21123456')
        },
        {
            name: 'Get Packages',
            test: () => service.getPackages('77123456', '21123456', 1)
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
                returnCode: error.returnCode
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
    const required = ['success', 'message', 'mobile_msisdn', 'fixed_isdn', 'balances'];
    
    for (const field of required) {
        if (!(field in response)) {
            throw new Error(`Missing required field: ${field}`);
        }
    }
    
    if (!Array.isArray(response.balances)) {
        throw new Error('balances must be an array');
    }
    
    for (const balance of response.balances) {
        const balanceRequired = ['name', 'type', 'value', 'formatted_value'];
        for (const field of balanceRequired) {
            if (!(field in balance)) {
                throw new Error(`Missing required balance field: ${field}`);
            }
        }
    }
    
    return true;
}
```

## Cas d'Usage Avancés

### 1. Opérations Batch
```javascript
// Consultation de plusieurs soldes en parallèle
async function getBatchBalances(msisdn, isdnList) {
    const promises = isdnList.map(isdn => 
        topUpService.getBalances(msisdn, isdn)
            .catch(error => ({ error, isdn }))
    );
    
    const results = await Promise.all(promises);
    
    return {
        successes: results.filter(r => !r.error),
        errors: results.filter(r => r.error)
    };
}
```

### 2. Workflow Complet
```javascript
// Workflow complet: vérification → package → souscription
async function fullPackageWorkflow(msisdn, isdn, packageType, packageCode, pin) {
    const transactionId = generateTransactionId();
    
    try {
        // 1. Vérifier le statut
        const status = await topUpService.getStatusForRecharge(isdn);
        if (!status.status.eligible) {
            throw new Error(`Number not eligible: ${status.status.reason}`);
        }
        
        // 2. Obtenir les packages
        const packages = await topUpService.getPackages(msisdn, isdn, packageType);
        const selectedPackage = packages.packages.find(p => p.package_code === packageCode);
        
        if (!selectedPackage) {
            throw new Error(`Package ${packageCode} not found`);
        }
        
        // 3. Vérifier l'affordabilité
        const balances = await topUpService.getBalances(msisdn, isdn);
        const mainBalance = balances.balances.find(b => b.type === 'money');
        
        if (!mainBalance || mainBalance.value < selectedPackage.price) {
            throw new Error(`Insufficient balance: ${mainBalance?.value} < ${selectedPackage.price}`);
        }
        
        // 4. Souscrire au package
        const subscription = await topUpService.subscribePackage({
            msisdn,
            isdn,
            package_code: packageCode,
            pincode: pin,
            transaction_id: transactionId
        });
        
        return {
            success: true,
            transactionId,
            package: selectedPackage,
            subscription,
            balanceAfter: subscription.account_impact?.balance_after
        };
        
    } catch (error) {
        return {
            success: false,
            error: error.message,
            transactionId
        };
    }
}
```

---

## Support et Maintenance

### Version API
- **Version actuelle**: Laravel 12.x
- **Backend SOAP**: TopUp System v2.0
- **Compatibilité**: Rétrocompatible avec les versions précédentes

### Limites et Quotas
- **Timeout par requête**: 60 secondes
- **Requêtes simultanées**: 10 par utilisateur
- **Taille maximale de réponse**: 1 MB

### Contact Support
- **Documentation technique**: Voir `CLAUDE.md`
- **Support API**: support-api@your-domain.com
- **Issues GitHub**: https://github.com/your-org/dtapi/issues

---

*Ce guide doit être mis à jour régulièrement en fonction des évolutions de l'API TopUp.*