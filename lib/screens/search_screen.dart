// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/screens/achat_forfait/forfait_recipient_screen.dart';
import 'package:dtservices/screens/forfaits_actifs/forfaits_actifs_screen.dart';
import 'package:dtservices/screens/transfer_credit/transfer_input_screen.dart';
import 'package:dtservices/screens/refill/refill_recipient_screen.dart';
import 'package:dtservices/screens/topup/home/topup_home_screen.dart';
import 'package:dtservices/screens/profile_screen.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../routes/custom_route_transitions.dart';
import '../services/user_session.dart';
import '../services/balance_service.dart';

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
  double _soldeActuel = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeSearchItems();
    _loadUserData();
    
    // Auto-focus sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
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
      final balanceData = await BalanceService.getCurrentBalance();
      
      if (mounted) {
        setState(() {
          _phoneNumber = phoneNumber ?? '';
          _soldeActuel = balanceData['solde'] != null 
              ? double.parse(balanceData['solde']) / 100 
              : 0.0;
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
    _allItems = [
      // Actions principales
      SearchItem(
        title: 'Achat de forfait',
        subtitle: 'Acheter des forfaits voix et data',
        keywords: ['forfait', 'achat', 'package', 'data', 'voix', 'internet'],
        icon: Icons.local_mall_sharp,
        category: 'Actions',
        action: () => _navigateToForfait(),
      ),
      SearchItem(
        title: 'Recharge de crédit',
        subtitle: 'Recharger votre compte mobile',
        keywords: ['recharge', 'credit', 'argent', 'solde'],
        icon: Icons.add_circle,
        category: 'Actions',
        action: () => _navigateToRecharge(),
      ),
      SearchItem(
        title: 'Transfert de crédit',
        subtitle: 'Transférer du crédit vers un autre numéro',
        keywords: ['transfert', 'envoyer', 'credit', 'partage'],
        icon: Icons.send,
        category: 'Actions',
        action: () => _navigateToTransfer(),
      ),
      SearchItem(
        title: 'Mes forfaits',
        subtitle: 'Consulter vos forfaits actifs',
        keywords: ['mes forfaits', 'actifs', 'consommation', 'historique'],
        icon: Icons.timer,
        category: 'Consultation',
        action: () => _navigateToForfaitsActifs(),
      ),
      
      // TopUp
      SearchItem(
        title: 'TopUp - Ma ligne',
        subtitle: 'Gérer votre ligne fixe TopUp',
        keywords: ['topup', 'fixe', 'ligne', 'consultation'],
        icon: Icons.phone,
        category: 'TopUp',
        action: () => _navigateToTopUp(),
      ),
      SearchItem(
        title: 'Acheter souscription',
        subtitle: 'Souscrire à des packages TopUp',
        keywords: ['souscription', 'topup', 'package', 'fixe'],
        icon: Icons.subscriptions,
        category: 'TopUp',
        action: () => _navigateToTopUp(),
      ),
      SearchItem(
        title: 'Recharger compte fixe',
        subtitle: 'Transférer crédit vers ligne fixe',
        keywords: ['recharge', 'fixe', 'transfert', 'topup'],
        icon: Icons.account_balance_wallet,
        category: 'TopUp',
        action: () => _navigateToTopUp(),
      ),
      
      // Profil et compte
      SearchItem(
        title: 'Mon profil',
        subtitle: 'Gérer vos informations personnelles',
        keywords: ['profil', 'compte', 'informations', 'email', 'nom'],
        icon: Icons.person,
        category: 'Compte',
        action: () => _navigateToProfile(),
      ),
      SearchItem(
        title: 'Solde principal',
        subtitle: 'Consulter votre solde mobile',
        keywords: ['solde', 'argent', 'balance', 'credit'],
        icon: Icons.account_balance_wallet_outlined,
        category: 'Consultation',
        action: () => Navigator.pop(context),
      ),
      SearchItem(
        title: 'Solde bonus',
        subtitle: 'Consulter votre solde bonus',
        keywords: ['bonus', 'solde', 'compte', 'dedié'],
        icon: Icons.add_card,
        category: 'Consultation',
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
          soldeActuel: _soldeActuel,
          onRefreshSolde: () {}, // Callback vide pour la recherche
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
          soldeActuel: _soldeActuel,
          onRefreshSolde: () {},
        ),
      ),
    );
  }

  void _navigateToForfaitsActifs() {
    Navigator.push(
      context,
      CustomRouteTransitions.slideRightRoute(
        page: ForfaitsActifsScreen(),
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
              hintText: 'Rechercher une action...',
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
          ? _buildLoadingState()
          : Column(
              children: [
                _buildSearchSummary(),
                Expanded(
                  child: _filteredItems.isEmpty
                      ? _buildNoResultsState()
                      : _buildSearchResults(),
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
            'Chargement...',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary() {
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
                ? '$totalCount actions disponibles'
                : '$resultCount résultat${resultCount > 1 ? 's' : ''} trouvé${resultCount > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Text(
              'pour "$_searchQuery"',
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

  Widget _buildNoResultsState() {
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
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(8)),
            Text(
              'Essayez avec des mots-clés différents comme :\n"forfait", "recharge", "topup", "profil"',
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
          backgroundColor: AppTheme.dtBlue.withOpacity(0.1),
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