// lib/models/activity.dart

class Activity {
  final int id;
  final String actionType;
  final String actionLabel;
  final String endpoint;
  final String status;
  final double? amount;
  final String? currency;
  final String? externalReference;
  final DateTime createdAt;
  final String? description;
  final double? oldBalance;
  final double? newBalance;
  final String? beneficiaryMsisdn;
  final Map<String, dynamic>? metadata;

  Activity({
    required this.id,
    required this.actionType,
    required this.actionLabel,
    required this.endpoint,
    required this.status,
    this.amount,
    this.currency,
    this.externalReference,
    required this.createdAt,
    this.description,
    this.oldBalance,
    this.newBalance,
    this.beneficiaryMsisdn,
    this.metadata,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: int.tryParse(json['id'].toString()) ?? 0,
      actionType: json['action_type']?.toString() ?? '',
      actionLabel: json['action_label']?.toString() ?? '',
      endpoint: json['endpoint']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount:
          json['amount'] != null
              ? double.tryParse(json['amount'].toString())
              : null,
      currency: json['currency']?.toString(),
      externalReference: json['external_reference']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      description: json['description']?.toString(),
      oldBalance:
          json['old_balance'] != null
              ? double.tryParse(json['old_balance'].toString())
              : null,
      newBalance:
          json['new_balance'] != null
              ? double.tryParse(json['new_balance'].toString())
              : null,
      beneficiaryMsisdn: json['beneficiary_msisdn']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType,
      'action_label': actionLabel,
      'endpoint': endpoint,
      'status': status,
      'amount': amount,
      'currency': currency,
      'external_reference': externalReference,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'old_balance': oldBalance,
      'new_balance': newBalance,
      'beneficiary_msisdn': beneficiaryMsisdn,
      'metadata': metadata,
    };
  }

  /// Retourne l'icône appropriée selon le type d'action
  String get icon {
    switch (actionType) {
      case 'offer_purchase':
      case 'offer_gift':
      case 'offer_received':
        return '📦';
      case 'credit_add':
      case 'voucher_refill':
      case 'credit_received':
        return '💰';
      case 'credit_deduct':
        return '💸';
      case 'credit_transfer':
        return '↗️';
      case 'topup_subscribe_package':
        return '📱';
      case 'topup_recharge_account':
        return '🔋';
      case 'profile_update':
        return '👤';
      default:
        return '📝';
    }
  }

  /// Retourne la couleur appropriée selon le statut
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'success':
        return 'green';
      case 'failed':
      case 'error':
        return 'red';
      case 'pending':
        return 'orange';
      default:
        return 'gray';
    }
  }

  /// Formate le montant avec la devise
  String get formattedAmount {
    if (amount == null) return '';
    final curr = currency ?? 'DJF';
    return '${amount!.toStringAsFixed(0)} $curr';
  }

  /// Formate la date pour l'affichage
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} à ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Retourne des détails supplémentaires pour l'affichage dans l'historique
  String? get detailsText {
    final parts = <String>[];

    // La description renvoyée par l'API contient souvent un contexte plus
    // riche que le libellé (ex: motif d'échec d'un voucher déjà utilisé)
    if (description != null &&
        description!.trim().isNotEmpty &&
        description != actionLabel) {
      parts.add(description!);
    }

    if (beneficiaryMsisdn != null && beneficiaryMsisdn!.isNotEmpty) {
      parts.add('Vers: ${cleanPhoneNumber(beneficiaryMsisdn!)}');
    }

    if (oldBalance != null && newBalance != null) {
      parts.add(
        'Solde: ${oldBalance!.toStringAsFixed(0)} → ${newBalance!.toStringAsFixed(0)} DJF',
      );
    }

    return parts.isEmpty ? null : parts.join('\n');
  }
}

const _localPhonePrefixes = ['77', '78', '70', '75', '76', '33'];

/// Nettoie un numéro de téléphone (253XXXXXXXX) pour n'afficher que le
/// numéro local lorsque c'est un numéro djiboutien.
String cleanPhoneNumber(String value) {
  final cleaned = value.replaceAll('253', '');
  for (final prefix in _localPhonePrefixes) {
    if (cleaned.startsWith(prefix)) return cleaned;
  }
  return value;
}

class ActivityPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ActivityPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ActivityPagination.fromJson(Map<String, dynamic> json) {
    return ActivityPagination(
      currentPage:
          json['current_page'] is int
              ? json['current_page']
              : int.tryParse(json['current_page']?.toString() ?? '0') ?? 0,
      lastPage:
          json['last_page'] is int
              ? json['last_page']
              : int.tryParse(json['last_page']?.toString() ?? '0') ?? 0,
      perPage:
          json['per_page'] is int
              ? json['per_page']
              : int.tryParse(json['per_page']?.toString() ?? '0') ?? 0,
      total:
          json['total'] is int
              ? json['total']
              : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

class ActivityFilters {
  final String msisdn;
  final int days;
  final int perPage;

  ActivityFilters({
    required this.msisdn,
    required this.days,
    required this.perPage,
  });

  factory ActivityFilters.fromJson(Map<String, dynamic> json) {
    return ActivityFilters(
      msisdn: json['msisdn']?.toString() ?? '',
      days:
          json['days'] is int
              ? json['days']
              : int.tryParse(json['days']?.toString() ?? '30') ?? 30,
      perPage:
          json['per_page'] is int
              ? json['per_page']
              : int.tryParse(json['per_page']?.toString() ?? '20') ?? 20,
    );
  }
}

class ActivityHistoryResponse {
  final bool success;
  final List<Activity> data;
  final ActivityPagination pagination;
  final ActivityFilters filters;

  ActivityHistoryResponse({
    required this.success,
    required this.data,
    required this.pagination,
    required this.filters,
  });

  factory ActivityHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryResponse(
      success: json['success'],
      data:
          (json['data'] as List)
              .map((item) => Activity.fromJson(item))
              .toList(),
      pagination: ActivityPagination.fromJson(json['pagination']),
      filters: ActivityFilters.fromJson(json['filters']),
    );
  }
}

class ActivityStats {
  final String actionType;
  final String actionLabel;
  final int totalCount;
  final int successCount;
  final double successRate;
  final double totalAmount;

  ActivityStats({
    required this.actionType,
    required this.actionLabel,
    required this.totalCount,
    required this.successCount,
    required this.successRate,
    required this.totalAmount,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      actionType: json['action_type'].toString(),
      actionLabel: json['action_label'].toString(),
      totalCount: int.tryParse(json['total_count'].toString()) ?? 0,
      successCount: int.tryParse(json['success_count'].toString()) ?? 0,
      successRate: double.tryParse(json['success_rate'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
    );
  }

  /// Retourne l'icône appropriée selon le type d'action
  String get icon {
    switch (actionType) {
      case 'offer_purchase':
      case 'offer_gift':
      case 'offer_received':
        return '📦';
      case 'credit_add':
      case 'voucher_refill':
      case 'credit_received':
        return '💰';
      case 'credit_deduct':
        return '💸';
      case 'credit_transfer':
        return '↗️';
      case 'topup_subscribe_package':
        return '📱';
      case 'topup_recharge_account':
        return '🔋';
      case 'profile_update':
        return '👤';
      default:
        return '📝';
    }
  }

  /// Formate le montant total
  String get formattedTotalAmount {
    return '${totalAmount.toStringAsFixed(0)} DJF';
  }

  /// Formate le taux de succès
  String get formattedSuccessRate {
    return '${successRate.toStringAsFixed(1)}%';
  }
}

class ActivityStatsResponse {
  final bool success;
  final List<ActivityStats> data;
  final int periodDays;
  final String msisdn;

  ActivityStatsResponse({
    required this.success,
    required this.data,
    required this.periodDays,
    required this.msisdn,
  });

  factory ActivityStatsResponse.fromJson(Map<String, dynamic> json) {
    return ActivityStatsResponse(
      success: json['success'] == true,
      data:
          (json['data'] as List)
              .map((item) => ActivityStats.fromJson(item))
              .toList(),
      periodDays: int.tryParse(json['period_days'].toString()) ?? 30,
      msisdn: json['msisdn'].toString(),
    );
  }

  /// Calcule le montant total de toutes les activités
  double get totalAmount {
    return data.fold(0.0, (sum, stat) => sum + stat.totalAmount);
  }

  /// Calcule le nombre total d'actions
  int get totalActions {
    return data.fold(0, (sum, stat) => sum + stat.totalCount);
  }

  /// Calcule le taux de succès global
  double get overallSuccessRate {
    if (totalActions == 0) return 0.0;
    final totalSuccess = data.fold(0, (sum, stat) => sum + stat.successCount);
    return (totalSuccess / totalActions) * 100;
  }
}
