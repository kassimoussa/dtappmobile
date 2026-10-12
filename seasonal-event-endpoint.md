# Événements saisonniers (animations de fêtes) — `GET /api/seasonal-event`

Document autonome à donner tel quel à l'agent / au développeur **back-end**. Il décrit
l'endpoint et l'administration à créer pour que l'application mobile **DT Mobile**
(Flutter, Djibouti Telecom) affiche des animations Lottie pendant les fêtes et
événements (Aïd, Ramadan, Mouled, Fête de l'Indépendance, Nouvel An…), **sans
republier l'application**.

Conventions déjà en place dans l'API, à respecter :
- Base : `/api` — enveloppe de réponse `{ "success": bool, "data": ... }`
- Champs en `snake_case`
- Les contenus promotionnels existants (`GET /api/banners`, `GET /api/popup`) sont publics,
  gérés dans l'administration, et leurs images sont des chemins relatifs (`image_url`).
  **Inspire-toi de leur implémentation** (contrôleur, modèle, upload de fichiers, écran
  d'administration) pour garder le même style et les mêmes outils.

## Contexte

Chaque fête a une ou plusieurs animations (fichiers Lottie `.json`), affichées à des
**emplacements précis** de l'application. Le back-end décide **quoi afficher, où et
quand** ; l'application ne contient que le moteur d'affichage. L'administrateur (équipe
marketing DT) doit pouvoir créer un événement, téléverser ses animations, choisir leurs
emplacements et ses dates, sans développeur.

Pourquoi le back-end et non Firebase Remote Config : l'administration des bannières et
popups existe déjà, les fichiers Lottie doivent de toute façon être hébergés, et le serveur
peut valider les saisies et décider avec sa propre horloge (fuseau de Djibouti) plutôt que
celle du téléphone.

## Endpoint

```
GET /api/seasonal-event
```

- **Public**, sans authentification : l'appel a lieu au démarrage, avant la connexion.
- Aucun paramètre obligatoire.
- Renvoie **l'événement actif à l'instant présent**, ou `data: null` s'il n'y en a pas.
- **Toujours `200`** quand il n'y a simplement pas d'événement. L'application ignore
  silencieusement toute erreur, mais évite les `5xx` inutiles.
- Réponse petite (quelques Ko), mise en cache courte : `Cache-Control: public, max-age=300`.

### Réponse — événement actif

```json
{
  "success": true,
  "data": {
    "id": 12,
    "name": "Aïd Moubarak",
    "starts_at": "2027-03-09T00:00:00+03:00",
    "ends_at": "2027-03-12T23:59:59+03:00",
    "animations": [
      {
        "id": 31,
        "placement": "header_strip",
        "animation_url": "/storage/uploads/events/dt-aid-croissant-9f3a1c.json",
        "position": "top_left",
        "width_fraction": 0.2,
        "loop": "infinite",
        "delay_ms": 0,
        "title": null
      },
      {
        "id": 32,
        "placement": "header_strip",
        "animation_url": "/storage/uploads/events/dt-aid-lanterne-b27e40.json",
        "position": "top_right",
        "width_fraction": 0.18,
        "loop": "infinite",
        "delay_ms": 0,
        "title": null
      },
      {
        "id": 33,
        "placement": "banner_strip",
        "animation_url": "/storage/uploads/events/aid-banner-51d9c2.json",
        "position": "center_left",
        "width_fraction": 0.2,
        "loop": "infinite",
        "delay_ms": 0,
        "title": { "fr": "Aïd Moubarak !", "en": "Eid Mubarak!" }
      }
    ]
  }
}
```

### Réponse — aucun événement actif

```json
{ "success": true, "data": null }
```

### Champs d'un événement

| Champ | Type | Règle |
|---|---|---|
| `id` | int | Identifiant stable : l'application s'en sert pour ne montrer l'animation qu'**une fois par utilisateur et par événement**. |
| `name` | string | Nom interne, jamais affiché. |
| `starts_at`, `ends_at` | string ISO 8601 **avec décalage** (`+03:00`) | `ends_at` strictement après `starts_at`. |
| `animations` | array | Voir ci-dessous. Peut être vide. |

### Champs d'une animation

| Champ | Type | Règle |
|---|---|---|
| `id` | int | |
| `placement` | string | **Enum fermé** : `header_strip`, `overlay`, `card_corner`, `banner_strip`, `splash`. Voir « Emplacements ». |
| `animation_url` | string | Chemin relatif commençant par `/` (ex. `/storage/uploads/events/x.json`) **ou** URL absolue `https://`. L'application résout un chemin relatif sur l'**origine du serveur, sans `/api`** (comme `image_url` des bannières). |
| `position` | string | **Enum fermé de 9 valeurs** : `top_left`, `top_center`, `top_right`, `center_left`, `center`, `center_right`, `bottom_left`, `bottom_center`, `bottom_right`. Position de l'animation **à l'intérieur de la zone** de l'emplacement. Voir « Positions dans la zone ». |
| `width_fraction` | nombre `]0, 1]` | Largeur de l'animation en **fraction de la largeur de la zone** de l'emplacement. |
| `loop` | string | `once` ou `infinite`. |
| `delay_ms` | int ≥ 0 | Attente avant le démarrage, une fois l'écran affiché. Défaut `0`. |
| `title` | `{fr, en}` ou `null` | Texte optionnel, **affiché seulement pour `banner_strip`** pour l'instant. Langues de l'app : `fr`, `en`. |

Valeurs hors bornes ou hors enum : refuser à la saisie dans l'administration (ne jamais les renvoyer).

## Emplacements

L'application définit ces cinq emplacements. **Le back-end ne peut pas en inventer** : un
nouvel emplacement demande une mise à jour de l'app. Une valeur inconnue est ignorée par
l'app, donc une ancienne version ne casse jamais. Dimensions en unités de maquette
(375 dp de large).

| `placement` | Où | Zone (largeur × hauteur) | Fond | Hauteur ajoutée à l'écran | Défauts (`position`, `width_fraction`, `loop`) |
|---|---|---|---|---|---|
| `header_strip` | Bande sous la barre d'état de l'accueil (lanternes suspendues, croissant). Plusieurs animations possibles (gauche **et** droite). | 375 × 56 | Bleu `#0D47A1` | **+56 dp** (seulement pendant l'événement) | `top_right`, `0.2`, `infinite` |
| `overlay` | Plein écran, par-dessus tout, sans bloquer les touches (confettis, feux d'artifice). | 375 × 812 | Transparent | 0 | `center`, `1.0`, `once` |
| `card_corner` | Coin bas-droit de la carte du solde, à la place de l'icône de portefeuille grisée. | 335 × 140 (carte), animation ≈ 90 × 90 | Blanc | 0 | `bottom_right`, `0.27`, `infinite` |
| `banner_strip` | Bandeau entre les actions rapides et les bannières promo. | 335 × 64 | Gris clair `#F8F9FE` | **+64 dp** (seulement pendant l'événement) | `center_left`, `0.2`, `infinite` |
| `splash` | Décor superposé au logo du splash (même canevas 500 × 500 que le logo). | 240 × 240 | Blanc | 0 | `center`, `1.0`, `once` |

L'administration doit **pré-remplir ces défauts** quand on choisit un emplacement.

### Positions dans la zone

Chaque emplacement a une **zone** (colonne « Zone » ci-dessus). `position` place l'animation
dans cette zone, sur une grille de 3 × 3 : les quatre **coins**, les quatre **milieux de
côté** et le **centre**. La position est relative à la **zone**, pas à l'écran entier
(sauf pour `overlay`, dont la zone est l'écran).

```
┌──────────────┬───────────────┬───────────────┐
│ top_left     │ top_center    │ top_right     │
├──────────────┼───────────────┼───────────────┤
│ center_left  │ center        │ center_right  │
├──────────────┼───────────────┼───────────────┤
│ bottom_left  │ bottom_center │ bottom_right  │
└──────────────┴───────────────┴───────────────┘
```

| `position` | Coin / côté | Équivalent `Alignment` Flutter (pour info) |
|---|---|---|
| `top_left` | coin haut gauche | `(-1, -1)` |
| `top_center` | milieu du bord haut | `(0, -1)` |
| `top_right` | coin haut droite | `(1, -1)` |
| `center_left` | milieu du bord gauche | `(-1, 0)` |
| `center` | centre | `(0, 0)` |
| `center_right` | milieu du bord droit | `(1, 0)` |
| `bottom_left` | coin bas gauche | `(-1, 1)` |
| `bottom_center` | milieu du bord bas | `(0, 1)` |
| `bottom_right` | coin bas droite | `(1, 1)` |

Les neuf valeurs sont acceptées pour tous les emplacements ; le résultat dépend de la
forme de la zone (dans `header_strip`, très plate, haut, centre et bas sont presque au
même endroit). Usages typiques :

| `placement` | Positions typiques |
|---|---|
| `header_strip` | `top_left` (croissant) et `top_right` (lanterne suspendue) ; une animation par coin |
| `overlay` | `center` en plein écran (`width_fraction` 1.0) ; un petit décor dans un coin est possible avec une fraction plus petite |
| `card_corner` | `bottom_right` (remplace l'icône de portefeuille), éventuellement `top_right` |
| `banner_strip` | `center_left` ou `center_right` |
| `splash` | `center` (même canevas que le logo), ou `top_right` pour un petit élément posé sur le logo |

L'application garde une petite marge intérieure (environ 5 % de la largeur de la zone) du
côté gauche et droit pour les positions `*_left` et `*_right`, afin que l'animation ne
colle pas au bord ; verticalement elle reste collée au bord (une lanterne suspendue part
du bord haut). Le back-end n'a rien à gérer là-dessus.

## Règle de sélection (côté serveur)

1. Heure de référence : **`Africa/Djibouti` (UTC+3)**, jamais l'heure du téléphone.
2. Un événement est actif si `is_active = true` et `starts_at <= maintenant <= ends_at`.
3. Si plusieurs événements se chevauchent : le plus grand `priority`, puis le `starts_at`
   le plus récent. **Un seul événement est renvoyé.**
4. Ne renvoyer que les animations actives, dont le `placement` est dans l'enum, triées par
   `sort_order` puis `id`.
5. Le changement d'état se fait à la seconde près à minuit heure de Djibouti, pas à minuit UTC.

## Modèle de données suggéré (adapter aux conventions du projet)

`seasonal_events` : `id`, `name`, `starts_at` (datetime), `ends_at` (datetime),
`priority` (int, défaut 0), `is_active` (bool, défaut true), timestamps.

`seasonal_event_animations` : `id`, `seasonal_event_id` (FK, suppression en cascade),
`placement` (string), `file_path` (string), `position` (string),
`width_fraction` (float), `loop` (string), `delay_ms` (int), `title_fr`, `title_en`
(string, nullables), `sort_order` (int), `is_active` (bool), timestamps.

Pas d'unicité par emplacement : `header_strip` en a deux (gauche et droite). Limites
raisonnables : 8 animations au plus par événement, 3 au plus par emplacement.

## Fichiers Lottie

À la saisie dans l'administration, **valider le fichier téléversé** :
- JSON valide, avec au minimum les clés Lottie `v`, `fr`, `ip`, `op`, `w`, `h`, `layers` ;
- taille ≤ **200 Ko** (objectif de conception : < 50 Ko) ;
- refuser les images embarquées (`"assets"` contenant des `data:` base64) ;
- extension `.json` uniquement ; nom de fichier **aléatoire** (suffixe hexadécimal) pour
  éviter les collisions et le cache périmé ;
- stockage public, servi avec `Content-Type: application/json`.

Deux fichiers d'exemple pour le jeu de test sont dans le dépôt de l'application :
`assets/lottie/dt-aid-croissant.json` et `assets/lottie/dt-aid-lanterne.json`
(à téléverser tels quels pour créer l'événement « Aïd Moubarak » ci-dessus).

## Administration

Ajouter une section **« Événements saisonniers »** dans le même panneau que les bannières
et le popup, avec le même style :
- liste des événements (nom, dates, statut actif/à venir/terminé) ;
- formulaire : nom, dates de début et de fin (saisies en heure de Djibouti), priorité,
  activé ;
- sous-formulaire d'animations : emplacement (liste des cinq valeurs), fichier, **position
  choisie sur une grille 3 × 3 cliquable** (une case par valeur de `position`, étiquetée
  « haut gauche », « haut droite », etc.), `width_fraction`, `loop`, `delay_ms`, titre
  fr/en (affiché seulement si l'emplacement est `banner_strip`) ;
- **avertissement** si l'événement chevauche un autre événement actif ;
- validation de toutes les bornes ci-dessus avec des messages d'erreur clairs.

## Côté application (pour info, ne pas coder côté serveur)

- Appel au démarrage depuis le splash, comme `/popup`, avec un délai maximum de 10 s et
  un échec silencieux (aucune animation, aucune erreur visible).
- Une animation `once` n'est jouée qu'une fois par utilisateur et par `id` d'événement
  (mémorisé sur l'appareil).
- Un `placement` inconnu est ignoré. Si le téléchargement du fichier échoue, rien n'est affiché.
- Les emplacements `header_strip` et `banner_strip` ajoutent de la hauteur à l'écran
  seulement quand un événement les utilise.
- Les animations ne bloquent jamais les touches et se figent si l'utilisateur a réduit les
  animations dans les réglages du téléphone.

## Critères de réception

Vérifier avec `curl https://<serveur>/api/seasonal-event` :

1. Aucun événement en base → `200`, `{"success":true,"data":null}`.
2. Événement actif dans sa fenêtre → renvoyé avec ses animations, dans l'ordre.
3. Événement hors fenêtre, ou `is_active = false` → non renvoyé.
4. Dernière seconde du jour de fin (`23:59:59+03:00`) → encore renvoyé ; `00:00:00` du
   lendemain → plus renvoyé.
5. Deux événements qui se chevauchent → celui de plus haute `priority`, un seul.
6. `animation_url` relatif → le fichier est bien téléchargeable à
   `https://<serveur><animation_url>` avec `Content-Type: application/json`.
7. L'administration refuse : `ends_at <= starts_at`, `position` hors des neuf valeurs,
   `width_fraction` hors de `]0, 1]`, `placement` inconnu, fichier non JSON ou trop gros.
8. Aucun appel à cet endpoint ne demande de token de session.
