// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../extensions/color_extensions.dart';
import '../widgets/appbar_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  ActivityStatsResponse? _statsResponse;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filtres
  int _selectedDays = 30;
  final List<int> _daysOptions = [7, 15, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ActivityService.getStats(days: _selectedDays);

      if (response != null && mounted) {
        setState(() {
          _statsResponse = response;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des statistiques';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des statistiques';
          _isLoading = false;
        });
      }
    }
  }

  void _onDaysFilterChanged(int days) {
    setState(() {
      _selectedDays = days;
    });
    _loadStats();
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'offer_purchase':
      case 'offer_gift':
        return Icons.local_mall;
      case 'credit_add':
      case 'voucher_refill':
        return Icons.add_circle;
      case 'credit_deduct':
        return Icons.remove_circle;
      case 'credit_transfer':
        return Icons.send;
      case 'topup_subscribe_package':
        return Icons.phone;
      case 'topup_recharge_account':
        return Icons.battery_charging_full;
      case 'profile_update':
        return Icons.person;
      default:
        return Icons.description;
    }
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Statistiques',
        showAction: false,
        showCancelToHome: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _statsResponse == null || _statsResponse!.data.isEmpty
                  ? _buildEmptyState()
                  : _buildStatsContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.dtBlue),
          SizedBox(height: ResponsiveSize.getHeight(16)),
          Text(
            'Chargement des statistiques...',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveSize.getFontSize(64),
              color: Colors.red[300],
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(24)),
            ElevatedButton(
              onPressed: _loadStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
              ),
              child: Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: ResponsiveSize.getFontSize(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              'Aucune statistique',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              'Aucune activité trouvée pour la période sélectionnée',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltersSection(),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
          _buildOverviewCards(),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
          _buildStatsDetails(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Période d\'analyse',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(12)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _daysOptions.map((days) {
                final isSelected = days == _selectedDays;
                return Padding(
                  padding: EdgeInsets.only(right: ResponsiveSize.getWidth(8)),
                  child: FilterChip(
                    label: Text(
                      '$days jours',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.dtBlue,
                        fontSize: ResponsiveSize.getFontSize(12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onDaysFilterChanged(days),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.dtBlue,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppTheme.dtBlue : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final stats = _statsResponse!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(12)),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Total dépensé',
                value: '${stats.totalAmount.toStringAsFixed(0)} DJF',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(12)),
            Expanded(
              child: _buildOverviewCard(
                title: 'Actions totales',
                value: '${stats.totalActions}',
                icon: Icons.trending_up,
                color: AppTheme.dtBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.getHeight(12)),
        _buildOverviewCard(
          title: 'Taux de succès global',
          value: '${stats.overallSuccessRate.toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: _getSuccessRateColor(stats.overallSuccessRate),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: ResponsiveSize.getFontSize(20)),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(12),
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDetails() {
    final stats = _statsResponse!.data;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail par action',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(12)),
        ...stats.map((stat) => _buildStatCard(stat)),
      ],
    );
  }

  Widget _buildStatCard(ActivityStats stat) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(12)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(8)),
                  decoration: BoxDecoration(
                    color: AppTheme.dtBlue.withOpacityValue(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
                  ),
                  child: Icon(
                    _getActionIcon(stat.actionType),
                    color: AppTheme.dtBlue,
                    size: ResponsiveSize.getFontSize(20),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(12)),
                Expanded(
                  child: Text(
                    stat.actionLabel,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(8),
                    vertical: ResponsiveSize.getHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: _getSuccessRateColor(stat.successRate).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
                  ),
                  child: Text(
                    stat.formattedSuccessRate,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(12),
                      fontWeight: FontWeight.bold,
                      color: _getSuccessRateColor(stat.successRate),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(12)),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'Total',
                    value: '${stat.totalCount}',
                    color: Colors.grey[600]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Réussis',
                    value: '${stat.successCount}',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'Montant',
                    value: stat.formattedTotalAmount,
                    color: AppTheme.dtBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(11),
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(4)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}