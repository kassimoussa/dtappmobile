// lib/models/topup_balance.dart
import 'package:flutter/material.dart';

class TopUpBalanceResponse {
  final bool success;
  final String message;
  final String mobileMsisdn;
  final String fixedIsdn;
  final List<TopUpBalance> balances;
  final int totalBalances;
  final TopUpBalanceSummary summary;
  final TopUpBalanceDetails details;

  TopUpBalanceResponse({
    required this.success,
    required this.message,
    required this.mobileMsisdn,
    required this.fixedIsdn,
    required this.balances,
    required this.totalBalances,
    required this.summary,
    required this.details,
  });

  factory TopUpBalanceResponse.fromJson(Map<String, dynamic> json) {
    return TopUpBalanceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      mobileMsisdn: json['mobile_msisdn'] ?? '',
      fixedIsdn: json['fixed_isdn'] ?? '',
      balances: (json['balances'] as List<dynamic>?)
          ?.map((item) => TopUpBalance.fromJson(item))
          .toList() ?? [],
      totalBalances: json['total_balances'] ?? 0,
      summary: TopUpBalanceSummary.fromJson(json['summary'] ?? {}),
      details: TopUpBalanceDetails.fromJson(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'mobile_msisdn': mobileMsisdn,
      'fixed_isdn': fixedIsdn,
      'balances': balances.map((balance) => balance.toJson()).toList(),
      'total_balances': totalBalances,
      'summary': summary.toJson(),
      'details': details.toJson(),
    };
  }
}

class TopUpBalance {
  final String name;
  final String type;
  final double value;
  final String formattedValue;
  final String unit;
  final String expireDate;
  final String expireDateFormatted;
  final TopUpExpirationStatus expirationStatus;
  final String rawType;

  TopUpBalance({
    required this.name,
    required this.type,
    required this.value,
    required this.formattedValue,
    required this.unit,
    required this.expireDate,
    required this.expireDateFormatted,
    required this.expirationStatus,
    required this.rawType,
  });

  factory TopUpBalance.fromJson(Map<String, dynamic> json) {
    return TopUpBalance(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      formattedValue: json['formatted_value'] ?? '',
      unit: json['unit'] ?? '',
      expireDate: json['expire_date'] ?? '',
      expireDateFormatted: json['expire_date_formatted'] ?? '',
      expirationStatus: TopUpExpirationStatus.fromJson(json['expiration_status'] ?? {}),
      rawType: json['raw_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'value': value,
      'formatted_value': formattedValue,
      'unit': unit,
      'expire_date': expireDate,
      'expire_date_formatted': expireDateFormatted,
      'expiration_status': expirationStatus.toJson(),
      'raw_type': rawType,
    };
  }

  // Helpers pour l'interface utilisateur
  bool get isMoneyType => type == 'money';
  bool get isDataType => type == 'data';
  bool get isVoiceType => type == 'voice';
  
  bool get isExpired => expirationStatus.status == 'expired';
  bool get isExpiringSoon => expirationStatus.status == 'warning' || expirationStatus.status == 'critical';
  bool get isActive => expirationStatus.status == 'active';
  
  Color get statusColor {
    switch (expirationStatus.status) {
      case 'active':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class TopUpExpirationStatus {
  final String status;
  final int priority;
  final String message;

  TopUpExpirationStatus({
    required this.status,
    required this.priority,
    required this.message,
  });

  factory TopUpExpirationStatus.fromJson(Map<String, dynamic> json) {
    return TopUpExpirationStatus(
      status: json['status'] ?? 'unknown',
      priority: json['priority'] ?? 0,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'priority': priority,
      'message': message,
    };
  }
}

class TopUpBalanceSummary {
  final int totalBalances;
  final double moneyTotal;
  final String moneyTotalFormatted;
  final int dataTotalBytes;
  final String dataTotalFormatted;
  final int voiceTotalSeconds;
  final String voiceTotalFormatted;

  TopUpBalanceSummary({
    required this.totalBalances,
    required this.moneyTotal,
    required this.moneyTotalFormatted,
    required this.dataTotalBytes,
    required this.dataTotalFormatted,
    required this.voiceTotalSeconds,
    required this.voiceTotalFormatted,
  });

  factory TopUpBalanceSummary.fromJson(Map<String, dynamic> json) {
    return TopUpBalanceSummary(
      totalBalances: (json['total_balances'] ?? 0) is int 
          ? json['total_balances'] 
          : (json['total_balances'] ?? 0).toInt(),
      moneyTotal: (json['money_total'] ?? 0).toDouble(),
      moneyTotalFormatted: json['money_total_formatted'] ?? '0 DJF',
      dataTotalBytes: (json['data_total_bytes'] ?? 0) is int 
          ? json['data_total_bytes'] 
          : (json['data_total_bytes'] ?? 0).toInt(),
      dataTotalFormatted: json['data_total_formatted'] ?? '0 Mo',
      voiceTotalSeconds: (json['voice_total_seconds'] ?? 0) is int 
          ? json['voice_total_seconds'] 
          : (json['voice_total_seconds'] ?? 0).toInt(),
      voiceTotalFormatted: json['voice_total_formatted'] ?? '00:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_balances': totalBalances,
      'money_total': moneyTotal,
      'money_total_formatted': moneyTotalFormatted,
      'data_total_bytes': dataTotalBytes,
      'data_total_formatted': dataTotalFormatted,
      'voice_total_seconds': voiceTotalSeconds,
      'voice_total_formatted': voiceTotalFormatted,
    };
  }
}

class TopUpBalanceDetails {
  final String mobileMsisdn;
  final String fixedIsdn;
  final String requestTime;
  final int totalBalances;
  final String backendApi;

  TopUpBalanceDetails({
    required this.mobileMsisdn,
    required this.fixedIsdn,
    required this.requestTime,
    required this.totalBalances,
    required this.backendApi,
  });

  factory TopUpBalanceDetails.fromJson(Map<String, dynamic> json) {
    return TopUpBalanceDetails(
      mobileMsisdn: json['mobile_msisdn'] ?? '',
      fixedIsdn: json['fixed_isdn'] ?? '',
      requestTime: json['request_time'] ?? '',
      totalBalances: json['total_balances'] ?? 0,
      backendApi: json['backend_api'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile_msisdn': mobileMsisdn,
      'fixed_isdn': fixedIsdn,
      'request_time': requestTime,
      'total_balances': totalBalances,
      'backend_api': backendApi,
    };
  }
}

// TopUp Package Models
class TopUpPackageResponse {
  final bool success;
  final String message;
  final String msisdn;
  final String isdn;
  final int type;
  final String typeDescription;
  final String returnCode;
  final String description;
  final List<TopUpPackage> packages;
  final int totalPackages;
  final TopUpPackageSummary summary;
  final TopUpPackageDetails details;

  TopUpPackageResponse({
    required this.success,
    required this.message,
    required this.msisdn,
    required this.isdn,
    required this.type,
    required this.typeDescription,
    required this.returnCode,
    required this.description,
    required this.packages,
    required this.totalPackages,
    required this.summary,
    required this.details,
  });

  factory TopUpPackageResponse.fromJson(Map<String, dynamic> json) {
    return TopUpPackageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      msisdn: json['msisdn'] ?? '',
      isdn: json['isdn'] ?? '',
      type: int.parse(json['type']?.toString() ?? '0'),
      typeDescription: json['type_description'] ?? '',
      returnCode: json['return_code'] ?? '',
      description: json['description'] ?? '',
      packages: (json['packages'] as List<dynamic>?)
          ?.map((item) => TopUpPackage.fromJson(item))
          .toList() ?? [],
      totalPackages: json['total_packages'] ?? 0,
      summary: TopUpPackageSummary.fromJson(json['summary'] ?? {}),
      details: TopUpPackageDetails.fromJson(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'msisdn': msisdn,
      'isdn': isdn,
      'type': type.toString(),
      'type_description': typeDescription,
      'return_code': returnCode,
      'description': description,
      'packages': packages.map((package) => package.toJson()).toList(),
      'total_packages': totalPackages,
      'summary': summary.toJson(),
      'details': details.toJson(),
    };
  }
}

class TopUpPackage {
  final String packageCode;
  final String description;
  final String descriptionEn;
  final int price;
  final String formattedPrice;
  final int validityDays;
  final String formattedValidity;
  final String profileCode;
  final bool dataUnlimited;
  final int dataQuantityGb;
  final int voiceQuantityMinutes;
  final int voiceFixedSeconds;
  final int voiceMobileSeconds;
  final bool voiceFixedUnlimited;
  final String formattedData;
  final String formattedVoice;
  final String category;
  final bool isAffordable;

  TopUpPackage({
    required this.packageCode,
    required this.description,
    required this.descriptionEn,
    required this.price,
    required this.formattedPrice,
    required this.validityDays,
    required this.formattedValidity,
    required this.profileCode,
    required this.dataUnlimited,
    required this.dataQuantityGb,
    required this.voiceQuantityMinutes,
    required this.voiceFixedSeconds,
    required this.voiceMobileSeconds,
    required this.voiceFixedUnlimited,
    required this.formattedData,
    required this.formattedVoice,
    required this.category,
    required this.isAffordable,
  });

  factory TopUpPackage.fromJson(Map<String, dynamic> json) {
    return TopUpPackage(
      packageCode: json['package_code'] ?? '',
      description: json['description'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      price: json['price'] ?? 0,
      formattedPrice: json['formatted_price'] ?? '',
      validityDays: json['validity_days'] ?? 0,
      formattedValidity: json['formatted_validity'] ?? '',
      profileCode: json['profile_code'] ?? '',
      dataUnlimited: json['data_unlimited'] ?? false,
      dataQuantityGb: json['data_quantity_gb'] ?? 0,
      voiceQuantityMinutes: json['voice_quantity_minutes'] ?? 0,
      voiceFixedSeconds: json['voice_fixed_seconds'] ?? 0,
      voiceMobileSeconds: json['voice_mobile_seconds'] ?? 0,
      voiceFixedUnlimited: json['voice_fixed_unlimited'] ?? false,
      formattedData: json['formatted_data'] ?? '',
      formattedVoice: json['formatted_voice'] ?? '',
      category: json['category'] ?? '',
      isAffordable: json['is_affordable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_code': packageCode,
      'description': description,
      'description_en': descriptionEn,
      'price': price,
      'formatted_price': formattedPrice,
      'validity_days': validityDays,
      'formatted_validity': formattedValidity,
      'profile_code': profileCode,
      'data_unlimited': dataUnlimited,
      'data_quantity_gb': dataQuantityGb,
      'voice_quantity_minutes': voiceQuantityMinutes,
      'voice_fixed_seconds': voiceFixedSeconds,
      'voice_mobile_seconds': voiceMobileSeconds,
      'voice_fixed_unlimited': voiceFixedUnlimited,
      'formatted_data': formattedData,
      'formatted_voice': formattedVoice,
      'category': category,
      'is_affordable': isAffordable,
    };
  }

  // Helpers pour l'interface utilisateur
  bool get isDataPackage => dataQuantityGb > 0;
  bool get isVoicePackage => voiceQuantityMinutes > 0;
  
  String get displayName => description.isNotEmpty ? description : packageCode;
  
  String get mainFeature {
    if (isDataPackage) {
      return formattedData;
    } else if (isVoicePackage) {
      return formattedVoice;
    }
    return 'Package';
  }
}

class TopUpPackageSummary {
  final int totalPackages;
  final Map<String, int> categories;
  final TopUpPriceRange priceRange;
  final int affordablePackages;

  TopUpPackageSummary({
    required this.totalPackages,
    required this.categories,
    required this.priceRange,
    required this.affordablePackages,
  });

  factory TopUpPackageSummary.fromJson(Map<String, dynamic> json) {
    return TopUpPackageSummary(
      totalPackages: json['total_packages'] ?? 0,
      categories: Map<String, int>.from(json['categories'] ?? {}),
      priceRange: TopUpPriceRange.fromJson(json['price_range'] ?? {}),
      affordablePackages: json['affordable_packages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_packages': totalPackages,
      'categories': categories,
      'price_range': priceRange.toJson(),
      'affordable_packages': affordablePackages,
    };
  }
}

class TopUpPriceRange {
  final int min;
  final int max;
  final double average;

  TopUpPriceRange({
    required this.min,
    required this.max,
    required this.average,
  });

  factory TopUpPriceRange.fromJson(Map<String, dynamic> json) {
    return TopUpPriceRange(
      min: json['min'] ?? 0,
      max: json['max'] ?? 0,
      average: (json['average'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'average': average,
    };
  }
}

class TopUpPackageDetails {
  final String msisdn;
  final String isdn;
  final int type;
  final String requestTime;
  final int totalPackages;
  final String backendApi;

  TopUpPackageDetails({
    required this.msisdn,
    required this.isdn,
    required this.type,
    required this.requestTime,
    required this.totalPackages,
    required this.backendApi,
  });

  factory TopUpPackageDetails.fromJson(Map<String, dynamic> json) {
    return TopUpPackageDetails(
      msisdn: json['msisdn'] ?? '',
      isdn: json['isdn'] ?? '',
      type: json['type'] ?? 0,
      requestTime: json['request_time'] ?? '',
      totalPackages: json['total_packages'] ?? 0,
      backendApi: json['backend_api'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msisdn': msisdn,
      'isdn': isdn,
      'type': type,
      'request_time': requestTime,
      'total_packages': totalPackages,
      'backend_api': backendApi,
    };
  }
}