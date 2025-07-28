# API Mobile - Documentation des Endpoints

## Workflow d'Authentification Mobile

L'application mobile utilise le workflow suivant (SANS inscription préalable) :

1. **Utilisateur tape son numéro** → Appelle `/api/sms/otp/send`
2. **Reçoit SMS avec OTP** → Tape le code OTP
3. **Valide l'OTP** → Appelle `/api/sms/otp/verify`
4. **Système crée automatiquement l'utilisateur** si première connexion
5. **Retourne session_token** pour utilisation de l'app

## Endpoints Principaux

### 1. Demander un code OTP (Existant)
```http
POST /api/sms/otp/send
```

**Payload:**
```json
{
    "to": "78901234",
    "from": "8686"
}
```

**Réponse (200):**
```json
{
    "status": "success",
    "message": "Code OTP envoyé avec succès",
    "debug": {
        "otp": "123456"
    }
}
```

### 2. Vérifier OTP et Connexion Automatique (Modifié)
```http
POST /api/sms/otp/verify
```

**Payload:**
```json
{
    "to": "78901234",
    "otp": "123456",
    "device_type": "android",
    "device_info": {
        "model": "Samsung Galaxy S23",
        "os_version": "Android 14",
        "app_version": "1.0.0",
        "device_id": "unique-device-id-123"
    }
}
```

**Réponse (200) - Première connexion:**
```json
{
    "status": "success",
    "message": "Connexion réussie",
    "data": {
        "session_token": "abc123def456...",
        "expires_at": "2025-02-27T15:30:00.000Z",
        "user": {
            "id": 1,
            "phone_number": "78901234",
            "name": null,
            "email": null,
            "is_active": true,
            "is_new_user": true,
            "last_login_at": "2025-01-28T15:30:00.000Z"
        }
    }
}
```

**Réponse (200) - Utilisateur existant:**
```json
{
    "status": "success",
    "message": "Connexion réussie",
    "data": {
        "session_token": "def456ghi789...",
        "expires_at": "2025-02-27T15:30:00.000Z",
        "user": {
            "id": 1,
            "phone_number": "78901234",
            "name": "Jean Dupont",
            "email": "jean@example.com",
            "is_active": true,
            "is_new_user": false,
            "last_login_at": "2025-01-28T15:30:00.000Z"
        }
    }
}
```

## Endpoints de Gestion de Session

### 3. Obtenir le profil utilisateur
```http
POST /api/mobile/profile
```

**Payload:**
```json
{
    "session_token": "abc123def456..."
}
```

**Réponse (200):**
```json
{
    "status": "success",
    "data": {
        "user": {
            "id": 1,
            "phone_number": "78901234",
            "name": "Jean Dupont",
            "email": "jean@example.com",
            "is_active": true,
            "phone_verified_at": "2025-01-28T15:30:00.000Z",
            "last_login_at": "2025-01-28T15:30:00.000Z",
            "created_at": "2025-01-20T10:00:00.000Z"
        },
        "session": {
            "login_at": "2025-01-28T15:30:00.000Z",
            "last_activity": "2025-01-28T16:15:00.000Z",
            "device_type": "android"
        }
    }
}
```

### 4. Mettre à jour le profil
```http
POST /api/mobile/update-profile
```

**Payload:**
```json
{
    "session_token": "abc123def456...",
    "name": "Jean Dupont",
    "email": "jean.dupont@example.com"
}
```

**Réponse (200):**
```json
{
    "status": "success",
    "message": "Profil mis à jour avec succès",
    "data": {
        "user": {
            "id": 1,
            "phone_number": "78901234",
            "name": "Jean Dupont",
            "email": "jean.dupont@example.com",
            "is_active": true,
            "last_login_at": "2025-01-28T15:30:00.000Z"
        }
    }
}
```

### 5. Déconnexion
```http
POST /api/mobile/logout
```

**Payload:**
```json
{
    "session_token": "abc123def456..."
}
```

**Réponse (200):**
```json
{
    "status": "success",
    "data": {
        "user": {
            "id": 1,
            "phone_number": "78901234",
            "name": "Jean Dupont",
            "email": "jean@example.com",
            "is_active": true,
            "phone_verified_at": "2025-01-28T15:30:00.000Z",
            "last_login_at": "2025-01-28T15:30:00.000Z",
            "created_at": "2025-01-20T10:00:00.000Z"
        },
        "session": {
            "login_at": "2025-01-28T15:30:00.000Z",
            "last_activity": "2025-01-28T16:15:00.000Z",
            "device_type": "android"
        }
    }
}
```

### 5. Déconnexion
```http
POST /api/mobile/logout
```

**Payload:**
```json
{
    "session_token": "abc123def456..."
}
```

**Réponse (200):**
```json
{
    "status": "success",
    "message": "Déconnexion réussie"
}
```

## Gestion des Erreurs

### Erreurs de Validation (422)
```json
{
    "message": "The given data was invalid.",
    "errors": {
        "phone_number": [
            "Le numéro de téléphone doit contenir entre 8 et 11 chiffres"
        ]
    }
}
```

### Erreurs d'Authentification (401)
```json
{
    "status": "error",
    "message": "Code OTP invalide ou expiré"
}
```

### Erreurs Serveur (500)
```json
{
    "status": "error",
    "message": "Erreur lors de la connexion",
    "error": "Détails de l'erreur..."
}
```

## Flux d'Utilisation Recommandé

1. **Nouveau Utilisateur:**
   - `POST /register` → Enregistrement
   - `POST /request-otp` → Demander OTP
   - `POST /login` → Connexion avec OTP

2. **Utilisateur Existant:**
   - `POST /request-otp` → Demander OTP
   - `POST /login` → Connexion avec OTP

3. **Session Active:**
   - `POST /profile` → Récupérer infos utilisateur
   - `POST /logout` → Déconnexion

## Validation des Données

### Numéro de Téléphone
- Format: 8 à 11 chiffres
- Exemple: `78901234`

### Code OTP
- Format: Exactement 6 chiffres
- Exemple: `123456`

### Device Type
- Valeurs autorisées: `android`, `ios`, `web`

### Session Token
- Généré automatiquement
- Durée de vie: 30 jours
- Doit être stocké côté client de manière sécurisée

## Notes Importantes

- Toutes les réponses sont en JSON
- Les dates sont au format ISO 8601
- Les sessions expirent après 30 jours d'inactivité
- L'OTP expire après 5 minutes
- Les numéros de téléphone sont automatiquement nettoyés (seuls les chiffres sont conservés)