# Intégration FCM — Guide mobile

> **Base URL :** `http://10.39.230.106/api`  
> **Stack serveur :** Laravel 12 · kreait/firebase-php · MySQL  
> **Dernière mise à jour :** Mai 2026

---

## Table des matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Cycle de vie du token FCM](#2-cycle-de-vie-du-token-fcm)
3. [Endpoints FCM](#3-endpoints-fcm)
   - [Enregistrer un token (avant auth)](#31-enregistrer-un-token-avant-auth)
   - [Mettre à jour un token (après auth)](#32-mettre-à-jour-un-token-après-auth)
   - [Supprimer un token (déconnexion)](#33-supprimer-un-token-déconnexion)
4. [Endpoint de configuration](#4-endpoint-de-configuration)
5. [Notifications automatiques](#5-notifications-automatiques)
   - [Structure du payload](#51-structure-du-payload)
   - [Types et deep links](#52-types-et-deep-links)
   - [Catalogue des notifications](#53-catalogue-des-notifications)
6. [Gestion multi-appareils](#6-gestion-multi-appareils)
7. [Nettoyage des tokens invalides](#7-nettoyage-des-tokens-invalides)
8. [Checklist d'intégration Flutter](#8-checklist-dintégration-flutter)

---

## 1. Vue d'ensemble

Le serveur envoie des notifications push FCM automatiquement lors de chaque transaction réussie. L'application mobile n'a pas à les déclencher — elle doit uniquement :

1. **Enregistrer** son token FCM dès le démarrage (avant la connexion)
2. **Mettre à jour** le token si Firebase en génère un nouveau
3. **Supprimer** le token lors de la déconnexion

```
App mobile                          Serveur
    │                                   │
    │── POST /mobile/fcm/register-token ──▶│  (dès le lancement)
    │                                   │
    │── POST /mobile/login-pin ──────────▶│
    │◀── session_token ──────────────────│
    │                                   │
    │── POST /mobile/fcm/update-token ───▶│  (après connexion)
    │                                   │
    │    [transaction : achat/transfert] │
    │◀── Notification FCM ───────────────│  (automatique)
    │                                   │
    │── POST /mobile/fcm/clear-token ────▶│  (lors du logout)
```

---

## 2. Cycle de vie du token FCM

```
Lancement de l'app
       │
       ▼
FirebaseMessaging.instance.getToken()
       │
       ▼
POST /mobile/fcm/register-token  ◄── toujours, même sans session
       │
       ▼
Connexion PIN réussie → session_token obtenu
       │
       ▼
POST /mobile/fcm/update-token  ◄── avec session_token + fcm_token
       │
       ├── onTokenRefresh (Firebase génère un nouveau token)
       │       └── POST /mobile/fcm/update-token
       │
       └── Déconnexion
               └── POST /mobile/fcm/clear-token
```

---

## 3. Endpoints FCM

### 3.1 Enregistrer un token (avant auth)

Appeler **dès le lancement de l'application**, avant même que l'utilisateur soit connecté. Cela permet de recevoir des notifications même si la session n'est pas encore établie (ex: OTP).

```
POST /api/mobile/fcm/register-token
Content-Type: application/json
```

**Corps de la requête**

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `phone_number` | string | ✅ | Numéro au format international `25377XXXXXX` |
| `fcm_token` | string | ✅ | Token FCM Firebase (min. 50 caractères) |
| `device_type` | string | — | `android` ou `ios` |
| `device_name` | string | — | Nom de l'appareil (ex: `"Samsung Galaxy S24"`) |

**Exemple**

```json
{
  "phone_number": "25377123456",
  "fcm_token": "dGhpcyBpcyBhIGZha2UgZmNtIHRva2VuIGZvciBkb2N1bWVudGF0aW9uIHB1cnBvc2Vz...",
  "device_type": "android",
  "device_name": "Pixel 8"
}
```

**Réponse 200**

```json
{
  "status": "success",
  "message": "Token FCM enregistré avec succès",
  "data": {
    "fcm_token_updated": true,
    "fcm_token_updated_at": "2026-05-06T10:30:00.000000Z"
  }
}
```

---

### 3.2 Mettre à jour un token (après auth)

Appeler après chaque connexion réussie, et à chaque fois que `FirebaseMessaging.onTokenRefresh` se déclenche.

```
POST /api/mobile/fcm/update-token
Content-Type: application/json
```

**Corps de la requête**

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `session_token` | string | ✅ | Token de session actif |
| `fcm_token` | string | ✅ | Token FCM Firebase |
| `device_type` | string | — | `android` ou `ios` |
| `device_name` | string | — | Nom de l'appareil |

**Exemple**

```json
{
  "session_token": "abc123...",
  "fcm_token": "dGhpcyBpcyBhIGZha2UgZmNtIHRva2VuIGZvciBkb2N1bWVudGF0aW9uIHB1cnBvc2Vz...",
  "device_type": "ios",
  "device_name": "iPhone 15 Pro"
}
```

**Réponse 200**

```json
{
  "status": "success",
  "message": "Token FCM mis à jour avec succès",
  "data": {
    "fcm_token_updated": true,
    "fcm_token_updated_at": "2026-05-06T10:31:00.000000Z"
  }
}
```

**Réponse 401** — session invalide ou expirée

```json
{
  "status": "error",
  "message": "Session non valide"
}
```

---

### 3.3 Supprimer un token (déconnexion)

Appeler lors du logout. Passer le `fcm_token` de l'appareil courant pour ne déconnecter que celui-ci (les autres appareils de l'utilisateur continuent de recevoir des notifications).

```
POST /api/mobile/fcm/clear-token
Content-Type: application/json
```

**Corps de la requête**

| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| `session_token` | string | ✅ | Token de session actif |
| `fcm_token` | string | — | Token FCM à supprimer. Si absent, supprime le plus récent |

**Exemple**

```json
{
  "session_token": "abc123...",
  "fcm_token": "dGhpcyBpcyBhIGZha2UgZmNtIHRva2VuIGZvciBkb2N1bWVudGF0aW9uIHB1cnBvc2Vz..."
}
```

**Réponse 200**

```json
{
  "status": "success",
  "message": "Token FCM supprimé avec succès",
  "data": {
    "fcm_token_cleared": true
  }
}
```

---

## 4. Endpoint de configuration

Permet de récupérer les paramètres configurables côté serveur, sans avoir à republier l'application pour les modifier.

```
GET /api/mobile/config
```

**Réponse 200**

```json
{
  "low_balance_threshold": 500
}
```

| Champ | Description |
|-------|-------------|
| `low_balance_threshold` | Seuil de solde bas en DJF. Afficher un avertissement dans l'app si `solde < low_balance_threshold` |

**Recommandation** : appeler cet endpoint au démarrage et mettre la valeur en cache local (SharedPreferences / Hive). Rafraîchir à chaque lancement.

```dart
// Exemple Flutter
final config = await api.getMobileConfig();
final threshold = config['low_balance_threshold'] as int; // 500
prefs.setInt('low_balance_threshold', threshold);
```

---

## 5. Notifications automatiques

### 5.1 Structure du payload

Toutes les notifications envoyées par le serveur suivent cette structure :

```json
{
  "notification": {
    "title": "Titre affiché",
    "body": "Corps du message"
  },
  "data": {
    "type": "offer_purchase",
    "amount": "1000",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

> ⚠️ Le champ `type` est **toujours présent** dans `data`. Il détermine le deep link à exécuter à l'ouverture.

---

### 5.2 Types et deep links

| `type` | Action dans l'app |
|--------|-------------------|
| `offer_purchase` | Naviguer vers la page des offres actives |
| `credit_transfer` | Naviguer vers l'historique des transactions |
| `voucher_refill` | Naviguer vers le solde / historique de recharge |
| `buy_offer` | Ouvrir la page d'achat d'offres |
| `security` | Naviguer vers les paramètres de sécurité |

---

### 5.3 Catalogue des notifications

#### Achat d'offre personnel

Déclenché par : `POST /api/air/purchase`  
Destinataire : l'acheteur

```json
{
  "notification": {
    "title": "Achat confirmé ! 🎉",
    "body": "Votre offre Confort a été activée pour 3000 DJF"
  },
  "data": {
    "type": "offer_purchase",
    "amount": "3000",
    "offer_id": "17",
    "offer_name": "Confort",
    "validity_days": "30",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

---

#### Offre reçue en cadeau

Déclenché par : `POST /api/air/gift`  
Destinataire : le bénéficiaire

```json
{
  "notification": {
    "title": "Cadeau reçu ! 🎁",
    "body": "Vous avez reçu l'offre Median de 77654321"
  },
  "data": {
    "type": "offer_purchase",
    "amount": "1000",
    "offer_id": "11",
    "offer_name": "Median",
    "sender": "77654321",
    "validity_days": "30",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

> L'acheteur reçoit également une notification de type `offer_purchase` confirmant son achat.

---

#### Transfert de crédit — expéditeur

Déclenché par : `POST /api/air/transfer-credit`  
Destinataire : l'expéditeur

```json
{
  "notification": {
    "title": "Transfert réussi ! 💸",
    "body": "Vous avez envoyé 500 DJF au 77987654"
  },
  "data": {
    "type": "credit_transfer",
    "amount": "500",
    "receiver": "77987654",
    "new_balance": "245000",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

---

#### Transfert de crédit — destinataire

Déclenché par : `POST /api/air/transfer-credit`  
Destinataire : le destinataire

```json
{
  "notification": {
    "title": "Crédit reçu ! 💰",
    "body": "Vous avez reçu 500 DJF de 77123456"
  },
  "data": {
    "type": "credit_transfer",
    "amount": "500",
    "sender": "77123456",
    "new_balance": "87500",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

> `new_balance` est exprimé en **centimes** (diviser par 100 pour obtenir les DJF).

---

#### Recharge voucher personnelle

Déclenché par : `POST /api/air/refill/voucher`  
Destinataire : le propriétaire du compte rechargé

```json
{
  "notification": {
    "title": "Recharge confirmée ! 🔋",
    "body": "Votre compte a été rechargé de 2000 DJF"
  },
  "data": {
    "type": "voucher_refill",
    "amount": "2000",
    "voucher_code": "1234****5678",
    "new_balance": "387500",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

---

#### Recharge voucher cadeau reçue

Déclenché par : `POST /api/air/refill/gift`  
Destinataire : le bénéficiaire

```json
{
  "notification": {
    "title": "Recharge cadeau reçue ! 🎁",
    "body": "Vous avez reçu une recharge de 1000 DJF de 77123456"
  },
  "data": {
    "type": "voucher_refill",
    "amount": "1000",
    "sender": "77123456",
    "new_balance": "152300",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

> L'expéditeur reçoit également une notification `voucher_refill` confirmant l'envoi.

---

## 6. Gestion multi-appareils

Le serveur stocke **un token FCM par appareil** dans la table `mobile_device_tokens`. Un même utilisateur peut avoir plusieurs appareils enregistrés simultanément.

**Comportement :**
- Chaque notification est envoyée à **tous les appareils** enregistrés (multicast Firebase)
- `clear-token` avec `fcm_token` supprime uniquement l'appareil courant
- `clear-token` sans `fcm_token` supprime le token le plus récent

**Recommandation Flutter :**

```dart
// Toujours passer le fcm_token lors du logout
final fcmToken = await FirebaseMessaging.instance.getToken();

await api.clearFcmToken(
  sessionToken: currentSession,
  fcmToken: fcmToken,
);
```

---

## 7. Nettoyage des tokens invalides

Le serveur gère automatiquement les tokens expirés ou désinstallés.

Quand Firebase retourne `UNREGISTERED` ou `messaging/registration-token-not-registered`, le serveur :
1. Détecte l'erreur dans la réponse FCM
2. Supprime le token invalide de la base de données
3. Continue l'envoi aux autres tokens valides de l'utilisateur

**Aucune action requise côté application** pour ce cas de figure.

---

## 8. Checklist d'intégration Flutter

### Initialisation (dans `main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Permissions (iOS)
  await FirebaseMessaging.instance.requestPermission();

  // Récupérer et enregistrer le token dès le lancement
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await api.registerFcmToken(
      phoneNumber: storedPhoneNumber, // depuis SharedPreferences
      fcmToken: token,
      deviceType: Platform.isIOS ? 'ios' : 'android',
      deviceName: await _getDeviceName(),
    );
  }

  // Écouter les renouvellements de token
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final sessionToken = prefs.getString('session_token');
    if (sessionToken != null) {
      await api.updateFcmToken(sessionToken: sessionToken, fcmToken: newToken);
    } else {
      await api.registerFcmToken(phoneNumber: storedPhoneNumber, fcmToken: newToken);
    }
  });

  runApp(MyApp());
}
```

### Gestion des notifications reçues

```dart
// Notification reçue en foreground
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final type = message.data['type'] ?? '';
  _showLocalNotification(message.notification, type);
});

// Tap sur une notification (app en background / terminée)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  _handleDeepLink(message.data['type'] ?? '');
});

// Vérifier si l'app a été ouverte via une notification
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial != null) {
  _handleDeepLink(initial.data['type'] ?? '');
}

void _handleDeepLink(String type) {
  switch (type) {
    case 'offer_purchase':
      router.push('/offers/active');
      break;
    case 'credit_transfer':
      router.push('/transactions');
      break;
    case 'voucher_refill':
      router.push('/balance');
      break;
    case 'buy_offer':
      router.push('/offers');
      break;
    case 'security':
      router.push('/settings/security');
      break;
    default:
      router.push('/home');
  }
}
```

### Après connexion réussie

```dart
final loginResponse = await api.loginWithPin(phone, pin);
final sessionToken = loginResponse['session_token'];

// Toujours mettre à jour le token après connexion
final fcmToken = await FirebaseMessaging.instance.getToken();
if (fcmToken != null) {
  await api.updateFcmToken(
    sessionToken: sessionToken,
    fcmToken: fcmToken,
    deviceType: Platform.isIOS ? 'ios' : 'android',
  );
}
```

### Lors du logout

```dart
final fcmToken = await FirebaseMessaging.instance.getToken();

await api.clearFcmToken(
  sessionToken: currentSessionToken,
  fcmToken: fcmToken, // important : cibler uniquement cet appareil
);

await api.logout(sessionToken: currentSessionToken);
prefs.remove('session_token');
```

### Configuration au démarrage

```dart
Future<void> loadServerConfig() async {
  try {
    final config = await api.getMobileConfig(); // GET /api/mobile/config
    final threshold = config['low_balance_threshold'] as int;
    await prefs.setInt('low_balance_threshold', threshold);
  } catch (_) {
    // Valeur par défaut si l'appel échoue
    await prefs.setInt('low_balance_threshold', 500);
  }
}
```

---

## Résumé des endpoints

| Méthode | Endpoint | Auth | Description |
|---------|----------|------|-------------|
| `POST` | `/api/mobile/fcm/register-token` | ❌ | Enregistrer token (avant connexion) |
| `POST` | `/api/mobile/fcm/update-token` | session_token | Mettre à jour token (après connexion) |
| `POST` | `/api/mobile/fcm/clear-token` | session_token | Supprimer token (logout) |
| `GET` | `/api/mobile/config` | ❌ | Paramètres configurables |
