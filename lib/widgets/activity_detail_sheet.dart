// lib/widgets/activity_detail_sheet.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../models/activity.dart';
import '../generated/l10n/app_localizations.dart';

/// Affiche les détails d'une activité dans une feuille modale.
Future<void> showActivityDetailSheet(BuildContext context, Activity activity) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ActivityDetailSheet(activity: activity),
  );
}

class ActivityDetailSheet extends StatelessWidget {
  final Activity activity;

  const ActivityDetailSheet({super.key, required this.activity});

  // Types pour lesquels displayTitle contient déjà le nom de l'offre/package :
  // la description brute de l'API ne fait alors que répéter la même info.
  static const Set<String> _typesWithEnrichedTitle = {
    'topup_subscribe_package',
    'offer_purchase',
    'offer_gift',
  };

  // Types dont les infos de la description (destinataire, frais...) sont
  // déjà reconstruites sous forme de lignes dédiées dans le tableau de détails.
  static const Set<String> _typesWithOwnDetailRows = {
    'credit_received',
    'credit_transfer',
    'offer_received',
  };

  static const List<String> _phonePrefixes = [
    '77',
    '78',
    '70',
    '75',
    '76',
    '33',
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'offer_purchase':
      case 'offer_gift':
      case 'offer_received':
        return Icons.local_mall_rounded;
      case 'credit_add':
      case 'voucher_refill':
      case 'credit_received':
        return Icons.add_circle_rounded;
      case 'credit_deduct':
        return Icons.remove_circle_rounded;
      case 'credit_transfer':
        return Icons.send_rounded;
      case 'topup_subscribe_package':
        return Icons.phone_android_rounded;
      case 'topup_recharge_account':
        return Icons.battery_charging_full_rounded;
      case 'profile_update':
        return Icons.person_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'failed':
      case 'error':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'success':
        return l10n.statusSuccessLabel;
      case 'failed':
      case 'error':
        return l10n.statusFailedLabel;
      case 'pending':
        return l10n.statusPendingLabel;
      default:
        return l10n.unknownStatus;
    }
  }

  String _cleanPhoneNumber(String value) {
    final cleaned = value.replaceAll('253', '');
    for (final prefix in _phonePrefixes) {
      if (cleaned.startsWith(prefix)) return cleaned;
    }
    return value;
  }

  String? get _fixedLineNumber =>
      activity.metadata?['fixed_line_number']?.toString();

  static const Set<String> _typesWithSender = {
    'credit_received',
    'offer_received',
  };

  // Le numéro de l'expéditeur n'est pas exposé dans un champ dédié pour les
  // crédits/forfaits reçus : on le récupère dans metadata si présent, sinon
  // on le retrouve dans la description ("Crédit reçu : 50.00 DJF de 77000112").
  String? get _senderMsisdn {
    if (!_typesWithSender.contains(activity.actionType)) return null;

    final metaSender =
        activity.metadata?['sender_msisdn']?.toString() ??
        activity.metadata?['from_msisdn']?.toString();
    if (metaSender != null && metaSender.isNotEmpty) {
      return _cleanPhoneNumber(metaSender);
    }

    if (activity.beneficiaryMsisdn != null &&
        activity.beneficiaryMsisdn!.isNotEmpty) {
      return _cleanPhoneNumber(activity.beneficiaryMsisdn!);
    }

    final match = RegExp(
      r'\bde\s+(\d{8,15})\b',
    ).firstMatch(activity.description ?? '');
    return match != null ? _cleanPhoneNumber(match.group(1)!) : null;
  }

  String? get _packageCode =>
      activity.metadata?['package_code']?.toString() ??
      activity.metadata?['package_id']?.toString();

  String? get _feeAmount {
    final fee = activity.feeValue;
    return fee != null ? '${fee.toStringAsFixed(0)} DJF' : null;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(activity.status);
    final isNegative = activity.isDebit;

    Color amountColor = AppTheme.textPrimary;
    String amountPrefix = '';
    if (activity.status.toLowerCase() == 'success' && activity.amount != null) {
      if (isNegative) {
        amountPrefix = '- ';
      } else {
        amountColor = Colors.green[700]!;
        amountPrefix = '+ ';
      }
    }

    // Tout le contenu informatif de la description (destinataire, frais...)
    // est reconstruit en lignes dédiées dans le tableau ; ce qui reste après
    // extraction retombe dans une ligne "Détails" générique du même tableau,
    // jamais affiché en texte libre sous le titre.
    final showGenericDescriptionRow =
        !_typesWithEnrichedTitle.contains(activity.actionType) &&
        !_typesWithOwnDetailRows.contains(activity.actionType) &&
        activity.description != null &&
        activity.description!.trim().isNotEmpty &&
        activity.description != activity.actionLabel;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            ResponsiveSize.getWidth(AppTheme.spacingM),
            ResponsiveSize.getHeight(AppTheme.spacingS),
            ResponsiveSize.getWidth(AppTheme.spacingM),
            ResponsiveSize.getHeight(AppTheme.spacingL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Poignée de la feuille
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(
                    bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // En-tête : icône + libellé + statut
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveSize.getWidth(14)),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActionIcon(activity.actionType),
                      color: statusColor,
                      size: ResponsiveSize.getFontSize(28),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.displayTitle(l10n),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(18),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.getHeight(6)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(activity.status),
                                size: ResponsiveSize.getFontSize(13),
                                color: statusColor,
                              ),
                              SizedBox(width: ResponsiveSize.getWidth(4)),
                              Text(
                                _statusLabel(activity.status, l10n),
                                style: TextStyle(
                                  fontSize: ResponsiveSize.getFontSize(11),
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (activity.amount != null) ...[
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveSize.getHeight(AppTheme.spacingL),
                  ),
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isNegative
                            ? l10n.amountDebitedLabel
                            : l10n.amountCreditedLabel,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(12),
                          fontWeight: FontWeight.w600,
                          color: amountColor.withValues(alpha: 0.7),
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(4)),
                      Text(
                        "$amountPrefix${activity.totalAmount!.abs().toStringAsFixed(0)} DJF",
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(32),
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Informations générales
              _buildCard([
                _buildInfoRow(l10n.transactionId, activity.transactionNo),
                _buildDivider(),
                _buildInfoRow(l10n.dateKey, activity.formattedDate),
                if (_senderMsisdn != null) ...[
                  _buildDivider(),
                  _buildInfoRow(l10n.fromLabel, _senderMsisdn!),
                ] else if (_fixedLineNumber != null &&
                    _fixedLineNumber!.isNotEmpty) ...[
                  _buildDivider(),
                  _buildInfoRow(l10n.rechargedLineLabel, _fixedLineNumber!),
                ] else if (activity.beneficiaryMsisdn != null &&
                    activity.beneficiaryMsisdn!.isNotEmpty) ...[
                  _buildDivider(),
                  _buildInfoRow(
                    l10n.beneficiaryLabel,
                    _cleanPhoneNumber(activity.beneficiaryMsisdn!),
                  ),
                ],
                if (_packageCode != null && _packageCode!.isNotEmpty) ...[
                  _buildDivider(),
                  _buildInfoRow(l10n.packageCodeLabel, _packageCode!),
                ],
                if (_feeAmount != null) ...[
                  // Sans frais, cette ligne ferait doublon avec le total
                  if (activity.amount != null) ...[
                    _buildDivider(),
                    _buildInfoRow(
                      l10n.amountKey,
                      '${activity.amount!.abs().toStringAsFixed(0)} DJF',
                    ),
                  ],
                  _buildDivider(),
                  _buildInfoRow(l10n.feeLabel, _feeAmount!),
                ],
                if (showGenericDescriptionRow) ...[
                  _buildDivider(),
                  _buildInfoRow(l10n.descriptionLabel, activity.description!),
                ],
                if (activity.totalAmount != null) ...[
                  _buildDivider(),
                  _buildInfoRow(
                    l10n.totalAmountLabel,
                    "$amountPrefix${activity.totalAmount!.abs().toStringAsFixed(0)} DJF",
                  ),
                ],
              ]),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Bouton fermer
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveSize.getHeight(14),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveSize.getWidth(AppTheme.radiusM),
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.closeAction,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveSize.getFontSize(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(16)),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
        vertical: ResponsiveSize.getHeight(4),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[100]);
  }

  Widget _buildInfoRow(
    String? label,
    String value, {
    bool isEmpty = false,
    bool muted = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(12)),
      child:
          isEmpty
              ? Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(13),
                    color: Colors.grey[500],
                  ),
                ),
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Largeur fixe (et non un ratio flex) pour que la colonne
                  // valeur démarre toujours au même endroit sur chaque ligne,
                  // quelle que soit la longueur du libellé.
                  SizedBox(
                    width: ResponsiveSize.getWidth(125),
                    child: Text(
                      label!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(14),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(muted ? 12 : 14),
                        fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
                        fontFamily: muted ? 'monospace' : null,
                        color: muted ? Colors.grey[500] : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
