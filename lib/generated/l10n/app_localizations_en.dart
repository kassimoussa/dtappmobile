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
  String get connectionSettings => 'Connection Settings';

  @override
  String get biometricLogin => 'Fingerprint Login';

  @override
  String get pinLogin => 'PIN Code Login';

  @override
  String get otpLogin => 'OTP';

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
  String get otpSendError => 'Error sending OTP code';

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
  String currentBalanceFormat(String balance) {
    return 'Current Balance: $balance DJF';
  }

  @override
  String balanceAfterTransferFormat(String balance) {
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
    return 'Automatic redirection in $seconds s';
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
  String get minutesLabel => 'Minutes';

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
  String get purchaseSuccessTitle => 'Purchase successful';

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
  String get daySunday => 'Sunday';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get dayClosed => 'Closed';

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
  String get currentBalance => 'Current Balance';

  @override
  String get balanceAfterPurchase => 'Balance after purchase';

  @override
  String get fixedLineRecipient => 'Recipient Landline';

  @override
  String get fromMobile => 'From your mobile';

  @override
  String get confirmPurchaseAction => 'Buy';

  @override
  String get rechargeTitle => 'Refill Landline Account';

  @override
  String get rechargeSubtitle => 'Account Refill';

  @override
  String get rechargeDescription =>
      'Transfer credit from your mobile to your landline';

  @override
  String get mobileSource => 'Mobile (source)';

  @override
  String get fixedDestination => 'Landline (destination)';

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

  @override
  String get checkFixedLine => 'Check your landline';

  @override
  String get enterFixedNumberInfo =>
      'Please enter your landline number to check balances';

  @override
  String get fixedLineNumberKey => 'Landline Number';

  @override
  String get fixedLineNumberHint => 'Ex: 21XXXXXX';

  @override
  String get fixedBalances => 'Landline Balances';

  @override
  String get consult => 'Check';

  @override
  String get consulting => 'Checking...';

  @override
  String get consultingInProgress => 'Checking balances...';

  @override
  String get numberSuspended => 'Number Suspended';

  @override
  String get numberSuspendedInfo => 'This number is temporarily suspended.';

  @override
  String get balancesConsultableOnly =>
      'You can check balances but purchases are temporarily unavailable.';

  @override
  String get understood => 'Understood';

  @override
  String get numberEligibleButBalancesUnavailable =>
      'The number is eligible but balances are unavailable. Please try again later.';

  @override
  String fixedLineNumberFormat(String number) {
    return 'Line: $number';
  }

  @override
  String get packagesUnavailable => 'No packages available';

  @override
  String packagesSoonAvailable(String type) {
    return '$type packages will be available soon for this line.';
  }

  @override
  String get choosePackageTitle => 'Choose your package';

  @override
  String availablePackagesCount(int count, String type) {
    return '$count $type package(s) available for your landline.';
  }

  @override
  String get availableStatus => 'Available';

  @override
  String get availability => 'Availability';

  @override
  String get subscriptionLabel => 'Subscription';

  @override
  String get rechargeSuccessTitle => 'Recharge successful!';

  @override
  String get rechargeSuccessMessage => 'Your recharge was successful';

  @override
  String get transferAmount => 'Transferred amount';

  @override
  String get fromMobileSource => 'From (Mobile)';

  @override
  String get toFixedDestination => 'To (Landline)';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get accountImpact => 'Impact on your accounts';

  @override
  String get newMobileBalance => 'New mobile balance';

  @override
  String get newFixedBalance => 'New landline balance';

  @override
  String get returnHome => 'Return to home';

  @override
  String get newRecharge => 'New recharge';

  @override
  String get topupPurchaseSuccess => 'TopUp purchase successful!';

  @override
  String packageActivatedMessage(Object package) {
    return 'Package $package has been successfully activated on your landline';
  }

  @override
  String get fixedLineLabel => 'Landline';

  @override
  String get mobileLineLabel => 'Mobile line';

  @override
  String get subscriptionSuccessTitle => 'Subscription successful';

  @override
  String get topupSubscriptionSuccess => 'TopUp subscription successful!';

  @override
  String subscriptionActivatedMessage(Object subscription) {
    return 'Subscription $subscription has been successfully activated on your landline';
  }

  @override
  String get callsToFixed => 'Calls to landlines';

  @override
  String get unlimited => 'Unlimited';

  @override
  String subscriptionMonthlyActivated(Object number) {
    return 'The monthly subscription has been activated on your landline $number';
  }

  @override
  String packageActivatedFixed(Object number) {
    return 'The package has been activated on your landline $number';
  }

  @override
  String get unknownStatus => 'Unknown status';

  @override
  String get activityDetailTitle => 'Activity details';

  @override
  String get activityStatusLabel => 'Status';

  @override
  String get referenceLabel => 'Reference';

  @override
  String get statusSuccessLabel => 'Successful';

  @override
  String get statusFailedLabel => 'Failed';

  @override
  String get statusPendingLabel => 'Pending';

  @override
  String get noAdditionalDetails => 'No additional details';

  @override
  String get beneficiaryLabel => 'Recipient';

  @override
  String get balanceBeforeLabel => 'Balance before';

  @override
  String get balanceAfterLabel => 'Balance after';

  @override
  String get amountDebitedLabel => 'Amount debited';

  @override
  String get amountCreditedLabel => 'Amount credited';

  @override
  String get feeLabel => 'Fee';

  @override
  String get packageCodeLabel => 'Package Code';

  @override
  String get totalAmountLabel => 'Total Amount';

  @override
  String get rechargedLineLabel => 'Recharged Line';

  @override
  String packagePurchaseTitle(String code) {
    return 'Purchase $code';
  }

  @override
  String offerPurchaseTitle(String name) {
    return 'Offer purchase: $name';
  }

  @override
  String offerGiftTitle(String name) {
    return 'Gifted offer: $name';
  }

  @override
  String get topupRechargeTitle => 'Landline recharge';

  @override
  String get money => 'Credit';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get numberNotFound => 'This number does not exist in the system.';

  @override
  String get biometricAuthPrompt => 'Authenticate to log in';

  @override
  String get biometricAuthError => 'Biometric authentication error';

  @override
  String get chooseConnectionMethod => 'Choose a connection method';

  @override
  String get smsCodeOtp => 'SMS Code (OTP)';

  @override
  String get loginWithFingerprint => 'Log in with fingerprint';

  @override
  String get loginWithPin => 'Log in with PIN';

  @override
  String get loginWithSms => 'Log in with SMS';

  @override
  String get otherConnectionMethod => 'Other connection method';

  @override
  String get forgotPin => 'Forgot PIN?';

  @override
  String get hello => 'Hello!';

  @override
  String get setupPinTitle => 'Setup a PIN code';

  @override
  String get setupPinMessage =>
      'Do you want to create a PIN code to log in faster next time?';

  @override
  String get later => 'Later';

  @override
  String get setup => 'Setup';

  @override
  String get loading => 'Loading...';

  @override
  String get pinLoginTitle => 'PIN Login';

  @override
  String remainingAttempts(Object count) {
    return '$count attempt(s) remaining';
  }

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Retry in $minutes min $seconds sec';
  }

  @override
  String get skip => 'Skip';

  @override
  String get confirmPinTitle => 'Confirm your PIN code';

  @override
  String get createPinTitle => 'Create a PIN code';

  @override
  String get confirmPinMessage => 'Enter your PIN a second time';

  @override
  String get createPinMessage => 'Create a 4-digit code to log in quickly';

  @override
  String get pinsDoNotMatch => 'PIN codes do not match';

  @override
  String get resetInfoMissing => 'Error: missing information for reset';

  @override
  String get pinResetSuccess => 'PIN code reset successfully!';

  @override
  String get pinSetupSuccess => 'PIN code configured successfully!';

  @override
  String get otpExpiredTitle => 'OTP Code Expired';

  @override
  String get otpExpiredMessage =>
      'The OTP code has expired. You must get a new code to reset your PIN.';

  @override
  String get getNewCode => 'Get a new code';

  @override
  String get resetPinTitle => 'Reset PIN';

  @override
  String get genericError => 'An error occurred. Please try again.';

  @override
  String get errorTitle => 'Error';

  @override
  String get howItWorks => 'How it works?';

  @override
  String get resetStep1 => 'We will send you a verification code by SMS';

  @override
  String get resetStep2 => 'Enter the received code to verify your identity';

  @override
  String get resetStep3 => 'Create a new secure PIN code';

  @override
  String get sendCode => 'Send code';

  @override
  String get enterReceivedCode => 'Enter received code';

  @override
  String codeSentTo(Object number) {
    return 'A 6-digit code has been sent to\n$number';
  }

  @override
  String get codeResentSuccess => 'Code resent successfully';

  @override
  String get continueText => 'Continue';

  @override
  String get oldPinTitle => 'Old PIN code';

  @override
  String get oldPinMessage => 'Enter your current PIN code';

  @override
  String get newPinTitle => 'New PIN code';

  @override
  String get newPinMessage => 'Create a new 4-digit code';

  @override
  String get changePinTitle => 'Change PIN code';

  @override
  String get newPinsDoNotMatch => 'New PIN codes do not match';

  @override
  String get newPinMustBeDifferent =>
      'New PIN must be different from the old one';

  @override
  String get pinChangedSuccess => 'PIN code changed successfully!';

  @override
  String get pinManagementTitle => 'PIN Management';

  @override
  String get forgotPinOption => 'Forgot PIN code';

  @override
  String get phoneNotFound => 'Phone number not found';

  @override
  String get topupFixedBalances => 'TopUp - Landline Balances';

  @override
  String get detailedConsultation => 'Detailed consultation';

  @override
  String dataExpireOn(String date) {
    return 'Data expires on $date';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get topupActions => 'TopUp Actions';

  @override
  String get topupRecharge => 'TopUp\nRefill';

  @override
  String get fixedPackage => 'Landline\nPackage';

  @override
  String get transferToFixed => 'Transfer\nto Landline';

  @override
  String get topupHistory => 'TopUp\nHistory';

  @override
  String get logoutTopUp => 'TopUp Logout';

  @override
  String get fixedNumberRequired => 'Please enter a landline number';

  @override
  String get fixedNumberFormatError =>
      'Number must start with 21 or 25321 and contain 8 or 11 digits';

  @override
  String get fixedHistory => 'Landline\nHistory';

  @override
  String get confirm => 'Confirm';

  @override
  String purchaseConfirmQuestion(String name) {
    return 'Do you want to buy $name?';
  }

  @override
  String balanceAfterPurchaseAmount(String amount) {
    return 'Balance after purchase: $amount DJF';
  }

  @override
  String get priceRow => 'Price:';

  @override
  String get dataRow => 'Data:';

  @override
  String get minutesRow => 'Minutes:';

  @override
  String get validityRow => 'Validity:';

  @override
  String get searchActionHint => 'Search for an action...';

  @override
  String searchActionsAvailable(int count) {
    return '$count actions available';
  }

  @override
  String searchResultsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count result$_temp0 found';
  }

  @override
  String searchFor(String query) {
    return 'for \"$query\"';
  }

  @override
  String get noResultsFound => 'No results found';

  @override
  String get searchSuggestions =>
      'Try with different keywords like:\n\"package\", \"refill\", \"topup\", \"profile\"';

  @override
  String get searchBuyPackage => 'Buy package';

  @override
  String get searchBuyPackageSub => 'Buy voice and data packages';

  @override
  String get searchCreditRefill => 'Credit refill';

  @override
  String get searchCreditRefillSub => 'Refill your mobile account';

  @override
  String get searchCreditTransfer => 'Credit transfer';

  @override
  String get searchCreditTransferSub => 'Transfer credit to another number';

  @override
  String get searchMyPackages => 'My packages';

  @override
  String get searchMyPackagesSub => 'View your active packages';

  @override
  String get searchTopUpLine => 'TopUp - My line';

  @override
  String get searchTopUpLineSub => 'Manage your TopUp landline';

  @override
  String get searchBuySubscription => 'Buy subscription';

  @override
  String get searchBuySubscriptionSub => 'Subscribe to TopUp packages';

  @override
  String get searchRechargeFixed => 'Refill landline account';

  @override
  String get searchRechargeFixedSub => 'Transfer credit to landline';

  @override
  String get searchMyProfile => 'My profile';

  @override
  String get searchMyProfileSub => 'Manage your personal information';

  @override
  String get searchMainBalance => 'Main balance';

  @override
  String get searchMainBalanceSub => 'Check your mobile balance';

  @override
  String get searchBonusBalance => 'Bonus balance';

  @override
  String get searchBonusBalanceSub => 'Check your bonus balance';

  @override
  String get categoryActions => 'Actions';

  @override
  String get categoryConsultation => 'Consultation';

  @override
  String get categoryTopUp => 'TopUp';

  @override
  String get categoryAccount => 'Account';

  @override
  String get pleaseReenterPin => 'Please re-enter your PIN code';

  @override
  String expiredOn(String date) {
    return 'Expired on $date';
  }

  @override
  String get buySubscriptionBtn => 'Buy a\nsubscription';

  @override
  String get buyPackagesBtn => 'Buy\npackages';

  @override
  String get rechargeAccountBtn => 'Refill\naccount';

  @override
  String get fixedHistoryComingSoon => 'Landline History - Coming soon';

  @override
  String get selectContact => 'Select a contact';

  @override
  String get searchContact => 'Search for a contact...';

  @override
  String get noContactFound => 'No contacts found';

  @override
  String get noNumber => 'No number';

  @override
  String get contactNoPhone => 'This contact has no phone number';

  @override
  String get contactPermissionDenied => 'Contact access permission denied';

  @override
  String get contactRetrievalError => 'Error retrieving contacts';

  @override
  String get djiboutiMobileStart => 'Djibouti mobile numbers start with 77';

  @override
  String get choosePackageType => 'Choose package type';

  @override
  String get additionalDataPackage => 'Additional\nData';

  @override
  String get additionalVoicePackage => 'Additional\nVoice';

  @override
  String get packageCardLabel => 'Package';

  @override
  String get buyPackagesTitle => 'Buy packages';

  @override
  String get unlimitedDataTitle => 'Unlimited Data';

  @override
  String get unlimitedDataMessage =>
      'Your line already has unlimited data. You do not need to purchase additional data.';

  @override
  String get dataForBrowsing => 'Data for your browsing';

  @override
  String get voicePackage => 'Voice Package';

  @override
  String get minutesForCalls => 'Minutes for your calls';

  @override
  String get internetPackages => 'Internet Packages';

  @override
  String get voicePackages => 'Voice Packages';

  @override
  String get packageSummary => 'Package summary';

  @override
  String get packageRow => 'Package:';

  @override
  String get rechargeYourAccount => 'Refill your account';

  @override
  String get amountToRecharge => 'Amount to refill (DJF)';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get dmoneyPaymentDesc => 'Payment via your D-Money account';

  @override
  String get mobileMainAccount => 'Mobile main account';

  @override
  String get mobileTransferDesc => 'Transfer from your mobile account';

  @override
  String get pleaseEnterRechargeAmount => 'Please enter an amount to refill';

  @override
  String get requestSent => 'Request sent';

  @override
  String rechargeRequestDmoney(String amount) {
    return 'Your request to refill $amount DJF via D-Money has been sent. Please follow the instructions on your phone to finalize the transaction.';
  }

  @override
  String rechargeRequestMobile(String amount) {
    return 'Your request to transfer $amount DJF from your main mobile account has been processed successfully. The amount has been added to your landline balance.';
  }

  @override
  String get payBill => 'Pay the bill';

  @override
  String get processingPayment => 'Processing payment...';

  @override
  String get pleaseWaitPayment => 'Please wait while we process your payment.';

  @override
  String get choosePaymentMethod => 'Choose a payment method:';

  @override
  String get mobileLinePayment => 'Payment via your mobile line credit';

  @override
  String get payNow => 'Pay now';

  @override
  String get invoiceLabel => 'Invoice:';

  @override
  String get dueDateLabel => 'Due date:';

  @override
  String get typeLabel => 'Type:';

  @override
  String otpCooldown(int seconds) {
    return 'Please wait ${seconds}s before requesting a new code.';
  }

  @override
  String otpWindowExceeded(int minutes) {
    return 'Too many attempts. Please try again in $minutes min.';
  }

  @override
  String get payAction => 'Buy';

  @override
  String get enterPinForPurchase => 'Enter your PIN to confirm purchase';

  @override
  String get enterPinForTransfer => 'Enter your PIN to confirm transfer';

  @override
  String get connectionError2 => 'Connection error';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyLastUpdated => 'Last updated: January 1, 2025';

  @override
  String get privacyPolicyScrollInfo =>
      'Read and scroll to the bottom to accept.';

  @override
  String get privacyPolicyAcceptBtn => 'Accept and continue';

  @override
  String get privacyPolicyDeclineBtn => 'Decline';

  @override
  String get privacyPolicyScrollToAccept =>
      'Scroll to the bottom to activate the button';

  @override
  String get iAcceptThe => 'I accept the ';

  @override
  String get privacyPolicyLinkText => 'Privacy Policy';

  @override
  String balanceDisplay(String amount, String currency) {
    return 'Balance: $amount $currency';
  }
}
