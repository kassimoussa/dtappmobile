# Guide Play Store — DJIBTEL Android

Procédure pour publier l'app sur Google Play (piste de test interne, puis production).
Identifiant de l'app (Android **et** iOS) : `com.djiboutitelecom.dtappmobile`

## ✅ Déjà fait (dans le code, ce dépôt)

- `applicationId` / `namespace` : `com.djiboutitelecom.dtappmobile` (`android/app/build.gradle.kts`)
- `targetSdk` 36 (fourni par Flutter 3.44), `minSdk` 24
- Config Firebase Android à jour (`android/app/google-services.json`)
- Pas de permission SMS (`READ_SMS` / `RECEIVE_SMS` retirées) : l'OTP passe par l'API
  SMS Retriever, qui n'en demande aucune. Google Play réserve ces permissions aux
  applications SMS par défaut. Le manifeste final (fusionné avec les plugins) ne les
  contient pas ; l'autofill reste à retester sur un téléphone (voir étape 6).
- `POST_NOTIFICATIONS` déclarée (ajoutée par un plugin de notifications, présente dans le manifeste final)

## ⛔ Étape 1 — Créer la clé d'envoi (upload key) — BLOQUANT

Sans `android/key.properties`, `build.gradle.kts` signe la release avec la clé
**debug** (`CN=Android Debug`) et **Google Play refuse** le fichier.

```bash
mkdir -p ~/keystores
keytool -genkeypair -v \
  -keystore ~/keystores/dtappmobile-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

- Choisir **un seul** mot de passe solide et le mettre dans un gestionnaire de mots de passe.
  `keytool` crée un trousseau au format PKCS12, qui n'admet pas de mot de passe de clé distinct :
  un second mot de passe est ignoré (vérifié avec Java 24 : « les mots de passe de clé et de banque
  distincts ne sont pas pris en charge pour les fichiers de clés d'accès PKCS12 »). Le renseigner
  donc **deux fois à l'identique** dans `key.properties`.
- Les questions d'identité (nom, organisation, pays) ne sont pas affichées aux utilisateurs :
  mettre par exemple `Djibouti Telecom` / `DT` / `DJ`.
- **Garder le `.jks` hors du dépôt** et en **sauvegarder une copie** ailleurs (autre disque,
  coffre). Avec Play App Signing, une clé d'envoi perdue se réinitialise via le support
  Google, mais c'est lent : mieux vaut ne pas la perdre.

Créer `android/key.properties` (le fichier est déjà dans `android/.gitignore`, ne pas le commiter) :

```properties
storePassword=<le mot de passe choisi>
keyPassword=<le même mot de passe>
keyAlias=upload
storeFile=/Users/<votre-utilisateur>/keystores/dtappmobile-upload.jks
```

Noter dès maintenant les empreintes de la clé d'envoi (utiles à l'étape 5 pour tester une release en local) :

```bash
keytool -list -v -keystore ~/keystores/dtappmobile-upload.jks -alias upload | grep -i "SHA"
```

## Étape 2 — Construire le bundle signé

```bash
flutter build appbundle --release
```

Résultat : `build/app/outputs/bundle/release/app-release.aab`.

**Vérifier la signature avant d'envoyer** — le propriétaire ne doit PAS être « Android Debug » :

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | head -5
```

⚠️ Incrémenter le numéro de build dans `pubspec.yaml` à **chaque** envoi
(`version: 1.0.0+2` → `+3`…) : Google Play refuse un `versionCode` déjà utilisé.

## Étape 3 — Créer l'app dans la Play Console

[play.google.com/console](https://play.google.com/console) → Créer une application :

- Nom : **DJIBTEL**, langue par défaut : français
- Activer **Play App Signing** (par défaut pour une nouvelle app) : Google conserve la clé
  de signature finale, vous n'envoyez que des bundles signés avec la clé d'envoi.
- Envoyer le `.aab` d'abord sur la piste **Test interne**, la plus rapide à mettre à disposition.

## Étape 4 — Déclarations obligatoires (Play Console → Contenu de l'application)

- **Politique de confidentialité** : une **URL publique** est exigée (l'app n'a que des écrans internes).
- **Sécurité des données (Data safety)** : l'app manipule le numéro de téléphone, les contacts
  (`READ_CONTACTS`), la position (carte des agences), un jeton de notification et des données
  de transaction. À déclarer fidèlement, en cohérence avec la politique de confidentialité.
- **Suppression de compte** : Google exige, pour les apps qui permettent de créer un compte,
  un moyen de supprimer le compte (dans l'app et par une URL web). À valider avec
  Djibouti Telecom : la connexion se fait par numéro + OTP, avec profil et PIN.
- **Accès à l'application** : la connexion exige un OTP SMS → fournir aux relecteurs un
  **numéro de test avec un OTP fixe** (à prévoir côté backend), sinon la review bloque.
- Classification du contenu, public cible, fiche (description, captures, icône 512×512, image 1024×500).

## Étape 5 — Enregistrer les empreintes de signature

Une fois le premier bundle envoyé : Play Console → **Configuration → Intégrité de l'application →
Signature d'application**. Relever les empreintes **SHA-1 et SHA-256** de :

- la **clé de signature d'application** (celle que verront les utilisateurs) ;
- la **clé d'envoi** (utile pour les builds de release testés en local).

Puis les déclarer :

1. **Google Cloud Console → API et services → Identifiants → la clé « Maps SDK for Android »**
   (celle de `AndroidManifest.xml`, restreinte par nom de package + SHA-1) : ajouter le SHA-1 de
   la clé de signature d'application et celui de la clé d'envoi. **Sans cela, la carte des
   agences s'affiche vide en production.** Vérifier aussi que la clé iOS (`AppDelegate.swift`)
   est restreinte au bundle ID `com.djiboutitelecom.dtappmobile`.
2. **Console Firebase → Paramètres du projet → app Android** : ajouter les mêmes empreintes
   (SHA-1 et SHA-256), notamment pour App Check (Play Integrity) si vous l'activez.

## Étape 6 — Hash SMS de production (autofill de l'OTP)

L'autofill Android ne remet le SMS à l'app **que s'il se termine par le hash de 11 caractères
de la signature de l'app**. Ce hash dépend du certificat : celui de la production (Play App
Signing) **n'est pas** celui du debug (`+p+NperHHd8`). Le backend (SMS DjibTel) doit utiliser le
bon.

L'app ne l'écrit qu'en debug : on le **calcule** à partir du certificat de signature d'application.
Play Console → Signature d'application → **Télécharger le certificat** (`.der`), puis :

```bash
PKG=com.djiboutitelecom.dtappmobile
CERT=~/Downloads/deployment_cert.der   # le fichier téléchargé

HEX=$(xxd -p "$CERT" | tr -d '[:space:]')
echo -n "$PKG $HEX" | shasum -a 256 | cut -d' ' -f1 | xxd -r -p | base64 | cut -c1-11
```

(Méthode vérifiée : appliquée au certificat de `android/app/debug.keystore`, elle redonne bien
`+p+NperHHd8`. Si le fichier téléchargé est un `.pem`, le convertir d'abord :
`openssl x509 -in cert.pem -outform der -out cert.der`.)

Format attendu du SMS (une ligne, 140 octets maximum) :

```
<#> Votre code DjibTel est 123456
<hash de production>
```

**À tester sur un téléphone réel**, avec l'app installée depuis la piste de test interne et un
SMS contenant le bon hash : le code doit se remplir seul. Sans permission SMS, c'est le
comportement attendu ; si ce n'était pas le cas, remonter le problème avant de publier.

## Étape 7 — Test avant production

- Installer depuis la piste **Test interne** et tester la **release** : connexion OTP, autofill,
  PIN, biométrie, achat, recharge, notifications push, carte des agences, test de débit.
- Lire le rapport **Pre-launch** de la Play Console (plantages, accessibilité, sécurité).
- Promouvoir vers la production. Les comptes développeur **personnels** récents doivent d'abord
  faire un test fermé (testeurs et durée minimums) ; les comptes d'organisation en sont en
  principe exemptés. Vérifier les exigences affichées dans votre Play Console.

## Après la publication

- Le lien de la fiche est déjà celui renvoyé par `/api/mobile/app-version` pour Android.
- Pour pousser une mise à jour : monter `latest_version` (proposée) ou `min_version`
  (bloquante) côté serveur.
