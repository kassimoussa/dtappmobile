// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DTServices';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get myProfile => 'My Profile';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get logoutAction => 'Log out';

  @override
  String get logoutError => 'Error during logout';

  @override
  String welcomeMessage(String phoneNumber) {
    return 'Welcome, $phoneNumber';
  }

  @override
  String get mainAccount => 'Main Account';

  @override
  String get bonusBalance => 'Bonus Balance';

  @override
  String expiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get buyPackage => 'Buy\nPackage';

  @override
  String get creditRefill => 'Credit\nRefill';

  @override
  String get myPackages => 'My\nPackages';

  @override
  String get creditTransfer => 'Credit\nTransfer';

  @override
  String get ourAgencies => 'Our\nAgencies';

  @override
  String get speedTest => 'Speed\nTest';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get preferences => 'Preferences';

  @override
  String get managePin => 'Manage PIN Code';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get save => 'Save';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get lastLogin => 'Last Login';

  @override
  String get accountCreated => 'Account Created';

  @override
  String get deviceType => 'Device Type';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileLoadError => 'Error loading profile';

  @override
  String get updateError => 'Error updating profile';

  @override
  String get saveError => 'Error saving profile';

  @override
  String get nameValidationError => 'Name must be at least 2 characters';

  @override
  String get emailValidationError => 'Please enter a valid email';

  @override
  String get notAvailable => 'Not available';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String get defaultUser => 'User';

  @override
  String get otpSendError => 'Error sending code';

  @override
  String get welcome => 'Welcome';

  @override
  String get loginPrompt => 'Log in with your number';

  @override
  String get savedPhoneNumber => 'Saved phone number';

  @override
  String get phoneValidationError => 'Please enter your number';

  @override
  String get phoneLengthError => 'Number must be 8 digits';

  @override
  String get phoneStartError => 'Number must start with 77';

  @override
  String get continueAction => 'Continue';

  @override
  String get smsVerificationMessage =>
      'A verification code will be sent by SMS';

  @override
  String get otpResentSuccess => 'A new code has been sent';

  @override
  String get otpResentError => 'Error resending code';

  @override
  String get otpInvalid => 'Invalid OTP code';

  @override
  String get verificationTitle => 'Verification';

  @override
  String verificationCodeSentTo(Object phone) {
    return 'A code was sent to $phone';
  }

  @override
  String get verifyAction => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeTimer(Object seconds) {
    return 'Resend code (${seconds}s)';
  }

  @override
  String get transferTitle => 'Credit Transfer';

  @override
  String get recipientLabel => 'Recipient Number';

  @override
  String get amountLabel => 'Amount to transfer';

  @override
  String get amountHint => 'Ex: 1000';

  @override
  String get amountInvalid => 'Invalid amount';

  @override
  String get amountPositive => 'Amount must be greater than 0';

  @override
  String get amountMinimum => 'Minimum amount: 50 DJF';

  @override
  String insufficientBalance(Object total) {
    return 'Insufficient balance (total with fees: $total DJF)';
  }

  @override
  String get selfTransferError => 'You cannot transfer money to yourself';

  @override
  String get recipientRequired => 'Please enter a recipient number';

  @override
  String get confirmTransfer => 'Confirm Transfer';

  @override
  String get transferConfirmationTitle => 'Transfer Confirmation';

  @override
  String get checkTransferDetails => 'Check transfer details';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get amountKey => 'Amount';

  @override
  String get feesKey => 'Fees (5%)';

  @override
  String get totalDebit => 'Total to debit';

  @override
  String get dateKey => 'Date';

  @override
  String currentBalance(String balance) {
    return 'Current Balance';
  }

  @override
  String balanceAfterTransfer(String balance) {
    return 'Balance after transfer: $balance DJF';
  }

  @override
  String get transferWarning =>
      'This transfer is immediate and irreversible. Please verify the recipient number.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String transferError(String error) {
    return 'Error during transfer: $error';
  }

  @override
  String get transferSuccessTitle => 'Transfer Successful';

  @override
  String transferSuccessMessage(Object recipient) {
    return 'Your credit has been successfully transferred to $recipient';
  }

  @override
  String get transferedAmount => 'Transferred Amount';

  @override
  String get transferFees => 'Transfer Fees';

  @override
  String get homeAction => 'Return to Home';

  @override
  String autoRedirect(Object seconds) {
    return 'Automatic redirect in $seconds s';
  }

  @override
  String get buyPackageTitle => 'Buy Package';

  @override
  String get internetClassique => 'Classic Internet';

  @override
  String get internetClassiqueDesc => 'Data packages for browsing';

  @override
  String get comboPackages => 'Combo Packages';

  @override
  String get comboPackagesDesc => 'Calls, SMS and Internet';

  @override
  String get tempoPackages => 'Tempo';

  @override
  String get tempoPackagesDesc => 'Weekend call minutes';

  @override
  String get newBadge => 'NEW';

  @override
  String get choosePackageHeader => 'Choose your package';

  @override
  String get internetDesc =>
      'Select one of our internet packages to stay connected.';

  @override
  String get comboDesc =>
      'Enjoy calls, SMS and data with our all-in-one packages.';

  @override
  String get tempoDesc => 'Special packages with call minutes for the weekend.';

  @override
  String get defaultPackageDesc => 'Choose the package that suits you.';

  @override
  String get emptyTempoTitle => 'No Tempo packages';

  @override
  String get emptyTempoDesc => 'Tempo packages will be available soon';

  @override
  String get recipientSelectionTitle => 'Choose Recipient';

  @override
  String get myNumber => 'My Number';

  @override
  String get otherNumber => 'Other Number';

  @override
  String get buyFor => 'Buy for';

  @override
  String get enterNumberTitle => 'Enter Number';

  @override
  String get enterNumberLabel => 'Enter phone number';

  @override
  String get djiboutiNumberRequired => 'Valid Djibouti mobile number required';

  @override
  String get purchaseConfirmationTitle => 'Purchase Confirmation';

  @override
  String get purchaseForMyNumber => 'Purchase for my number';

  @override
  String get giftPurchase => 'Gift Purchase';

  @override
  String validFor(Object validity) {
    return 'Valid for $validity';
  }

  @override
  String get priceLabel => 'Price';

  @override
  String get internetLabel => 'Internet';

  @override
  String get callsLabel => 'Calls';

  @override
  String get minutesLabel => 'Call Minutes';

  @override
  String get smsLabel => 'SMS';

  @override
  String get validityLabel => 'Validity';

  @override
  String get weekendValidity => 'Weekend';

  @override
  String currentBalanceFDJ(Object amount) {
    return 'Current Balance: $amount FDJ';
  }

  @override
  String balanceAfterPurchaseFDJ(Object amount) {
    return 'Balance after purchase: $amount FDJ';
  }

  @override
  String get lowBalanceWarning => 'Low balance after purchase';

  @override
  String get confirmPurchase => 'Confirm Purchase';

  @override
  String get purchaseSuccessTitle => 'Purchase Successful';

  @override
  String purchaseSuccessMessage(Object name) {
    return 'Your package $name has been successfully activated';
  }

  @override
  String get packageLabel => 'Package';

  @override
  String get newBalance => 'New Balance';

  @override
  String get purchaseError => 'Error during purchase';

  @override
  String get refillTitle => 'Credit Refill';

  @override
  String get refillGiftTitle => 'Gift Refill';

  @override
  String get refillMyCredit => 'Refill My Credit';

  @override
  String refillRecipient(String phone) {
    return 'Recipient: $phone';
  }

  @override
  String refillMyNumber(String phone) {
    return 'My Number: $phone';
  }

  @override
  String get refillCodeLabel => 'Refill Code';

  @override
  String get refillCodeLengthError => 'Code must contain exactly 12 digits';

  @override
  String get refillCodeDigitError => 'Code must contain only digits';

  @override
  String get howToUseCode => 'How to use your code';

  @override
  String get refillInstructions =>
      '• Scratch the card to reveal the 12-digit code\n• Enter the full code without spaces or dashes\n• Credit will be added immediately after validation\n• Each code can only be used once';

  @override
  String get confirmRefill => 'Confirm Refill';

  @override
  String get refillSuccessTitle => 'Refill Successful!';

  @override
  String refillSuccessMessageGift(String phone) {
    return 'Refill was successful for $phone';
  }

  @override
  String get refillSuccessMessageMine =>
      'Your credit has been successfully refilled';

  @override
  String get refillAmount => 'Refilled Amount';

  @override
  String refillNewBalance(String balance) {
    return 'New Balance: $balance DJF';
  }

  @override
  String get closeAction => 'Close';

  @override
  String refillFor(Object phone) {
    return 'Refill for $phone';
  }

  @override
  String refillForMyNumberMessage(Object phone) {
    return 'Refill for my number: $phone';
  }

  @override
  String get buyAction => 'Buy';

  @override
  String get insufficientBalanceSimple => 'Insufficient Balance';

  @override
  String get insufficientBalanceForPurchase =>
      'Insufficient balance for this purchase.';

  @override
  String get popularBadge => 'Popular';

  @override
  String get noData => 'No data';

  @override
  String get genericRetryError => 'An error occurred. Please try again.';

  @override
  String get buyAPackage => 'Buy a package';

  @override
  String validityHours(Object hours) {
    return '${hours}h';
  }

  @override
  String validityDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get validityWeekendLong => 'From Friday 07:00 to Sunday 07:00';

  @override
  String get myPackagesTitle => 'My Packages';

  @override
  String get loadingPackages => 'Loading packages...';

  @override
  String get serverUnavailable =>
      'Server temporarily unavailable. Please try again later.';

  @override
  String get retry => 'Retry';

  @override
  String get noActivePackages => 'No active packages';

  @override
  String get buyPackageToStart => 'Buy a package to start using our services!';

  @override
  String get consumptionResume => 'Consumption Summary';

  @override
  String get internetData => 'Internet Data';

  @override
  String get lastUpdateSeconds => 'a few seconds ago';

  @override
  String lastUpdateMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count minute$_temp0 ago';
  }

  @override
  String lastUpdateHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count hour$_temp0 ago';
  }

  @override
  String lastUpdateDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count day$_temp0 ago';
  }

  @override
  String lastUpdateLabel(Object time) {
    return 'Last update $time';
  }

  @override
  String get loadingDetails => 'Loading details...';

  @override
  String refreshError(Object error) {
    return 'Unable to refresh data: $error';
  }

  @override
  String get packageNotFound => 'Package not found';

  @override
  String get packageNotFoundDesc =>
      'This package does not exist or is no longer available';

  @override
  String get back => 'Back';

  @override
  String get comboPackage => 'Combo Package';

  @override
  String get internetPackage => 'Internet Package';

  @override
  String get purchaseDate => 'Purchase Date:';

  @override
  String get expirationDate => 'Expiration Date:';

  @override
  String remainingOf(Object remaining, Object total) {
    return '$remaining remaining / $total';
  }

  @override
  String remainingOfMinutes(Object remaining, Object total) {
    return '$remaining remaining / $total';
  }

  @override
  String get consumption => 'Consumption';

  @override
  String get used => 'Used';

  @override
  String get remaining => 'Remaining';

  @override
  String get total => 'Total';

  @override
  String get speedTestTitle => 'Speed Test';

  @override
  String get startTest => 'START TEST';

  @override
  String get testingInProgress => 'Testing...';

  @override
  String get phaseIdle => 'Ready to test';

  @override
  String get phasePing => 'Testing ping...';

  @override
  String get phaseDownload => 'Testing download...';

  @override
  String get phaseUpload => 'Testing upload...';

  @override
  String get phaseDone => 'Test finished';

  @override
  String get downloadLabel => 'Download';

  @override
  String get uploadLabel => 'Upload';

  @override
  String get pingLabel => 'Ping';

  @override
  String speedTestError(Object error) {
    return 'Error: $error';
  }

  @override
  String get agenciesTitle => 'Our Agencies';

  @override
  String get loadingAgencies => 'Loading agencies...';

  @override
  String get noAgencies => 'No agencies available';

  @override
  String get call => 'Call';

  @override
  String get directions => 'Directions';

  @override
  String get openingHours => 'Opening Hours';

  @override
  String get launchPhoneError => 'Could not launch phone app.';

  @override
  String get invalidPhone => 'Invalid phone number.';

  @override
  String get launchMapError => 'Could not launch Google Maps.';

  @override
  String get mapView => 'Map view';

  @override
  String get listView => 'List view';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get logoutTopUpSuccess => 'TopUp logout successful';

  @override
  String logoutConfirmMessage(String number) {
    return 'Do you want to log out from line $number?';
  }

  @override
  String get manualTest => 'Manual Test';

  @override
  String get batchTest => 'Batch Tests';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get myLineTitle => 'My Line';

  @override
  String get historyTitle => 'History';

  @override
  String get statisticsTooltip => 'Statistics';

  @override
  String get periodLabel => 'Period';

  @override
  String daysUnit(int days) {
    return '${days}d';
  }

  @override
  String activitiesFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities found',
      one: '1 activity found',
      zero: 'No activity found',
    );
    return '$_temp0';
  }

  @override
  String get historyLoading => 'Loading history...';

  @override
  String get historyLoadError => 'Error loading history';

  @override
  String get loadingErrorTitle => 'Loading Error';

  @override
  String get emptyHistoryTitle => 'No activity';

  @override
  String get emptyHistoryMessage => 'No activity found for the selected period';

  @override
  String get toggleHideDetails => 'Hide details';

  @override
  String get toggleShowDetails => 'Show details';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navMyLine => 'My Line';

  @override
  String get historyTransactions => 'Transaction History';

  @override
  String get comingSoonMessage => 'This feature will be available soon.';

  @override
  String get ok => 'OK';

  @override
  String get packageSubscriptionPurchase => 'TopUp Subscription Purchase';

  @override
  String get packageTopUpPurchase => 'TopUp Package Purchase';

  @override
  String get dataSubscription => 'Data Subscription';

  @override
  String get voiceSubscription => 'Voice Subscription';

  @override
  String get dataPackageAddon => 'Data Package Add-on';

  @override
  String get voicePackageAddon => 'Voice Package Add-on';

  @override
  String get insufficientBalanceError =>
      'Insufficient balance for this purchase.';

  @override
  String get subscriptionError => 'Error subscribing to package';

  @override
  String get connectionError => 'Connection error';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String get confirmPurchaseTitle => 'Confirm Purchase';

  @override
  String get packageCode => 'Package Code';

  @override
  String get price => 'Price';

  @override
  String get validity => 'Validity';

  @override
  String get content => 'Content';

  @override
  String get days => 'days';

  @override
  String get balanceAfterPurchase => 'Balance after purchase';

  @override
  String get fixedLineRecipient => 'Recipient Fixed Line';

  @override
  String get fromMobile => 'From your mobile';

  @override
  String get confirmPurchaseAction => 'Confirm Purchase';

  @override
  String get rechargeTitle => 'Refill Fixed Account';

  @override
  String get rechargeSubtitle => 'Account Refill';

  @override
  String get rechargeDescription =>
      'Transfer credit from your mobile to your fixed line';

  @override
  String get mobileSource => 'Mobile (source)';

  @override
  String get fixedDestination => 'Fixed (destination)';

  @override
  String get mobileBalanceAvailable => 'Available mobile balance';

  @override
  String get quickAmounts => 'Quick Amounts';

  @override
  String get amountToTransfer => 'Amount to transfer *';

  @override
  String get pinCode => 'PIN Code (optional)';

  @override
  String get pinDefaultInfo => 'If empty, default code (0000) will be used';

  @override
  String get pinError => 'PIN code must contain 4 digits';

  @override
  String get performRecharge => 'Refill Account';

  @override
  String get rechargeError => 'Error during refill';

  @override
  String get enterAmount => 'Please enter an amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get minAmount => 'Minimum amount: 100 DJF';

  @override
  String get maxAmount => 'Maximum amount: 50 000 DJF';

  @override
  String insufficientBalanceGeneric(String amount) {
    return 'Insufficient balance ($amount DJF)';
  }

  @override
  String get insufficientBalanceForRecharge =>
      'Insufficient balance for this refill.';

  @override
  String get activeSubscriptionTitle => 'Active Subscription';

  @override
  String activeSubscriptionMessage(String type, String date) {
    return 'You already have an active $type subscription expiring on $date.';
  }

  @override
  String get replaceSubscriptionWarning =>
      'Buying a new subscription will replace the current one. Do you want to continue?';

  @override
  String get buySubscriptionTitle => 'Buy Subscription';

  @override
  String get chooseSubscriptionType => 'Choose Subscription Type';

  @override
  String get checkingActiveSubscriptions => 'Checking active subscriptions...';

  @override
  String get dataType => 'Data';

  @override
  String get voiceType => 'Voice';

  @override
  String get dataSubscriptions => 'Data Subscriptions';

  @override
  String get voiceSubscriptions => 'Voice Subscriptions';

  @override
  String get subscriptionTypeData => 'data';

  @override
  String get subscriptionTypeVoice => 'voice';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get analysisPeriod => 'Analysis Period';

  @override
  String get statsOverview => 'Overview';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get totalActions => 'Total Actions';

  @override
  String get globalSuccessRate => 'Global Success Rate';

  @override
  String get actionDetails => 'Details by Action';

  @override
  String get successful => 'Successful';

  @override
  String get amount => 'Amount';

  @override
  String get successRate => 'Success Rate';

  @override
  String get transferImportantInfo => 'Important Information';

  @override
  String get transferMinAmountParams => '• Minimum amount: 50 DJF';

  @override
  String get transferFeesParams => '• Transfer fees: 5% of amount';

  @override
  String transferCurrentBalance(String balance) {
    return '• Your current balance: $balance DJF';
  }
}
