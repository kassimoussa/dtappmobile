// lib/models/refill_models.dart

class RefillOffer {
  final int? id;
  final int? type;
  final int? state;
  final int? productId;
  final String? startDate;
  final String? expiryDate;

  RefillOffer({
    this.id,
    this.type,
    this.state,
    this.productId,
    this.startDate,
    this.expiryDate,
  });

  factory RefillOffer.fromJson(Map<String, dynamic> json) {
    return RefillOffer(
      id: json['id'],
      type: json['type'],
      state: json['state'],
      productId: json['product_id'],
      startDate: json['start_date'],
      expiryDate: json['expiry_date'],
    );
  }
}

class RefillAccountInfo {
  final String? balance;
  final String? balanceFormatted;
  final String? supervisionExpiry;
  final String? serviceFeeExpiry;
  final String? creditClearanceDate;
  final String? serviceRemovalDate;
  final int? serviceClass;
  final String? accountType;
  final List<RefillOffer> offers;

  RefillAccountInfo({
    this.balance,
    this.balanceFormatted,
    this.supervisionExpiry,
    this.serviceFeeExpiry,
    this.creditClearanceDate,
    this.serviceRemovalDate,
    this.serviceClass,
    this.accountType,
    this.offers = const [],
  });

  factory RefillAccountInfo.fromJson(Map<String, dynamic> json) {
    return RefillAccountInfo(
      balance: json['balance'],
      balanceFormatted: json['balance_formatted'],
      supervisionExpiry: json['supervision_expiry'],
      serviceFeeExpiry: json['service_fee_expiry'],
      creditClearanceDate: json['credit_clearance_date'],
      serviceRemovalDate: json['service_removal_date'],
      serviceClass: json['service_class'],
      accountType: json['account_type'],
      offers: (json['offers'] as List<dynamic>?)
          ?.map((e) => RefillOffer.fromJson(e))
          .toList() ?? [],
    );
  }
}

class RefillVoucherInfo {
  final String? serialNumber;
  final String? group;
  final String? agent;

  RefillVoucherInfo({
    this.serialNumber,
    this.group,
    this.agent,
  });

  factory RefillVoucherInfo.fromJson(Map<String, dynamic> json) {
    return RefillVoucherInfo(
      serialNumber: json['serial_number'],
      group: json['group'],
      agent: json['agent'],
    );
  }
}

class RefillInfo {
  final int? type;
  final String? amount;
  final String? amountFormatted;
  final int? supervisionDaysExtended;
  final int? serviceFeeDaysExtended;

  RefillInfo({
    this.type,
    this.amount,
    this.amountFormatted,
    this.supervisionDaysExtended,
    this.serviceFeeDaysExtended,
  });

  factory RefillInfo.fromJson(Map<String, dynamic> json) {
    return RefillInfo(
      type: json['type'],
      amount: json['amount'],
      amountFormatted: json['amount_formatted'],
      supervisionDaysExtended: json['supervision_days_extended'],
      serviceFeeDaysExtended: json['service_fee_days_extended'],
    );
  }
}

class RefillBalanceEvolution {
  final int? before;
  final int? after;
  final int? increase;
  final String? increaseFormatted;

  RefillBalanceEvolution({
    this.before,
    this.after,
    this.increase,
    this.increaseFormatted,
  });

  factory RefillBalanceEvolution.fromJson(Map<String, dynamic> json) {
    return RefillBalanceEvolution(
      before: json['before'],
      after: json['after'],
      increase: json['increase'],
      increaseFormatted: json['increase_formatted'],
    );
  }
}

class RefillDateExtensions {
  final int? supervisionDays;
  final int? serviceFeeDays;

  RefillDateExtensions({
    this.supervisionDays,
    this.serviceFeeDays,
  });

  factory RefillDateExtensions.fromJson(Map<String, dynamic> json) {
    return RefillDateExtensions(
      supervisionDays: json['supervision_days'],
      serviceFeeDays: json['service_fee_days'],
    );
  }
}

class RefillDetails {
  final String? msisdn;
  final String? voucherCodeMasked;
  final int? refillType;
  final String? refillTypeName;
  final int? selectedOption;
  final String? refillTime;
  final String? transactionType;

  RefillDetails({
    this.msisdn,
    this.voucherCodeMasked,
    this.refillType,
    this.refillTypeName,
    this.selectedOption,
    this.refillTime,
    this.transactionType,
  });

  factory RefillDetails.fromJson(Map<String, dynamic> json) {
    return RefillDetails(
      msisdn: json['msisdn'],
      voucherCodeMasked: json['voucher_code_masked'],
      refillType: json['refill_type'],
      refillTypeName: json['refill_type_name'],
      selectedOption: json['selected_option'],
      refillTime: json['refill_time'],
      transactionType: json['transaction_type'],
    );
  }
}

class RefillResponse {
  final int codeReponse;
  final String messageReponse;
  final String? transactionId;
  final String? voucherCode;
  final RefillVoucherInfo? voucherInfo;
  final RefillInfo? refillInfo;
  final RefillAccountInfo? accountBefore;
  final RefillAccountInfo? accountAfter;
  final String? currency;
  final String? transactionAmount;
  final String? masterAccountNumber;
  final int? languageId;
  final String? segmentationId;
  final RefillDetails? details;
  final RefillBalanceEvolution? balanceEvolution;
  final RefillDateExtensions? dateExtensions;
  final int? refillFraudCount;

  RefillResponse({
    required this.codeReponse,
    required this.messageReponse,
    this.transactionId,
    this.voucherCode,
    this.voucherInfo,
    this.refillInfo,
    this.accountBefore,
    this.accountAfter,
    this.currency,
    this.transactionAmount,
    this.masterAccountNumber,
    this.languageId,
    this.segmentationId,
    this.details,
    this.balanceEvolution,
    this.dateExtensions,
    this.refillFraudCount,
  });

  bool get isSuccess => codeReponse == 0;

  factory RefillResponse.fromJson(Map<String, dynamic> json) {
    return RefillResponse(
      codeReponse: json['code_reponse'] ?? 0,
      messageReponse: json['message_reponse'] ?? '',
      transactionId: json['transaction_id'],
      voucherCode: json['voucher_code'],
      voucherInfo: json['voucher_info'] != null
          ? RefillVoucherInfo.fromJson(json['voucher_info'])
          : null,
      refillInfo: json['refill_info'] != null
          ? RefillInfo.fromJson(json['refill_info'])
          : null,
      accountBefore: json['account_before'] != null
          ? RefillAccountInfo.fromJson(json['account_before'])
          : null,
      accountAfter: json['account_after'] != null
          ? RefillAccountInfo.fromJson(json['account_after'])
          : null,
      currency: json['currency'],
      transactionAmount: json['transaction_amount'],
      masterAccountNumber: json['master_account_number'],
      languageId: json['language_id'],
      segmentationId: json['segmentation_id'],
      details: json['details'] != null
          ? RefillDetails.fromJson(json['details'])
          : null,
      balanceEvolution: json['balance_evolution'] != null
          ? RefillBalanceEvolution.fromJson(json['balance_evolution'])
          : null,
      dateExtensions: json['date_extensions'] != null
          ? RefillDateExtensions.fromJson(json['date_extensions'])
          : null,
      refillFraudCount: json['refill_fraud_count'],
    );
  }
}

class RefillException implements Exception {
  final int code;
  final String message;
  final String? transactionId;

  RefillException({
    required this.code,
    required this.message,
    this.transactionId,
  });

  @override
  String toString() => 'RefillException($code): $message';

  String get userFriendlyMessage {
    switch (code) {
      case 102:
        return 'Numéro de téléphone non trouvé';
      case 108:
        return 'Ce code de recharge a déjà été utilisé';
      case 109:
        return 'Code de recharge invalide';
      case 110:
        return 'Code de recharge expiré';
      case 111:
        return 'Montant de recharge insuffisant';
      case -404:
        return 'Service de recharge temporairement indisponible';
      case -1:
        return 'Problème de connexion internet';
      case -2:
        return 'Erreur de communication avec le serveur';
      default:
        return message.isNotEmpty ? message : 'Une erreur est survenue';
    }
  }
}