# Guide TestFlight — DJIBTEL iOS

Procédure restante pour distribuer l'app sur TestFlight.
Bundle ID cible (iOS **et** Android) : `com.djiboutitelecom.dtappmobile`

## ✅ Déjà fait (dans le code, ce dépôt)

- Bundle ID iOS remplacé dans `ios/Runner.xcodeproj/project.pbxproj` (6 configurations)
- `applicationId` + `namespace` Android remplacés dans `android/app/build.gradle.kts`,
  `MainActivity.kt` déplacé vers `kotlin/com/djiboutitelecom/dtappmobile/`
- Capability push : `ios/Runner/Runner.entitlements` (`aps-environment`) + `CODE_SIGN_ENTITLEMENTS`
- `UIBackgroundModes` (`fetch`, `remote-notification`) dans `Info.plist`
- `ITSAppUsesNonExemptEncryption = false` dans `Info.plist` (pas de question de conformité export à chaque build)
- Icônes iOS vérifiées (1024×1024 sans canal alpha, logo DT)
- Config Firebase régénérée : apps iOS + Android `com.djiboutitelecom.dtappmobile`
  enregistrées dans le projet `dtapp-60b81` ; `firebase_options.dart`,
  `GoogleService-Info.plist` et `google-services.json` à jour ; build Android vérifié

## Étape 2 — Côté Apple Developer (rôle Admin requis pour la clé)

1. **App ID** : vérifier que `com.djiboutitelecom.dtappmobile` est enregistré avec la
   capability **Push Notifications** ([developer.apple.com](https://developer.apple.com)
   → Certificates, Identifiers & Profiles → Identifiers). Xcode en signature automatique
   peut souvent le faire seul (voir étape 3) ; sinon demander à un Admin.
2. **Clé APNs (.p8)** : seuls les rôles *Admin* / *Account Holder* peuvent créer des clés.
   Demander à un admin — **une clé existante du compte convient** (une clé APNs sert
   pour toutes les apps de l'équipe, max 2 par compte). Récupérer :
   - le fichier `.p8`
   - le **Key ID**
   - le **Team ID** (visible dans Membership)

## Étape 3 — Signature dans Xcode

```bash
open ios/Runner.xcworkspace
```

Target **Runner** → onglet **Signing & Capabilities** → sélectionner la team →
vérifier que le profil se génère sans erreur (la capability Push doit apparaître).

> Erreur « provisioning profile doesn't support Push Notifications » = l'App ID
> n'a pas la capability (retour à l'étape 2.1).

## Étape 4 — Uploader la clé APNs dans Firebase

Console Firebase → ⚙️ Paramètres du projet → **Cloud Messaging** → section de la
**nouvelle app iOS** (`com.djiboutitelecom.dtappmobile`) → *APNs Authentication Key*
→ uploader le `.p8` avec Key ID + Team ID.

Sans cette clé, aucun push ne peut être livré sur iOS.

## Étape 5 — Test push sur iPhone réel

```bash
flutter run          # sur un iPhone physique (ou simulateur Mac Apple Silicon, iOS 16+)
```

1. Accepter la permission notifications
2. Repérer `FCM TOKEN:` dans les logs
3. Console Firebase → Messaging → « Envoyer un message test » avec ce token

## Étape 6 — Créer la fiche app (App Store Connect, rôle App Manager suffit)

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Mes apps → **+** → Nouvelle app :

| Champ | Valeur |
|---|---|
| Plateforme | iOS |
| Nom | DJIBTEL (unique sur l'App Store) |
| Langue principale | Français |
| Bundle ID | `com.djiboutitelecom.dtappmobile` (dans la liste) |
| SKU | libre, ex. `djibtel-ios` |
| **Catégorie principale** | **Utilitaires** (standard des apps opérateur) |
| Catégorie secondaire | Finance (transferts / recharges) |

## Étape 7 — Build et upload

```bash
flutter build ipa --release
```

Puis, au choix :

- ouvrir `build/ios/archive/Runner.xcarchive` dans Xcode → Organizer →
  *Distribute App* → *App Store Connect* → *Upload* ; ou
- glisser le `.ipa` de `build/ios/ipa/` dans l'app **Transporter**.

⚠️ Incrémenter le numéro de build dans `pubspec.yaml` à **chaque** upload
(`version: 1.0.0+1` → `+2` → `+3`…). Traitement côté Apple : ~10-30 min.

## Étape 8 — Distribuer dans TestFlight

Onglet **TestFlight** de la fiche app :

- **Testeurs internes** (max 100) : disponibles immédiatement, sans review.
  Ils doivent être utilisateurs App Store Connect de l'équipe — **seul un Admin
  peut ajouter des utilisateurs** (Users and Access).
- **Testeurs externes** (max 10 000, email ou lien public) : pas de compte requis,
  mais le premier build passe une **Beta App Review** (~1-2 jours).
  ⚠️ Login par OTP SMS → fournir au reviewer un **compte de démo** : prévoir côté
  backend un numéro de test avec OTP fixe, sinon la review bloque.

Les builds TestFlight expirent après 90 jours.

## Notes backend (recommandé, non bloquant)

- **Son iOS** : ajouter dans les envois FCM (HTTP v1 / Admin SDK) au moins pour
  transactions et sécurité :
  ```json
  "apns": { "payload": { "aps": { "sound": "default" } } }
  ```
  (sur iOS le son vient du payload, pas des channels comme Android)
- Confirmer que le backend utilise l'**API HTTP v1** ou le SDK Admin (l'API legacy est morte)
- **Multi-appareils** : un même numéro pourra avoir un token Android + un token iPhone —
  vérifier que le stockage des tokens ne les écrase pas mutuellement

## Avant l'App Store (pas bloquant pour TestFlight interne)

- Retirer le bypass SSL `_TrustAllCerts` dans `lib/main.dart` (motif de rejet + faille) —
  le bon correctif est la chaîne de certificats côté serveur
- Vérifier que l'app pointe vers l'API publique (pas l'IP privée `10.39.230.106`)
- TestFlight utilise l'environnement APNs **production** : un token FCM obtenu en
  build debug ne recevra pas les push d'un build TestFlight (re-tester avec le build TestFlight)
