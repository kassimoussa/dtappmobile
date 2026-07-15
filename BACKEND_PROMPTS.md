# Prompts back-end — DT Mobile

Endpoints à implémenter côté serveur pour l'application mobile **DT Mobile**
(Flutter, Djibouti Telecom). Chaque section ci-dessous est un **prompt autonome**
(contexte inclus) à donner tel quel à l'agent / au développeur back-end.

Conventions communes de l'API :
- Base : `/api`
- Enveloppe de réponse : `{ "success": bool, "data": { ... } }`
- Mêmes en-têtes JSON que les autres endpoints mobile
- Identifiants app : package Android / bundle iOS = `com.djiboutitelecom.dtappmobile`

| # | Endpoint | Auth | Statut app |
|---|----------|------|-----------|
| 1 | `GET /api/mobile/app-version` | Public | Client à brancher |
| 2 | `GET`/`PUT /api/mobile/notification-preferences` | Session token | `TODO(backend)` déjà en place |

---

## 1. Endpoint version applicative (gestion des mises à jour)

```
Contexte
--------
Application mobile « DT Mobile » (Flutter, Djibouti Telecom). Je dois ajouter la
gestion des mises à jour applicatives. Au démarrage (écran Splash, AVANT la
connexion de l'utilisateur), l'app appellera un endpoint pour savoir si une mise
à jour est disponible ou obligatoire, puis affichera un dialogue en conséquence.

Tâche
-----
Implémenter l'endpoint REST suivant, en respectant les conventions déjà en place
dans l'API (base `/api`, enveloppe de réponse JSON `{ "success": bool, "data": {...} }`,
mêmes en-têtes JSON que les autres endpoints mobile).

    GET  /api/mobile/app-version?platform=android|ios

Exigences
---------
1. PUBLIC / NON authentifié : l'appel a lieu avant le login (pas de session
   token disponible). Ne pas exiger d'auth.
2. Paramètre de requête `platform` : "android" ou "ios". Les valeurs renvoyées
   doivent pouvoir DIFFÉRER par plateforme (versions et URL de store distinctes).
   Si `platform` est absent/inconnu → renvoyer les valeurs Android par défaut
   (ou 400 au choix, mais préférer un 200 robuste).
3. Les valeurs doivent être CONFIGURABLES sans redéploiement (table de config /
   petit panneau admin), pour pouvoir monter `min_version` et forcer une mise à
   jour en production sans livrer de code.
4. Versions au format semver "MAJEUR.MINEUR.CORRECTIF" (ex. "1.2.0").
5. Toujours répondre en 200 avec des données cohérentes (l'app applique une règle
   « fail-open » : en cas d'erreur/timeout elle laisse passer, donc évite les 5xx
   inutiles).

Schéma de la réponse (data)
---------------------------
    latest_version : string  // dernière version publiée sur le store
    min_version    : string  // version minimale supportée ; en-dessous = MAJ OBLIGATOIRE
    force_update   : bool     // forcer la MAJ même si version >= min_version (kill-switch)
    store_url      : string   // lien de la fiche store (Play Store / App Store)
    release_notes  : string   // notes de version affichées à l'utilisateur (localisées FR si possible)

Logique côté application (pour info, ne pas coder côté serveur)
---------------------------------------------------------------
    installée < min_version   OU force_update == true  → MAJ OBLIGATOIRE (dialogue bloquant)
    installée < latest_version                          → MAJ RECOMMANDÉE (dialogue « Plus tard » / « Mettre à jour »)
    sinon                                               → rien

Exemples de réponses
--------------------
# À jour (rien à faire) — app en 1.2.0
{ "success": true, "data": {
  "latest_version": "1.2.0", "min_version": "1.0.0", "force_update": false,
  "store_url": "https://play.google.com/store/apps/details?id=com.djiboutitelecom.dtappmobile",
  "release_notes": "" } }

# Mise à jour recommandée — app en 1.1.0
{ "success": true, "data": {
  "latest_version": "1.2.0", "min_version": "1.0.0", "force_update": false,
  "store_url": "https://play.google.com/store/apps/details?id=com.djiboutitelecom.dtappmobile",
  "release_notes": "Corrections de bugs et améliorations de performance." } }

# Mise à jour obligatoire — app en 1.0.5, min = 1.1.0
{ "success": true, "data": {
  "latest_version": "1.2.0", "min_version": "1.1.0", "force_update": false,
  "store_url": "https://play.google.com/store/apps/details?id=com.djiboutitelecom.dtappmobile",
  "release_notes": "Cette version corrige un problème de sécurité. Mise à jour requise." } }

Suggestion de modèle de données
--------------------------------
Table `app_versions` :
    platform       varchar   (PK, "android" | "ios")
    latest_version varchar
    min_version    varchar
    force_update   boolean   default false
    store_url      varchar
    release_notes  text
    updated_at     timestamp

Identifiants connus :
    - Package Android : com.djiboutitelecom.dtappmobile
    - Bundle iOS      : com.djiboutitelecom.dtappmobile (fiche App Store à venir)

Livrable attendu
----------------
- L'endpoint GET /api/mobile/app-version fonctionnel (public), lisant depuis la
  table de config, filtré par `platform`.
- Un moyen d'éditer ces valeurs (seed + endpoint admin protégé, ou interface).
```

---

## 2. Endpoints préférences de notification

```
Contexte
--------
Application mobile « DT Mobile » (Flutter, Djibouti Telecom). Un écran
« Préférences de notification » propose 4 interrupteurs (transactions, offres,
solde, sécurité). Aujourd'hui ces choix sont stockés uniquement en local sur le
téléphone : ils N'ONT AUCUN effet sur les push réellement envoyés. Il faut donc
(1) persister ces préférences côté serveur par utilisateur, et (2) les respecter
au moment d'envoyer les notifications.

Tâche
-----
Implémenter deux endpoints REST, en respectant les conventions de l'API
(base `/api`, enveloppe `{ "success": bool, "data": {...} }`, mêmes en-têtes JSON).

    GET  /api/mobile/notification-preferences
    PUT  /api/mobile/notification-preferences

Exigences
---------
1. AUTHENTIFIÉ : ces endpoints nécessitent l'utilisateur connecté. Utiliser le
   même mécanisme de session token que les autres endpoints mobile (ex.
   /mobile/logout). Les préférences sont rattachées au msisdn/compte authentifié.
2. Un utilisateur sans préférences enregistrées → renvoyer les valeurs par défaut
   (toutes à true), et les créer à la première écriture (upsert).
3. Réponses toujours en 200 avec l'objet complet des 4 champs.

Schéma (data) — 4 booléens
--------------------------
    transactions : bool   // rechargements, transferts, achats de forfaits
    offers       : bool   // promotions & offres marketing
    balance      : bool   // alertes de solde bas / expiration de forfait
    security     : bool   // connexions, changements de sécurité (PIN, nouvel appareil)

GET /api/mobile/notification-preferences
----------------------------------------
# Réponse 200
{ "success": true, "data": {
  "transactions": true, "offers": true, "balance": true, "security": true } }

PUT /api/mobile/notification-preferences
----------------------------------------
# Requête (corps) — l'app envoie l'état complet
{ "transactions": true, "offers": false, "balance": true, "security": true }

# Réponse 200
{ "success": true, "message": "Préférences mises à jour", "data": {
  "transactions": true, "offers": false, "balance": true, "security": true } }

IMPORTANT — côté envoi des notifications
----------------------------------------
Persister ne suffit pas : au moment d'envoyer un push, le serveur doit
1) déterminer la CATÉGORIE de la notification (transactions | offers | balance |
   security),
2) vérifier la préférence de l'utilisateur pour cette catégorie,
3) NE PAS envoyer si elle est à false.
Ajouter aussi la catégorie dans le payload FCM (ex. data.category) pour le suivi
et un éventuel filtrage futur.

Décision à valider : les notifications de catégorie « security » sont souvent
envoyées TOUJOURS (non désactivables) pour raisons de sécurité. À trancher :
respecter le toggle, ou forcer l'envoi des alertes de sécurité critiques.

Suggestion de modèle de données
--------------------------------
Table `notification_preferences` :
    msisdn        varchar   (PK / FK vers l'utilisateur)
    transactions  boolean   default true
    offers        boolean   default true
    balance       boolean   default true
    security      boolean   default true
    updated_at    timestamp

Livrable attendu
----------------
- GET + PUT fonctionnels (authentifiés), avec upsert et valeurs par défaut.
- Prise en compte effective des préférences au moment de l'envoi des push
  (filtrage par catégorie).
```

---

## Côté application (pour info)

Dès qu'un endpoint est en ligne, le branchement client est rapide :

- **Préférences de notification** — le point d'accroche existe déjà :
  `TODO(backend)` dans `lib/services/notification_preferences_service.dart`
  (méthodes `load()` / `save()` à faire pointer vers l'endpoint).
- **Version applicative** — à implémenter côté app : un `AppUpdateService`
  (fetch + comparaison semver), un dialogue de MAJ conforme à la charte
  (`Dialog` + `DtButton` ; obligatoire = non-fermable), déclenché au Splash,
  avec règle **fail-open** et throttling du rappel « recommandé ».
