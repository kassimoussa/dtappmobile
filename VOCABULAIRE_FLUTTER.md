# Vocabulaire des composants Flutter

Mémo pour nommer précisément un élément d'interface quand on signale un bug ou
demande une modification. Dire « le SnackBar de déconnexion » plutôt que « la
notification en bas de l'écran » évite un aller-retour de recherche.

Les composants sont classés par **endroit où ils apparaissent à l'écran**, parce
que c'est ainsi qu'on les décrit spontanément. Le nombre de fichiers indique
l'usage réel dans ce projet.

---

## Ce qui surgit par-dessus l'écran

| Nom | À quoi ça ressemble | Dans ce projet |
|---|---|---|
| **SnackBar** | Bandeau bref en **bas** de l'écran, disparaît seul. Peut porter un bouton d'action. | 25 fichiers. Ex. confirmation de recharge |
| **AlertDialog** | Boîte **centrée**, fond assombri, boutons Annuler / Confirmer. Bloque l'écran. | 13 fichiers. Ex. confirmation de déconnexion |
| **BottomSheet** | Panneau qui **monte depuis le bas**, souvent glissable. Ouvert par `showModalBottomSheet`. | `PinVerificationBottomSheet`, `ActivityDetailSheet` |
| **Dialog** | Terme générique pour toute boîte modale. `AlertDialog` en est la variante standard. | `PromoPopupDialog`, `BillPaymentDialog` |
| **Banner** | Bandeau persistant **en haut**, qui ne disparaît pas tout seul. | `ConnectivityBanner`, `InAppNotificationBanner` |
| **Tooltip** | Petite bulle d'aide à l'appui long sur une icône. | Non utilisé |

> **Le piège classique** : « notification » peut désigner trois choses très
> différentes — le SnackBar en bas, le Banner en haut, ou la vraie notification
> **push** du système hors de l'app. Préciser laquelle fait gagner du temps.

---

## Les barres

| Nom | À quoi ça ressemble | Dans ce projet |
|---|---|---|
| **AppBar** | Barre de titre en haut de l'écran. | Remplacée par `GlassAppBar`, le header maison |
| **BottomNavigationBar** | Barre d'onglets en bas (Accueil, Profil…). | 2 fichiers |
| **TabBar** | Onglets horizontaux sous le titre. | Non utilisé |
| **Drawer** | Menu latéral qui sort du bord gauche. | Non utilisé |

---

## Les conteneurs

| Nom | À quoi ça ressemble | Dans ce projet |
|---|---|---|
| **Card** | Bloc blanc à coins arrondis avec ombre. | 21 fichiers. Ex. `BalanceCard`, `ForfaitCard` |
| **ListTile** | Ligne standard : icône + titre + sous-titre + chevron. | 3 fichiers. `SettingsTile` en est l'équivalent maison |
| **ExpansionTile** | Ligne qui se déplie au clic (accordéon). | 2 fichiers |
| **Divider** | Fin trait de séparation entre deux lignes. | 22 fichiers |
| **Chip** | Petite étiquette arrondie, souvent colorée. | 1 fichier. Ex. les pastilles « 30 Go » / « 60 minutes » |
| **Badge** | Petite pastille de compteur collée à une icône. | Non utilisé |

---

## Les champs de saisie

| Nom | À quoi ça ressemble | Dans ce projet |
|---|---|---|
| **TextField** | Champ de texte simple. | 5 fichiers |
| **TextFormField** | Champ de texte **avec validation** dans un formulaire. | 11 fichiers |
| **Switch** | Interrupteur qui glisse (activé / désactivé). | 3 fichiers. Ex. paramètres de connexion |
| **Checkbox** | Case à cocher carrée. | 1 fichier. Ex. acceptation de la politique |
| **Radio** | Bouton rond à choix **exclusif** dans un groupe. | 5 fichiers |
| **DropdownButton** | Liste déroulante. | Non utilisé |
| **Slider** | Curseur glissant sur une plage de valeurs. | Non utilisé |

---

## Les indicateurs d'attente

| Nom | À quoi ça ressemble | Dans ce projet |
|---|---|---|
| **CircularProgressIndicator** | Roue qui tourne. | 36 fichiers |
| **LinearProgressIndicator** | Barre de progression horizontale. | 2 fichiers |
| **RefreshIndicator** | Roue déclenchée en **tirant la liste vers le bas**. | 4 fichiers |
| **Shimmer / Skeleton** | Silhouette grise animée pendant le chargement. | Non utilisé |

---

## Les zones tactiles

| Nom | Différence | Dans ce projet |
|---|---|---|
| **InkWell** | Zone cliquable **avec** l'onde d'encre au toucher. | 17 fichiers |
| **GestureDetector** | Zone cliquable **sans** effet visuel. Gère aussi glissement, appui long. | 14 fichiers |
| **Dismissible** | Élément qu'on supprime en le balayant. | Non utilisé |
| **FloatingActionButton** | Bouton rond flottant en bas à droite. | 1 fichier. Ex. les boutons de zoom de la carte |

---

## Les composants maison de ce projet

Ceux-là n'existent pas dans Flutter, ils sont propres à l'app. Les nommer
directement est le plus efficace.

| Nom | Rôle |
|---|---|
| **GlassAppBar** | Header standard : titre bleu, bouton retour et actions en pastilles translucides. Remplace `AppBar` partout |
| **GlassAppBarAction** | Une pastille d'action du header (retour, croix, « Enregistrer ») |
| **SettingsCard** | Carte blanche de réglages, séparateurs insérés automatiquement |
| **SettingsTile** | Une ligne de `SettingsCard` : libellé + élément de droite |
| **DtButton** | Bouton principal de l'app |
| **BalanceCard** | Carte de solde de l'écran d'accueil |
| **ForfaitCard** | Carte d'un forfait achetable |
| **ForfaitActifCard2** | Carte d'un forfait en cours |
| **TransactionCard** | Ligne d'historique de transaction |
| **PinVerificationBottomSheet** | Panneau de saisie du code PIN |
| **PinKeyboard** / **PinDots** | Clavier numérique et points de saisie du PIN |
| **InAppNotificationBanner** | Bandeau de notification affiché **dans** l'app, au premier plan |
| **ConnectivityBanner** | Bandeau de perte de connexion |
| **PhoneNumberSelector** | Sélecteur de numéro avec accès aux contacts |
| **SwipeableAccountCards** | Cartes de comptes que l'on fait défiler latéralement |

---

## Structure et mise en page

Vocabulaire utile pour décrire un problème d'agencement.

| Nom | Rôle |
|---|---|
| **Row** / **Column** | Alignement horizontal / vertical |
| **Stack** | Éléments **superposés** en profondeur |
| **Expanded** | Enfant qui occupe toute la place restante |
| **Flexible** | Comme `Expanded`, mais sans obligation de tout remplir |
| **Padding** | Marge **intérieure** |
| **SizedBox** | Boîte de taille fixe, souvent utilisée comme espaceur |
| **SafeArea** | Évite l'encoche et la barre système. 50 fichiers |
| **SingleChildScrollView** | Rend défilant un contenu trop grand |
| **ListView** | Liste défilante d'éléments |
| **FittedBox** | Réduit son contenu pour le faire tenir. Ex. les titres longs du header |
| **Overflow** | Le débordement : la bande rayée jaune et noire signalant qu'un élément ne tient pas |
