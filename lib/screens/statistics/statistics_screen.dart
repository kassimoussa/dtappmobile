// lib/screens/statistics/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../extensions/color_extensions.dart';
import '../../generated/l10n/app_localizations.dart';

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
          _errorMessage = AppLocalizations.of(context)!.historyLoadError;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.historyLoadError;
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
        return Icons.local_mall_rounded;
      case 'credit_add':
      case 'voucher_refill':
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
        return Icons.description_rounded;
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          // Background Radial Gradient for Premium Feel
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueO08,
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: l10n.statsTitle),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _errorMessage != null
                      ? _buildErrorState()
                      : _statsResponse == null || _statsResponse!.data.isEmpty
                      ? _buildEmptyState()
                      : _buildStatsContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.dtBlueDark, strokeWidth: 3),
          SizedBox(height: ResponsiveSize.getHeight(16)),
          Text(
            AppLocalizations.of(context)!.historyLoading,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: ResponsiveSize.getFontSize(48),
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(24)),
            Text(
              AppLocalizations.of(context)!.loadingErrorTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              _errorMessage ?? AppLocalizations.of(context)!.genericRetryError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(32)),
            ElevatedButton(
              onPressed: _loadStats,
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              ),
              child: Text(AppLocalizations.of(context)!.retry),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, spreadRadius: 5)
                ]
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: ResponsiveSize.getFontSize(48),
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(24)),
            Text(
              AppLocalizations.of(context)!.emptyHistoryTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              AppLocalizations.of(context)!.emptyHistoryMessage,
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
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltersSection(),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
          _buildOverviewCards(),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
          _buildStatsDetails(),
          SizedBox(height: ResponsiveSize.getHeight(32)),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: ResponsiveSize.getWidth(4), bottom: ResponsiveSize.getHeight(12)),
            child: Text(
              AppLocalizations.of(context)!.analysisPeriod,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlueDark,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _daysOptions.map((days) {
                final isSelected = days == _selectedDays;
                return Padding(
                  padding: EdgeInsets.only(right: ResponsiveSize.getWidth(10)),
                  child: InkWell(
                    onTap: () => _onDaysFilterChanged(days),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.dtBlueDark : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.dtBlueDark : Colors.grey[300]!,
                        ),
                        boxShadow: isSelected ? [
                          const BoxShadow(color: AppTheme.dtBlueO30, blurRadius: 8, offset: Offset(0, 4))
                        ] : [],
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.daysUnit(days),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontSize: ResponsiveSize.getFontSize(13),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
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
        Padding(
          padding: EdgeInsets.only(left: ResponsiveSize.getWidth(4), bottom: ResponsiveSize.getHeight(12)),
          child: Text(
            AppLocalizations.of(context)!.statsOverview,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlueDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: AppLocalizations.of(context)!.totalSpent,
                value: '${stats.totalAmount.toStringAsFixed(0)} DJF',
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green,
              ),
            ),
            SizedBox(width: ResponsiveSize.getWidth(12)),
            Expanded(
              child: _buildOverviewCard(
                title: AppLocalizations.of(context)!.totalActions,
                value: '${stats.totalActions}',
                icon: Icons.trending_up,
                color: AppTheme.dtBlueDark,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.getHeight(12)),
        _buildOverviewCard(
          title: AppLocalizations.of(context)!.globalSuccessRate,
          value: '${stats.overallSuccessRate.toStringAsFixed(1)}%',
          icon: Icons.check_circle_rounded,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(16)),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04), // Lighter colored shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: ResponsiveSize.getFontSize(16)),
              ),
              SizedBox(width: ResponsiveSize.getWidth(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(12),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSize.getHeight(12)),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(20),
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
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
        Padding(
          padding: EdgeInsets.only(left: ResponsiveSize.getWidth(4), bottom: ResponsiveSize.getHeight(12)),
          child: Text(
            AppLocalizations.of(context)!.actionDetails,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlueDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
        ...stats.map((stat) => _buildStatCard(stat)),
      ],
    );
  }

  Widget _buildStatCard(ActivityStats stat) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(16)),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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
                    color: AppTheme.dtBlueDark.withOpacityValue(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getActionIcon(stat.actionType),
                    color: AppTheme.dtBlueDark,
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
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(8),
                    vertical: ResponsiveSize.getHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: _getSuccessRateColor(stat.successRate).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: AppLocalizations.of(context)!.total,
                    value: '${stat.totalCount}',
                    color: Colors.grey[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: AppLocalizations.of(context)!.successful,
                    value: '${stat.successCount}',
                    color: Colors.green[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: AppLocalizations.of(context)!.amount,
                    value: stat.formattedTotalAmount,
                    color: AppTheme.dtBlueDark,
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
          label.toUpperCase(),
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(10),
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(4)),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
