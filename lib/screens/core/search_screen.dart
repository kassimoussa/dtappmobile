// lib/screens/core/search_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/topup/home/topup_home_screen.dart';
import 'package:dtservices/screens/user/profile_screen.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../routes/custom_route_transitions.dart';
import '../../services/user_session.dart';
import '../../generated/l10n/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<SearchItem> _allItems = [];
  List<SearchItem> _filteredItems = [];
  String _searchQuery = '';
  bool _isLoading = true;

  // Données utilisateur pour navigation
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Auto-focus sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSearchItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final phoneNumber = await UserSession.getPhoneNumber();

      if (mounted) {
        setState(() {
          _phoneNumber = phoneNumber ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeSearchItems() {
    final l10n = AppLocalizations.of(context)!;
    _allItems = [
      // Actions principales
      SearchItem(
        title: l10n.searchBuyPackage,
        subtitle: l10n.searchBuyPackageSub,
        keywords: ['forfait', 'achat', 'package', 'data', 'voix', 'internet'],
        icon: Icons.local_mall_sharp,
        category: l10n.categoryActions,
        action: () => _navigateToForfait(),
      ),
      SearchItem(
        title: l10n.searchCreditRefill,
        subtitle: l10n.searchCreditRefillSub,
        keywords: ['recharge', 'credit', 'argent', 'solde', 'refill'],
        icon: Icons.add_circle,
        category: l10n.categoryActions,
        action: () => _navigateToRecharge(),
      ),
      SearchItem(
        title: l10n.searchCreditTransfer,
        subtitle: l10n.searchCreditTransferSub,
        keywords: ['transfert', 'envoyer', 'credit', 'partage', 'transfer'],
        icon: Icons.send,
        category: l10n.categoryActions,
        action: () => _navigateToTransfer(),
      ),
      SearchItem(
        title: l10n.searchMyPackages,
        subtitle: l10n.searchMyPackagesSub,
        keywords: ['mes forfaits', 'actifs', 'consommation', 'historique', 'packages'],
        icon: Icons.timer,
        category: l10n.categoryConsultation,
        action: () => _navigateToForfaitsActifs(),
      ),

      // TopUp
      SearchItem(
        title: l10n.searchTopUpLine,
        subtitle: l10n.searchTopUpLineSub,
        keywords: ['topup', 'fixe', 'ligne', 'consultation', 'fixed'],
        icon: Icons.phone,
        category: l10n.categoryTopUp,
        action: () => _navigateToTopUp(),
      ),
      SearchItem(
        title: l10n.searchBuySubscription,
        subtitle: l10n.searchBuySubscriptionSub,
        keywords: ['souscription', 'topup', 'package', 'fixe', 'subscription'],
        icon: Icons.subscriptions,
        category: l10n.categoryTopUp,
        action: () => _navigateToTopUp(),
      ),
      SearchItem(
        title: l10n.searchRechargeFixed,
        subtitle: l10n.searchRechargeFixedSub,
        keywords: ['recharge', 'fixe', 'transfert', 'topup', 'fixed'],
        icon: Icons.account_balance_wallet,
        category: l10n.categoryTopUp,
        action: () => _navigateToTopUp(),
      ),

      // Profil et compte
      SearchItem(
        title: l10n.searchMyProfile,
        subtitle: l10n.searchMyProfileSub,
        keywords: ['profil', 'compte', 'informations', 'email', 'nom', 'profile'],
        icon: Icons.person,
        category: l10n.categoryAccount,
        action: () => _navigateToProfile(),
      ),
      SearchItem(
        title: l10n.searchMainBalance,
        subtitle: l10n.searchMainBalanceSub,
        keywords: ['solde', 'argent', 'balance', 'credit'],
        icon: Icons.account_balance_wallet_outlined,
        category: l10n.categoryConsultation,
        action: () => Navigator.pop(context),
      ),
      SearchItem(
        title: l10n.searchBonusBalance,
        subtitle: l10n.searchBonusBalanceSub,
        keywords: ['bonus', 'solde', 'compte', 'dedié'],
        icon: Icons.add_card,
        category: l10n.categoryConsultation,
        action: () => Navigator.pop(context),
      ),
    ];

    _filteredItems = List.from(_allItems);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredItems = List.from(_allItems);
      } else {
        _filteredItems = _allItems.where((item) {
          return item.title.toLowerCase().contains(_searchQuery) ||
                 item.subtitle.toLowerCase().contains(_searchQuery) ||
                 item.keywords.any((keyword) => keyword.toLowerCase().contains(_searchQuery));
        }).toList();
      }
    });
  }

  // Navigation methods
  void _navigateToForfait() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: ForfaitRecipientScreen(
          phoneNumber: _phoneNumber,
        ),
      ),
    );
  }

  void _navigateToRecharge() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: RefillRecipientScreen(phoneNumber: _phoneNumber),
      ),
    );
  }

  void _navigateToTransfer() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: TransferInputScreen(
          phoneNumber: _phoneNumber,
        ),
      ),
    );
  }

  void _navigateToForfaitsActifs() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: const ForfaitsActifsScreen(),
      ),
    );
  }

  void _navigateToTopUp() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: const TopUpHomeScreen(),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: const ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(20)),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.searchActionHint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: ResponsiveSize.getFontSize(14),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[500],
                size: ResponsiveSize.getFontSize(20),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[500],
                        size: ResponsiveSize.getFontSize(18),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: ResponsiveSize.getHeight(8),
              ),
            ),
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.black87,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(l10n)
          : Column(
              children: [
                _buildSearchSummary(l10n),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? _buildNoResultsState(l10n)
                      : _buildSearchResults(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.dtBlue),
          SizedBox(height: ResponsiveSize.getHeight(16)),
          Text(
            l10n.loading,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary(AppLocalizations l10n) {
    final resultCount = _filteredItems.length;
    final totalCount = _allItems.length;

    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _searchQuery.isEmpty
                ? l10n.searchActionsAvailable(totalCount)
                : l10n.searchResultsFound(resultCount),
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Text(
              l10n.searchFor(_searchQuery),
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(12),
                color: AppTheme.dtBlue,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(32)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: ResponsiveSize.getFontSize(64),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveSize.getHeight(16)),
            Text(
              l10n.noResultsFound,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              l10n.searchSuggestions,
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

  Widget _buildSearchResults() {
    // Grouper les résultats par catégorie
    final groupedItems = <String, List<SearchItem>>{};
    for (final item in _filteredItems) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final category = groupedItems.keys.elementAt(index);
        final items = groupedItems[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) SizedBox(height: ResponsiveSize.getHeight(24)),
            _buildCategoryHeader(category),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            ...items.map((item) => _buildSearchItem(item)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize.getWidth(4),
        vertical: ResponsiveSize.getHeight(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: ResponsiveSize.getFontSize(16),
          fontWeight: FontWeight.bold,
          color: AppTheme.dtBlue,
        ),
      ),
    );
  }

  Widget _buildSearchItem(SearchItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(8)),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(12)),
      ),
      child: ListTile(
        onTap: item.action,
        leading: CircleAvatar(
          backgroundColor: AppTheme.dtBlueO10,
          child: Icon(
            item.icon,
            color: AppTheme.dtBlue,
            size: ResponsiveSize.getFontSize(20),
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: ResponsiveSize.getFontSize(14),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.getWidth(16),
          vertical: ResponsiveSize.getHeight(4),
        ),
      ),
    );
  }
}

class SearchItem {
  final String title;
  final String subtitle;
  final List<String> keywords;
  final IconData icon;
  final String category;
  final VoidCallback action;

  SearchItem({
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.icon,
    required this.category,
    required this.action,
  });
}
