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

  // Libellés français pour les clés techniques retournées par l'API
  // (champ "metadata" de l'activité, spécifique à chaque type d'action,
  // voir activity-history-responses.md section 4)
  static const Map<String, String> _detailLabels = {
    'offer_name': 'Offre',
    'package_name': 'Package',
    'validity_days': 'Validité',
    'fixed_line_number': 'Ligne fixe',
    'voucher_serial': 'Numéro de voucher',
    'voucher_value': 'Valeur du voucher',
    'refill_type': 'Type de recharge',
    'recharge_type': 'Type de recharge',
    'sender_msisdn': 'Expéditeur',
    'contact_name': 'Contact',
    'contact_number': 'Numéro du contact',
    'error_code': 'Code erreur',
  };

  // Valeurs techniques traduites pour un affichage plus lisible
  static const Map<String, String> _valueLabels = {
    'personal': 'Personnel',
    'gift': 'Cadeau',
    'voucher': 'Voucher',
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

  String _formatLabel(String key) {
    final knownLabel = _detailLabels[key];
    if (knownLabel != null) return knownLabel;

    return key
        .split('_')
        .map(
          (word) =>
              word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatValue(String key, dynamic value) {
    final text = value.toString();
    if (text.isEmpty) return text;

    final knownValue = _valueLabels[text];
    if (knownValue != null) return knownValue;

    if (key.contains('msisdn') ||
        key.contains('destinataire') ||
        key.contains('expediteur') ||
        key.contains('numero') ||
        key.contains('phone')) {
      return _cleanPhoneNumber(text);
    }

    if (key.contains('montant') || key.contains('solde')) {
      final parsed = double.tryParse(text);
      if (parsed != null) return '${parsed.toStringAsFixed(0)} DJF';
    }

    if (key == 'validity_days') {
      final days = int.tryParse(text);
      if (days != null) return '$days jour${days > 1 ? 's' : ''}';
    }

    if (key == 'voucher_value') {
      final parsed = double.tryParse(text);
      if (parsed != null) return '${parsed.toStringAsFixed(0)} DJF';
    }

    return text;
  }

  // Clés techniques à ne jamais afficher à l'utilisateur
  // (error_message duplique déjà activity.description pour les échecs ;
  // offer_id/package_id/selected_option sont des codes internes déjà
  // reflétés par offer_name/package_name/refill_type)
  static const Set<String> _hiddenKeys = {
    'success',
    'message',
    'error_message',
    'status',
    'http_code',
    'error',
    'errors',
    'token',
    'signature',
    'raw',
    'offer_id',
    'package_id',
    'selected_option',
    // déjà affiché via le champ racine beneficiary_msisdn (info card)
    'to_msisdn',
  };

  List<MapEntry<String, String>> _buildDetailRows() {
    final metadata = activity.metadata;
    if (metadata == null) return [];

    final rows = <MapEntry<String, String>>[];
    for (final entry in metadata.entries) {
      if (_hiddenKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value == null) continue;
      // On évite d'afficher des objets/listes imbriqués bruts
      if (value is Map || value is List) continue;
      final text = value.toString();
      if (text.isEmpty) continue;
      rows.add(
        MapEntry(_formatLabel(entry.key), _formatValue(entry.key, value)),
      );
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor(activity.status);
    final isNegative =
        activity.actionType == 'credit_deduct' ||
        (activity.amount != null && activity.amount! < 0);

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

    final detailRows = _buildDetailRows();
    final showDescription =
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
                          activity.actionLabel,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(18),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: ResponsiveSize.getHeight(4)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(activity.status, l10n),
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(11),
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (showDescription) ...[
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
                Text(
                  activity.description!,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(13),
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],

              if (activity.amount != null) ...[
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                Center(
                  child: Text(
                    "$amountPrefix${activity.amount!.toStringAsFixed(0)} DJF",
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(32),
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Informations générales
              _buildCard([
                _buildInfoRow(l10n.dateKey, activity.formattedDate),
                _buildDivider(),
                _buildInfoRow(l10n.transactionId, '#${activity.id}'),
                if (activity.externalReference != null) ...[
                  _buildDivider(),
                  _buildInfoRow(
                    l10n.referenceLabel,
                    activity.externalReference!,
                  ),
                ],
                if (activity.beneficiaryMsisdn != null &&
                    activity.beneficiaryMsisdn!.isNotEmpty) ...[
                  _buildDivider(),
                  _buildInfoRow(
                    l10n.beneficiaryLabel,
                    _cleanPhoneNumber(activity.beneficiaryMsisdn!),
                  ),
                ],
                if (activity.oldBalance != null &&
                    activity.newBalance != null) ...[
                  _buildDivider(),
                  _buildInfoRow(
                    l10n.balanceBeforeLabel,
                    '${activity.oldBalance!.toStringAsFixed(0)} DJF',
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    l10n.balanceAfterLabel,
                    '${activity.newBalance!.toStringAsFixed(0)} DJF',
                  ),
                ],
              ]),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

              // Détails spécifiques
              _buildSectionTitle(l10n.activityDetailTitle),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              detailRows.isEmpty
                  ? _buildCard([
                    _buildInfoRow(
                      null,
                      l10n.noAdditionalDetails,
                      isEmpty: true,
                    ),
                  ])
                  : _buildCard([
                    for (int i = 0; i < detailRows.length; i++) ...[
                      if (i > 0) _buildDivider(),
                      _buildInfoRow(detailRows[i].key, detailRows[i].value),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveSize.getFontSize(14),
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: -0.2,
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

  Widget _buildInfoRow(String? label, String value, {bool isEmpty = false}) {
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
                  Expanded(
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(14),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                  Flexible(
                    flex: 2,
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(14),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
