# Guide de Migration vers Provider - DT Mobile App

## 📚 Table des Matières

1. [Introduction](#introduction)
2. [Qu'est-ce que le State Management Centralisé ?](#quest-ce-que-le-state-management-centralisé)
3. [Providers Disponibles](#providers-disponibles)
4. [Comment Utiliser les Providers](#comment-utiliser-les-providers)
5. [Exemples de Migration](#exemples-de-migration)
6. [Bonnes Pratiques](#bonnes-pratiques)
7. [FAQ](#faq)

---

## Introduction

Ce guide explique comment migrer les écrans existants pour utiliser **Provider** au lieu d'appels directs aux services. Cela centralise la gestion de l'état et améliore la performance de l'application.

### Avantages du Provider

✅ **Une seule source de vérité** - L'état est centralisé
✅ **Synchronisation automatique** - Tous les écrans se mettent à jour ensemble
✅ **Cache intelligent** - Réduit les appels API redondants
✅ **Code plus simple** - Moins de StatefulWidget et setState()
✅ **Meilleure performance** - Reconstructions ciblées avec Consumer

---

## Qu'est-ce que le State Management Centralisé ?

### ❌ Avant (Sans Provider)

Chaque écran charge ses propres données :

```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? balance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => isLoading = true);
    balance = await BalanceService.getBalance(); // ❌ Appel API direct
    setState(() => isLoading = false);
  }
}

// ProfileScreen fait la MÊME chose -> 2 appels API !
```

**Problèmes :**
- 🔴 Duplication des appels API
- 🔴 État non synchronisé entre écrans
- 🔴 Logique répétée partout
- 🔴 Pas de cache partagé

### ✅ Après (Avec Provider)

Un provider centralisé gère les données pour TOUS les écrans :

```dart
// Écran 1: HomeScreen
class HomeScreen extends StatelessWidget { // Plus besoin de StatefulWidget !
  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<BalanceProvider>(context);

    return Text('Solde: ${balanceProvider.formattedBalance}');
  }
}

// Écran 2: ProfileScreen
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<BalanceProvider>(context);

    return Text('Solde: ${balanceProvider.formattedBalance}'); // MÊME donnée, ZÉRO appel API !
  }
}
```

**Avantages :**
- ✅ UN seul appel API
- ✅ Synchronisation automatique
- ✅ Cache partagé
- ✅ Code simplifié

---

## Providers Disponibles

### 1. `UserSessionProvider`

**Gère :** Authentification et session utilisateur

**État disponible :**
```dart
class UserSessionProvider {
  String? phoneNumber;          // Numéro de téléphone
  String? sessionToken;         // Token de session
  bool isAuthenticated;         // Est authentifié ?
  bool isLoading;              // Chargement en cours ?
  String? error;               // Erreur éventuelle
  DateTime? lastActivityTime;  // Dernière activité
}
```

**Méthodes principales :**
```dart
await sessionProvider.initSession();              // Initialiser
await sessionProvider.login(phone, otp);         // Se connecter
await sessionProvider.logout();                  // Se déconnecter
await sessionProvider.updateActivity();          // Mettre à jour activité
await sessionProvider.handleAppResumed();        // App au premier plan
await sessionProvider.handleAppPaused();         // App en arrière-plan
```

---

### 2. `BalanceProvider`

**Gère :** Solde utilisateur avec cache intelligent

**État disponible :**
```dart
class BalanceProvider {
  Map<String, dynamic>? balanceData;  // Données brutes du solde
  bool isLoading;                     // Chargement en cours ?
  String? error;                      // Erreur éventuelle
  DateTime? lastFetch;                // Dernière récupération

  // Getters pratiques
  String mainBalance;                 // Solde principal
  String currency;                    // Devise (DJF)
  String formattedBalance;            // "1000 DJF"
  bool isCacheValid;                  // Cache valide ? (< 10 min)
}
```

**Méthodes principales :**
```dart
await balanceProvider.fetchBalance();            // Charger (utilise cache si valide)
await balanceProvider.refresh();                 // Forcer rechargement
balanceProvider.invalidateCache();               // Invalider cache
balanceProvider.clear();                         // Effacer tout
```

**Cache automatique :** 10 minutes
**Utilisation :** Après achat forfait, invalider le cache avec `invalidateCache()`

---

### 3. `ForfaitProvider`

**Gère :** Forfaits actifs avec cache et filtres

**État disponible :**
```dart
class ForfaitProvider {
  List<ForfaitActif2> forfaitsActifs; // Liste des forfaits
  bool isLoading;                     // Chargement en cours ?
  String? error;                      // Erreur éventuelle
  DateTime? lastFetch;                // Dernière récupération

  // Getters pratiques
  bool hasData;                       // A des données ?
  int count;                          // Nombre de forfaits
  bool isCacheValid;                  // Cache valide ? (< 5 min)
}
```

**Méthodes principales :**
```dart
await forfaitProvider.fetchForfaits();           // Charger (utilise cache si valide)
await forfaitProvider.refresh();                 // Forcer rechargement
ForfaitActif2? forfait = forfaitProvider.getForfaitById(id);
List<ForfaitActif2> actifs = forfaitProvider.getActiveForfaits();
List<ForfaitActif2> data = forfaitProvider.getDataForfaits();
List<ForfaitActif2> voice = forfaitProvider.getVoiceForfaits();
forfaitProvider.invalidateCache();               // Invalider cache
```

**Cache automatique :** 5 minutes
**Utilisation :** Après achat forfait, invalider le cache et recharger

---

## Comment Utiliser les Providers

### Méthode 1 : `Provider.of<T>()` (Simple)

**Quand utiliser :** Écrans simples, accès unique

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Accéder au provider
    final balanceProvider = Provider.of<BalanceProvider>(context);

    // Utiliser les données
    return Text('Solde: ${balanceProvider.formattedBalance}');
  }
}
```

**⚠️ Important :** Reconstruit TOUT le widget quand le provider change

---

### Méthode 2 : `Consumer<T>()` (Optimisé)

**Quand utiliser :** Écrans complexes, reconstructions ciblées

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Titre statique'), // Ne se reconstruit PAS

        // Seulement ce Consumer se reconstruit
        Consumer<BalanceProvider>(
          builder: (context, balanceProvider, child) {
            if (balanceProvider.isLoading) {
              return CircularProgressIndicator();
            }

            if (balanceProvider.error != null) {
              return Text('Erreur: ${balanceProvider.error}');
            }

            return Text('Solde: ${balanceProvider.formattedBalance}');
          },
        ),
      ],
    );
  }
}
```

**✅ Avantage :** Meilleure performance, reconstructions ciblées

---

### Méthode 3 : `listen: false` (Actions uniquement)

**Quand utiliser :** Appeler des méthodes sans écouter les changements

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // NE PAS écouter les changements, juste appeler une méthode
        final balanceProvider = Provider.of<BalanceProvider>(
          context,
          listen: false, // ← Important !
        );
        balanceProvider.refresh(); // Rafraîchir
      },
      child: Text('Rafraîchir'),
    );
  }
}
```

**⚠️ Important :** Dans `initState()`, toujours utiliser `listen: false`

```dart
@override
void initState() {
  super.initState();

  // ✅ CORRECT
  final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
  balanceProvider.fetchBalance();

  // ❌ INCORRECT (provoque une erreur)
  final badProvider = Provider.of<BalanceProvider>(context);
  badProvider.fetchBalance();
}
```

---

## Exemples de Migration

### Exemple 1 : Migrer un écran simple

**Avant (Sans Provider) :**

```dart
class BalanceScreen extends StatefulWidget {
  @override
  _BalanceScreenState createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  String? balance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => isLoading = true);

    try {
      final data = await BalanceService.getCurrentBalance();
      setState(() {
        balance = data['solde'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CircularProgressIndicator();
    }

    return Text('Solde: $balance DJF');
  }
}
```

**Après (Avec Provider) :**

```dart
class BalanceScreen extends StatelessWidget { // ← Plus besoin de StatefulWidget !
  @override
  Widget build(BuildContext context) {
    return Consumer<BalanceProvider>(
      builder: (context, balanceProvider, child) {
        // Charger au premier affichage
        if (!balanceProvider.hasData && !balanceProvider.isLoading) {
          Future.microtask(() => balanceProvider.fetchBalance());
        }

        // Gestion du chargement
        if (balanceProvider.isLoading) {
          return CircularProgressIndicator();
        }

        // Gestion des erreurs
        if (balanceProvider.error != null) {
          return Text('Erreur: ${balanceProvider.error}');
        }

        // Affichage
        return Text('Solde: ${balanceProvider.formattedBalance}');
      },
    );
  }
}
```

**Changements :**
- ✅ StatefulWidget → StatelessWidget
- ✅ Plus de setState()
- ✅ Utilise Consumer pour écouter les changements
- ✅ Gestion automatique du cache

---

### Exemple 2 : Rafraîchir les données après une action

**Scénario :** Après achat d'un forfait, mettre à jour le solde et les forfaits

```dart
class ForfaitPurchaseScreen extends StatelessWidget {
  Future<void> _purchaseForfait(BuildContext context, Forfait forfait) async {
    try {
      // Acheter le forfait
      await ForfaitService.purchase(forfait);

      // Invalider les caches et recharger
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      final forfaitProvider = Provider.of<ForfaitProvider>(context, listen: false);

      // Méthode 1: Invalider et laisser les écrans recharger
      balanceProvider.invalidateCache();
      forfaitProvider.invalidateCache();

      // Méthode 2: Forcer le rechargement immédiat
      await Future.wait([
        balanceProvider.refresh(),
        forfaitProvider.refresh(),
      ]);

      // Tous les écrans affichant le solde/forfaits se mettent à jour automatiquement !

      // Afficher message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Forfait acheté avec succès !')),
      );

      Navigator.pop(context);
    } catch (e) {
      // Gérer l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _purchaseForfait(context, selectedForfait),
      child: Text('Acheter'),
    );
  }
}
```

---

### Exemple 3 : Écran avec plusieurs providers

```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<UserSessionProvider>(
          builder: (context, sessionProvider, child) {
            return Text(sessionProvider.phoneNumber ?? '');
          },
        ),
      ),
      body: Column(
        children: [
          // Section Solde
          Consumer<BalanceProvider>(
            builder: (context, balanceProvider, child) {
              return Text('Solde: ${balanceProvider.formattedBalance}');
            },
          ),

          // Section Forfaits
          Consumer<ForfaitProvider>(
            builder: (context, forfaitProvider, child) {
              return Text('${forfaitProvider.count} forfait(s) actif(s)');
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Bonnes Pratiques

### ✅ À FAIRE

1. **Utiliser `listen: false` dans `initState()`**
   ```dart
   @override
   void initState() {
     super.initState();
     final provider = Provider.of<BalanceProvider>(context, listen: false);
     provider.fetchBalance();
   }
   ```

2. **Utiliser Consumer pour les reconstructions ciblées**
   ```dart
   Consumer<BalanceProvider>(
     builder: (context, provider, child) {
       return Text(provider.formattedBalance);
     },
   )
   ```

3. **Invalider le cache après mutations**
   ```dart
   // Après achat, transfert, etc.
   balanceProvider.invalidateCache();
   forfaitProvider.invalidateCache();
   ```

4. **Vérifier l'état avant d'afficher**
   ```dart
   if (provider.isLoading) return CircularProgressIndicator();
   if (provider.error != null) return ErrorWidget();
   return SuccessWidget();
   ```

5. **Charger les données au démarrage**
   ```dart
   @override
   void initState() {
     super.initState();
     Future.microtask(() {
       final provider = Provider.of<BalanceProvider>(context, listen: false);
       provider.fetchBalance();
     });
   }
   ```

---

### ❌ À ÉVITER

1. **Ne PAS utiliser Provider.of() sans listen: false dans initState()**
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
   }
   ```

2. **Ne PAS faire d'appels API directs dans les écrans**
   ```dart
   // ❌ INCORRECT
   final balance = await BalanceService.getCurrentBalance();

   // ✅ CORRECT
   await balanceProvider.fetchBalance();
   ```

3. **Ne PAS oublier de gérer le loading et les erreurs**
   ```dart
   // ❌ INCORRECT
   return Text(provider.formattedBalance); // Et si loading ou erreur ?

   // ✅ CORRECT
   if (provider.isLoading) return CircularProgressIndicator();
   if (provider.error != null) return Text('Erreur');
   return Text(provider.formattedBalance);
   ```

4. **Ne PAS appeler notifyListeners() depuis l'extérieur**
   ```dart
   // ❌ INCORRECT
   balanceProvider.notifyListeners(); // Seulement dans le provider !

   // ✅ CORRECT
   balanceProvider.refresh(); // Utiliser les méthodes du provider
   ```

---

## FAQ

### Q: Quand utiliser `Provider.of()` vs `Consumer()` ?

**R:**
- `Provider.of()` : Écrans simples, accès unique
- `Consumer()` : Écrans complexes, reconstructions ciblées (meilleure performance)

---

### Q: Comment savoir si le cache est valide ?

**R:**
```dart
final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
if (balanceProvider.isCacheValid) {
  print('Cache valide !');
} else {
  print('Cache expiré, va recharger');
}
```

---

### Q: Comment forcer un rechargement ?

**R:**
```dart
// Méthode 1: Forcer un refresh
await balanceProvider.refresh();

// Méthode 2: Invalider le cache puis charger
balanceProvider.invalidateCache();
await balanceProvider.fetchBalance();
```

---

### Q: Que faire après un achat de forfait ?

**R:**
```dart
// Après achat réussi
await ForfaitService.purchase(forfait);

// Invalider les caches
balanceProvider.invalidateCache();
forfaitProvider.invalidateCache();

// Recharger les données
await Future.wait([
  balanceProvider.refresh(),
  forfaitProvider.refresh(),
]);

// Tous les écrans se mettent à jour automatiquement !
```

---

### Q: Comment débugger les providers ?

**R:**
Les providers loguent automatiquement dans la console :
```
💰 Récupération du solde depuis l'API...
✅ Solde récupéré: 1000 DJF
📦 Récupération des forfaits depuis l'API...
✅ 3 forfait(s) récupéré(s)
💰 Utilisation du cache pour le solde (valide pendant 8 min)
```

---

### Q: Puis-je utiliser les anciens services en même temps ?

**R:** Oui ! Les providers utilisent les services existants en interne. Vous pouvez migrer progressivement :

1. HomeScreen → Provider ✅
2. ProfileScreen → Provider ✅
3. ForfaitScreen → Service ancien (temporaire) ⏳
4. etc.

---

## Fichiers d'Exemple

- **`lib/providers/user_session_provider.dart`** - Provider de session
- **`lib/providers/balance_provider.dart`** - Provider de solde
- **`lib/providers/forfait_provider.dart`** - Provider de forfaits
- **`lib/screens/home_screen_with_provider.dart`** - Exemple complet de HomeScreen migré
- **`lib/screens/otp_screen_with_provider.dart`** - Exemple OTP migré

---

## Support

Pour toute question sur la migration, consultez :
- Ce guide
- Les fichiers d'exemple
- Le code source des providers
- CLAUDE.md (documentation générale du projet)

---

**Bonne migration ! 🚀**
