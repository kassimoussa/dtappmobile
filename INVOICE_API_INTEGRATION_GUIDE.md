# Guide d'Intégration Détaillé - Invoice API

## Vue d'ensemble

L'API Invoice est conçue pour la gestion des factures de télécommunications à Djibouti. Elle permet de consulter les factures ouvertes par numéro de téléphone ou par numéro de facture via une interface REST qui communique avec un système SOAP backend.

**Base URL**: `https://your-domain.com/api/invoice`

## Architecture Système

### Backend SOAP
- **URL**: `http://10.39.230.58:8700/soap/queueSoapService`
- **Authentification**: SOAP Header (username: `apigwdj`, password: `ApiDjtGw2020#`)
- **Timeout**: 60 secondes
- **Namespace**: `http://web.Top_Up_Djib.djibouti.com/`

### Validation des Paramètres

#### Numéros de Téléphone (MSISDN)
- **Format local mobile**: 8 chiffres commençant par `77` (exemple: `77123456`)
- **Format international mobile**: 11 chiffres commençant par `25377` (exemple: `25377123456`)
- **Format local fixe**: 8 chiffres commençant par `21` (exemple: `21123456`)
- **Format international fixe**: 11 chiffres commençant par `25321` (exemple: `25321123456`)
- **Regex mobile**: `^(77|25377)[0-9]{6}$`
- **Regex fixe**: `^(21|25321)[0-9]{6}$`

#### Numéros de Facture
- **Format**: Alphanumériques uniquement
- **Longueur**: 5 à 50 caractères
- **Regex**: `^[a-zA-Z0-9]+$`

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
    "return_code": "0",
    "description": "Succès",
    "msisdn": "77123456",
    "invoices": [
        {
            "invoice_number": "INV2024001",
            "amounts": {
                "invoice_amount": "2500.00",
                "remaining_amount": "2500.00",
                "formatted_invoice_amount": "2 500.00 FDJ",
                "formatted_remaining_amount": "2 500.00 FDJ"
            },
            "dates": {
                "bill_date": "2024-01-01",
                "due_date": "2024-01-31",
                "formatted_bill_date": "01/01/2024",
                "formatted_due_date": "31/01/2024"
            },
            "status": {
                "is_overdue": false,
                "days_until_due": 25,
                "status_text": "En cours"
            },
            "meta": {
                "can_pay": true,
                "payment_methods": ["mobile_payment", "card_payment", "cash_payment"]
            }
        }
    ],
    "total_invoices": 1,
    "summary": {
        "total_invoices": 1,
        "total_amount": "2 500.00 FDJ",
        "total_remaining": "2 500.00 FDJ",
        "overdue_invoices": 0,
        "upcoming_due_invoices": 1
    },
    "backend_api": "Invoice SOAP",
    "response_time": "2024-01-15T10:30:00Z"
}
```

### Réponse d'Erreur
```json
{
    "success": false,
    "error": "Facture introuvable",
    "return_code": "404",
    "msisdn": "77123456",
    "backend_api": "Invoice SOAP"
}
```

### Codes de Statut HTTP
- **200**: Succès
- **401**: Authentification échouée
- **403**: Accès refusé
- **404**: Facture déjà payée ou introuvable
- **500**: Erreur serveur interne
- **502**: Erreur SOAP
- **503**: Service indisponible (problème de connexion base de données)

## Endpoints Détaillés

### 1. Consultation des Factures par Numéro de Téléphone

#### Endpoint
```http
GET /api/invoice/phone/{msisdn}
POST /api/invoice/phone
```

#### Paramètres
- **GET**: `msisdn` dans l'URL
- **POST**: `msisdn` dans le body JSON

```json
{
    "msisdn": "77123456"    // Numéro de téléphone (mobile ou fixe)
}
```

#### Validation
- `msisdn`: Obligatoire, format mobile ou fixe valide (local ou international)

#### Réponse de Succès
```json
{
    "success": true,
    "return_code": "0",
    "description": "Factures récupérées avec succès",
    "msisdn": "77123456",
    "invoices": [
        {
            "invoice_number": "INV2024001",
            "amounts": {
                "invoice_amount": "2500.00",
                "remaining_amount": "2500.00",
                "formatted_invoice_amount": "2 500.00 FDJ",
                "formatted_remaining_amount": "2 500.00 FDJ"
            },
            "dates": {
                "bill_date": "2024-01-01",
                "due_date": "2024-01-31",
                "formatted_bill_date": "01/01/2024",
                "formatted_due_date": "31/01/2024"
            },
            "status": {
                "is_overdue": false,
                "days_until_due": 25,
                "status_text": "En cours"
            },
            "meta": {
                "can_pay": true,
                "payment_methods": ["mobile_payment", "card_payment", "cash_payment"]
            }
        },
        {
            "invoice_number": "INV2024002",
            "amounts": {
                "invoice_amount": "1800.00",
                "remaining_amount": "1800.00",
                "formatted_invoice_amount": "1 800.00 FDJ",
                "formatted_remaining_amount": "1 800.00 FDJ"
            },
            "dates": {
                "bill_date": "2024-01-15",
                "due_date": "2024-01-10",
                "formatted_bill_date": "15/01/2024",
                "formatted_due_date": "10/01/2024"
            },
            "status": {
                "is_overdue": true,
                "days_until_due": -5,
                "status_text": "En retard"
            },
            "meta": {
                "can_pay": true,
                "payment_methods": ["mobile_payment", "card_payment", "cash_payment"]
            }
        }
    ],
    "total_invoices": 2,
    "summary": {
        "total_invoices": 2,
        "total_amount": "4 300.00 FDJ",
        "total_remaining": "4 300.00 FDJ",
        "overdue_invoices": 1,
        "upcoming_due_invoices": 1
    },
    "backend_api": "Invoice SOAP",
    "response_time": "2024-01-15T10:30:00Z"
}
```

#### Statuts des Factures
- **En cours**: Plus de 7 jours jusqu'à l'échéance
- **Échéance proche (X jours)**: 1-7 jours jusqu'à l'échéance
- **Échu aujourd'hui**: Échéance aujourd'hui
- **En retard**: Facture en retard
- **Statut inconnu**: Pas de date d'échéance

#### Erreurs Possibles
```json
{
    "success": false,
    "error": "Aucune facture trouvée pour ce numéro",
    "return_code": "404",
    "msisdn": "77123456",
    "backend_api": "Invoice SOAP"
}
```

### 2. Consultation d'une Facture par Numéro de Facture

#### Endpoint
```http
GET /api/invoice/number/{invoiceNumber}
POST /api/invoice/number
```

#### Paramètres
- **GET**: `invoiceNumber` dans l'URL
- **POST**: `invoice_number` dans le body JSON

```json
{
    "invoice_number": "INV2024001"    // Numéro de facture
}
```

#### Validation
- `invoice_number`: Obligatoire, format alphanumérique, 5-50 caractères

#### Réponse de Succès
```json
{
    "success": true,
    "return_code": "0",
    "description": "Facture récupérée avec succès",
    "invoice_number": "INV2024001",
    "invoice": {
        "invoice_number": "INV2024001",
        "amounts": {
            "invoice_amount": "2500.00",
            "remaining_amount": "2500.00",
            "formatted_invoice_amount": "2 500.00 FDJ",
            "formatted_remaining_amount": "2 500.00 FDJ"
        },
        "dates": {
            "bill_date": "2024-01-01",
            "due_date": "2024-01-31",
            "formatted_bill_date": "01/01/2024",
            "formatted_due_date": "31/01/2024"
        },
        "status": {
            "is_overdue": false,
            "days_until_due": 25,
            "status_text": "En cours"
        },
        "meta": {
            "can_pay": true,
            "payment_methods": ["mobile_payment", "card_payment", "cash_payment"]
        }
    },
    "backend_api": "Invoice SOAP",
    "response_time": "2024-01-15T10:30:00Z"
}
```

#### Erreurs Possibles
```json
{
    "success": false,
    "error": "Facture introuvable ou déjà payée",
    "return_code": "404",
    "invoice_number": "INV2024001",
    "backend_api": "Invoice SOAP"
}
```

### 3. Test de Connectivité

#### Endpoint
```http
GET /api/invoice/test
```

#### Réponse de Succès
```json
{
    "success": true,
    "message": "Connexion Invoice réussie",
    "soap_url": "http://10.39.230.58:8700/soap/queueSoapService",
    "http_status": 200,
    "response_headers": {
        "Content-Type": "text/xml",
        "Server": "Apache/2.4.41"
    }
}
```

#### Réponse d'Erreur
```json
{
    "success": false,
    "error": "Erreur de connexion SOAP",
    "message": "Connection timeout",
    "url": "http://10.39.230.58:8700/soap/queueSoapService"
}
```

## Codes d'Erreur Spécifiques

### Codes de Retour Invoice
- **0**: Succès
- **200**: Succès
- **401**: Authentification échouée
- **402**: Connexion base de données impossible
- **403**: Accès refusé
- **404**: Facture déjà payée ou introuvable
- **500**: Erreur serveur
- **SOAP_FAULT**: Erreur SOAP

### Mapping HTTP Status
- **0, 200**: HTTP 200 (OK)
- **401**: HTTP 401 (Unauthorized)
- **402**: HTTP 503 (Service Unavailable)
- **403**: HTTP 403 (Forbidden)
- **404**: HTTP 404 (Not Found)
- **500**: HTTP 500 (Internal Server Error)
- **SOAP_FAULT**: HTTP 502 (Bad Gateway)

## Structure des Données

### Objet Invoice
```json
{
    "invoice_number": "INV2024001",
    "amounts": {
        "invoice_amount": "2500.00",           // Montant original
        "remaining_amount": "2500.00",          // Montant restant à payer
        "formatted_invoice_amount": "2 500.00 FDJ",
        "formatted_remaining_amount": "2 500.00 FDJ"
    },
    "dates": {
        "bill_date": "2024-01-01",             // Date de facturation
        "due_date": "2024-01-31",              // Date d'échéance
        "formatted_bill_date": "01/01/2024",
        "formatted_due_date": "31/01/2024"
    },
    "status": {
        "is_overdue": false,                    // Facture en retard
        "days_until_due": 25,                   // Jours jusqu'à l'échéance (négatif si en retard)
        "status_text": "En cours"              // Statut lisible
    },
    "meta": {
        "can_pay": true,                        // Peut être payée
        "payment_methods": [                    // Méthodes de paiement disponibles
            "mobile_payment",
            "card_payment", 
            "cash_payment"
        ]
    }
}
```

### Objet Summary
```json
{
    "total_invoices": 2,
    "total_amount": "4 300.00 FDJ",           // Montant total de toutes les factures
    "total_remaining": "4 300.00 FDJ",        // Montant total restant à payer
    "overdue_invoices": 1,                     // Nombre de factures en retard
    "upcoming_due_invoices": 1                 // Nombre de factures proches de l'échéance (≤7 jours)
}
```

## Gestion des Erreurs

### Erreurs de Validation
```json
{
    "success": false,
    "error": "Données invalides",
    "message": "Les données fournies ne respectent pas les règles de validation",
    "errors": {
        "msisdn": [
            "Le numéro de téléphone doit être au format mobile (77XXXXXX ou 25377XXXXXX) ou fixe (21XXXXXX ou 25321XXXXXX)"
        ]
    },
    "details": {
        "endpoint": "invoice/phone",
        "method": "POST",
        "timestamp": "2024-01-15T10:30:00Z"
    }
}
```

### Erreurs SOAP
```json
{
    "success": false,
    "error": "Erreur SOAP Fault",
    "fault_code": "Server",
    "fault_string": "Connection timeout",
    "backend_api": "Invoice SOAP"
}
```

### Erreurs Système
```json
{
    "success": false,
    "error": "Erreur serveur",
    "message": "Une erreur est survenue lors du traitement de la requête",
    "msisdn": "77123456",
    "backend_api": "Invoice SOAP"
}
```

## Exemples d'Intégration Mobile

### Classe Service Flutter/Dart
```dart
class InvoiceApiService {
    final String baseUrl;
    final http.Client client;
    
    InvoiceApiService({
        required this.baseUrl,
        http.Client? client,
    }) : client = client ?? http.Client();
    
    Future<InvoiceResponse> getInvoicesByPhone({
        required String msisdn,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/invoice/phone'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'msisdn': msisdn,
            }),
        );
        
        if (response.statusCode == 200) {
            return InvoiceResponse.fromJson(jsonDecode(response.body));
        } else {
            throw InvoiceApiException.fromResponse(response);
        }
    }
    
    Future<SingleInvoiceResponse> getInvoiceByNumber({
        required String invoiceNumber,
    }) async {
        final response = await client.post(
            Uri.parse('$baseUrl/invoice/number'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            body: jsonEncode({
                'invoice_number': invoiceNumber,
            }),
        );
        
        if (response.statusCode == 200) {
            return SingleInvoiceResponse.fromJson(jsonDecode(response.body));
        } else {
            throw InvoiceApiException.fromResponse(response);
        }
    }
    
    Future<ConnectionTestResponse> testConnection() async {
        final response = await client.get(
            Uri.parse('$baseUrl/invoice/test'),
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
        );
        
        if (response.statusCode == 200) {
            return ConnectionTestResponse.fromJson(jsonDecode(response.body));
        } else {
            throw InvoiceApiException.fromResponse(response);
        }
    }
}

// Modèles de données
class InvoiceResponse {
    final bool success;
    final String returnCode;
    final String description;
    final String msisdn;
    final List<Invoice> invoices;
    final int totalInvoices;
    final InvoiceSummary summary;
    final String backendApi;
    final String responseTime;
    
    InvoiceResponse({
        required this.success,
        required this.returnCode,
        required this.description,
        required this.msisdn,
        required this.invoices,
        required this.totalInvoices,
        required this.summary,
        required this.backendApi,
        required this.responseTime,
    });
    
    factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
        return InvoiceResponse(
            success: json['success'],
            returnCode: json['return_code'],
            description: json['description'],
            msisdn: json['msisdn'],
            invoices: (json['invoices'] as List)
                .map((item) => Invoice.fromJson(item))
                .toList(),
            totalInvoices: json['total_invoices'],
            summary: InvoiceSummary.fromJson(json['summary']),
            backendApi: json['backend_api'],
            responseTime: json['response_time'],
        );
    }
}

class Invoice {
    final String invoiceNumber;
    final InvoiceAmounts amounts;
    final InvoiceDates dates;
    final InvoiceStatus status;
    final InvoiceMeta meta;
    
    Invoice({
        required this.invoiceNumber,
        required this.amounts,
        required this.dates,
        required this.status,
        required this.meta,
    });
    
    factory Invoice.fromJson(Map<String, dynamic> json) {
        return Invoice(
            invoiceNumber: json['invoice_number'],
            amounts: InvoiceAmounts.fromJson(json['amounts']),
            dates: InvoiceDates.fromJson(json['dates']),
            status: InvoiceStatus.fromJson(json['status']),
            meta: InvoiceMeta.fromJson(json['meta']),
        );
    }
}

class InvoiceAmounts {
    final String invoiceAmount;
    final String remainingAmount;
    final String formattedInvoiceAmount;
    final String formattedRemainingAmount;
    
    InvoiceAmounts({
        required this.invoiceAmount,
        required this.remainingAmount,
        required this.formattedInvoiceAmount,
        required this.formattedRemainingAmount,
    });
    
    factory InvoiceAmounts.fromJson(Map<String, dynamic> json) {
        return InvoiceAmounts(
            invoiceAmount: json['invoice_amount'],
            remainingAmount: json['remaining_amount'],
            formattedInvoiceAmount: json['formatted_invoice_amount'],
            formattedRemainingAmount: json['formatted_remaining_amount'],
        );
    }
}

class InvoiceDates {
    final String billDate;
    final String dueDate;
    final String formattedBillDate;
    final String formattedDueDate;
    
    InvoiceDates({
        required this.billDate,
        required this.dueDate,
        required this.formattedBillDate,
        required this.formattedDueDate,
    });
    
    factory InvoiceDates.fromJson(Map<String, dynamic> json) {
        return InvoiceDates(
            billDate: json['bill_date'],
            dueDate: json['due_date'],
            formattedBillDate: json['formatted_bill_date'],
            formattedDueDate: json['formatted_due_date'],
        );
    }
}

class InvoiceStatus {
    final bool isOverdue;
    final int? daysUntilDue;
    final String statusText;
    
    InvoiceStatus({
        required this.isOverdue,
        this.daysUntilDue,
        required this.statusText,
    });
    
    factory InvoiceStatus.fromJson(Map<String, dynamic> json) {
        return InvoiceStatus(
            isOverdue: json['is_overdue'],
            daysUntilDue: json['days_until_due'],
            statusText: json['status_text'],
        );
    }
}

class InvoiceMeta {
    final bool canPay;
    final List<String> paymentMethods;
    
    InvoiceMeta({
        required this.canPay,
        required this.paymentMethods,
    });
    
    factory InvoiceMeta.fromJson(Map<String, dynamic> json) {
        return InvoiceMeta(
            canPay: json['can_pay'],
            paymentMethods: List<String>.from(json['payment_methods']),
        );
    }
}

class InvoiceSummary {
    final int totalInvoices;
    final String totalAmount;
    final String totalRemaining;
    final int overdueInvoices;
    final int upcomingDueInvoices;
    
    InvoiceSummary({
        required this.totalInvoices,
        required this.totalAmount,
        required this.totalRemaining,
        required this.overdueInvoices,
        required this.upcomingDueInvoices,
    });
    
    factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
        return InvoiceSummary(
            totalInvoices: json['total_invoices'],
            totalAmount: json['total_amount'],
            totalRemaining: json['total_remaining'],
            overdueInvoices: json['overdue_invoices'],
            upcomingDueInvoices: json['upcoming_due_invoices'],
        );
    }
}

// Gestion des erreurs
class InvoiceApiException implements Exception {
    final String error;
    final String message;
    final String? returnCode;
    final int statusCode;
    final String? msisdn;
    final String? invoiceNumber;
    
    InvoiceApiException({
        required this.error,
        required this.message,
        this.returnCode,
        required this.statusCode,
        this.msisdn,
        this.invoiceNumber,
    });
    
    factory InvoiceApiException.fromResponse(http.Response response) {
        final body = jsonDecode(response.body);
        return InvoiceApiException(
            error: body['error'] ?? 'Erreur inconnue',
            message: body['message'] ?? 'Une erreur est survenue',
            returnCode: body['return_code'],
            statusCode: response.statusCode,
            msisdn: body['msisdn'],
            invoiceNumber: body['invoice_number'],
        );
    }
    
    @override
    String toString() {
        return 'InvoiceApiException: $error - $message (HTTP $statusCode)';
    }
}
```

### Classe Service React Native/TypeScript
```typescript
interface InvoiceApiConfig {
    baseUrl: string;
    timeout?: number;
}

interface InvoiceAmounts {
    invoice_amount: string;
    remaining_amount: string;
    formatted_invoice_amount: string;
    formatted_remaining_amount: string;
}

interface InvoiceDates {
    bill_date: string;
    due_date: string;
    formatted_bill_date: string;
    formatted_due_date: string;
}

interface InvoiceStatus {
    is_overdue: boolean;
    days_until_due: number | null;
    status_text: string;
}

interface InvoiceMeta {
    can_pay: boolean;
    payment_methods: string[];
}

interface Invoice {
    invoice_number: string;
    amounts: InvoiceAmounts;
    dates: InvoiceDates;
    status: InvoiceStatus;
    meta: InvoiceMeta;
}

interface InvoiceSummary {
    total_invoices: number;
    total_amount: string;
    total_remaining: string;
    overdue_invoices: number;
    upcoming_due_invoices: number;
}

interface InvoiceResponse {
    success: boolean;
    return_code: string;
    description: string;
    msisdn: string;
    invoices: Invoice[];
    total_invoices: number;
    summary: InvoiceSummary;
    backend_api: string;
    response_time: string;
}

interface SingleInvoiceResponse {
    success: boolean;
    return_code: string;
    description: string;
    invoice_number: string;
    invoice: Invoice;
    backend_api: string;
    response_time: string;
}

interface ConnectionTestResponse {
    success: boolean;
    message: string;
    soap_url: string;
    http_status: number;
    response_headers: Record<string, string>;
}

class InvoiceApiService {
    private baseUrl: string;
    private timeout: number;
    
    constructor(config: InvoiceApiConfig) {
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
                throw new InvoiceApiError(
                    responseData.error || 'Erreur inconnue',
                    responseData.message || 'Une erreur est survenue',
                    response.status,
                    responseData.return_code,
                    responseData.msisdn,
                    responseData.invoice_number
                );
            }
            
            return responseData as T;
        } catch (error) {
            clearTimeout(timeoutId);
            if (error instanceof InvoiceApiError) {
                throw error;
            }
            throw new InvoiceApiError(
                'Erreur réseau',
                'Impossible de communiquer avec le serveur',
                0,
                undefined,
                undefined,
                undefined
            );
        }
    }
    
    async getInvoicesByPhone(msisdn: string): Promise<InvoiceResponse> {
        return this.request<InvoiceResponse>('/invoice/phone', 'POST', {
            msisdn,
        });
    }
    
    async getInvoiceByNumber(invoiceNumber: string): Promise<SingleInvoiceResponse> {
        return this.request<SingleInvoiceResponse>('/invoice/number', 'POST', {
            invoice_number: invoiceNumber,
        });
    }
    
    async testConnection(): Promise<ConnectionTestResponse> {
        return this.request<ConnectionTestResponse>('/invoice/test', 'GET');
    }
}

class InvoiceApiError extends Error {
    constructor(
        public error: string,
        public message: string,
        public statusCode: number,
        public returnCode?: string,
        public msisdn?: string,
        public invoiceNumber?: string
    ) {
        super(message);
        this.name = 'InvoiceApiError';
    }
}

// Utilitaires de validation
class InvoiceValidation {
    static validateMsisdn(msisdn: string): boolean {
        const mobileRegex = /^(77|25377)[0-9]{6}$/;
        const fixedRegex = /^(21|25321)[0-9]{6}$/;
        return mobileRegex.test(msisdn) || fixedRegex.test(msisdn);
    }
    
    static validateInvoiceNumber(invoiceNumber: string): boolean {
        const regex = /^[a-zA-Z0-9]+$/;
        return regex.test(invoiceNumber) && 
               invoiceNumber.length >= 5 && 
               invoiceNumber.length <= 50;
    }
    
    static formatPhoneNumber(msisdn: string): string {
        if (msisdn.length === 8) {
            return msisdn.replace(/(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4');
        }
        if (msisdn.length === 11) {
            return msisdn.replace(/(\d{3})(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4 $5');
        }
        return msisdn;
    }
    
    static getPhoneNumberType(msisdn: string): 'mobile' | 'fixed' | 'unknown' {
        if (msisdn.startsWith('77') || msisdn.startsWith('25377')) {
            return 'mobile';
        }
        if (msisdn.startsWith('21') || msisdn.startsWith('25321')) {
            return 'fixed';
        }
        return 'unknown';
    }
}

// Utilisation
const invoiceService = new InvoiceApiService({
    baseUrl: 'https://your-domain.com/api',
    timeout: 30000,
});

// Exemple d'utilisation
async function handleGetInvoices() {
    try {
        const msisdn = '77123456';
        
        // Validation côté client
        if (!InvoiceValidation.validateMsisdn(msisdn)) {
            console.error('Numéro de téléphone invalide');
            return;
        }
        
        const response = await invoiceService.getInvoicesByPhone(msisdn);
        
        console.log('Factures trouvées:', response.invoices.length);
        console.log('Montant total:', response.summary.total_amount);
        console.log('Factures en retard:', response.summary.overdue_invoices);
        
        // Traitement des factures
        response.invoices.forEach(invoice => {
            console.log(`Facture ${invoice.invoice_number}:`);
            console.log(`  Montant: ${invoice.amounts.formatted_remaining_amount}`);
            console.log(`  Statut: ${invoice.status.status_text}`);
            console.log(`  Échéance: ${invoice.dates.formatted_due_date}`);
        });
        
    } catch (error) {
        if (error instanceof InvoiceApiError) {
            console.error('API Error:', error.error);
            console.error('Message:', error.message);
            console.error('Return Code:', error.returnCode);
            console.error('Status Code:', error.statusCode);
        } else {
            console.error('Unexpected error:', error);
        }
    }
}

async function handleGetSingleInvoice() {
    try {
        const invoiceNumber = 'INV2024001';
        
        // Validation côté client
        if (!InvoiceValidation.validateInvoiceNumber(invoiceNumber)) {
            console.error('Numéro de facture invalide');
            return;
        }
        
        const response = await invoiceService.getInvoiceByNumber(invoiceNumber);
        
        console.log('Facture trouvée:', response.invoice.invoice_number);
        console.log('Montant:', response.invoice.amounts.formatted_remaining_amount);
        console.log('Statut:', response.invoice.status.status_text);
        
    } catch (error) {
        if (error instanceof InvoiceApiError) {
            console.error('API Error:', error.error);
            if (error.returnCode === '404') {
                console.log('Facture introuvable ou déjà payée');
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
// Validation des numéros de téléphone
function validateMsisdn(msisdn) {
    const mobileRegex = /^(77|25377)[0-9]{6}$/;
    const fixedRegex = /^(21|25321)[0-9]{6}$/;
    return mobileRegex.test(msisdn) || fixedRegex.test(msisdn);
}

// Validation des numéros de facture
function validateInvoiceNumber(invoiceNumber) {
    const regex = /^[a-zA-Z0-9]+$/;
    return regex.test(invoiceNumber) && 
           invoiceNumber.length >= 5 && 
           invoiceNumber.length <= 50;
}

// Formatage des numéros de téléphone
function formatPhoneNumber(msisdn) {
    if (msisdn.length === 8) {
        return msisdn.replace(/(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4');
    }
    if (msisdn.length === 11) {
        return msisdn.replace(/(\d{3})(\d{2})(\d{2})(\d{2})(\d{2})/, '$1 $2 $3 $4 $5');
    }
    return msisdn;
}
```

### 2. Gestion des Timeouts
```javascript
// Timeouts recommandés par type d'opération
const TIMEOUTS = {
    invoice_query: 20000,      // 20 secondes
    single_invoice: 15000,     // 15 secondes
    connection_test: 10000,    // 10 secondes
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
// États pour les factures
const INVOICE_STATES = {
    LOADING: 'loading',
    SUCCESS: 'success',
    ERROR: 'error',
    EMPTY: 'empty'
};

// Gestion des factures en cache
class InvoiceCache {
    constructor(ttl = 300000) { // 5 minutes
        this.cache = new Map();
        this.ttl = ttl;
    }
    
    set(key, value) {
        const expiry = Date.now() + this.ttl;
        this.cache.set(key, { value, expiry });
    }
    
    get(key) {
        const entry = this.cache.get(key);
        if (entry && entry.expiry > Date.now()) {
            return entry.value;
        }
        this.cache.delete(key);
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
class InvoiceFormatter {
    static formatAmount(amount) {
        const num = parseFloat(amount);
        return new Intl.NumberFormat('fr-DJ', {
            style: 'currency',
            currency: 'DJF',
            minimumFractionDigits: 2
        }).format(num);
    }
    
    static formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString('fr-FR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });
    }
    
    static getStatusColor(status) {
        switch (status.status_text) {
            case 'En retard':
                return '#FF4444';
            case 'Échéance proche':
                return '#FF8800';
            case 'Échu aujourd\'hui':
                return '#FF6600';
            case 'En cours':
                return '#00AA00';
            default:
                return '#666666';
        }
    }
    
    static getStatusIcon(status) {
        switch (status.status_text) {
            case 'En retard':
                return '⚠️';
            case 'Échéance proche':
                return '⏰';
            case 'Échu aujourd\'hui':
                return '🔔';
            case 'En cours':
                return '✅';
            default:
                return 'ℹ️';
        }
    }
}
```

## Monitoring et Debugging

### 1. Logging
```javascript
class InvoiceLogger {
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
                service: 'invoice-api'
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
class InvoiceMetrics {
    constructor() {
        this.metrics = {
            requests: 0,
            successes: 0,
            errors: 0,
            responseTime: [],
            errorsByType: {},
            invoicesByStatus: {}
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
    
    recordInvoiceStatus(status) {
        this.metrics.invoicesByStatus[status] = 
            (this.metrics.invoicesByStatus[status] || 0) + 1;
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
async function testInvoiceApi() {
    const service = new InvoiceApiService({
        baseUrl: 'https://your-domain.com/api',
        timeout: 30000
    });
    
    const testCases = [
        {
            name: 'Test Connection',
            test: () => service.testConnection()
        },
        {
            name: 'Get Invoices by Phone',
            test: () => service.getInvoicesByPhone('77123456')
        },
        {
            name: 'Get Invoice by Number',
            test: () => service.getInvoiceByNumber('INV2024001')
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
function validateInvoiceResponse(response) {
    const required = ['success', 'return_code', 'msisdn', 'invoices', 'total_invoices'];
    
    for (const field of required) {
        if (!(field in response)) {
            throw new Error(`Missing required field: ${field}`);
        }
    }
    
    if (!Array.isArray(response.invoices)) {
        throw new Error('invoices must be an array');
    }
    
    for (const invoice of response.invoices) {
        const invoiceRequired = ['invoice_number', 'amounts', 'dates', 'status'];
        for (const field of invoiceRequired) {
            if (!(field in invoice)) {
                throw new Error(`Missing required invoice field: ${field}`);
            }
        }
    }
    
    return true;
}
```

## Cas d'Usage Avancés

### 1. Surveillance des Échéances
```javascript
// Surveillance des factures proches de l'échéance
async function monitorUpcomingInvoices(msisdn) {
    try {
        const response = await invoiceService.getInvoicesByPhone(msisdn);
        
        const upcomingInvoices = response.invoices.filter(invoice => {
            const daysUntilDue = invoice.status.days_until_due;
            return daysUntilDue !== null && daysUntilDue > 0 && daysUntilDue <= 7;
        });
        
        const overdueInvoices = response.invoices.filter(invoice => {
            return invoice.status.is_overdue;
        });
        
        return {
            upcoming: upcomingInvoices,
            overdue: overdueInvoices,
            total: response.invoices.length,
            totalAmount: response.summary.total_remaining
        };
        
    } catch (error) {
        console.error('Error monitoring invoices:', error);
        throw error;
    }
}
```

### 2. Tableau de Bord des Factures
```javascript
// Génération d'un tableau de bord
async function generateInvoiceDashboard(msisdn) {
    try {
        const response = await invoiceService.getInvoicesByPhone(msisdn);
        
        const dashboard = {
            summary: response.summary,
            invoices: response.invoices,
            insights: {
                averageAmount: 0,
                oldestInvoice: null,
                newestInvoice: null,
                paymentUrgency: 'low'
            }
        };
        
        if (response.invoices.length > 0) {
            // Calculer le montant moyen
            const totalAmount = response.invoices.reduce((sum, inv) => 
                sum + parseFloat(inv.amounts.remaining_amount), 0);
            dashboard.insights.averageAmount = totalAmount / response.invoices.length;
            
            // Trouver les factures les plus anciennes et récentes
            const sortedByDate = response.invoices.sort((a, b) => 
                new Date(a.dates.bill_date) - new Date(b.dates.bill_date));
            dashboard.insights.oldestInvoice = sortedByDate[0];
            dashboard.insights.newestInvoice = sortedByDate[sortedByDate.length - 1];
            
            // Déterminer l'urgence de paiement
            if (response.summary.overdue_invoices > 0) {
                dashboard.insights.paymentUrgency = 'high';
            } else if (response.summary.upcoming_due_invoices > 0) {
                dashboard.insights.paymentUrgency = 'medium';
            }
        }
        
        return dashboard;
        
    } catch (error) {
        console.error('Error generating dashboard:', error);
        throw error;
    }
}
```

### 3. Workflow de Paiement
```javascript
// Workflow de préparation de paiement
async function preparePaymentWorkflow(msisdn, invoiceNumbers = []) {
    try {
        let invoicesToPay = [];
        
        if (invoiceNumbers.length > 0) {
            // Récupérer des factures spécifiques
            const promises = invoiceNumbers.map(num => 
                invoiceService.getInvoiceByNumber(num)
                    .then(response => response.invoice)
                    .catch(error => ({ error, invoice_number: num }))
            );
            
            const results = await Promise.all(promises);
            invoicesToPay = results.filter(r => !r.error);
        } else {
            // Récupérer toutes les factures
            const response = await invoiceService.getInvoicesByPhone(msisdn);
            invoicesToPay = response.invoices;
        }
        
        // Calculer le montant total
        const totalAmount = invoicesToPay.reduce((sum, inv) => 
            sum + parseFloat(inv.amounts.remaining_amount), 0);
        
        // Trier par priorité (factures en retard en premier)
        const sortedInvoices = invoicesToPay.sort((a, b) => {
            if (a.status.is_overdue && !b.status.is_overdue) return -1;
            if (!a.status.is_overdue && b.status.is_overdue) return 1;
            return (a.status.days_until_due || 0) - (b.status.days_until_due || 0);
        });
        
        return {
            invoices: sortedInvoices,
            totalAmount,
            formattedTotal: InvoiceFormatter.formatAmount(totalAmount),
            paymentPriority: sortedInvoices.map(inv => ({
                invoice_number: inv.invoice_number,
                amount: inv.amounts.remaining_amount,
                priority: inv.status.is_overdue ? 'high' : 
                         (inv.status.days_until_due <= 7 ? 'medium' : 'low')
            }))
        };
        
    } catch (error) {
        console.error('Error preparing payment:', error);
        throw error;
    }
}
```

---

## Support et Maintenance

### Version API
- **Version actuelle**: Laravel 12.x
- **Backend SOAP**: Invoice System v2.0
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

*Ce guide doit être mis à jour régulièrement en fonction des évolutions de l'API Invoice.*