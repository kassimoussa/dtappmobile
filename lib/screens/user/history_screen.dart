// lib/screens/user/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../models/activity.dart';
import '../../providers/transaction_provider.dart';
import '../../extensions/color_extensions.dart';
import '../../routes/custom_route_transitions.dart';
import '../statistics/statistics_screen.dart';
import '../../generated/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<int> _daysOptions = [7, 15, 30, 60, 90];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Charger l'historique via le provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionProvider>().loadMore();
    }
  }

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
        return Icons.local_mall;
      case 'credit_add':
      case 'voucher_refill':
      case 'credit_received':
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

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          l10n.historyTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  CustomRouteTransitions.slideRightRoute(
                    page: const StatisticsScreen(),
                  ),
                ),
            tooltip: l10n.statisticsTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(transactionProvider),
          Expanded(
            child:
                transactionProvider.isLoading && transactionProvider.activities.isEmpty
                    ? _buildLoadingState()
                    : transactionProvider.errorMessage != null && transactionProvider.activities.isEmpty
                    ? _buildErrorState(transactionProvider)
                    : transactionProvider.activities.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(transactionProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(TransactionProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.periodLabel,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              fontWeight: FontWeight.w600,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(8)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _daysOptions.map((days) {
                    final isSelected = days == provider.selectedDays;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: ResponsiveSize.getWidth(8),
                      ),
                      child: FilterChip(
                        label: Text(
                          l10n.daysUnit(days),
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.dtBlue,
                            fontSize: ResponsiveSize.getFontSize(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => provider.changeDaysFilter(days),
                        backgroundColor: Colors.white,
                        selectedColor: AppTheme.dtBlue,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color:
                              isSelected ? AppTheme.dtBlue : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          if (provider.pagination != null)
            Padding(
              padding: EdgeInsets.only(top: ResponsiveSize.getHeight(8)),
              child: Text(
                l10n.activitiesFound(provider.pagination!.total),
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(12),
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.dtBlue),
          SizedBox(height: ResponsiveSize.getHeight(16)),
          Text(
            l10n.historyLoading,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(TransactionProvider provider) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.loadingErrorTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              provider.errorMessage ?? l10n.error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(24)),
            ElevatedButton(
              onPressed: () => provider.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: ResponsiveSize.getFontSize(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              l10n.emptyHistoryTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              l10n.emptyHistoryMessage,
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

  Widget _buildHistoryList(TransactionProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppTheme.dtBlue,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        itemCount: provider.activities.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.activities.length) {
            return _buildLoadingMoreIndicator();
          }

          final activity = provider.activities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
      alignment: Alignment.center,
      child: SizedBox(
        width: ResponsiveSize.getWidth(24),
        height: ResponsiveSize.getHeight(24),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
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
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(8),
                    ),
                  ),
                  child: Icon(
                    _getActionIcon(activity.actionType),
                    color: AppTheme.dtBlue,
                    size: ResponsiveSize.getFontSize(20),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.actionLabel,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(16),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(4)),
                      Text(
                        activity.formattedDate,
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(12),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveSize.getWidth(8),
                        vertical: ResponsiveSize.getHeight(4),
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          activity.status,
                        ).withOpacityValue(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveSize.getWidth(12),
                        ),
                      ),
                      child: Text(
                        activity.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(10),
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(activity.status),
                        ),
                      ),
                    ),
                    if (activity.amount != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: ResponsiveSize.getHeight(4),
                        ),
                        child: Text(
                          activity.formattedAmount,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(14),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dtBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (activity.detailsText != null)
              Padding(
                padding: EdgeInsets.only(top: ResponsiveSize.getHeight(8)),
                child: Text(
                  activity.detailsText!,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(12),
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
