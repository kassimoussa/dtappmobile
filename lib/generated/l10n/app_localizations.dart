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

  /// No description provided for @managePin.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du code PIN'**
  String get managePin;

  /// No description provided for @changeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get changeLanguage;

  /// No description provided for @connectionSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètre de connexion'**
  String get connectionSettings;

  /// No description provided for @biometricLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par empreinte digitale'**
  String get biometricLogin;

  /// No description provided for @pinLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par code PIN'**
  String get pinLogin;

  /// No description provided for @otpLogin.
  ///
  /// In fr, this message translates to:
  /// **'OTP'**
  String get otpLogin;

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
  /// **'Erreur lors de l\'envoi du code OTP'**
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

  /// No description provided for @currentBalanceFormat.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel: {balance} DJF'**
  String currentBalanceFormat(String balance);

  /// No description provided for @balanceAfterTransferFormat.
  ///
  /// In fr, this message translates to:
  /// **'Solde après transfert: {balance} DJF'**
  String balanceAfterTransferFormat(String balance);

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
  String transferError(String error);

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
  /// **'Minutes'**
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
  /// **'Package'**
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
  String refillRecipient(String phone);

  /// No description provided for @refillMyNumber.
  ///
  /// In fr, this message translates to:
  /// **'Mon numéro : {phone}'**
  String refillMyNumber(String phone);

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
  String refillSuccessMessageGift(String phone);

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
  String refillNewBalance(String balance);

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

  /// No description provided for @agenciesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nos Agences'**
  String get agenciesTitle;

  /// No description provided for @loadingAgencies.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des agences...'**
  String get loadingAgencies;

  /// No description provided for @noAgencies.
  ///
  /// In fr, this message translates to:
  /// **'Aucune agence disponible'**
  String get noAgencies;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @directions.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get directions;

  /// No description provided for @openingHours.
  ///
  /// In fr, this message translates to:
  /// **'Horaires d\'ouverture'**
  String get openingHours;

  /// No description provided for @launchPhoneError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer l\'application téléphone.'**
  String get launchPhoneError;

  /// No description provided for @invalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide.'**
  String get invalidPhone;

  /// No description provided for @launchMapError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer Google Maps.'**
  String get launchMapError;

  /// No description provided for @mapView.
  ///
  /// In fr, this message translates to:
  /// **'Vue carte'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In fr, this message translates to:
  /// **'Vue liste'**
  String get listView;

  /// No description provided for @subscribe.
  ///
  /// In fr, this message translates to:
  /// **'Souscrire'**
  String get subscribe;

  /// No description provided for @logoutTopUpSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion TopUp réussie'**
  String get logoutTopUpSuccess;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vous déconnecter de la ligne {number} ?'**
  String logoutConfirmMessage(String number);

  /// No description provided for @manualTest.
  ///
  /// In fr, this message translates to:
  /// **'Test Manuel'**
  String get manualTest;

  /// No description provided for @batchTest.
  ///
  /// In fr, this message translates to:
  /// **'Tests Batch'**
  String get batchTest;

  /// No description provided for @copiedToClipboard.
  ///
  /// In fr, this message translates to:
  /// **'Copié dans le presse-papiers'**
  String get copiedToClipboard;

  /// No description provided for @myLineTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma ligne'**
  String get myLineTitle;

  /// No description provided for @historyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historyTitle;

  /// No description provided for @statisticsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statisticsTooltip;

  /// No description provided for @periodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get periodLabel;

  /// No description provided for @daysUnit.
  ///
  /// In fr, this message translates to:
  /// **'{days}j'**
  String daysUnit(int days);

  /// No description provided for @activitiesFound.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune activité trouvée} =1{1 activité trouvée} other{{count} activités trouvées}}'**
  String activitiesFound(int count);

  /// No description provided for @historyLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de l\'historique...'**
  String get historyLoading;

  /// No description provided for @historyLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement de l\'historique'**
  String get historyLoadError;

  /// No description provided for @loadingErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadingErrorTitle;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistoryMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité trouvée pour la période sélectionnée'**
  String get emptyHistoryMessage;

  /// No description provided for @toggleHideDetails.
  ///
  /// In fr, this message translates to:
  /// **'Masquer les détails'**
  String get toggleHideDetails;

  /// No description provided for @toggleShowDetails.
  ///
  /// In fr, this message translates to:
  /// **'Afficher plus de détails'**
  String get toggleShowDetails;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get navHistory;

  /// No description provided for @navMyLine.
  ///
  /// In fr, this message translates to:
  /// **'Ma ligne'**
  String get navMyLine;

  /// No description provided for @historyTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Historique des transactions'**
  String get historyTransactions;

  /// No description provided for @comingSoonMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonctionnalité sera bientôt disponible.'**
  String get comingSoonMessage;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @packageSubscriptionPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat de souscription TopUp'**
  String get packageSubscriptionPurchase;

  /// No description provided for @packageTopUpPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat de package TopUp'**
  String get packageTopUpPurchase;

  /// No description provided for @dataSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Souscription données'**
  String get dataSubscription;

  /// No description provided for @voiceSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Souscription voix'**
  String get voiceSubscription;

  /// No description provided for @dataPackageAddon.
  ///
  /// In fr, this message translates to:
  /// **'Package données additionnel'**
  String get dataPackageAddon;

  /// No description provided for @voicePackageAddon.
  ///
  /// In fr, this message translates to:
  /// **'Package voix additionnel'**
  String get voicePackageAddon;

  /// No description provided for @insufficientBalanceError.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant pour cet achat.'**
  String get insufficientBalanceError;

  /// No description provided for @subscriptionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la souscription au package'**
  String get subscriptionError;

  /// No description provided for @connectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get connectionError;

  /// No description provided for @unexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue'**
  String get unexpectedError;

  /// No description provided for @confirmPurchaseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation d\'achat'**
  String get confirmPurchaseTitle;

  /// No description provided for @packageCode.
  ///
  /// In fr, this message translates to:
  /// **'Code du package'**
  String get packageCode;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @validity.
  ///
  /// In fr, this message translates to:
  /// **'Validité'**
  String get validity;

  /// No description provided for @content.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get content;

  /// No description provided for @days.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get days;

  /// No description provided for @currentBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get currentBalance;

  /// No description provided for @balanceAfterPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Solde après achat'**
  String get balanceAfterPurchase;

  /// No description provided for @fixedLineRecipient.
  ///
  /// In fr, this message translates to:
  /// **'Ligne fixe destinataire'**
  String get fixedLineRecipient;

  /// No description provided for @fromMobile.
  ///
  /// In fr, this message translates to:
  /// **'Depuis votre mobile'**
  String get fromMobile;

  /// No description provided for @confirmPurchaseAction.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l\'achat'**
  String get confirmPurchaseAction;

  /// No description provided for @rechargeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recharger compte fixe'**
  String get rechargeTitle;

  /// No description provided for @rechargeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recharge de compte'**
  String get rechargeSubtitle;

  /// No description provided for @rechargeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Transférez du crédit de votre mobile vers votre ligne fixe'**
  String get rechargeDescription;

  /// No description provided for @mobileSource.
  ///
  /// In fr, this message translates to:
  /// **'Mobile (source)'**
  String get mobileSource;

  /// No description provided for @fixedDestination.
  ///
  /// In fr, this message translates to:
  /// **'Fixe (destination)'**
  String get fixedDestination;

  /// No description provided for @mobileBalanceAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Solde mobile disponible'**
  String get mobileBalanceAvailable;

  /// No description provided for @quickAmounts.
  ///
  /// In fr, this message translates to:
  /// **'Montants rapides'**
  String get quickAmounts;

  /// No description provided for @amountToTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Montant à transférer *'**
  String get amountToTransfer;

  /// No description provided for @pinCode.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN (optionnel)'**
  String get pinCode;

  /// No description provided for @pinDefaultInfo.
  ///
  /// In fr, this message translates to:
  /// **'Si non renseigné, le code par défaut (0000) sera utilisé'**
  String get pinDefaultInfo;

  /// No description provided for @pinError.
  ///
  /// In fr, this message translates to:
  /// **'Le code PIN doit contenir 4 chiffres'**
  String get pinError;

  /// No description provided for @performRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Effectuer la recharge'**
  String get performRecharge;

  /// No description provided for @rechargeError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la recharge'**
  String get rechargeError;

  /// No description provided for @enterAmount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un montant'**
  String get enterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get invalidAmount;

  /// No description provided for @minAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant minimum: 100 DJF'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant maximum: 50 000 DJF'**
  String get maxAmount;

  /// No description provided for @insufficientBalanceGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant ({amount} DJF)'**
  String insufficientBalanceGeneric(String amount);

  /// No description provided for @insufficientBalanceForRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Solde insuffisant pour cette recharge.'**
  String get insufficientBalanceForRecharge;

  /// No description provided for @activeSubscriptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Souscription active'**
  String get activeSubscriptionTitle;

  /// No description provided for @activeSubscriptionMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà une souscription {type} active qui expire le {date}.'**
  String activeSubscriptionMessage(String type, String date);

  /// No description provided for @replaceSubscriptionWarning.
  ///
  /// In fr, this message translates to:
  /// **'Acheter une nouvelle souscription remplacera l\'actuelle. Voulez-vous continuer ?'**
  String get replaceSubscriptionWarning;

  /// No description provided for @buySubscriptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Acheter une souscription'**
  String get buySubscriptionTitle;

  /// No description provided for @chooseSubscriptionType.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le type de souscription'**
  String get chooseSubscriptionType;

  /// No description provided for @checkingActiveSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Vérification des souscriptions actives...'**
  String get checkingActiveSubscriptions;

  /// No description provided for @dataType.
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get dataType;

  /// No description provided for @voiceType.
  ///
  /// In fr, this message translates to:
  /// **'Voix'**
  String get voiceType;

  /// No description provided for @dataSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Souscriptions Données'**
  String get dataSubscriptions;

  /// No description provided for @voiceSubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Souscriptions Voix'**
  String get voiceSubscriptions;

  /// No description provided for @subscriptionTypeData.
  ///
  /// In fr, this message translates to:
  /// **'données'**
  String get subscriptionTypeData;

  /// No description provided for @subscriptionTypeVoice.
  ///
  /// In fr, this message translates to:
  /// **'voix'**
  String get subscriptionTypeVoice;

  /// No description provided for @statsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statsTitle;

  /// No description provided for @analysisPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période d\'analyse'**
  String get analysisPeriod;

  /// No description provided for @statsOverview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble'**
  String get statsOverview;

  /// No description provided for @totalSpent.
  ///
  /// In fr, this message translates to:
  /// **'Total dépensé'**
  String get totalSpent;

  /// No description provided for @totalActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions totales'**
  String get totalActions;

  /// No description provided for @globalSuccessRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de succès global'**
  String get globalSuccessRate;

  /// No description provided for @actionDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détail par action'**
  String get actionDetails;

  /// No description provided for @successful.
  ///
  /// In fr, this message translates to:
  /// **'Réussis'**
  String get successful;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @successRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de succès'**
  String get successRate;

  /// No description provided for @transferImportantInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations importantes'**
  String get transferImportantInfo;

  /// No description provided for @transferMinAmountParams.
  ///
  /// In fr, this message translates to:
  /// **'• Montant minimum : 50 DJF'**
  String get transferMinAmountParams;

  /// No description provided for @transferFeesParams.
  ///
  /// In fr, this message translates to:
  /// **'• Frais de transfert : 5% du montant'**
  String get transferFeesParams;

  /// No description provided for @transferCurrentBalance.
  ///
  /// In fr, this message translates to:
  /// **'• Votre solde actuel : {balance} DJF'**
  String transferCurrentBalance(String balance);

  /// No description provided for @checkFixedLine.
  ///
  /// In fr, this message translates to:
  /// **'Consulter votre ligne fixe'**
  String get checkFixedLine;

  /// No description provided for @enterFixedNumberInfo.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre numéro de ligne fixe pour consulter ses soldes'**
  String get enterFixedNumberInfo;

  /// No description provided for @fixedLineNumberKey.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de ligne fixe'**
  String get fixedLineNumberKey;

  /// No description provided for @fixedLineNumberHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 21XXXXXX'**
  String get fixedLineNumberHint;

  /// No description provided for @fixedBalances.
  ///
  /// In fr, this message translates to:
  /// **'Soldes Fixes'**
  String get fixedBalances;

  /// No description provided for @consult.
  ///
  /// In fr, this message translates to:
  /// **'Consulter'**
  String get consult;

  /// No description provided for @consulting.
  ///
  /// In fr, this message translates to:
  /// **'Consultation...'**
  String get consulting;

  /// No description provided for @consultingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Consultation des soldes en cours...'**
  String get consultingInProgress;

  /// No description provided for @numberSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Numéro suspendu'**
  String get numberSuspended;

  /// No description provided for @numberSuspendedInfo.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro est temporairement suspendu.'**
  String get numberSuspendedInfo;

  /// No description provided for @balancesConsultableOnly.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez consulter les soldes mais les achats sont temporairement indisponibles.'**
  String get balancesConsultableOnly;

  /// No description provided for @understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get understood;

  /// No description provided for @numberEligibleButBalancesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro est éligible mais les soldes sont indisponibles. Réessayez plus tard.'**
  String get numberEligibleButBalancesUnavailable;

  /// No description provided for @fixedLineNumberFormat.
  ///
  /// In fr, this message translates to:
  /// **'Ligne: {number}'**
  String fixedLineNumberFormat(String number);

  /// No description provided for @packagesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun package disponible'**
  String get packagesUnavailable;

  /// No description provided for @packagesSoonAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Les packages {type} seront bientôt disponibles pour cette ligne.'**
  String packagesSoonAvailable(String type);

  /// No description provided for @choosePackageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre package'**
  String get choosePackageTitle;

  /// No description provided for @availablePackagesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} package(s) {type} disponible(s) pour votre ligne fixe.'**
  String availablePackagesCount(int count, String type);

  /// No description provided for @availableStatus.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get availableStatus;

  /// No description provided for @availability.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get availability;

  /// No description provided for @subscriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Souscription'**
  String get subscriptionLabel;

  /// No description provided for @rechargeSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recharge effectuée !'**
  String get rechargeSuccessTitle;

  /// No description provided for @rechargeSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre recharge a été effectuée avec succès'**
  String get rechargeSuccessMessage;

  /// No description provided for @transferAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant transféré'**
  String get transferAmount;

  /// No description provided for @fromMobileSource.
  ///
  /// In fr, this message translates to:
  /// **'De (Mobile)'**
  String get fromMobileSource;

  /// No description provided for @toFixedDestination.
  ///
  /// In fr, this message translates to:
  /// **'Vers (Fixe)'**
  String get toFixedDestination;

  /// No description provided for @transactionId.
  ///
  /// In fr, this message translates to:
  /// **'ID Transaction'**
  String get transactionId;

  /// No description provided for @accountImpact.
  ///
  /// In fr, this message translates to:
  /// **'Impact sur vos comptes'**
  String get accountImpact;

  /// No description provided for @newMobileBalance.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde mobile'**
  String get newMobileBalance;

  /// No description provided for @newFixedBalance.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau solde fixe'**
  String get newFixedBalance;

  /// No description provided for @returnHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour accueil'**
  String get returnHome;

  /// No description provided for @newRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle recharge'**
  String get newRecharge;

  /// No description provided for @topupPurchaseSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Achat TopUp réussi !'**
  String get topupPurchaseSuccess;

  /// No description provided for @packageActivatedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le package {package} a été activé avec succès sur votre ligne fixe'**
  String packageActivatedMessage(Object package);

  /// No description provided for @fixedLineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ligne fixe'**
  String get fixedLineLabel;

  /// No description provided for @mobileLineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ligne mobile'**
  String get mobileLineLabel;

  /// No description provided for @subscriptionSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Souscription réussie'**
  String get subscriptionSuccessTitle;

  /// No description provided for @topupSubscriptionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Souscription TopUp réussie !'**
  String get topupSubscriptionSuccess;

  /// No description provided for @subscriptionActivatedMessage.
  ///
  /// In fr, this message translates to:
  /// **'La souscription {subscription} a été activée avec succès sur votre ligne fixe'**
  String subscriptionActivatedMessage(Object subscription);

  /// No description provided for @callsToFixed.
  ///
  /// In fr, this message translates to:
  /// **'Appels vers fixes'**
  String get callsToFixed;

  /// No description provided for @unlimited.
  ///
  /// In fr, this message translates to:
  /// **'Illimités'**
  String get unlimited;

  /// No description provided for @subscriptionMonthlyActivated.
  ///
  /// In fr, this message translates to:
  /// **'La souscription mensuelle a été activée sur votre ligne fixe {number}'**
  String subscriptionMonthlyActivated(Object number);

  /// No description provided for @packageActivatedFixed.
  ///
  /// In fr, this message translates to:
  /// **'Le package a été activé sur votre ligne fixe {number}'**
  String packageActivatedFixed(Object number);

  /// No description provided for @unknownStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut inconnu'**
  String get unknownStatus;

  /// No description provided for @money.
  ///
  /// In fr, this message translates to:
  /// **'Crédit'**
  String get money;

  /// No description provided for @invalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide'**
  String get invalidNumber;

  /// No description provided for @numberNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro n\'existe pas dans le système.'**
  String get numberNotFound;

  /// No description provided for @biometricAuthPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Authentifiez-vous pour vous connecter'**
  String get biometricAuthPrompt;

  /// No description provided for @biometricAuthError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'authentification biométrique'**
  String get biometricAuthError;

  /// No description provided for @chooseConnectionMethod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une méthode de connexion'**
  String get chooseConnectionMethod;

  /// No description provided for @smsCodeOtp.
  ///
  /// In fr, this message translates to:
  /// **'Code SMS (OTP)'**
  String get smsCodeOtp;

  /// No description provided for @loginWithFingerprint.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec empreinte'**
  String get loginWithFingerprint;

  /// No description provided for @loginWithPin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec PIN'**
  String get loginWithPin;

  /// No description provided for @loginWithSms.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec SMS'**
  String get loginWithSms;

  /// No description provided for @otherConnectionMethod.
  ///
  /// In fr, this message translates to:
  /// **'Autre méthode de connexion'**
  String get otherConnectionMethod;

  /// No description provided for @forgotPin.
  ///
  /// In fr, this message translates to:
  /// **'PIN oublié ?'**
  String get forgotPin;

  /// No description provided for @hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour !'**
  String get hello;

  /// No description provided for @setupPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configurer un code PIN'**
  String get setupPinTitle;

  /// No description provided for @setupPinMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous créer un code PIN pour vous connecter plus rapidement la prochaine fois ?'**
  String get setupPinMessage;

  /// No description provided for @later.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// No description provided for @setup.
  ///
  /// In fr, this message translates to:
  /// **'Configurer'**
  String get setup;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement en cours...'**
  String get loading;

  /// No description provided for @pinLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion PIN'**
  String get pinLoginTitle;

  /// No description provided for @remainingAttempts.
  ///
  /// In fr, this message translates to:
  /// **'{count} tentative(s) restante(s)'**
  String remainingAttempts(Object count);

  /// No description provided for @retryIn.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez dans {minutes} min {seconds} sec'**
  String retryIn(Object minutes, Object seconds);

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @confirmPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre code PIN'**
  String get confirmPinTitle;

  /// No description provided for @createPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez un code PIN'**
  String get createPinTitle;

  /// No description provided for @confirmPinMessage.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre PIN une seconde fois'**
  String get confirmPinMessage;

  /// No description provided for @createPinMessage.
  ///
  /// In fr, this message translates to:
  /// **'Créez un code à 4 chiffres pour vous connecter rapidement'**
  String get createPinMessage;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les codes PIN ne correspondent pas'**
  String get pinsDoNotMatch;

  /// No description provided for @resetInfoMissing.
  ///
  /// In fr, this message translates to:
  /// **'Erreur: informations manquantes pour la réinitialisation'**
  String get resetInfoMissing;

  /// No description provided for @pinResetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN réinitialisé avec succès !'**
  String get pinResetSuccess;

  /// No description provided for @pinSetupSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN configuré avec succès !'**
  String get pinSetupSuccess;

  /// No description provided for @otpExpiredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code OTP expiré'**
  String get otpExpiredTitle;

  /// No description provided for @otpExpiredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le code OTP a expiré. Vous devez obtenir un nouveau code pour réinitialiser votre PIN.'**
  String get otpExpiredMessage;

  /// No description provided for @getNewCode.
  ///
  /// In fr, this message translates to:
  /// **'Obtenir un nouveau code'**
  String get getNewCode;

  /// No description provided for @resetPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le PIN'**
  String get resetPinTitle;

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get genericError;

  /// No description provided for @errorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get errorTitle;

  /// No description provided for @howItWorks.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get howItWorks;

  /// No description provided for @resetStep1.
  ///
  /// In fr, this message translates to:
  /// **'Nous allons vous envoyer un code de vérification par SMS'**
  String get resetStep1;

  /// No description provided for @resetStep2.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code reçu pour vérifier votre identité'**
  String get resetStep2;

  /// No description provided for @resetStep3.
  ///
  /// In fr, this message translates to:
  /// **'Créez un nouveau code PIN sécurisé'**
  String get resetStep3;

  /// No description provided for @sendCode.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get sendCode;

  /// No description provided for @enterReceivedCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code reçu'**
  String get enterReceivedCode;

  /// No description provided for @codeSentTo.
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres a été envoyé au\n{number}'**
  String codeSentTo(Object number);

  /// No description provided for @codeResentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code renvoyé avec succès'**
  String get codeResentSuccess;

  /// No description provided for @continueText.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueText;

  /// No description provided for @oldPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ancien code PIN'**
  String get oldPinTitle;

  /// No description provided for @oldPinMessage.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code PIN actuel'**
  String get oldPinMessage;

  /// No description provided for @newPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code PIN'**
  String get newPinTitle;

  /// No description provided for @newPinMessage.
  ///
  /// In fr, this message translates to:
  /// **'Créez un nouveau code à 4 chiffres'**
  String get newPinMessage;

  /// No description provided for @changePinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le code PIN'**
  String get changePinTitle;

  /// No description provided for @newPinsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les nouveaux codes PIN ne correspondent pas'**
  String get newPinsDoNotMatch;

  /// No description provided for @newPinMustBeDifferent.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau PIN doit être différent de l\'ancien'**
  String get newPinMustBeDifferent;

  /// No description provided for @pinChangedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN modifié avec succès !'**
  String get pinChangedSuccess;

  /// No description provided for @pinManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du code PIN'**
  String get pinManagementTitle;

  /// No description provided for @forgotPinOption.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN oublié'**
  String get forgotPinOption;

  /// No description provided for @phoneNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone introuvable'**
  String get phoneNotFound;

  /// No description provided for @topupFixedBalances.
  ///
  /// In fr, this message translates to:
  /// **'TopUp - Soldes Fixes'**
  String get topupFixedBalances;

  /// No description provided for @detailedConsultation.
  ///
  /// In fr, this message translates to:
  /// **'Consultation détaillée'**
  String get detailedConsultation;

  /// No description provided for @dataExpireOn.
  ///
  /// In fr, this message translates to:
  /// **'Données expirent le {date}'**
  String dataExpireOn(String date);

  /// No description provided for @topupActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions TopUp'**
  String get topupActions;

  /// No description provided for @topupRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Recharge\nTopUp'**
  String get topupRecharge;

  /// No description provided for @fixedPackage.
  ///
  /// In fr, this message translates to:
  /// **'Forfait\nFixe'**
  String get fixedPackage;

  /// No description provided for @transferToFixed.
  ///
  /// In fr, this message translates to:
  /// **'Transfert\nvers Fixe'**
  String get transferToFixed;

  /// No description provided for @topupHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique\nTopUp'**
  String get topupHistory;

  /// No description provided for @logoutTopUp.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion TopUp'**
  String get logoutTopUp;

  /// No description provided for @fixedNumberRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un numéro de téléphone fixe'**
  String get fixedNumberRequired;

  /// No description provided for @fixedNumberFormatError.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro doit commencer par 21 ou 25321 et contenir 8 ou 11 chiffres'**
  String get fixedNumberFormatError;

  /// No description provided for @fixedHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique\nFixe'**
  String get fixedHistory;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @purchaseConfirmQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous acheter le {name} ?'**
  String purchaseConfirmQuestion(String name);

  /// No description provided for @balanceAfterPurchaseAmount.
  ///
  /// In fr, this message translates to:
  /// **'Solde après achat: {amount} FDJ'**
  String balanceAfterPurchaseAmount(String amount);

  /// No description provided for @priceRow.
  ///
  /// In fr, this message translates to:
  /// **'Prix:'**
  String get priceRow;

  /// No description provided for @dataRow.
  ///
  /// In fr, this message translates to:
  /// **'Data:'**
  String get dataRow;

  /// No description provided for @minutesRow.
  ///
  /// In fr, this message translates to:
  /// **'Minutes:'**
  String get minutesRow;

  /// No description provided for @validityRow.
  ///
  /// In fr, this message translates to:
  /// **'Validité:'**
  String get validityRow;

  /// No description provided for @searchActionHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une action...'**
  String get searchActionHint;

  /// No description provided for @searchActionsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'{count} actions disponibles'**
  String searchActionsAvailable(int count);

  /// No description provided for @searchResultsFound.
  ///
  /// In fr, this message translates to:
  /// **'{count} résultat{count, plural, =1{} other{s}} trouvé{count, plural, =1{} other{s}}'**
  String searchResultsFound(int count);

  /// No description provided for @searchFor.
  ///
  /// In fr, this message translates to:
  /// **'pour \"{query}\"'**
  String searchFor(String query);

  /// No description provided for @noResultsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noResultsFound;

  /// No description provided for @searchSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Essayez avec des mots-clés différents comme :\n\"forfait\", \"recharge\", \"topup\", \"profil\"'**
  String get searchSuggestions;

  /// No description provided for @searchBuyPackage.
  ///
  /// In fr, this message translates to:
  /// **'Achat de forfait'**
  String get searchBuyPackage;

  /// No description provided for @searchBuyPackageSub.
  ///
  /// In fr, this message translates to:
  /// **'Acheter des forfaits voix et data'**
  String get searchBuyPackageSub;

  /// No description provided for @searchCreditRefill.
  ///
  /// In fr, this message translates to:
  /// **'Recharge de crédit'**
  String get searchCreditRefill;

  /// No description provided for @searchCreditRefillSub.
  ///
  /// In fr, this message translates to:
  /// **'Recharger votre compte mobile'**
  String get searchCreditRefillSub;

  /// No description provided for @searchCreditTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert de crédit'**
  String get searchCreditTransfer;

  /// No description provided for @searchCreditTransferSub.
  ///
  /// In fr, this message translates to:
  /// **'Transférer du crédit vers un autre numéro'**
  String get searchCreditTransferSub;

  /// No description provided for @searchMyPackages.
  ///
  /// In fr, this message translates to:
  /// **'Mes forfaits'**
  String get searchMyPackages;

  /// No description provided for @searchMyPackagesSub.
  ///
  /// In fr, this message translates to:
  /// **'Consulter vos forfaits actifs'**
  String get searchMyPackagesSub;

  /// No description provided for @searchTopUpLine.
  ///
  /// In fr, this message translates to:
  /// **'TopUp - Ma ligne'**
  String get searchTopUpLine;

  /// No description provided for @searchTopUpLineSub.
  ///
  /// In fr, this message translates to:
  /// **'Gérer votre ligne fixe TopUp'**
  String get searchTopUpLineSub;

  /// No description provided for @searchBuySubscription.
  ///
  /// In fr, this message translates to:
  /// **'Acheter souscription'**
  String get searchBuySubscription;

  /// No description provided for @searchBuySubscriptionSub.
  ///
  /// In fr, this message translates to:
  /// **'Souscrire à des packages TopUp'**
  String get searchBuySubscriptionSub;

  /// No description provided for @searchRechargeFixed.
  ///
  /// In fr, this message translates to:
  /// **'Recharger compte fixe'**
  String get searchRechargeFixed;

  /// No description provided for @searchRechargeFixedSub.
  ///
  /// In fr, this message translates to:
  /// **'Transférer crédit vers ligne fixe'**
  String get searchRechargeFixedSub;

  /// No description provided for @searchMyProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get searchMyProfile;

  /// No description provided for @searchMyProfileSub.
  ///
  /// In fr, this message translates to:
  /// **'Gérer vos informations personnelles'**
  String get searchMyProfileSub;

  /// No description provided for @searchMainBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde principal'**
  String get searchMainBalance;

  /// No description provided for @searchMainBalanceSub.
  ///
  /// In fr, this message translates to:
  /// **'Consulter votre solde mobile'**
  String get searchMainBalanceSub;

  /// No description provided for @searchBonusBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde bonus'**
  String get searchBonusBalance;

  /// No description provided for @searchBonusBalanceSub.
  ///
  /// In fr, this message translates to:
  /// **'Consulter votre solde bonus'**
  String get searchBonusBalanceSub;

  /// No description provided for @categoryActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get categoryActions;

  /// No description provided for @categoryConsultation.
  ///
  /// In fr, this message translates to:
  /// **'Consultation'**
  String get categoryConsultation;

  /// No description provided for @categoryTopUp.
  ///
  /// In fr, this message translates to:
  /// **'TopUp'**
  String get categoryTopUp;

  /// No description provided for @categoryAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get categoryAccount;

  /// No description provided for @pleaseReenterPin.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ressaisir votre code PIN'**
  String get pleaseReenterPin;

  /// No description provided for @expiredOn.
  ///
  /// In fr, this message translates to:
  /// **'Expiré le {date}'**
  String expiredOn(String date);

  /// No description provided for @buySubscriptionBtn.
  ///
  /// In fr, this message translates to:
  /// **'Acheter une\nsouscription'**
  String get buySubscriptionBtn;

  /// No description provided for @buyPackagesBtn.
  ///
  /// In fr, this message translates to:
  /// **'Acheter\npackages'**
  String get buyPackagesBtn;

  /// No description provided for @rechargeAccountBtn.
  ///
  /// In fr, this message translates to:
  /// **'Recharger\ncompte'**
  String get rechargeAccountBtn;

  /// No description provided for @fixedHistoryComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Historique Fixe - Bientôt disponible'**
  String get fixedHistoryComingSoon;

  /// No description provided for @selectContact.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un contact'**
  String get selectContact;

  /// No description provided for @searchContact.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un contact...'**
  String get searchContact;

  /// No description provided for @noContactFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contact trouvé'**
  String get noContactFound;

  /// No description provided for @noNumber.
  ///
  /// In fr, this message translates to:
  /// **'Aucun numéro'**
  String get noNumber;

  /// No description provided for @contactNoPhone.
  ///
  /// In fr, this message translates to:
  /// **'Ce contact n\'a pas de numéro de téléphone'**
  String get contactNoPhone;

  /// No description provided for @contactPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission d\'accès aux contacts refusée'**
  String get contactPermissionDenied;

  /// No description provided for @contactRetrievalError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la récupération des contacts'**
  String get contactRetrievalError;

  /// No description provided for @djiboutiMobileStart.
  ///
  /// In fr, this message translates to:
  /// **'Les numéros mobiles djiboutiens commencent par 77'**
  String get djiboutiMobileStart;

  /// No description provided for @choosePackageType.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un type de forfait'**
  String get choosePackageType;

  /// No description provided for @dataForBrowsing.
  ///
  /// In fr, this message translates to:
  /// **'Données pour votre navigation'**
  String get dataForBrowsing;

  /// No description provided for @voicePackage.
  ///
  /// In fr, this message translates to:
  /// **'Forfait Appels'**
  String get voicePackage;

  /// No description provided for @minutesForCalls.
  ///
  /// In fr, this message translates to:
  /// **'Minutes pour vos appels'**
  String get minutesForCalls;

  /// No description provided for @internetPackages.
  ///
  /// In fr, this message translates to:
  /// **'Forfaits Internet'**
  String get internetPackages;

  /// No description provided for @voicePackages.
  ///
  /// In fr, this message translates to:
  /// **'Forfaits Appels'**
  String get voicePackages;

  /// No description provided for @packageSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé du forfait'**
  String get packageSummary;

  /// No description provided for @packageRow.
  ///
  /// In fr, this message translates to:
  /// **'Forfait:'**
  String get packageRow;

  /// No description provided for @rechargeYourAccount.
  ///
  /// In fr, this message translates to:
  /// **'Recharger votre compte'**
  String get rechargeYourAccount;

  /// No description provided for @amountToRecharge.
  ///
  /// In fr, this message translates to:
  /// **'Montant à recharger (DJF)'**
  String get amountToRecharge;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement'**
  String get paymentMethod;

  /// No description provided for @dmoneyPaymentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Paiement via votre compte D-Money'**
  String get dmoneyPaymentDesc;

  /// No description provided for @mobileMainAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte principal mobile'**
  String get mobileMainAccount;

  /// No description provided for @mobileTransferDesc.
  ///
  /// In fr, this message translates to:
  /// **'Transfert depuis votre compte mobile'**
  String get mobileTransferDesc;

  /// No description provided for @pleaseEnterRechargeAmount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un montant à recharger'**
  String get pleaseEnterRechargeAmount;

  /// No description provided for @requestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get requestSent;

  /// No description provided for @rechargeRequestDmoney.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande de rechargement de {amount} DJF via D-Money a été envoyée. Veuillez suivre les instructions sur votre téléphone pour finaliser la transaction.'**
  String rechargeRequestDmoney(String amount);

  /// No description provided for @rechargeRequestMobile.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande de transfert de {amount} DJF depuis votre compte principal mobile a été traitée avec succès. Le montant a été ajouté à votre solde fixe.'**
  String rechargeRequestMobile(String amount);

  /// No description provided for @payBill.
  ///
  /// In fr, this message translates to:
  /// **'Payer la facture'**
  String get payBill;

  /// No description provided for @processingPayment.
  ///
  /// In fr, this message translates to:
  /// **'Traitement du paiement...'**
  String get processingPayment;

  /// No description provided for @pleaseWaitPayment.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez patienter pendant que nous traitons votre paiement.'**
  String get pleaseWaitPayment;

  /// No description provided for @choosePaymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une méthode de paiement:'**
  String get choosePaymentMethod;

  /// No description provided for @mobileLinePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement via le crédit de votre ligne mobile'**
  String get mobileLinePayment;

  /// No description provided for @payNow.
  ///
  /// In fr, this message translates to:
  /// **'Payer maintenant'**
  String get payNow;

  /// No description provided for @invoiceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Facture:'**
  String get invoiceLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'échéance:'**
  String get dueDateLabel;

  /// No description provided for @typeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type:'**
  String get typeLabel;

  /// No description provided for @balanceDisplay.
  ///
  /// In fr, this message translates to:
  /// **'Solde: {amount} {currency}'**
  String balanceDisplay(String amount, String currency);
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
