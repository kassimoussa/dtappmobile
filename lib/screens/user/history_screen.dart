// lib/screens/user/history_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../models/activity.dart';
import '../../providers/transaction_provider.dart';
import '../../routes/custom_route_transitions.dart';
import '../../widgets/activity_detail_sheet.dart';
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

  String _getDateHeader(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return l10n.todayLabel;
    } else if (dateToCheck == yesterday) {
      return l10n.yesterdayLabel;
    } else {
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          // Radial Gradient Background (App-like feel)
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.dtBlueO08, Colors.transparent],
                  radius: 0.8,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: l10n.historyTitle, showBack: false, actions: [GlassAppBarAction(icon: Icons.bar_chart_rounded, label: 'Stats', onTap: () => Navigator.push(context, CustomRouteTransitions.slideRightRoute(page: const StatisticsScreen())))]),
                _buildFiltersSection(transactionProvider, l10n),
                Expanded(child: _buildBodyContent(transactionProvider)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFiltersSection(TransactionProvider provider, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveSize.getHeight(8),
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children:
              _daysOptions.map((days) {
                final isSelected = days == provider.selectedDays;
                return Padding(
                  padding: EdgeInsets.only(right: ResponsiveSize.getWidth(10)),
                  child: InkWell(
                    onTap: () => provider.changeDaysFilter(days),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.dtBlueDark
                                : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppTheme.dtBlueDark
                                  : Colors.grey[300]!,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  const BoxShadow(
                                    color: AppTheme.dtBlueO30,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                                : [],
                      ),
                      child: Text(
                        l10n.daysFilterLabel(days),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontSize: ResponsiveSize.getFontSize(13),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildBodyContent(TransactionProvider provider) {
    if (provider.isLoading && provider.activities.isEmpty) {
      return _buildLoadingState();
    } else if (provider.errorMessage != null && provider.activities.isEmpty) {
      return _buildErrorState(provider);
    } else if (provider.activities.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildHistoryList(provider);
    }
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.dtBlueDark, strokeWidth: 3),
          SizedBox(height: ResponsiveSize.getHeight(16)),
          Text(
            l10n.historyLoading,
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

  Widget _buildErrorState(TransactionProvider provider) {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.loadingErrorTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              provider.errorMessage ?? l10n.error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(32)),
            ElevatedButton(
              onPressed: () => provider.refresh(),
              style: AppTheme.primaryButtonStyle.copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: ResponsiveSize.getFontSize(48),
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(24)),
            Text(
              l10n.emptyHistoryTitle,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
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
    final l10n = AppLocalizations.of(context)!;
    final items = <Widget>[];
    String? lastDate;

    // On masque les opérations échouées de l'historique affiché
    final visibleActivities = provider.activities
        .where((a) => a.status.toLowerCase() != 'failed' && a.status.toLowerCase() != 'error')
        .toList();

    if (visibleActivities.isEmpty) {
      return _buildEmptyState();
    }

    // Construction de la liste sémantique avec headers
    for (int i = 0; i < visibleActivities.length; i++) {
      final activity = visibleActivities[i];
      final currentHeader = _getDateHeader(activity.createdAt, l10n);

      if (currentHeader != lastDate) {
        items.add(_buildDateHeader(currentHeader));
        lastDate = currentHeader;
      }
      items.add(_buildActivityCard(activity, l10n));
    }

    if (provider.isLoadingMore) {
      items.add(_buildLoadingMoreIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: AppTheme.dtBlueDark,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: ResponsiveSize.getWidth(AppTheme.spacingM),
          right: ResponsiveSize.getWidth(AppTheme.spacingM),
          top: ResponsiveSize.getHeight(8),
          bottom: ResponsiveSize.getHeight(32),
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return items[index];
        },
      ),
    );
  }

  Widget _buildDateHeader(String dateText) {
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveSize.getHeight(24),
        bottom: ResponsiveSize.getHeight(8),
        left: ResponsiveSize.getWidth(4),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: ResponsiveSize.getFontSize(18),
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(24)),
      alignment: Alignment.center,
      child: SizedBox(
        width: ResponsiveSize.getWidth(24),
        height: ResponsiveSize.getHeight(24),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlueDark),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity, AppLocalizations l10n) {
    final statusColor = _getStatusColor(activity.status);
    final isNegative = activity.isDebit;

    // Determining amount text styling dynamically
    Color amountColor = Colors.black87;
    String amountPrefix = '';
    if (activity.status.toLowerCase() == 'success') {
      if (isNegative) {
        amountColor = Colors.black87;
        amountPrefix = '- ';
      } else {
        amountColor = Colors.green[700]!;
        amountPrefix = '+ ';
      }
    }

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
          ),
        ],
      ),
      child: InkWell(
        onTap: () => showActivityDetailSheet(context, activity),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(16)),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Icon Container with dynamic color
              Container(
                padding: EdgeInsets.all(ResponsiveSize.getWidth(12)),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(activity.actionType),
                  color: statusColor,
                  size: ResponsiveSize.getFontSize(22),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.displayTitle(l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.getHeight(4)),
                    // Time and Status Row
                    Row(
                      children: [
                        Text(
                          "${activity.createdAt.hour}:${activity.createdAt.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(13),
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (activity.status.toLowerCase() != 'success') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activity.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: ResponsiveSize.getFontSize(10),
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(12)),
              // Amount Details
              if (activity.amount != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$amountPrefix${activity.amount!.toStringAsFixed(0)} DJF",
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
