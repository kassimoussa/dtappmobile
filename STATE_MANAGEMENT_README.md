# État de la Migration vers Provider - DT Mobile App

## 🎯 Objectif

Centraliser la gestion de l'état de l'application avec **Provider** pour améliorer :
- ✅ La performance (moins d'appels API redondants)
- ✅ La synchronisation (données cohérentes entre tous les écrans)
- ✅ La maintenabilité (code plus simple et réutilisable)
- ✅ L'expérience utilisateur (cache intelligent, mises à jour automatiques)

---

## 📊 État Actuel

### ✅ Ce qui a été fait

#### 1. Providers Créés (3)

| Provider | Fichier | Fonction | Cache |
|----------|---------|----------|-------|
| **UserSessionProvider** | `lib/providers/user_session_provider.dart` | Gestion session & authentification | N/A |
| **BalanceProvider** | `lib/providers/balance_provider.dart` | Gestion du solde utilisateur | 10 min |
| **ForfaitProvider** | `lib/providers/forfait_provider.dart` | Gestion des forfaits actifs | 5 min |

#### 2. Configuration Main.dart ✅

Le fichier `lib/main.dart` a été configuré avec `MultiProvider` :

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserSessionProvider()),
    ChangeNotifierProvider(create: (_) => BalanceProvider()),
    ChangeNotifierProvider(create: (_) => ForfaitProvider()),
  ],
  child: MaterialApp(...),
)
```

**Status:** ✅ Opérationnel

#### 3. Exemples de Migration Créés

| Écran | Fichier | Description |
|-------|---------|-------------|
| **HomeScreen** | `lib/screens/home_screen_with_provider.dart` | Exemple complet d'utilisation des 3 providers |
| **OTPScreen** | `lib/screens/otp_screen_with_provider.dart` | Exemple d'authentification avec UserSessionProvider |

**Status:** ✅ Prêts à utiliser comme référence

#### 4. Documentation Complète ✅

- **`PROVIDER_MIGRATION_GUIDE.md`** - Guide complet de migration (60+ pages)
  - Explications conceptuelles
  - Comparaisons avant/après
  - Exemples pratiques
  - Bonnes pratiques
  - FAQ détaillée

**Status:** ✅ Documentation exhaustive disponible

---

### 🔄 Ce qui reste à faire

#### Écrans à Migrer (Progressivement)

**Priorité Haute (Écrans principaux) :**
1. `lib/screens/home_screen.dart` → Remplacer par la version avec provider
2. `lib/screens/otp_screen.dart` → Remplacer par la version avec provider
3. `lib/screens/main_screen.dart` → Initialiser les providers au démarrage
4. `lib/screens/profile_screen.dart` → Utiliser UserSessionProvider et BalanceProvider

**Priorité Moyenne (Écrans de transactions) :**
5. `lib/screens/forfaits_actifs/forfaits_actifs_screen.dart` → Utiliser ForfaitProvider
6. `lib/screens/forfaits_actifs/forfait_detail_screen.dart` → Utiliser ForfaitProvider
7. `lib/screens/achat_forfait/*.dart` → Invalider cache après achat
8. `lib/screens/transfer_credit/*.dart` → Invalider cache après transfert
9. `lib/screens/refill/*.dart` → Invalider cache après rechargement

**Priorité Basse (Écrans secondaires) :**
10. `lib/screens/history_screen.dart` → Peut utiliser un futur ActivityProvider
11. `lib/screens/topup/*.dart` → Peut utiliser un futur TopUpProvider

**Note:** La migration peut se faire progressivement. Les anciens écrans continueront de fonctionner pendant la transition.

---

## 🚀 Comment Utiliser les Providers Maintenant

### Exemple 1 : Afficher le Solde

```dart
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        // Charger si pas encore chargé
        if (!balanceProvider.hasData && !balanceProvider.isLoading) {
          Future.microtask(() => balanceProvider.fetchBalance());
        }

        // Afficher chargement
        if (balanceProvider.isLoading) {
          return CircularProgressIndicator();
        }

        // Afficher erreur
        if (balanceProvider.error != null) {
          return Text('Erreur: ${balanceProvider.error}');
        }

        // Afficher solde
        return Text('Solde: ${balanceProvider.formattedBalance}');
      },
    );
  }
}
```

### Exemple 2 : Vérifier l'Authentification

```dart
import 'package:provider/provider.dart';
import '../providers/user_session_provider.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<UserSessionProvider>(context);

    if (!sessionProvider.isAuthenticated) {
      return LoginScreen(); // Rediriger si pas authentifié
    }

    return Text('Bienvenue ${sessionProvider.phoneNumber}');
  }
}
```

### Exemple 3 : Rafraîchir Après Achat Forfait

```dart
Future<void> _purchaseForfait(BuildContext context) async {
  try {
    // Acheter le forfait
    await ForfaitService.purchase(selectedForfait);

    // Invalider les caches
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final forfaitProvider = Provider.of<ForfaitProvider>(context, listen: false);

    balanceProvider.invalidateCache();
    forfaitProvider.invalidateCache();

    // Recharger (optionnel, les écrans le feront automatiquement)
    await Future.wait([
      balanceProvider.refresh(),
      forfaitProvider.refresh(),
    ]);

    // Afficher succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Forfait acheté avec succès !')),
    );

    // Tous les écrans se mettent à jour automatiquement !
    Navigator.pop(context);
  } catch (e) {
    // Gérer erreur
  }
}
```

---

## 📁 Structure des Fichiers

```
lib/
├── providers/                              # ✅ NOUVEAU
│   ├── user_session_provider.dart         # Session & auth
│   ├── balance_provider.dart              # Solde
│   └── forfait_provider.dart              # Forfaits
│
├── screens/
│   ├── home_screen_with_provider.dart     # ✅ EXEMPLE
│   ├── otp_screen_with_provider.dart      # ✅ EXEMPLE
│   ├── home_screen.dart                   # ⏳ À migrer
│   ├── otp_screen.dart                    # ⏳ À migrer
│   └── ...autres écrans                   # ⏳ À migrer
│
├── services/                               # ✅ Gardé (utilisé par providers)
│   ├── user_session.dart
│   ├── balance_service.dart
│   ├── forfait_actif_service.dart
│   └── ...
│
├── main.dart                               # ✅ MODIFIÉ (MultiProvider)
│
└── documentation/
    ├── PROVIDER_MIGRATION_GUIDE.md         # ✅ Guide complet
    └── STATE_MANAGEMENT_README.md          # ✅ Ce fichier
```

---

## 🎓 Ressources d'Apprentissage

### Documentation Interne
1. **`PROVIDER_MIGRATION_GUIDE.md`** - Guide complet (LIRE EN PREMIER)
2. **`lib/providers/user_session_provider.dart`** - Code commenté du provider de session
3. **`lib/providers/balance_provider.dart`** - Code commenté du provider de solde
4. **`lib/screens/home_screen_with_provider.dart`** - Exemple concret complet
5. **`lib/screens/otp_screen_with_provider.dart`** - Exemple d'authentification

### Documentation Externe
- [Provider Package - pub.dev](https://pub.dev/packages/provider)
- [Flutter State Management - Provider](https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple)

---

## 🔍 Comment Vérifier que ça Fonctionne

### 1. Logs dans la Console

Les providers loguent automatiquement leurs actions :

```
✅ Session restaurée pour: +253 77123456
💰 Récupération du solde depuis l'API...
✅ Solde récupéré: 1000 DJF
📦 Récupération des forfaits depuis l'API...
✅ 3 forfait(s) récupéré(s)
💰 Utilisation du cache pour le solde (valide pendant 8 min)
```

### 2. Test du Cache

Naviguez entre plusieurs écrans affichant le solde :
- **1er écran** → Appel API (log: "Récupération du solde depuis l'API...")
- **2ème écran** → Cache utilisé (log: "Utilisation du cache pour le solde...")
- **Après 10 min** → Nouveau appel API automatique

### 3. Test de Synchronisation

1. Ouvrez HomeScreen (affiche le solde)
2. Ouvrez ProfileScreen (affiche aussi le solde)
3. Dans ProfileScreen, achetez un forfait
4. Appelez `balanceProvider.invalidateCache()` après achat
5. Les DEUX écrans se mettent à jour automatiquement !

---

## ⚙️ Configuration

### Durées de Cache (Modifiables)

Dans les providers, vous pouvez ajuster les durées :

```dart
// balance_provider.dart
static const Duration _cacheDuration = Duration(minutes: 10); // Modifiable

// forfait_provider.dart
static const Duration _cacheDuration = Duration(minutes: 5);  // Modifiable
```

### Désactiver le Cache

Pour désactiver temporairement le cache :

```dart
// Force toujours un refresh
await balanceProvider.fetchBalance(forceRefresh: true);

// Ou invalider le cache avant
balanceProvider.invalidateCache();
await balanceProvider.fetchBalance();
```

---

## 🐛 Debugging

### Problème : "Could not find a provider"

**Erreur :**
```
Could not find the correct Provider<BalanceProvider> above this Widget
```

**Solution :**
Assurez-vous que `MultiProvider` est bien dans `main.dart` et enveloppe `MaterialApp`.

---

### Problème : "setState() or markNeedsBuild() called during build"

**Erreur :**
```
setState() called during build
```

**Solution :**
Ne pas utiliser `Provider.of()` dans `initState()` sans `listen: false` :

```dart
// ❌ INCORRECT
@override
void initState() {
  super.initState();
  final provider = Provider.of<BalanceProvider>(context); // Erreur !
}

// ✅ CORRECT
@override
void initState() {
  super.initState();
  final provider = Provider.of<BalanceProvider>(context, listen: false);
  // OU
  Future.microtask(() {
    final provider = Provider.of<BalanceProvider>(context, listen: false);
    provider.fetchBalance();
  });
}
```

---

### Problème : Les données ne se mettent pas à jour

**Solution :**
Vérifiez que vous utilisez `Consumer` ou `Provider.of()` avec `listen: true` (par défaut) :

```dart
// ❌ N'écoute PAS les changements
final provider = Provider.of<BalanceProvider>(context, listen: false);
return Text(provider.formattedBalance); // Ne se met pas à jour

// ✅ Écoute les changements
final provider = Provider.of<BalanceProvider>(context); // listen: true par défaut
return Text(provider.formattedBalance); // Se met à jour automatiquement
```

---

## 📈 Prochaines Étapes

### Phase 1 : Migration des Écrans Principaux (PRIORITAIRE)
- [ ] Remplacer `home_screen.dart` par `home_screen_with_provider.dart`
- [ ] Remplacer `otp_screen.dart` par `otp_screen_with_provider.dart`
- [ ] Migrer `profile_screen.dart`
- [ ] Tester le flux complet : Login → OTP → Home → Profile

### Phase 2 : Migration des Écrans de Transactions
- [ ] Migrer écrans forfaits
- [ ] Migrer écrans transfert
- [ ] Migrer écrans refill
- [ ] Ajouter invalidation de cache après chaque transaction

### Phase 3 : Providers Additionnels (Optionnel)
- [ ] Créer `ActivityProvider` pour l'historique
- [ ] Créer `TopUpProvider` pour TopUp
- [ ] Créer `AgencyProvider` pour les agences

### Phase 4 : Optimisations
- [ ] Ajouter persistence du cache (SQLite)
- [ ] Ajouter support offline
- [ ] Ajouter analytics sur l'utilisation du cache

---

## 🤝 Contribution

Pour migrer un nouvel écran :

1. Lire `PROVIDER_MIGRATION_GUIDE.md`
2. Étudier les exemples (`home_screen_with_provider.dart`, `otp_screen_with_provider.dart`)
3. Identifier les appels directs aux services
4. Remplacer par des appels aux providers
5. Tester le chargement, les erreurs, et le cache
6. Documenter les changements

---

## 📞 Support

Pour toute question :
- Consulter `PROVIDER_MIGRATION_GUIDE.md` (FAQ détaillée)
- Examiner les exemples dans `lib/screens/*_with_provider.dart`
- Lire les commentaires dans les providers (`lib/providers/*.dart`)

---

## 📝 Changelog

### 2025-01-XX - Mise en Place Initiale

**Ajouts :**
- ✅ 3 providers créés (UserSession, Balance, Forfait)
- ✅ Configuration MultiProvider dans main.dart
- ✅ 2 exemples d'écrans migrés
- ✅ Documentation complète (60+ pages)
- ✅ Cache intelligent (10 min balance, 5 min forfaits)
- ✅ Synchronisation automatique entre écrans
- ✅ Gestion d'erreurs centralisée
- ✅ Logs de debugging

**Status :** Infrastructure complète, migration progressive en cours

---

**Dernière mise à jour :** 2025-01-XX
**Auteur :** Migration vers Provider - DT Mobile Team
**Version :** 1.0.0
