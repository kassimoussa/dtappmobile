// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../extensions/color_extensions.dart';
import '../routes/custom_route_transitions.dart';
import 'statistics_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Activity> _activities = [];
  ActivityPagination? _pagination;
  ActivityFilters? _filters;
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  
  // Filtres
  int _selectedDays = 30;
  final List<int> _daysOptions = [7, 15, 30, 60, 90];
  
  // Pagination
  int _currentPage = 1;
  final int _perPage = 20;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreHistory();
    }
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _activities.clear();
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ActivityService.getHistory(
        page: _currentPage,
        perPage: _perPage,
        days: _selectedDays,
      );

      if (response != null && mounted) {
        setState(() {
          if (refresh || _currentPage == 1) {
            _activities = response.data;
          } else {
            _activities.addAll(response.data);
          }
          _pagination = response.pagination;
          _filters = response.filters;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement de l\'historique';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement de l\'historique';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMore || _pagination == null || !_pagination!.hasNextPage) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadHistory();
  }

  void _onDaysFilterChanged(int days) {
    setState(() {
      _selectedDays = days;
      _currentPage = 1;
    });
    _loadHistory(refresh: true);
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

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Historique',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveSize.getFontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              CustomRouteTransitions.slideRightRoute(
                page: const StatisticsScreen(),
              ),
            ),
            tooltip: 'Statistiques',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersSection(),
          Expanded(
            child: _isLoading && _activities.isEmpty
                ? _buildLoadingState()
                : _errorMessage != null && _activities.isEmpty
                    ? _buildErrorState()
                    : _activities.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Période',
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
              children: _daysOptions.map((days) {
                final isSelected = days == _selectedDays;
                return Padding(
                  padding: EdgeInsets.only(right: ResponsiveSize.getWidth(8)),
                  child: FilterChip(
                    label: Text(
                      '${days}j',
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
          if (_pagination != null)
            Padding(
              padding: EdgeInsets.only(top: ResponsiveSize.getHeight(8)),
              child: Text(
                '${_pagination!.total} activité${_pagination!.total > 1 ? 's' : ''} trouvée${_pagination!.total > 1 ? 's' : ''}',
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.dtBlue),
          SizedBox(height: ResponsiveSize.getHeight(16)),
          Text(
            'Chargement de l\'historique...',
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
              onPressed: () => _loadHistory(refresh: true),
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
              Icons.history,
              size: ResponsiveSize.getFontSize(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              'Aucune activité',
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

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: () => _loadHistory(refresh: true),
      color: AppTheme.dtBlue,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        itemCount: _activities.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _activities.length) {
            return _buildLoadingMoreIndicator();
          }
          
          final activity = _activities[index];
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
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
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
                        color: _getStatusColor(activity.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
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
                        padding: EdgeInsets.only(top: ResponsiveSize.getHeight(4)),
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