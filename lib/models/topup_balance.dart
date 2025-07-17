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
 