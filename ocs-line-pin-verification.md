# Demande à l'équipe OCS — vérifier le PIN d'une ligne fixe (« Ma ligne », application DJIBTEL)

**À :** équipe OCS, responsable de la plateforme TopUp DJIB
**De :** [nom, fonction]
**Date :** 15/11/2026
**Réponse souhaitée avant le :** [date]

## En bref

Dans l'application mobile DJIBTEL, la rubrique **« Ma ligne »** permet de consulter et
recharger une ligne fixe. Aujourd'hui, **le numéro seul suffit** pour y accéder. Nous voulons
exiger le **même couple numéro de ligne + PIN que sur le portail client**
(`my.djiboutitelecom.dj/user/index.php`, type d'utilisateur « Subscriber »).

Il nous manque **un moyen de vérifier ce couple depuis l'API**. C'est ce que nous vous demandons.

## Contexte : ce que dit la documentation TopUp v3.3

- Les méthodes de lecture (`getMyNumbers`, `getBalances`, `getPackagesByPhoneNumber(New)`,
  `getStatusForRecharge`) **n'exigent aucun PIN**.
- `postCommand` a un paramètre `Pincode` (valeur par défaut `0000`) et un paramètre `Skip`
  (1 = ne pas contrôler le PIN). Le document le décrit comme le PIN **de l'abonné mobile** :
  nous ne savons pas s'il s'agit du même PIN que celui du portail.
- Il n'existe **aucune méthode qui vérifie un PIN sans exécuter une opération**.
- Le document ne mentionne pas le portail client.

## Ce que nous demandons

**1. Répondre à deux questions, qui conditionnent le reste :**

- Le PIN du portail est-il le même que `Pincode` de `postCommand` ? Sinon, quel système le
  gère (OCS, facturation, base du portail) ?
- Le portail utilise sûrement un contrôle du couple (ligne, PIN) : peut-il être exposé à l'API ?
  Les captures SoapUI du document montrent aussi une opération `comparePasswordByUsername` qui
  n'est pas décrite : à quoi sert-elle ?

**2. Mettre à disposition une méthode de vérification.** Proposition, à adapter à vos
conventions (même compte API, REST et SOAP comme les autres méthodes) :

| Entrée | Type | Description |
|---|---|---|
| `username`, `password` | String | Compte API existant |
| `isdn` | String | Ligne fixe, même format que les autres méthodes |
| `pin` | String | PIN de la ligne, le même que sur le portail |
| `msisdn` | String | Mobile de l'utilisateur de l'application (traçabilité) |

Sortie : `returnCode` + `description`, avec des codes alignés sur ceux qui existent déjà :

| `returnCode` | Sens |
|---|---|
| `0` | PIN correct |
| `406` | PIN incorrect (voir la remarque sur l'énumération ci-dessous) |
| `2` | Ligne suspendue ou bloquée |
| *à définir* | PIN verrouillé après trop d'essais (avec la durée restante si possible) |
| `401` | Compte API incorrect |
| `402` | Erreur technique : à traiter comme ambiguë, on réessaie |

## Exigences de sécurité

1. **Le PIN voyage dans le corps d'une requête POST**, jamais dans l'URL. Les appels REST
   actuels passent les numéros dans l'URL (`/getBalances/{msisdn}/{isdn}`) : un PIN s'y
   retrouverait dans les journaux.
2. **Limitation des essais côté OCS**, avec le **même compteur que le portail**. Sans cela, l'API
   permettrait de deviner un PIN court par essais successifs. Notre backend limitera aussi le
   débit, mais il ne doit pas être la seule protection.
3. **Aucun PIN en clair dans vos journaux** ni dans ceux d'un éventuel reverse proxy.
4. **Pas de distinction entre « ligne inconnue » et « PIN faux »** (même code `406`), pour ne
   pas permettre de lister les lignes existantes.
5. **Transport :** le document cite des URL en `http://SERVER_IP:8700` et `:8800`. Merci de
   confirmer que ce PIN transitera en TLS, ou par un réseau privé, avec les adresses IP des
   appelants autorisées comme le recommande le §3.3 du document.

## Autres questions

1. **Format du PIN** (longueur, chiffres seulement ?) et **règle de blocage** (nombre d'essais,
   durée).
2. **PIN par défaut :** peut-on savoir qu'une ligne a encore son PIN d'origine (`0000` ?) pour
   inciter l'abonné à le changer ?
3. **Lignes postpayées** et autres types d'utilisateurs : le portail les accepte-t-il ? Nous
   ne visons que « Subscriber ».
4. **PIN oublié :** quelle est la procédure aujourd'hui (agence, 1500, SMS) ? Nous la
   mentionnerons dans l'application, qui ne pourra pas le réinitialiser.
5. **Environnement de test :** URL, compte API, une ligne avec un PIN connu et une ligne verrouillée
   pour tester les erreurs.

## Ce que nous ferons de notre côté

- L'utilisateur saisit numéro + PIN dans l'application. Ils sont envoyés en HTTPS à notre
  backend, qui appelle votre méthode.
- Notre backend retient « ligne X vérifiée pour le mobile Y » et **l'exige sur tous les appels
  TopUp suivants**, pour que le contrôle ne repose pas seulement sur l'écran de l'application.
- Le PIN n'est ni stocké ni journalisé chez nous.
- Hors périmètre : changer ou réinitialiser le PIN depuis l'application. Si vous préférez
  exposer le changement de PIN (`Action_type 1`), dites-le-nous.

## Livrables attendus

1. Les réponses aux questions ci-dessus, en commençant par les deux premières.
2. La spécification de la méthode (adaptée de la proposition), avec la valeur de chaque code.
3. L'accès à l'environnement de test avec les lignes de test.
