# Réorganisation de la Structure des Screens

**Date** : 2025-12-08
**Branche** : `feature/state-management-providers`

---

## 🎯 Objectif

Réorganiser les fichiers screens éparpillés à la racine du dossier `lib/screens/` dans des sous-dossiers logiques pour améliorer la maintenabilité et la lisibilité du projet.

---

## 📁 Nouvelle Structure

```
lib/screens/
├── auth/                           # Authentification (3 fichiers)
│   ├── login_screen.dart
│   ├── otp_screen.dart
│   └── splash_screen.dart
│
├── core/                           # Écrans principaux (3 fichiers)
│   ├── main_screen.dart
│   ├── home_screen.dart
│   └── search_screen.dart
│
├── user/                           # Profil et compte (3 fichiers)
│   ├── profile_screen.dart
│   ├── my_line_screen.dart
│   └── history_screen.dart
│
├── statistics/                     # Statistiques (1 fichier)
│   └── statistics_screen.dart
│
├── settings/                       # Paramètres (1 fichier)
│   └── language_selection_screen.dart
│
├── debug/                          # Tests et debug (3 fichiers)
│   ├── debug_activity_screen.dart
│   ├── test_activity_screen.dart
│   └── test_forfait_success_screen.dart
│
└── [Dossiers existants conservés]
    ├── achat_forfait/
    ├── agencies/
    ├── forfaits_actifs/
    ├── refill/
    ├── speedtest/
    ├── topup/
    └── transfer_credit/
```

---

## 📦 Fichiers Déplacés

### 1. auth/ - Authentification (3 fichiers)
- ✅ `login_screen.dart` - Écran de connexion
- ✅ `otp_screen.dart` - Vérification OTP
- ✅ `splash_screen.dart` - Écran de démarrage

**Raison** : Grouper tous les écrans liés à l'authentification

### 2. core/ - Écrans Principaux (3 fichiers)
- ✅ `main_screen.dart` - Container principal avec bottom navigation
- ✅ `home_screen.dart` - Dashboard principal
- ✅ `search_screen.dart` - Recherche globale

**Raison** : Écrans essentiels au fonctionnement de l'app

### 3. user/ - Profil et Compte (3 fichiers)
- ✅ `profile_screen.dart` - Profil utilisateur
- ✅ `my_line_screen.dart` - Informations de la ligne
- ✅ `history_screen.dart` - Historique des transactions

**Raison** : Tout ce qui concerne le compte utilisateur

### 4. statistics/ - Statistiques (1 fichier)
- ✅ `statistics_screen.dart` - Statistiques de consommation

**Raison** : Isoler les fonctionnalités d'analyse

### 5. settings/ - Paramètres (1 fichier)
- ✅ `language_selection_screen.dart` - Sélection de langue

**Raison** : Paramètres et configuration

### 6. debug/ - Tests et Debug (3 fichiers)
- ✅ `debug_activity_screen.dart` - Debug d'activités
- ✅ `test_activity_screen.dart` - Tests d'activités
- ✅ `test_forfait_success_screen.dart` - Test forfait

**Raison** : Séparer les écrans de développement/test

---

## 🔄 Mises à Jour des Imports

Tous les imports ont été automatiquement mis à jour dans l'ensemble du projet :

### Avant
```dart
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
```

### Après
```dart
import '../screens/auth/login_screen.dart';
import '../screens/core/home_screen.dart';
import '../screens/user/profile_screen.dart';
```

---

## 📊 Statistiques

| Catégorie | Nombre de fichiers |
|-----------|-------------------|
| **auth** | 3 fichiers |
| **core** | 3 fichiers |
| **user** | 3 fichiers |
| **statistics** | 1 fichier |
| **settings** | 1 fichier |
| **debug** | 3 fichiers |
| **Total déplacés** | **14 fichiers** |

---

## ✅ Vérifications Effectuées

- ✅ Tous les fichiers déplacés via `git mv` (historique préservé)
- ✅ Tous les imports mis à jour automatiquement
- ✅ Structure logique et claire
- ✅ Aucun fichier `.dart` restant à la racine de `/lib/screens/`
- ✅ Dossiers existants conservés intacts

---

## 🎯 Avantages

### 1. Meilleure Organisation
- Fichiers groupés par fonctionnalité
- Navigation plus facile dans le projet
- Réduction du "clutter" à la racine

### 2. Maintenabilité Améliorée
- Localisation rapide des écrans
- Logique métier claire
- Séparation des responsabilités

### 3. Scalabilité
- Structure extensible pour futurs écrans
- Patterns clairs pour nouvelles features
- Facilite l'onboarding de nouveaux développeurs

### 4. Conformité aux Best Practices
- Structure modulaire
- Séparation par domaine fonctionnel
- Code plus professionnel

---

## 📝 Notes Techniques

### Commandes Utilisées

```bash
# Création des dossiers
mkdir -p auth core user statistics settings debug

# Déplacement des fichiers (préserve l'historique git)
git mv login_screen.dart auth/
git mv otp_screen.dart auth/
git mv splash_screen.dart auth/
# ... etc

# Mise à jour automatique des imports
find lib/ -type f -name "*.dart" -exec sed -i \
  -e "s|screens/login_screen\.dart|screens/auth/login_screen.dart|g" \
  -e "s|screens/home_screen\.dart|screens/core/home_screen.dart|g" \
  # ... etc
  {} +
```

### Git Status
Git a correctement détecté tous les déplacements comme des "renames" (RM) :
```
RM lib/screens/login_screen.dart -> lib/screens/auth/login_screen.dart
RM lib/screens/home_screen.dart -> lib/screens/core/home_screen.dart
# ... (14 fichiers au total)
```

---

## 🚀 Prochaines Étapes

### Optionnel - Réorganisation Future
Si d'autres screens sont créés à la racine, les déplacer dans les dossiers appropriés :
- Auth-related → `auth/`
- Main navigation → `core/`
- User-related → `user/`
- Configuration → `settings/`
- Analytics → `statistics/`
- Development → `debug/`

### Patterns à Suivre
Pour les nouveaux écrans, suivre la structure :
```
lib/screens/
├── [domaine]/
│   ├── [feature]_screen.dart
│   ├── [feature]_detail_screen.dart
│   └── [feature]_confirmation_screen.dart
```

---

## ⚠️ Points d'Attention

1. **Imports Absolus vs Relatifs**
   - Vérifier que tous les imports sont cohérents
   - Préférer les imports relatifs dans le même module

2. **Tests**
   - Mettre à jour les tests si nécessaire
   - Vérifier que tous les tests passent après réorganisation

3. **Documentation**
   - Mettre à jour la documentation interne si nécessaire
   - Informer l'équipe de la nouvelle structure

---

## ✨ Conclusion

La réorganisation des screens améliore significativement la structure du projet en :
- ✅ Éliminant le désordre à la racine
- ✅ Créant une hiérarchie logique et claire
- ✅ Facilitant la maintenance future
- ✅ Respectant les best practices Flutter

**Tous les fichiers sont maintenant organisés de manière cohérente ! 🎉**

---

_Réorganisation effectuée le 2025-12-08_
_Commit à venir : "refactor: Reorganize screens into logical folders"_
