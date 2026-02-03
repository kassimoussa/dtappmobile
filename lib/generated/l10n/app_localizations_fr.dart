// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'DTServices';

  @override
  String get home => 'Accueil';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get myProfile => 'Mon Profil';

  @override
  String get logoutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get logoutAction => 'Déconnecter';

  @override
  String get logoutError => 'Erreur lors de la déconnexion';

  @override
  String welcomeMessage(String phoneNumber) {
    return 'Bienvenue, $phoneNumber';
  }

  @override
  String get mainAccount => 'Compte Principal';

  @override
  String get bonusBalance => 'Solde Bonus';

  @override
  String expiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String get buyPackage => 'Achat de\nforfait';

  @override
  String get creditRefill => 'Recharge\nde crédit';

  @override
  String get myPackages => 'Mes\nforfaits';

  @override
  String get creditTransfer => 'Transfert\nde crédit';

  @override
  String get ourAgencies => 'Nos\nagences';

  @override
  String get speedTest => 'Speed\nTest';

  @override
  String get personalInfo => 'Informations personnelles';

  @override
  String get accountInfo => 'Informations du compte';

  @override
  String get preferences => 'Préférences';

  @override
  String get managePin => 'Gestion du code PIN';

  @override
  String get changeLanguage => 'Changer la langue';

  @override
  String get connectionSettings => 'Paramètre de connexion';

  @override
  String get biometricLogin => 'Connexion par empreinte digitale';

  @override
  String get pinLogin => 'Connexion par code PIN';

  @override
  String get otpLogin => 'OTP';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get save => 'Enregistrer';

  @override
  String get nameLabel => 'Nom complet';

  @override
  String get nameHint => 'Entrez votre nom';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'exemple@email.com';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get lastLogin => 'Dernière connexion';

  @override
  String get accountCreated => 'Compte créé le';

  @override
  String get deviceType => 'Type d\'appareil';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get profileLoadError => 'Erreur lors du chargement du profil';

  @override
  String get updateError => 'Erreur lors de la mise à jour';

  @override
  String get saveError => 'Erreur lors de la sauvegarde';

  @override
  String get nameValidationError =>
      'Le nom doit contenir au moins 2 caractères';

  @override
  String get emailValidationError => 'Veuillez saisir un email valide';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get loadingProfile => 'Chargement du profil...';

  @override
  String get profileUpdateSuccess => 'Profil mis à jour avec succès';

  @override
  String get defaultUser => 'Utilisateur';

  @override
  String get otpSendError => 'Erreur lors de l\'envoi du code OTP';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get loginPrompt => 'Connectez-vous avec votre numéro';

  @override
  String get savedPhoneNumber => 'Numéro de téléphone sauvegardé';

  @override
  String get phoneValidationError => 'Veuillez saisir votre numéro';

  @override
  String get phoneLengthError => 'Le numéro doit contenir 8 chiffres';

  @override
  String get phoneStartError => 'Le numéro doit commencer par 77';

  @override
  String get continueAction => 'Continuer';

  @override
  String get smsVerificationMessage =>
      'Un code de vérification vous sera envoyé par SMS';

  @override
  String get otpResentSuccess => 'Un nouveau code a été envoyé';

  @override
  String get otpResentError => 'Erreur lors du réenvoi du code';

  @override
  String get otpInvalid => 'Code OTP incorrect';

  @override
  String get verificationTitle => 'Vérification';

  @override
  String verificationCodeSentTo(Object phone) {
    return 'Un code a été envoyé au $phone';
  }

  @override
  String get verifyAction => 'Vérifier';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String resendCodeTimer(Object seconds) {
    return 'Renvoyer le code (${seconds}s)';
  }

  @override
  String get transferTitle => 'Transfert de crédit';

  @override
  String get recipientLabel => 'Numéro destinataire';

  @override
  String get amountLabel => 'Montant à transférer';

  @override
  String get amountHint => 'Ex: 1000';

  @override
  String get amountInvalid => 'Montant invalide';

  @override
  String get amountPositive => 'Le montant doit être supérieur à 0';

  @override
  String get amountMinimum => 'Montant minimum : 50 DJF';

  @override
  String insufficientBalance(Object total) {
    return 'Solde insuffisant (total avec frais: $total DJF)';
  }

  @override
  String get selfTransferError =>
      'Vous ne pouvez pas vous transférer de l\'argent';

  @override
  String get recipientRequired => 'Veuillez entrer un numéro de destinataire';

  @override
  String get confirmTransfer => 'Confirmer le transfert';

  @override
  String get transferConfirmationTitle => 'Confirmation de transfert';

  @override
  String get checkTransferDetails => 'Vérifiez les détails du transfert';

  @override
  String get fromLabel => 'De';

  @override
  String get toLabel => 'Vers';

  @override
  String get amountKey => 'Montant';

  @override
  String get feesKey => 'Frais (5%)';

  @override
  String get totalDebit => 'Total à débiter';

  @override
  String get dateKey => 'Date';

  @override
  String currentBalanceFormat(String balance) {
    return 'Solde actuel: $balance DJF';
  }

  @override
  String balanceAfterTransferFormat(String balance) {
    return 'Solde après transfert: $balance DJF';
  }

  @override
  String get transferWarning =>
      'Ce transfert est immédiat et irréversible. Vérifiez bien le numéro du destinataire.';

  @override
  String get cancelAction => 'Annuler';

  @override
  String get authFailed => 'Authentification échouée';

  @override
  String transferError(String error) {
    return 'Erreur lors du transfert: $error';
  }

  @override
  String get transferSuccessTitle => 'Transfert réussi';

  @override
  String transferSuccessMessage(Object recipient) {
    return 'Votre crédit a été transféré avec succès vers $recipient';
  }

  @override
  String get transferedAmount => 'Montant transféré';

  @override
  String get transferFees => 'Frais de transfert';

  @override
  String get homeAction => 'Retour à l\'accueil';

  @override
  String autoRedirect(Object seconds) {
    return 'Redirection automatique dans $seconds s';
  }

  @override
  String get buyPackageTitle => 'Achat de forfait';

  @override
  String get internetClassique => 'Internet Classique';

  @override
  String get internetClassiqueDesc => 'Forfaits data pour naviguer';

  @override
  String get comboPackages => 'Forfaits Combo';

  @override
  String get comboPackagesDesc => 'Appels, SMS et Internet';

  @override
  String get tempoPackages => 'Tempo';

  @override
  String get tempoPackagesDesc => 'Minutes d\'appels week-end';

  @override
  String get newBadge => 'NOUVEAU';

  @override
  String get choosePackageHeader => 'Choisissez votre forfait';

  @override
  String get internetDesc =>
      'Sélectionnez l\'un de nos forfaits internet pour rester connecté.';

  @override
  String get comboDesc =>
      'Profitez d\'appels, SMS et data avec nos forfaits tout-en-un.';

  @override
  String get tempoDesc =>
      'Forfaits spéciaux avec minutes d\'appels pour le week-end.';

  @override
  String get defaultPackageDesc => 'Choisissez le forfait qui vous convient.';

  @override
  String get emptyTempoTitle => 'Aucun forfait Tempo';

  @override
  String get emptyTempoDesc => 'Les forfaits Tempo seront bientôt disponibles';

  @override
  String get recipientSelectionTitle => 'Choisir le destinataire';

  @override
  String get myNumber => 'Mon numéro';

  @override
  String get otherNumber => 'Autre numéro';

  @override
  String get buyFor => 'Acheter pour';

  @override
  String get enterNumberTitle => 'Saisir le numéro';

  @override
  String get enterNumberLabel => 'Entrez le numéro de téléphone';

  @override
  String get djiboutiNumberRequired => 'Numéro mobile valide à Djibouti requis';

  @override
  String get purchaseConfirmationTitle => 'Confirmation d\'achat';

  @override
  String get purchaseForMyNumber => 'Achat pour mon numéro';

  @override
  String get giftPurchase => 'Achat cadeau';

  @override
  String validFor(Object validity) {
    return 'Valide pendant $validity';
  }

  @override
  String get priceLabel => 'Prix';

  @override
  String get internetLabel => 'Internet';

  @override
  String get callsLabel => 'Appels';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get smsLabel => 'SMS';

  @override
  String get validityLabel => 'Validité';

  @override
  String get weekendValidity => 'Week-end';

  @override
  String currentBalanceFDJ(Object amount) {
    return 'Solde actuel: $amount FDJ';
  }

  @override
  String balanceAfterPurchaseFDJ(Object amount) {
    return 'Solde après achat: $amount FDJ';
  }

  @override
  String get lowBalanceWarning => 'Solde faible après achat';

  @override
  String get confirmPurchase => 'Confirmer l\'achat';

  @override
  String get purchaseSuccessTitle => 'Achat réussi';

  @override
  String purchaseSuccessMessage(Object name) {
    return 'Votre forfait $name a été activé avec succès';
  }

  @override
  String get packageLabel => 'Package';

  @override
  String get newBalance => 'Nouveau solde';

  @override
  String get purchaseError => 'Erreur lors de l\'achat';

  @override
  String get refillTitle => 'Recharge de crédit';

  @override
  String get refillGiftTitle => 'Recharge cadeau';

  @override
  String get refillMyCredit => 'Recharger mon crédit';

  @override
  String refillRecipient(String phone) {
    return 'Destinataire : $phone';
  }

  @override
  String refillMyNumber(String phone) {
    return 'Mon numéro : $phone';
  }

  @override
  String get refillCodeLabel => 'Code de recharge';

  @override
  String get refillCodeLengthError =>
      'Le code doit contenir exactement 12 chiffres';

  @override
  String get refillCodeDigitError =>
      'Le code ne doit contenir que des chiffres';

  @override
  String get howToUseCode => 'Comment utiliser votre code';

  @override
  String get refillInstructions =>
      '• Grattez la carte pour révéler le code à 12 chiffres\n• Saisissez le code complet sans espaces ni tirets\n• Le crédit sera ajouté immédiatement après validation\n• Chaque code ne peut être utilisé qu\'une seule fois';

  @override
  String get confirmRefill => 'Confirmer la recharge';

  @override
  String get refillSuccessTitle => 'Recharge réussie !';

  @override
  String refillSuccessMessageGift(String phone) {
    return 'La recharge a été effectuée avec succès pour $phone';
  }

  @override
  String get refillSuccessMessageMine =>
      'Votre crédit a été rechargé avec succès';

  @override
  String get refillAmount => 'Montant rechargé';

  @override
  String refillNewBalance(String balance) {
    return 'Nouveau solde : $balance DJF';
  }

  @override
  String get closeAction => 'Fermer';

  @override
  String refillFor(Object phone) {
    return 'Recharge pour $phone';
  }

  @override
  String refillForMyNumberMessage(Object phone) {
    return 'Recharge pour mon numéro: $phone';
  }

  @override
  String get buyAction => 'Acheter';

  @override
  String get insufficientBalanceSimple => 'Solde insuffisant';

  @override
  String get insufficientBalanceForPurchase =>
      'Solde insuffisant pour cet achat.';

  @override
  String get popularBadge => 'Populaire';

  @override
  String get noData => 'Aucune data';

  @override
  String get genericRetryError =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get buyAPackage => 'Acheter un forfait';

  @override
  String validityHours(Object hours) {
    return '${hours}h';
  }

  @override
  String validityDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get validityWeekendLong => 'Du Vendredi 07h00 au Dimanche 07h00';

  @override
  String get myPackagesTitle => 'Mes Forfaits';

  @override
  String get loadingPackages => 'Chargement des forfaits...';

  @override
  String get serverUnavailable =>
      'Le serveur est temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get retry => 'Réessayer';

  @override
  String get noActivePackages => 'Vous n\'avez aucun forfait actif';

  @override
  String get buyPackageToStart =>
      'Achetez un forfait pour commencer à utiliser nos services!';

  @override
  String get consumptionResume => 'Résumé de consommation';

  @override
  String get internetData => 'Données Internet';

  @override
  String get lastUpdateSeconds => 'il y a quelques secondes';

  @override
  String lastUpdateMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'il y a $count minute$_temp0';
  }

  @override
  String lastUpdateHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'il y a $count heure$_temp0';
  }

  @override
  String lastUpdateDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'il y a $count jour$_temp0';
  }

  @override
  String lastUpdateLabel(Object time) {
    return 'Dernière mise à jour $time';
  }

  @override
  String get loadingDetails => 'Chargement des détails...';

  @override
  String refreshError(Object error) {
    return 'Impossible de rafraîchir les données: $error';
  }

  @override
  String get packageNotFound => 'Forfait introuvable';

  @override
  String get packageNotFoundDesc =>
      'Ce forfait n\'existe pas ou n\'est plus disponible';

  @override
  String get back => 'Retour';

  @override
  String get comboPackage => 'Forfait Combo';

  @override
  String get internetPackage => 'Forfait Internet';

  @override
  String get purchaseDate => 'Date d\'achat:';

  @override
  String get expirationDate => 'Date d\'expiration:';

  @override
  String remainingOf(Object remaining, Object total) {
    return '$remaining restants / $total';
  }

  @override
  String remainingOfMinutes(Object remaining, Object total) {
    return '$remaining restantes / $total';
  }

  @override
  String get consumption => 'Consommation';

  @override
  String get used => 'Utilisé';

  @override
  String get remaining => 'Restant';

  @override
  String get total => 'Total';

  @override
  String get speedTestTitle => 'Test de vitesse';

  @override
  String get startTest => 'LANCER LE TEST';

  @override
  String get testingInProgress => 'Test en cours...';

  @override
  String get phaseIdle => 'Prêt à tester';

  @override
  String get phasePing => 'Test du ping...';

  @override
  String get phaseDownload => 'Test de téléchargement...';

  @override
  String get phaseUpload => 'Test d\'upload...';

  @override
  String get phaseDone => 'Test terminé';

  @override
  String get downloadLabel => 'Download';

  @override
  String get uploadLabel => 'Upload';

  @override
  String get pingLabel => 'Ping';

  @override
  String speedTestError(Object error) {
    return 'Erreur: $error';
  }

  @override
  String get agenciesTitle => 'Nos Agences';

  @override
  String get loadingAgencies => 'Chargement des agences...';

  @override
  String get noAgencies => 'Aucune agence disponible';

  @override
  String get call => 'Appeler';

  @override
  String get directions => 'Itinéraire';

  @override
  String get openingHours => 'Horaires d\'ouverture';

  @override
  String get launchPhoneError =>
      'Impossible de lancer l\'application téléphone.';

  @override
  String get invalidPhone => 'Numéro de téléphone invalide.';

  @override
  String get launchMapError => 'Impossible de lancer Google Maps.';

  @override
  String get mapView => 'Vue carte';

  @override
  String get listView => 'Vue liste';

  @override
  String get subscribe => 'Souscrire';

  @override
  String get logoutTopUpSuccess => 'Déconnexion TopUp réussie';

  @override
  String logoutConfirmMessage(String number) {
    return 'Voulez-vous vous déconnecter de la ligne $number ?';
  }

  @override
  String get manualTest => 'Test Manuel';

  @override
  String get batchTest => 'Tests Batch';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get myLineTitle => 'Ma ligne';

  @override
  String get historyTitle => 'Historique';

  @override
  String get statisticsTooltip => 'Statistiques';

  @override
  String get periodLabel => 'Période';

  @override
  String daysUnit(int days) {
    return '${days}j';
  }

  @override
  String activitiesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités trouvées',
      one: '1 activité trouvée',
      zero: 'Aucune activité trouvée',
    );
    return '$_temp0';
  }

  @override
  String get historyLoading => 'Chargement de l\'historique...';

  @override
  String get historyLoadError => 'Erreur lors du chargement de l\'historique';

  @override
  String get loadingErrorTitle => 'Erreur de chargement';

  @override
  String get emptyHistoryTitle => 'Aucune activité';

  @override
  String get emptyHistoryMessage =>
      'Aucune activité trouvée pour la période sélectionnée';

  @override
  String get toggleHideDetails => 'Masquer les détails';

  @override
  String get toggleShowDetails => 'Afficher plus de détails';

  @override
  String get navHome => 'Accueil';

  @override
  String get navHistory => 'Historique';

  @override
  String get navMyLine => 'Ma ligne';

  @override
  String get historyTransactions => 'Historique des transactions';

  @override
  String get comingSoonMessage =>
      'Cette fonctionnalité sera bientôt disponible.';

  @override
  String get ok => 'OK';

  @override
  String get packageSubscriptionPurchase => 'Achat de souscription TopUp';

  @override
  String get packageTopUpPurchase => 'Achat de package TopUp';

  @override
  String get dataSubscription => 'Souscription données';

  @override
  String get voiceSubscription => 'Souscription voix';

  @override
  String get dataPackageAddon => 'Package données additionnel';

  @override
  String get voicePackageAddon => 'Package voix additionnel';

  @override
  String get insufficientBalanceError => 'Solde insuffisant pour cet achat.';

  @override
  String get subscriptionError => 'Erreur lors de la souscription au package';

  @override
  String get connectionError => 'Erreur de connexion';

  @override
  String get unexpectedError => 'Erreur inattendue';

  @override
  String get confirmPurchaseTitle => 'Confirmation d\'achat';

  @override
  String get packageCode => 'Code du package';

  @override
  String get price => 'Prix';

  @override
  String get validity => 'Validité';

  @override
  String get content => 'Contenu';

  @override
  String get days => 'jours';

  @override
  String get currentBalance => 'Solde actuel';

  @override
  String get balanceAfterPurchase => 'Solde après achat';

  @override
  String get fixedLineRecipient => 'Ligne fixe destinataire';

  @override
  String get fromMobile => 'Depuis votre mobile';

  @override
  String get confirmPurchaseAction => 'Confirmer l\'achat';

  @override
  String get rechargeTitle => 'Recharger compte fixe';

  @override
  String get rechargeSubtitle => 'Recharge de compte';

  @override
  String get rechargeDescription =>
      'Transférez du crédit de votre mobile vers votre ligne fixe';

  @override
  String get mobileSource => 'Mobile (source)';

  @override
  String get fixedDestination => 'Fixe (destination)';

  @override
  String get mobileBalanceAvailable => 'Solde mobile disponible';

  @override
  String get quickAmounts => 'Montants rapides';

  @override
  String get amountToTransfer => 'Montant à transférer *';

  @override
  String get pinCode => 'Code PIN (optionnel)';

  @override
  String get pinDefaultInfo =>
      'Si non renseigné, le code par défaut (0000) sera utilisé';

  @override
  String get pinError => 'Le code PIN doit contenir 4 chiffres';

  @override
  String get performRecharge => 'Effectuer la recharge';

  @override
  String get rechargeError => 'Erreur lors de la recharge';

  @override
  String get enterAmount => 'Veuillez saisir un montant';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get minAmount => 'Montant minimum: 100 DJF';

  @override
  String get maxAmount => 'Montant maximum: 50 000 DJF';

  @override
  String insufficientBalanceGeneric(String amount) {
    return 'Solde insuffisant ($amount DJF)';
  }

  @override
  String get insufficientBalanceForRecharge =>
      'Solde insuffisant pour cette recharge.';

  @override
  String get activeSubscriptionTitle => 'Souscription active';

  @override
  String activeSubscriptionMessage(String type, String date) {
    return 'Vous avez déjà une souscription $type active qui expire le $date.';
  }

  @override
  String get replaceSubscriptionWarning =>
      'Acheter une nouvelle souscription remplacera l\'actuelle. Voulez-vous continuer ?';

  @override
  String get buySubscriptionTitle => 'Acheter une souscription';

  @override
  String get chooseSubscriptionType => 'Choisir le type de souscription';

  @override
  String get checkingActiveSubscriptions =>
      'Vérification des souscriptions actives...';

  @override
  String get dataType => 'Données';

  @override
  String get voiceType => 'Voix';

  @override
  String get dataSubscriptions => 'Souscriptions Données';

  @override
  String get voiceSubscriptions => 'Souscriptions Voix';

  @override
  String get subscriptionTypeData => 'données';

  @override
  String get subscriptionTypeVoice => 'voix';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get analysisPeriod => 'Période d\'analyse';

  @override
  String get statsOverview => 'Vue d\'ensemble';

  @override
  String get totalSpent => 'Total dépensé';

  @override
  String get totalActions => 'Actions totales';

  @override
  String get globalSuccessRate => 'Taux de succès global';

  @override
  String get actionDetails => 'Détail par action';

  @override
  String get successful => 'Réussis';

  @override
  String get amount => 'Montant';

  @override
  String get successRate => 'Taux de succès';

  @override
  String get transferImportantInfo => 'Informations importantes';

  @override
  String get transferMinAmountParams => '• Montant minimum : 50 DJF';

  @override
  String get transferFeesParams => '• Frais de transfert : 5% du montant';

  @override
  String transferCurrentBalance(String balance) {
    return '• Votre solde actuel : $balance DJF';
  }

  @override
  String get checkFixedLine => 'Consulter votre ligne fixe';

  @override
  String get enterFixedNumberInfo =>
      'Veuillez entrer votre numéro de ligne fixe pour consulter ses soldes';

  @override
  String get fixedLineNumberKey => 'Numéro de ligne fixe';

  @override
  String get fixedLineNumberHint => 'Ex: 21XXXXXX';

  @override
  String get fixedBalances => 'Soldes Fixes';

  @override
  String get consult => 'Consulter';

  @override
  String get consulting => 'Consultation...';

  @override
  String get consultingInProgress => 'Consultation des soldes en cours...';

  @override
  String get numberSuspended => 'Numéro suspendu';

  @override
  String get numberSuspendedInfo => 'Ce numéro est temporairement suspendu.';

  @override
  String get balancesConsultableOnly =>
      'Vous pouvez consulter les soldes mais les achats sont temporairement indisponibles.';

  @override
  String get understood => 'Compris';

  @override
  String get numberEligibleButBalancesUnavailable =>
      'Le numéro est éligible mais les soldes sont indisponibles. Réessayez plus tard.';

  @override
  String fixedLineNumberFormat(String number) {
    return 'Ligne: $number';
  }

  @override
  String get packagesUnavailable => 'Aucun package disponible';

  @override
  String packagesSoonAvailable(String type) {
    return 'Les packages $type seront bientôt disponibles pour cette ligne.';
  }

  @override
  String get choosePackageTitle => 'Choisissez votre package';

  @override
  String availablePackagesCount(int count, String type) {
    return '$count package(s) $type disponible(s) pour votre ligne fixe.';
  }

  @override
  String get availableStatus => 'Disponible';

  @override
  String get availability => 'Disponibilité';

  @override
  String get subscriptionLabel => 'Souscription';

  @override
  String get rechargeSuccessTitle => 'Recharge effectuée !';

  @override
  String get rechargeSuccessMessage =>
      'Votre recharge a été effectuée avec succès';

  @override
  String get transferAmount => 'Montant transféré';

  @override
  String get fromMobileSource => 'De (Mobile)';

  @override
  String get toFixedDestination => 'Vers (Fixe)';

  @override
  String get transactionId => 'ID Transaction';

  @override
  String get accountImpact => 'Impact sur vos comptes';

  @override
  String get newMobileBalance => 'Nouveau solde mobile';

  @override
  String get newFixedBalance => 'Nouveau solde fixe';

  @override
  String get returnHome => 'Retour accueil';

  @override
  String get newRecharge => 'Nouvelle recharge';

  @override
  String get topupPurchaseSuccess => 'Achat TopUp réussi !';

  @override
  String packageActivatedMessage(Object package) {
    return 'Le package $package a été activé avec succès sur votre ligne fixe';
  }

  @override
  String get fixedLineLabel => 'Ligne fixe';

  @override
  String get mobileLineLabel => 'Ligne mobile';

  @override
  String get subscriptionSuccessTitle => 'Souscription réussie';

  @override
  String get topupSubscriptionSuccess => 'Souscription TopUp réussie !';

  @override
  String subscriptionActivatedMessage(Object subscription) {
    return 'La souscription $subscription a été activée avec succès sur votre ligne fixe';
  }

  @override
  String get callsToFixed => 'Appels vers fixes';

  @override
  String get unlimited => 'Illimités';

  @override
  String subscriptionMonthlyActivated(Object number) {
    return 'La souscription mensuelle a été activée sur votre ligne fixe $number';
  }

  @override
  String packageActivatedFixed(Object number) {
    return 'Le package a été activé sur votre ligne fixe $number';
  }

  @override
  String get unknownStatus => 'Statut inconnu';

  @override
  String get money => 'Crédit';

  @override
  String get invalidNumber => 'Numéro invalide';

  @override
  String get numberNotFound => 'Ce numéro n\'existe pas dans le système.';

  @override
  String get biometricAuthPrompt => 'Authentifiez-vous pour vous connecter';

  @override
  String get biometricAuthError => 'Erreur d\'authentification biométrique';

  @override
  String get chooseConnectionMethod => 'Choisir une méthode de connexion';

  @override
  String get smsCodeOtp => 'Code SMS (OTP)';

  @override
  String get loginWithFingerprint => 'Se connecter avec empreinte';

  @override
  String get loginWithPin => 'Se connecter avec PIN';

  @override
  String get loginWithSms => 'Se connecter avec SMS';

  @override
  String get otherConnectionMethod => 'Autre méthode de connexion';

  @override
  String get forgotPin => 'PIN oublié ?';

  @override
  String get hello => 'Bonjour !';

  @override
  String get setupPinTitle => 'Configurer un code PIN';

  @override
  String get setupPinMessage =>
      'Voulez-vous créer un code PIN pour vous connecter plus rapidement la prochaine fois ?';

  @override
  String get later => 'Plus tard';

  @override
  String get setup => 'Configurer';

  @override
  String get loading => 'Chargement en cours...';

  @override
  String get pinLoginTitle => 'Connexion PIN';

  @override
  String remainingAttempts(Object count) {
    return '$count tentative(s) restante(s)';
  }

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Réessayez dans $minutes min $seconds sec';
  }

  @override
  String get skip => 'Passer';

  @override
  String get confirmPinTitle => 'Confirmez votre code PIN';

  @override
  String get createPinTitle => 'Créez un code PIN';

  @override
  String get confirmPinMessage => 'Entrez votre PIN une seconde fois';

  @override
  String get createPinMessage =>
      'Créez un code à 4 chiffres pour vous connecter rapidement';

  @override
  String get pinsDoNotMatch => 'Les codes PIN ne correspondent pas';

  @override
  String get resetInfoMissing =>
      'Erreur: informations manquantes pour la réinitialisation';

  @override
  String get pinResetSuccess => 'Code PIN réinitialisé avec succès !';

  @override
  String get pinSetupSuccess => 'Code PIN configuré avec succès !';

  @override
  String get otpExpiredTitle => 'Code OTP expiré';

  @override
  String get otpExpiredMessage =>
      'Le code OTP a expiré. Vous devez obtenir un nouveau code pour réinitialiser votre PIN.';

  @override
  String get getNewCode => 'Obtenir un nouveau code';

  @override
  String get resetPinTitle => 'Réinitialiser le PIN';

  @override
  String get genericError => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get errorTitle => 'Erreur';

  @override
  String get howItWorks => 'Comment ça marche ?';

  @override
  String get resetStep1 =>
      'Nous allons vous envoyer un code de vérification par SMS';

  @override
  String get resetStep2 => 'Entrez le code reçu pour vérifier votre identité';

  @override
  String get resetStep3 => 'Créez un nouveau code PIN sécurisé';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get enterReceivedCode => 'Entrez le code reçu';

  @override
  String codeSentTo(Object number) {
    return 'Un code à 6 chiffres a été envoyé au\n$number';
  }

  @override
  String get codeResentSuccess => 'Code renvoyé avec succès';

  @override
  String get continueText => 'Continuer';

  @override
  String get oldPinTitle => 'Ancien code PIN';

  @override
  String get oldPinMessage => 'Entrez votre code PIN actuel';

  @override
  String get newPinTitle => 'Nouveau code PIN';

  @override
  String get newPinMessage => 'Créez un nouveau code à 4 chiffres';

  @override
  String get changePinTitle => 'Modifier le code PIN';

  @override
  String get newPinsDoNotMatch => 'Les nouveaux codes PIN ne correspondent pas';

  @override
  String get newPinMustBeDifferent =>
      'Le nouveau PIN doit être différent de l\'ancien';

  @override
  String get pinChangedSuccess => 'Code PIN modifié avec succès !';

  @override
  String get pinManagementTitle => 'Gestion du code PIN';

  @override
  String get forgotPinOption => 'Code PIN oublié';

  @override
  String get phoneNotFound => 'Numéro de téléphone introuvable';
}
