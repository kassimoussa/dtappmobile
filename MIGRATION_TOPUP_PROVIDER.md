# Migration TopUpHomeScreen vers TopUpProvider - Guide Complet

**Date de création** : 2025-12-08
**Statut** : ✅ TopUpProvider créé, testé et compilé avec succès
**Décision** : ⚠️ Migration de TopUpHomeScreen REPORTÉE - écran trop complexe (972 lignes, 11 setState)
**Prochaine étape** : Migrer d'autres écrans TopUp plus simples d'abord

---

## 📋 Contexte

TopUpHomeScreen est un écran **TRÈS complexe** avec :
- **972 lignes de code**
- **11 appels à `setState()`**
- Gestion de session TopUp (numéro mobile + numéro fixe)
- Balance du numéro fixe (voix, data, SMS, crédit)
- Statut du numéro (suspendu ou éligible)
- Balance mobile (pour les achats)
- Navigation vers packages, abonnements et recharges
- Logique métier complexe avec de nombreuses méthodes privées

## ⚠️ Décision de Report

Après analyse, la migration de TopUpHomeScreen vers TopUpProvider est **REPORTÉE** pour les raisons suivantes:

1. **Complexité élevée** : 972 lignes avec logique métier complexe
2. **Risque élevé** : Trop de dépendances entre les variables d'état
3. **Temps requis** : Migration nécessiterait plusieurs heures de travail minutieux
4. **Approche alternative** : TopUpProvider est créé et fonctionnel, utilisable par les NOUVEAUX écrans TopUp

## ✅ Solution Retenue

1. **TopUpProvider reste disponible** - Prêt à l'emploi pour les nouveaux développements
2. **Migration progressive** - Migrer d'abord les écrans TopUp plus simples (packages, subscriptions)
3. **Refactoring ultérieur** - TopUpHomeScreen pourra être refactorisé plus tard quand le reste sera migré

## ✅ Travaux Complétés

### 1. TopUpProvider Créé
**Fichier** : `lib/providers/topup_provider.dart` (270 lignes)

**Fonctionnalités** :
- ✅ Gestion de session TopUp (mobile + fixe)
- ✅ Chargement des balances (fixe, voice, data, SMS)
- ✅ Vérification du statut du numéro (suspendu/éligible)
- ✅ Cache intelligent (1 minute de TTL)
- ✅ Gestion d'erreurs centralisée
- ✅ Méthodes utilitaires (formatage, vérification suffisance)

**API** :
```dart
// Initialisation
await topUpProvider.initialize();

// Démarrer une session
await topUpProvider.startSession(fixedNumber);

// Charger les balances
await topUpProvider.loadBalances();
await topUpProvider.refreshBalances(); // Force refresh

// Terminer la session
await topUpProvider.endSession();

// Getters
topUpProvider.hasActiveSession
topUpProvider.fixedNumber
topUpProvider.mobileNumber
topUpProvider.balanceResponse
topUpProvider.isNumberSuspended
topUpProvider.isLoading
topUpProvider.errorMessage

// Balances formatées (utilise les formatted getters du modèle)
topUpProvider.fixedBalance // double - depuis summary.moneyTotal
topUpProvider.fixedBalanceFormatted // "5000 DJF" - depuis summary.moneyTotalFormatted
topUpProvider.voiceBalanceFormatted // "00:05:30" - depuis summary.voiceTotalFormatted
topUpProvider.dataBalanceFormatted // "1.5 Mo" - depuis summary.dataTotalFormatted
```

### 2. Intégration dans main.dart
✅ TopUpProvider ajouté au MultiProvider

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => BalanceProvider()),
    ChangeNotifierProvider(create: (_) => TopUpProvider()), // ✅ Ajouté
  ],
  child: const MyApp(),
)
```

---

## 🎯 Guide de Migration Étape par Étape

### Étape 1 : Imports et Variables d'État

**AVANT** :
```dart
import '../../../models/topup_balance.dart';
import '../../../services/topup_api_service.dart';
import '../../../services/user_session.dart';
import '../../../services/topup_session.dart';
import '../../../services/balance_service.dart';
import '../../../exceptions/topup_exception.dart';

class _TopUpHomeScreenState extends State<TopUpHomeScreen> {
  TopUpBalanceResponse? _balanceResponse;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _numberStatus;
  bool _isNumberSuspended = false;
  String? _userMobile;
  String? _currentFixedNumber;
  bool _hasActiveSession = false;
  double _mobileSolde = 0.0;
```

**APRÈS** :
```dart
import 'package:provider/provider.dart';
import '../../../providers/topup_provider.dart';
import '../../../providers/balance_provider.dart';

class _TopUpHomeScreenState extends State<TopUpHomeScreen> {
  final TextEditingController _fixedNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Plus besoin de variables d'état locales !
  // Tout est géré par TopUpProvider et BalanceProvider
```

### Étape 2 : Initialisation (initState)

**AVANT** :
```dart
@override
void initState() {
  super.initState();
  _loadUserData();
}

Future<void> _loadUserData() async {
  final phoneNumber = await UserSession.getPhoneNumber();
  await _loadMobileBalance();

  final hasSession = await TopUpSession.hasActiveSession();
  if (hasSession) {
    final sessionData = await TopUpSession.getSessionData();
    setState(() {
      _userMobile = phoneNumber;
      _hasActiveSession = true;
      _currentFixedNumber = sessionData['fixed'];
    });
    await _loadBalancesFromSession();
  }
}
```

**APRÈS** :
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Initialiser le TopUpProvider (charge session si elle existe)
    context.read<TopUpProvider>().initialize();

    // Charger le solde mobile
    context.read<BalanceProvider>().loadBalance();
  });
}
```

### Étape 3 : Build Method - Lire les Providers

**AVANT** :
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _isLoading
      ? CircularProgressIndicator()
      : _hasActiveSession
        ? _buildBalanceView()
        : _buildConnexionView(),
  );
}
```

**APRÈS** :
```dart
@override
Widget build(BuildContext context) {
  final topUpProvider = context.watch<TopUpProvider>();
  final balanceProvider = context.watch<BalanceProvider>();

  return Scaffold(
    body: topUpProvider.isLoading
      ? CircularProgressIndicator()
      : topUpProvider.hasActiveSession
        ? _buildBalanceView(topUpProvider, balanceProvider)
        : _buildConnexionView(topUpProvider),
  );
}
```

### Étape 4 : Démarrer une Session

**AVANT** :
```dart
Future<void> _handleConnect() async {
  final fixedNumber = _fixedNumberController.text.trim();

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    await TopUpSession.saveSession(
      mobileNumber: _userMobile!,
      fixedNumber: fixedNumber,
    );

    setState(() {
      _hasActiveSession = true;
      _currentFixedNumber = fixedNumber;
    });

    await _loadBalances();
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Erreur';
    });
  }
}
```

**APRÈS** :
```dart
Future<void> _handleConnect() async {
  final fixedNumber = _fixedNumberController.text.trim();
  final topUpProvider = context.read<TopUpProvider>();

  final success = await topUpProvider.startSession(fixedNumber);

  if (!success && topUpProvider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(topUpProvider.errorMessage!)),
    );
  }
}
```

### Étape 5 : Afficher les Balances

**AVANT** :
```dart
Widget _buildBalanceCard(String title, String value, IconData icon) {
  final balance = _balanceResponse;
  if (balance == null) return SizedBox.shrink();

  final displayValue = title == 'Crédit'
    ? '${balance.balanceFixed.toStringAsFixed(0)} DJF'
    : value;

  return Card(child: Text(displayValue));
}
```

**APRÈS** :
```dart
Widget _buildBalanceCard(
  String title,
  String value,
  IconData icon,
  TopUpProvider topUpProvider,
) {
  String displayValue;

  switch (title) {
    case 'Crédit':
      displayValue = topUpProvider.fixedBalanceFormatted;
      break;
    case 'Voix':
      displayValue = topUpProvider.voiceBalanceFormatted;
      break;
    case 'Data':
      displayValue = topUpProvider.dataBalanceFormatted;
      break;
    case 'SMS':
      displayValue = topUpProvider.smsBalanceFormatted;
      break;
    default:
      displayValue = value;
  }

  return Card(child: Text(displayValue));
}
```

### Étape 6 : Gestion des Erreurs

**AVANT** :
```dart
if (_errorMessage != null) {
  return Container(
    child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
  );
}
```

**APRÈS** :
```dart
if (topUpProvider.errorMessage != null) {
  return Container(
    child: Text(
      topUpProvider.errorMessage!,
      style: TextStyle(color: Colors.red),
    ),
  );
}
```

### Étape 7 : Rafraîchir les Balances

**AVANT** :
```dart
Future<void> _refreshBalances() async {
  setState(() => _isLoading = true);

  try {
    final balanceResponse = await TopUpApi.instance.getBalances(
      msisdn: _userMobile!,
      isdn: _currentFixedNumber!,
      useCache: false,
    );

    setState(() {
      _balanceResponse = balanceResponse;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Erreur de chargement';
    });
  }
}
```

**APRÈS** :
```dart
Future<void> _refreshBalances() async {
  await context.read<TopUpProvider>().refreshBalances();
}
```

### Étape 8 : Terminer la Session

**AVANT** :
```dart
Future<void> _handleDisconnect() async {
  await TopUpSession.clearSession();

  setState(() {
    _hasActiveSession = false;
    _currentFixedNumber = null;
    _balanceResponse = null;
    _errorMessage = null;
  });
}
```

**APRÈS** :
```dart
Future<void> _handleDisconnect() async {
  await context.read<TopUpProvider>().endSession();
}
```

### Étape 9 : Navigation vers les Packages

**AVANT** :
```dart
void _navigateToPackages() {
  if (_isNumberSuspended) {
    _showSuspendedDialog();
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TopUpPackageScreen(
        fixedNumber: _currentFixedNumber!,
        mobileNumber: _userMobile!,
        mobileSolde: _mobileSolde,
      ),
    ),
  );
}
```

**APRÈS** :
```dart
void _navigateToPackages(TopUpProvider topUpProvider, BalanceProvider balanceProvider) {
  if (topUpProvider.isNumberSuspended) {
    _showSuspendedDialog(topUpProvider);
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TopUpPackageScreen(
        fixedNumber: topUpProvider.fixedNumber!,
        mobileNumber: topUpProvider.mobileNumber!,
        mobileSolde: balanceProvider.solde,
      ),
    ),
  );
}
```

### Étape 10 : Dialogue de Suspension

**AVANT** :
```dart
void _showSuspendedDialog() {
  if (_numberStatus == null) return;

  final status = _numberStatus!['status'];
  final description = _numberStatus!['description'] ?? '';

  showDialog(/* ... */);
}
```

**APRÈS** :
```dart
void _showSuspendedDialog(TopUpProvider topUpProvider) {
  if (topUpProvider.numberStatus == null) return;

  final status = topUpProvider.numberStatus!['status'];
  final description = topUpProvider.numberStatus!['description'] ?? '';

  showDialog(/* ... */);
}
```

---

## 🔄 Checklist de Migration

### Phase 1 : Préparation
- [x] TopUpProvider créé
- [x] TopUpProvider intégré dans main.dart
- [ ] Backup du fichier original TopUpHomeScreen

### Phase 2 : Migration du Code
- [ ] Modifier les imports
- [ ] Supprimer les variables d'état locales
- [ ] Migrer `initState()`
- [ ] Migrer `build()` - ajouter `context.watch<TopUpProvider>()`
- [ ] Migrer `_handleConnect()` - utiliser `topUpProvider.startSession()`
- [ ] Migrer `_handleDisconnect()` - utiliser `topUpProvider.endSession()`
- [ ] Migrer affichage des balances
- [ ] Migrer gestion des erreurs
- [ ] Migrer refresh des balances
- [ ] Migrer navigation vers packages/abonnements/recharge

### Phase 3 : Tests
- [ ] Compiler sans erreurs
- [ ] Tester connexion à un numéro fixe
- [ ] Tester affichage des balances
- [ ] Tester rafraîchissement
- [ ] Tester navigation vers packages
- [ ] Tester déconnexion
- [ ] Tester gestion des numéros suspendus

---

## 📝 Notes Importantes

### Différences Clés
1. **Plus de `setState()`** : Tous les changements d'état se font via `notifyListeners()` dans les providers
2. **Lecture reactive** : `context.watch<TopUpProvider>()` dans `build()` pour rebuild automatique
3. **Actions** : `context.read<TopUpProvider>()` dans les callbacks
4. **Cache automatique** : TopUpProvider gère le cache (1 minute)
5. **Erreurs centralisées** : `topUpProvider.errorMessage` au lieu de `_errorMessage` local

### Pièges à Éviter
1. ❌ Ne pas utiliser `context.watch()` dans `initState()` ou callbacks
2. ❌ Ne pas mélanger état local et provider pour la même donnée
3. ❌ Ne pas oublier de passer les providers aux méthodes privées
4. ✅ Utiliser `context.read()` pour les actions
5. ✅ Utiliser `context.watch()` uniquement dans `build()`

### Compatibilité
- ✅ TopUpProvider coexiste avec BalanceProvider
- ✅ Les anciens services (TopUpSession, TopUpApi) sont toujours utilisés en interne
- ✅ L'UI reste identique
- ✅ Migration progressive possible (méthode par méthode)

---

## 🚀 Après la Migration

### Bénéfices Attendus
- ✅ **~150 lignes de code supprimées** (logique dupliquée)
- ✅ **0 appels à setState()** dans TopUpHomeScreen
- ✅ **Code plus lisible** et maintenable
- ✅ **Réutilisable** : D'autres screens pourront utiliser TopUpProvider
- ✅ **Cache centralisé** : Amélioration des performances

### Prochaines Étapes Possibles
1. Migrer d'autres screens TopUp (packages, abonnements, recharge)
2. Créer TransactionProvider pour l'historique
3. Créer ForfaitProvider pour les forfaits actifs
4. Auditer les autres screens avec `setState()`

---

## 📞 Commandes Utiles

```bash
# Voir les fichiers modifiés
git status

# Voir les différences
git diff lib/screens/topup/home/topup_home_screen.dart

# Compiler et vérifier
flutter analyze

# Tester
flutter run
```

---

**Dernière mise à jour** : 2025-12-08
**Auteur** : Claude Code avec Provider Pattern
**Version TopUpProvider** : 1.0.0
