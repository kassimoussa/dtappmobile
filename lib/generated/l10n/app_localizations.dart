import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Titre de l'application
  ///
  /// In fr, this message translates to:
  /// **'DTServices'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get myProfile;

  /// No description provided for @logoutConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get logoutConfirmation;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @logoutAction.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get logoutAction;

  /// No description provided for @logoutError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la déconnexion'**
  String get logoutError;

  /// No description provided for @welcomeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, {phoneNumber}'**
  String welcomeMessage(String phoneNumber);

  /// No description provided for @mainAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte Principal'**
  String get mainAccount;

  /// No description provided for @bonusBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde Bonus'**
  String get bonusBalance;

  /// No description provided for @expiresOn.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String expiresOn(String date);

  /// No description provided for @buyPackage.
  ///
  /// In fr, this message translates to:
  /// **'Achat de\nforfait'**
  String get buyPackage;

  /// No description provided for @creditRefill.
  ///
  /// In fr, this message translates to:
  /// **'Recharge\nde crédit'**
  String get creditRefill;

  /// No description provided for @myPackages.
  ///
  /// In fr, this message translates to:
  /// **'Mes\nforfaits'**
  String get myPackages;

  /// No description provided for @creditTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert\nde crédit'**
  String get creditTransfer;

  /// No description provided for @ourAgencies.
  ///
  /// In fr, this message translates to:
  /// **'Nos\nagences'**
  String get ourAgencies;

  /// No description provided for @speedTest.
  ///
  /// In fr, this message translates to:
  /// **'Speed\nTest'**
  String get speedTest;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @accountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get accountInfo;

  /// No description provided for @preferences.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get preferences;

  /// No description provided for @changeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get changeLanguage;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @nameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nom'**
  String get nameHint;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'exemple@email.com'**
  String get emailHint;

  /// No description provided for @phoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneNumber;

  /// No description provided for @lastLogin.
  ///
  /// In fr, this message translates to:
  /// **'Dernière connexion'**
  String get lastLogin;

  /// No description provided for @accountCreated.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé le'**
  String get accountCreated;

  /// No description provided for @deviceType.
  ///
  /// In fr, this message translates to:
  /// **'Type d\'appareil'**
  String get deviceType;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @profileLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement du profil'**
  String get profileLoadError;

  /// No description provided for @updateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour'**
  String get updateError;

  /// No description provided for @saveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde'**
  String get saveError;

  /// No description provided for @nameValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 2 caractères'**
  String get nameValidationError;

  /// No description provided for @emailValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un email valide'**
  String get emailValidationError;

  /// No description provided for @notAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible'**
  String get notAvailable;

  /// No description provided for @loadingProfile.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du profil...'**
  String get loadingProfile;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profileUpdateSuccess;

  /// No description provided for @defaultUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get defaultUser;

  /// No description provided for @otpSendError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi du code'**
  String get otpSendError;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @loginPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous avec votre numéro'**
  String get loginPrompt;

  /// No description provided for @savedPhoneNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone sauvegardé'**
  String get savedPhoneNumber;

  /// No description provided for @phoneValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre numéro'**
  String get phoneValidationError;

  /// No description provided for @phoneLengthError.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro doit contenir 8 chiffres'**
  String get phoneLengthError;

  /// No description provided for @phoneStartError.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro doit commencer par 77'**
  String get phoneStartError;

  /// No description provided for @continueAction.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueAction;

  /// No description provided for @smsVerificationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un code de vérification vous sera envoyé par SMS'**
  String get smsVerificationMessage;

  /// No description provided for @otpResentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Un nouveau code a été envoyé'**
  String get otpResentSuccess;

  /// No description provided for @otpResentError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du réenvoi du code'**
  String get otpResentError;

  /// No description provided for @otpInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code OTP incorrect'**
  String get otpInvalid;

  /// No description provided for @verificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get verificationTitle;

  /// No description provided for @verificationCodeSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Un code a été envoyé au {phone}'**
  String verificationCodeSentTo(Object phone);

  /// No description provided for @verifyAction.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get verifyAction;

  /// No description provided for @resendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// No description provided for @resendCodeTimer.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code ({seconds}s)'**
  String resendCodeTimer(Object seconds);

  /// No description provided for @transferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transfert de crédit'**
  String get transferTitle;

  /// No description provided for @recipientLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro destinataire'**
  String get recipientLabel;

  /// No description provided for @amountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Montant à transférer'**
  String get amountLabel;

  /// No description provided for @amountHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 1000'**
  String get amountHint;

  /// No description provided for @amountInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get amountInvalid;

  /// No description provided for @amountPositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être supérieur à 0'**
  String get amountPositive;

  /// No description provided for @amountMinimum.
  ///
  /// In fr, this message translates to:
  /// **'Montant minimum : 50 DJF'**
  String get amountMinimum;

  /// No description provided for @insufficientBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant (total avec frais: {total} DJF)'**
  String insufficientBalance(Object total);

  /// No description provided for @selfTransferError.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas vous transférer de l\'argent'**
  String get selfTransferError;

  /// No description provided for @recipientRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un numéro de destinataire'**
  String get recipientRequired;

  /// No description provided for @confirmTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le transfert'**
  String get confirmTransfer;

  /// No description provided for @transferConfirmationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation de transfert'**
  String get transferConfirmationTitle;

  /// No description provided for @checkTransferDetails.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les détails du transfert'**
  String get checkTransferDetails;

  /// No description provided for @fromLabel.
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get toLabel;

  /// No description provided for @amountKey.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amountKey;

  /// No description provided for @feesKey.
  ///
  /// In fr, this message translates to:
  /// **'Frais (5%)'**
  String get feesKey;

  /// No description provided for @totalDebit.
  ///
  /// In fr, this message translates to:
  /// **'Total à débiter'**
  String get totalDebit;

  /// No description provided for @dateKey.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get dateKey;

  /// No description provided for @currentBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel: {balance} DJF'**
  String currentBalance(Object balance);

  /// No description provided for @balanceAfterTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Solde après transfert: {balance} DJF'**
  String balanceAfterTransfer(Object balance);

  /// No description provided for @transferWarning.
  ///
  /// In fr, this message translates to:
  /// **'Ce transfert est immédiat et irréversible. Vérifiez bien le numéro du destinataire.'**
  String get transferWarning;

  /// No description provided for @cancelAction.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelAction;

  /// No description provided for @authFailed.
  ///
  /// In fr, this message translates to:
  /// **'Authentification échouée'**
  String get authFailed;

  /// No description provided for @transferError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du transfert: {error}'**
  String transferError(Object error);

  /// No description provided for @transferSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transfert réussi'**
  String get transferSuccessTitle;

  /// No description provided for @transferSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre crédit a été transféré avec succès vers {recipient}'**
  String transferSuccessMessage(Object recipient);

  /// No description provided for @transferedAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant transféré'**
  String get transferedAmount;

  /// No description provided for @transferFees.
  ///
  /// In fr, this message translates to:
  /// **'Frais de transfert'**
  String get transferFees;

  /// No description provided for @homeAction.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get homeAction;

  /// No description provided for @autoRedirect.
  ///
  /// In fr, this message translates to:
  /// **'Redirection automatique dans {seconds} s'**
  String autoRedirect(Object seconds);

  /// No description provided for @buyPackageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achat de forfait'**
  String get buyPackageTitle;

  /// No description provided for @internetClassique.
  ///
  /// In fr, this message translates to:
  /// **'Internet Classique'**
  String get internetClassique;

  /// No description provided for @internetClassiqueDesc.
  ///
  /// In fr, this message translates to:
  /// **'Forfaits data pour naviguer'**
  String get internetClassiqueDesc;

  /// No description provided for @comboPackages.
  ///
  /// In fr, this message translates to:
  /// **'Forfaits Combo'**
  String get comboPackages;

  /// No description provided for @comboPackagesDesc.
  ///
  /// In fr, this message translates to:
  /// **'Appels, SMS et Internet'**
  String get comboPackagesDesc;

  /// No description provided for @tempoPackages.
  ///
  /// In fr, this message translates to:
  /// **'Tempo'**
  String get tempoPackages;

  /// No description provided for @tempoPackagesDesc.
  ///
  /// In fr, this message translates to:
  /// **'Minutes d\'appels week-end'**
  String get tempoPackagesDesc;

  /// No description provided for @newBadge.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU'**
  String get newBadge;

  /// No description provided for @choosePackageHeader.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre forfait'**
  String get choosePackageHeader;

  /// No description provided for @internetDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez l\'un de nos forfaits internet pour rester connecté.'**
  String get internetDesc;

  /// No description provided for @comboDesc.
  ///
  /// In fr, this message translates to:
  /// **'Profitez d\'appels, SMS et data avec nos forfaits tout-en-un.'**
  String get comboDesc;

  /// No description provided for @tempoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Forfaits spéciaux avec minutes d\'appels pour le week-end.'**
  String get tempoDesc;

  /// No description provided for @defaultPackageDesc.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le forfait qui vous convient.'**
  String get defaultPackageDesc;

  /// No description provided for @emptyTempoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun forfait Tempo'**
  String get emptyTempoTitle;

  /// No description provided for @emptyTempoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les forfaits Tempo seront bientôt disponibles'**
  String get emptyTempoDesc;

  /// No description provided for @recipientSelectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le destinataire'**
  String get recipientSelectionTitle;

  /// No description provided for @myNumber.
  ///
  /// In fr, this message translates to:
  /// **'Mon numéro'**
  String get myNumber;

  /// No description provided for @otherNumber.
  ///
  /// In fr, this message translates to:
  /// **'Autre numéro'**
  String get otherNumber;

  /// No description provided for @buyFor.
  ///
  /// In fr, this message translates to:
  /// **'Acheter pour'**
  String get buyFor;

  /// No description provided for @enterNumberTitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le numéro'**
  String get enterNumberTitle;

  /// No description provided for @enterNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le numéro de téléphone'**
  String get enterNumberLabel;

  /// No description provided for @djiboutiNumberRequired.
  ///
  /// In fr, this message translates to:
  /// **'Numéro mobile valide à Djibouti requis'**
  String get djiboutiNumberRequired;

  /// No description provided for @purchaseConfirmationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation d\'achat'**
  String get purchaseConfirmationTitle;

  /// No description provided for @purchaseForMyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Achat pour mon numéro'**
  String get purchaseForMyNumber;

  /// No description provided for @giftPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat cadeau'**
  String get giftPurchase;

  /// No description provided for @validFor.
  ///
  /// In fr, this message translates to:
  /// **'Valide pendant {validity}'**
  String validFor(Object validity);

  /// No description provided for @priceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get priceLabel;

  /// No description provided for @internetLabel.
  ///
  /// In fr, this message translates to:
  /// **'Internet'**
  String get internetLabel;

  /// No description provided for @callsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Appels'**
  String get callsLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Minutes d\'appel'**
  String get minutesLabel;

  /// No description provided for @smsLabel.
  ///
  /// In fr, this message translates to:
  /// **'SMS'**
  String get smsLabel;

  /// No description provided for @validityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Validité'**
  String get validityLabel;

  /// No description provided for @weekendValidity.
  ///
  /// In fr, this message translates to:
  /// **'Week-end'**
  String get weekendValidity;

  /// No description provided for @currentBalanceFDJ.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel: {amount} FDJ'**
  String currentBalanceFDJ(Object amount);

  /// No description provided for @balanceAfterPurchaseFDJ.
  ///
  /// In fr, this message translates to:
  /// **'Solde après achat: {amount} FDJ'**
  String balanceAfterPurchaseFDJ(Object amount);

  /// No description provided for @lowBalanceWarning.
  ///
  /// In fr, this message translates to:
  /// **'Solde faible après achat'**
  String get lowBalanceWarning;

  /// No description provided for @confirmPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'achat'**
  String get confirmPurchase;

  /// No description provided for @purchaseSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Achat réussi'**
  String get purchaseSuccessTitle;

  /// No description provided for @purchaseSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre forfait {name} a été activé avec succès'**
  String purchaseSuccessMessage(Object name);

  /// No description provided for @packageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Forfait'**
  String get packageLabel;

  /// No description provided for @newBalance.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde'**
  String get newBalance;

  /// No description provided for @purchaseError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'achat'**
  String get purchaseError;

  /// No description provided for @refillTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recharge de crédit'**
  String get refillTitle;

  /// No description provided for @refillGiftTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recharge cadeau'**
  String get refillGiftTitle;

  /// No description provided for @refillMyCredit.
  ///
  /// In fr, this message translates to:
  /// **'Recharger mon crédit'**
  String get refillMyCredit;

  /// No description provided for @refillRecipient.
  ///
  /// In fr, this message translates to:
  /// **'Destinataire : {phone}'**
  String refillRecipient(Object phone);

  /// No description provided for @refillMyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Mon numéro : {phone}'**
  String refillMyNumber(Object phone);

  /// No description provided for @refillCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code de recharge'**
  String get refillCodeLabel;

  /// No description provided for @refillCodeLengthError.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit contenir exactement 12 chiffres'**
  String get refillCodeLengthError;

  /// No description provided for @refillCodeDigitError.
  ///
  /// In fr, this message translates to:
  /// **'Le code ne doit contenir que des chiffres'**
  String get refillCodeDigitError;

  /// No description provided for @howToUseCode.
  ///
  /// In fr, this message translates to:
  /// **'Comment utiliser votre code'**
  String get howToUseCode;

  /// No description provided for @refillInstructions.
  ///
  /// In fr, this message translates to:
  /// **'• Grattez la carte pour révéler le code à 12 chiffres\n• Saisissez le code complet sans espaces ni tirets\n• Le crédit sera ajouté immédiatement après validation\n• Chaque code ne peut être utilisé qu\'une seule fois'**
  String get refillInstructions;

  /// No description provided for @confirmRefill.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la recharge'**
  String get confirmRefill;

  /// No description provided for @refillSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recharge réussie !'**
  String get refillSuccessTitle;

  /// No description provided for @refillSuccessMessageGift.
  ///
  /// In fr, this message translates to:
  /// **'La recharge a été effectuée avec succès pour {phone}'**
  String refillSuccessMessageGift(Object phone);

  /// No description provided for @refillSuccessMessageMine.
  ///
  /// In fr, this message translates to:
  /// **'Votre crédit a été rechargé avec succès'**
  String get refillSuccessMessageMine;

  /// No description provided for @refillAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant rechargé'**
  String get refillAmount;

  /// No description provided for @refillNewBalance.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde : {balance} DJF'**
  String refillNewBalance(Object balance);

  /// No description provided for @closeAction.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeAction;

  /// No description provided for @refillFor.
  ///
  /// In fr, this message translates to:
  /// **'Recharge pour {phone}'**
  String refillFor(Object phone);

  /// No description provided for @refillForMyNumberMessage.
  ///
  /// In fr, this message translates to:
  /// **'Recharge pour mon numéro: {phone}'**
  String refillForMyNumberMessage(Object phone);

  /// No description provided for @unexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue: {error}'**
  String unexpectedError(Object error);

  /// No description provided for @buyAction.
  ///
  /// In fr, this message translates to:
  /// **'Acheter'**
  String get buyAction;

  /// No description provided for @insufficientBalanceSimple.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant'**
  String get insufficientBalanceSimple;

  /// No description provided for @insufficientBalanceForPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant pour cet achat.'**
  String get insufficientBalanceForPurchase;

  /// No description provided for @popularBadge.
  ///
  /// In fr, this message translates to:
  /// **'Populaire'**
  String get popularBadge;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune data'**
  String get noData;

  /// No description provided for @genericRetryError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get genericRetryError;

  /// No description provided for @buyAPackage.
  ///
  /// In fr, this message translates to:
  /// **'Acheter un forfait'**
  String get buyAPackage;

  /// No description provided for @validityHours.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h'**
  String validityHours(Object hours);

  /// No description provided for @validityDays.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{1 jour} other{{days} jours}}'**
  String validityDays(num days);

  /// No description provided for @validityWeekendLong.
  ///
  /// In fr, this message translates to:
  /// **'Du Vendredi 07h00 au Dimanche 07h00'**
  String get validityWeekendLong;

  /// No description provided for @myPackagesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Forfaits'**
  String get myPackagesTitle;

  /// No description provided for @loadingPackages.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des forfaits...'**
  String get loadingPackages;

  /// No description provided for @serverUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur est temporairement indisponible. Veuillez réessayer plus tard.'**
  String get serverUnavailable;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @noActivePackages.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez aucun forfait actif'**
  String get noActivePackages;

  /// No description provided for @buyPackageToStart.
  ///
  /// In fr, this message translates to:
  /// **'Achetez un forfait pour commencer à utiliser nos services!'**
  String get buyPackageToStart;

  /// No description provided for @consumptionResume.
  ///
  /// In fr, this message translates to:
  /// **'Résumé de consommation'**
  String get consumptionResume;

  /// No description provided for @internetData.
  ///
  /// In fr, this message translates to:
  /// **'Données Internet'**
  String get internetData;

  /// No description provided for @lastUpdateSeconds.
  ///
  /// In fr, this message translates to:
  /// **'il y a quelques secondes'**
  String get lastUpdateSeconds;

  /// No description provided for @lastUpdateMinutes.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} minute{count, plural, =1{} other{s}}'**
  String lastUpdateMinutes(num count);

  /// No description provided for @lastUpdateHours.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} heure{count, plural, =1{} other{s}}'**
  String lastUpdateHours(num count);

  /// No description provided for @lastUpdateDays.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} jour{count, plural, =1{} other{s}}'**
  String lastUpdateDays(num count);

  /// No description provided for @lastUpdateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour {time}'**
  String lastUpdateLabel(Object time);

  /// No description provided for @loadingDetails.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des détails...'**
  String get loadingDetails;

  /// No description provided for @refreshError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de rafraîchir les données: {error}'**
  String refreshError(Object error);

  /// No description provided for @packageNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Forfait introuvable'**
  String get packageNotFound;

  /// No description provided for @packageNotFoundDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ce forfait n\'existe pas ou n\'est plus disponible'**
  String get packageNotFoundDesc;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @comboPackage.
  ///
  /// In fr, this message translates to:
  /// **'Forfait Combo'**
  String get comboPackage;

  /// No description provided for @internetPackage.
  ///
  /// In fr, this message translates to:
  /// **'Forfait Internet'**
  String get internetPackage;

  /// No description provided for @purchaseDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'achat:'**
  String get purchaseDate;

  /// No description provided for @expirationDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration:'**
  String get expirationDate;

  /// No description provided for @remainingOf.
  ///
  /// In fr, this message translates to:
  /// **'{remaining} restants / {total}'**
  String remainingOf(Object remaining, Object total);

  /// No description provided for @remainingOfMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{remaining} restantes / {total}'**
  String remainingOfMinutes(Object remaining, Object total);

  /// No description provided for @consumption.
  ///
  /// In fr, this message translates to:
  /// **'Consommation'**
  String get consumption;

  /// No description provided for @used.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé'**
  String get used;

  /// No description provided for @remaining.
  ///
  /// In fr, this message translates to:
  /// **'Restant'**
  String get remaining;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @speedTestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Test de vitesse'**
  String get speedTestTitle;

  /// No description provided for @startTest.
  ///
  /// In fr, this message translates to:
  /// **'LANCER LE TEST'**
  String get startTest;

  /// No description provided for @testingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Test en cours...'**
  String get testingInProgress;

  /// No description provided for @phaseIdle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à tester'**
  String get phaseIdle;

  /// No description provided for @phasePing.
  ///
  /// In fr, this message translates to:
  /// **'Test du ping...'**
  String get phasePing;

  /// No description provided for @phaseDownload.
  ///
  /// In fr, this message translates to:
  /// **'Test de téléchargement...'**
  String get phaseDownload;

  /// No description provided for @phaseUpload.
  ///
  /// In fr, this message translates to:
  /// **'Test d\'upload...'**
  String get phaseUpload;

  /// No description provided for @phaseDone.
  ///
  /// In fr, this message translates to:
  /// **'Test terminé'**
  String get phaseDone;

  /// No description provided for @downloadLabel.
  ///
  /// In fr, this message translates to:
  /// **'Download'**
  String get downloadLabel;

  /// No description provided for @uploadLabel.
  ///
  /// In fr, this message translates to:
  /// **'Upload'**
  String get uploadLabel;

  /// No description provided for @pingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ping'**
  String get pingLabel;

  /// No description provided for @speedTestError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: {error}'**
  String speedTestError(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
