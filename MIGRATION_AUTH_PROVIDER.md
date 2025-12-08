# Migration AuthProvider - Résumé

## ✅ Implémentation Complétée

### 1. AuthProvider Créé
- ✅ [auth_provider.dart](lib/providers/auth_provider.dart) - Provider complet pour l'authentification
- ✅ **380+ lignes** de logique centralisée
- ✅ Toutes les fonctionnalités d'auth implémentées

### 2. Setup dans l'App
- ✅ [main.dart](lib/main.dart#L50) - AuthProvider ajouté au MultiProvider
- ✅ [main.dart](lib/main.dart#L82) - Lifecycle app intégré avec AuthProvider
- ✅ Import `user_session.dart` supprimé de main.dart

### 3. Architecture

```
AuthProvider (State Management)
    ↓
UserSession (Persistence - SharedPreferences)
    ↓
OtpService / LogoutService (API Calls)
```

## 🎯 Fonctionnalités de l'AuthProvider

### Authentification
```dart
// Envoyer OTP
final success = await context.read<AuthProvider>().sendOtp(phoneNumber);

// Vérifier OTP et créer session
final success = await context.read<AuthProvider>().verifyOtp(phoneNumber, otp);

// Déconnexion
final success = await context.read<AuthProvider>().logout();
```

### Gestion de Session
```dart
// Vérifier si authentifié
final isAuth = context.watch<AuthProvider>().isAuthenticated;

// Obtenir le numéro
final phone = context.watch<AuthProvider>().phoneNumber;

// Numéro formaté (+253 XX XX XX XX)
final formattedPhone = context.watch<AuthProvider>().formattedPhoneNumber;

// Session token
final token = context.read<AuthProvider>().sessionToken;

// Vérifier validité session
final isValid = await context.read<AuthProvider>().checkSession();
```

### Gestion d'Activité
```dart
// Mettre à jour activité (déjà fait dans MyApp build)
context.read<AuthProvider>().updateActivity();

// Vérifier expiration
final isExpired = context.read<AuthProvider>().isSessionExpired;

// Temps restant avant expiration
final remaining = context.read<AuthProvider>().timeUntilExpiration; // Duration?

// Durée session active
final duration = context.read<AuthProvider>().sessionDuration; // Duration?
```

### États UI
```dart
// Indicateur de chargement
final isLoading = context.watch<AuthProvider>().isLoading;

// Message d'erreur
final error = context.watch<AuthProvider>().errorMessage;

// Effacer erreur
context.read<AuthProvider>().clearError();
```

### Lifecycle App
```dart
// Déjà intégré dans MyApp, mais peut être appelé manuellement si besoin
context.read<AuthProvider>().appResumed();
context.read<AuthProvider>().appPaused();
context.read<AuthProvider>().appTerminated();
```

### Utilitaires
```dart
// Validation numéro de téléphone
final isValid = AuthProvider.isValidPhoneNumber('77123456'); // static method

// Réinitialiser provider
context.read<AuthProvider>().reset();
```

## 📊 État du Provider

L'AuthProvider maintient :

| État | Type | Description |
|------|------|-------------|
| `phoneNumber` | `String?` | Numéro de l'utilisateur |
| `sessionToken` | `String?` | Token de session API |
| `isAuthenticated` | `bool` | Statut d'auth |
| `lastActivityTime` | `DateTime?` | Dernière activité |
| `isLoading` | `bool` | Opération en cours |
| `errorMessage` | `String?` | Erreur actuelle |
| `sessionCreatedAt` | `DateTime?` | Date création session |

## 🔄 Flow d'Authentification

### 1. Login Flow (LoginScreen → OTPScreen)

**LoginScreen** (à migrer) :
```dart
// AVANT
final result = await _otpService.sendOtp(phoneNumber);
if (result['status'] == 'success') {
  Navigator.push(...);
}

// APRÈS
final success = await context.read<AuthProvider>().sendOtp(phoneNumber);
if (success) {
  Navigator.push(...);
} else {
  // Afficher context.read<AuthProvider>().errorMessage
}
```

**OTPScreen** (à migrer) :
```dart
// AVANT
final result = await _otpService.verifyOtp(widget.phone, otp);
if (result['status'] == 'success') {
  final sessionToken = result['data']?['session_token'];
  await UserSession.createSession(widget.phone, sessionToken: sessionToken);
  await FCMTokenService.updateTokenOnServer();
  Navigator.pushAndRemoveUntil(...);
}

// APRÈS
final success = await context.read<AuthProvider>().verifyOtp(widget.phone, otp);
if (success) {
  // Session créée automatiquement, FCM envoyé automatiquement
  Navigator.pushAndRemoveUntil(...);
} else {
  // Afficher context.read<AuthProvider>().errorMessage
}
```

### 2. Logout Flow

**ProfileScreen** (ou autre écran de déconnexion) :
```dart
// AVANT
final success = await LogoutService.logout();
if (success) {
  Navigator.pushAndRemoveUntil(...);
}

// APRÈS
final success = await context.read<AuthProvider>().logout();
if (success) {
  // BalanceProvider devrait aussi être reset
  context.read<BalanceProvider>().reset();
  Navigator.pushAndRemoveUntil(...);
}
```

### 3. Session Check Flow

**SplashScreen** (ou HomeScreen) :
```dart
// AVANT
final isAuth = await UserSession.isAuthenticated();
if (isAuth) {
  Navigator.pushReplacement(...HomeScreen);
} else {
  Navigator.pushReplacement(...LoginScreen);
}

// APRÈS
final authProvider = context.watch<AuthProvider>();
if (authProvider.isAuthenticated) {
  Navigator.pushReplacement(...HomeScreen);
} else {
  Navigator.pushReplacement(...LoginScreen);
}
```

## 🎨 Exemples d'Utilisation

### LoginScreen avec AuthProvider
```dart
class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.sendOtp(_phoneController.text);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(phone: _phoneController.text),
        ),
      );
    } else {
      // Afficher erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          TextField(controller: _phoneController),

          if (authProvider.errorMessage != null)
            Text(authProvider.errorMessage!, style: TextStyle(color: Colors.red)),

          ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleLogin,
            child: authProvider.isLoading
                ? CircularProgressIndicator()
                : Text('Continuer'),
          ),
        ],
      ),
    );
  }
}
```

### OTPScreen avec AuthProvider
```dart
class _OTPScreenState extends State<OTPScreen> {
  void _onOTPSubmit() async {
    String otp = _controllers.map((c) => c.text).join();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(widget.phone, otp);

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      // Afficher erreur
      setState(() {
        _errorMessage = authProvider.errorMessage;
        _clearAllFields();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          // OTP fields...

          if (authProvider.errorMessage != null)
            Text(authProvider.errorMessage!, style: TextStyle(color: Colors.red)),

          ElevatedButton(
            onPressed: authProvider.isLoading ? null : _onOTPSubmit,
            child: authProvider.isLoading
                ? CircularProgressIndicator()
                : Text('Vérifier'),
          ),
        ],
      ),
    );
  }
}
```

### HomeScreen - Afficher Info User
```dart
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenue ${authProvider.formattedPhoneNumber ?? ''}'),
      ),
      body: Column(
        children: [
          Text('Connecté depuis: ${authProvider.sessionDuration?.inMinutes ?? 0} min'),

          if (authProvider.isSessionExpired)
            Text('Session expirée!', style: TextStyle(color: Colors.red)),

          ElevatedButton(
            onPressed: () async {
              final success = await authProvider.logout();
              if (success) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
```

### Protected Route - Vérifier Auth
```dart
class ProtectedScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Rediriger si non authentifié
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      });
      return Scaffold(body: CircularProgressIndicator());
    }

    // Afficher contenu protégé
    return Scaffold(
      appBar: AppBar(title: Text('Contenu Protégé')),
      body: Text('Bienvenue ${authProvider.phoneNumber}'),
    );
  }
}
```

## 🔗 Intégration avec BalanceProvider

Lors du logout, il faut aussi réinitialiser le BalanceProvider :

```dart
Future<void> _logout() async {
  final authProvider = context.read<AuthProvider>();
  final balanceProvider = context.read<BalanceProvider>();

  final success = await authProvider.logout();

  if (success) {
    // Réinitialiser aussi le solde
    balanceProvider.reset();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }
}
```

## ⚡ Avantages

### 1. Centralisation
- ✅ Toute la logique auth en un seul endroit
- ✅ Plus besoin d'appeler directement UserSession/OtpService
- ✅ État partagé entre tous les écrans

### 2. Réactivité
```dart
// Tous les widgets qui watch se mettent à jour automatiquement
final isAuth = context.watch<AuthProvider>().isAuthenticated;
```

### 3. Simplification du Code
```dart
// AVANT - 20 lignes dans chaque screen
try {
  final result = await _otpService.verifyOtp(...);
  if (result['status'] == 'success') {
    final token = result['data']?['session_token'];
    await UserSession.createSession(..., sessionToken: token);
    await FCMTokenService.updateTokenOnServer();
    Navigator.push(...);
  } else {
    setState(() => _errorMessage = result['message']);
  }
} catch (e) {
  setState(() => _errorMessage = 'Erreur');
}

// APRÈS - 5 lignes
final success = await context.read<AuthProvider>().verifyOtp(...);
if (success) {
  Navigator.push(...);
} else {
  // Afficher context.read<AuthProvider>().errorMessage
}
```

### 4. Lifecycle Automatique
- ✅ Gestion automatique de session expiration
- ✅ Mise à jour activité dans MyApp build
- ✅ Détection retour app (session expirée?)

### 5. État UI Intégré
- ✅ `isLoading` pour afficher loading
- ✅ `errorMessage` pour afficher erreurs
- ✅ Plus besoin de variables locales

## 🚀 Prochaines Étapes

### À Faire
1. ✅ AuthProvider créé
2. ✅ Main.dart mis à jour
3. ✅ Lifecycle intégré
4. ⏳ **Migrer LoginScreen** - Utiliser AuthProvider
5. ⏳ **Migrer OTPScreen** - Utiliser AuthProvider
6. ⏳ **Migrer SplashScreen** - Check auth via provider
7. ⏳ **Migrer ProfileScreen** - Logout via provider
8. ⏳ **Migrer HomeScreen** - Afficher user info

### Screens à Migrer

| Screen | Priorité | Complexité | État |
|--------|----------|------------|------|
| LoginScreen | 🔴 Haute | Faible | ⏳ À faire |
| OTPScreen | 🔴 Haute | Faible | ⏳ À faire |
| SplashScreen | 🔴 Haute | Faible | ⏳ À faire |
| ProfileScreen | 🟡 Moyenne | Faible | ⏳ À faire |
| HomeScreen | 🟡 Moyenne | Faible | ⏳ À faire |

## 📝 Notes Importantes

### UserSession Toujours Utilisé
L'AuthProvider **utilise** UserSession en interne pour la persistence :
- ✅ AuthProvider = State management (réactif)
- ✅ UserSession = Persistence (SharedPreferences)
- ✅ Ne PAS supprimer UserSession
- ✅ Juste ne plus l'appeler directement dans les screens

### Pattern Provider
```dart
// Dans build() - Rebuild quand state change
context.watch<AuthProvider>().isAuthenticated

// Dans callbacks/initState - Pas de rebuild
context.read<AuthProvider>().logout()
```

### Gestion Erreurs
```dart
// AuthProvider gère les erreurs automatiquement
final success = await authProvider.verifyOtp(...);
if (!success) {
  // errorMessage est automatiquement set
  print(authProvider.errorMessage);
}
```

## ✨ Features Bonus

### Validation Numéro
```dart
// Méthode statique
final isValid = AuthProvider.isValidPhoneNumber('77123456');
// Vérifie format Djibouti (77, 78, 70, 75, 76, 33)
```

### Session Info
```dart
// Temps écoulé depuis login
final duration = authProvider.sessionDuration; // ex: Duration(minutes: 15)

// Temps avant expiration (si inactif)
final remaining = authProvider.timeUntilExpiration; // ex: Duration(minutes: 8)

// Vérifier expiration
if (authProvider.isSessionExpired) {
  // Rediriger vers login
}
```

### Formatage Automatique
```dart
// Stocké: "77123456" ou "25377123456"
// Affiché: "+253 77 12 34 56"
final formatted = authProvider.formattedPhoneNumber;
```

## 🎯 Résultat Final

✅ **Authentification centralisée** dans un seul provider
✅ **Code simplifié** dans tous les screens
✅ **Réactivité automatique** avec watch/read
✅ **Lifecycle géré** dans MyApp
✅ **Persistence** via UserSession
✅ **Base solide** pour migration progressive

---

**Date de création** : 2025-12-07
**Provider créé** : AuthProvider (380+ lignes)
**Intégrations** : MyApp lifecycle, UserSession, OtpService, LogoutService, FCMTokenService
**Prochaine étape** : Migrer LoginScreen et OTPScreen
