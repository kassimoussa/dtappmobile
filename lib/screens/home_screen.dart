// lib/screens/home_screen.dart
// VERSION MIGRÉE AVEC PROVIDER

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../extensions/color_extensions.dart';
import '../routes/custom_route_transitions.dart';
import '../providers/user_session_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/forfait_provider.dart';

// Imports des écrans
import 'achat_forfait/forfait_recipient_screen.dart';
import 'agencies/agencies_screen.dart';
import 'forfaits_actifs/forfaits_actifs_screen.dart';
import 'login_screen.dart';
import 'transfer_credit/transfer_input_screen.dart';
import 'refill/refill_recipient_screen.dart';
import 'speedtest/speedtest_native_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showMainBalance = false;
  bool _showBonusBalance = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialise les données au chargement de l'écran
  /// Utilise les providers au lieu de services directs
  Future<void> _initializeData() async {
    // Accéder aux providers SANS ÉCOUTER (pas dans build)
    final sessionProvider = Provider.of<UserSessionProvider>(context, listen: false);
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final forfaitProvider = Provider.of<ForfaitProvider>(context, listen: false);

    // Vérifier que l'utilisateur est authentifié
    if (!sessionProvider.isAuthenticated) {
      // Rediriger vers login si pas authentifié
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        CustomRouteTransitions.fadeScaleRoute(page: const LoginScreen()),
        (route) => false,
      );
      return;
    }

    // Charger les données en parallèle
    await Future.wait([
      balanceProvider.fetchBalance(), // Utilise le cache si valide
      forfaitProvider.fetchForfaits(), // Utilise le cache si valide
    ]);
  }

  /// Rafraîchit toutes les données
  Future<void> _refreshData() async {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final forfaitProvider = Provider.of<ForfaitProvider>(context, listen: false);

    await Future.wait([
      balanceProvider.refresh(), // Force un rechargement
      forfaitProvider.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    // CONSOMMER LES PROVIDERS
    // Consumer permet de reconstruire uniquement ce widget quand le provider change
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildBalanceCard(),
                  SizedBox(height: ResponsiveSize.height(20)),
                  _buildForfaitsCard(),
                  SizedBox(height: ResponsiveSize.height(20)),
                  _buildQuickActions(),
                  SizedBox(height: ResponsiveSize.height(40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barre d'application avec les informations utilisateur
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: ResponsiveSize.height(200),
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.dtBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.dtBlue,
                AppTheme.dtBlue2,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveSize.width(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // CONSUMER 1: Session Provider pour afficher le numéro
                      Consumer<UserSessionProvider>(
                        builder: (context, sessionProvider, child) {
                          if (sessionProvider.isLoading) {
                            return const CircularProgressIndicator(
                              color: Colors.white,
                            );
                          }

                          final phoneNumber = sessionProvider.phoneNumber ?? '';
                          final formattedPhone = _formatPhoneNumber(phoneNumber);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: ResponsiveSize.fontSize(14),
                                ),
                              ),
                              Text(
                                formattedPhone,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveSize.fontSize(20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            CustomRouteTransitions.fadeScaleRoute(
                              page: const SearchScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Carte affichant le solde
  Widget _buildBalanceCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.width(16)),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.width(20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solde',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSize(16),
                    color: AppTheme.textSecondary,
                  ),
                ),
                // CONSUMER 2: Balance Provider pour le bouton de rafraîchissement
                Consumer<BalanceProvider>(
                  builder: (context, balanceProvider, child) {
                    return IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: balanceProvider.isLoading
                            ? AppTheme.textSecondary
                            : AppTheme.dtBlue,
                      ),
                      onPressed: balanceProvider.isLoading
                          ? null
                          : () => balanceProvider.refresh(),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.height(10)),

            // CONSUMER 3: Balance Provider pour afficher le solde
            Consumer<BalanceProvider>(
              builder: (context, balanceProvider, child) {
                // Gestion du chargement
                if (balanceProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Gestion des erreurs
                if (balanceProvider.error != null) {
                  return Column(
                    children: [
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: ResponsiveSize.fontSize(14),
                        ),
                      ),
                      TextButton(
                        onPressed: () => balanceProvider.refresh(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  );
                }

                // Affichage du solde
                final balance = balanceProvider.mainBalance;
                final currency = balanceProvider.currency;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMainBalance = !_showMainBalance;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        _showMainBalance ? '$balance $currency' : '*** $currency',
                        style: TextStyle(
                          fontSize: ResponsiveSize.fontSize(32),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                      SizedBox(width: ResponsiveSize.width(10)),
                      Icon(
                        _showMainBalance
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppTheme.textSecondary,
                        size: ResponsiveSize.iconSize(20),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Afficher le cache info
            Consumer<BalanceProvider>(
              builder: (context, balanceProvider, child) {
                if (balanceProvider.lastFetch != null) {
                  final timeSinceFetch = DateTime.now()
                      .difference(balanceProvider.lastFetch!)
                      .inMinutes;
                  return Padding(
                    padding: EdgeInsets.only(top: ResponsiveSize.height(8)),
                    child: Text(
                      'Mis à jour il y a $timeSinceFetch min',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSize(12),
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Carte affichant les forfaits actifs
  Widget _buildForfaitsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.width(16)),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.width(20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes Forfaits',
                  style: TextStyle(
                    fontSize: ResponsiveSize.fontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CustomRouteTransitions.slideRoute(
                        page: const ForfaitsActifsScreen(),
                      ),
                    );
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),

            // CONSUMER 4: Forfait Provider pour afficher les forfaits
            Consumer<ForfaitProvider>(
              builder: (context, forfaitProvider, child) {
                // Chargement
                if (forfaitProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Erreur
                if (forfaitProvider.error != null) {
                  return Center(
                    child: Column(
                      children: [
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: ResponsiveSize.fontSize(14),
                          ),
                        ),
                        TextButton(
                          onPressed: () => forfaitProvider.refresh(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                // Pas de forfaits
                if (!forfaitProvider.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Aucun forfait actif',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: ResponsiveSize.fontSize(14),
                        ),
                      ),
                    ),
                  );
                }

                // Afficher les 3 premiers forfaits
                final activeForfaits = forfaitProvider.getActiveForfaits();
                final displayForfaits = activeForfaits.take(3).toList();

                return Column(
                  children: [
                    Text(
                      '${activeForfaits.length} forfait(s) actif(s)',
                      style: TextStyle(
                        fontSize: ResponsiveSize.fontSize(14),
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: ResponsiveSize.height(10)),
                    ...displayForfaits.map((forfait) {
                      return ListTile(
                        leading: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: ResponsiveSize.iconSize(24),
                        ),
                        title: Text(
                          forfait.nomOffre ?? 'Forfait',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontSize(14),
                          ),
                        ),
                        subtitle: Text(
                          forfait.statut ?? '',
                          style: TextStyle(
                            fontSize: ResponsiveSize.fontSize(12),
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Actions rapides
  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.width(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions Rapides',
            style: TextStyle(
              fontSize: ResponsiveSize.fontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveSize.height(16)),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: ResponsiveSize.width(16),
            mainAxisSpacing: ResponsiveSize.height(16),
            children: [
              _buildActionButton(
                icon: Icons.shopping_bag,
                label: 'Acheter\nForfait',
                color: AppTheme.dtBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    CustomRouteTransitions.slideRoute(
                      page: const ForfaitRecipientScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.card_giftcard,
                label: 'Recharger',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    CustomRouteTransitions.slideRoute(
                      page: const RefillRecipientScreen(),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.send,
                label: 'Transférer',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    CustomRouteTransitions.slideRoute(
                      page: const TransferInputScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveSize.iconSize(32),
            ),
            SizedBox(height: ResponsiveSize.height(8)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.fontSize(12),
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formate le numéro de téléphone pour l'affichage
  String _formatPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.startsWith('253')) {
      cleanNumber = cleanNumber.substring(3);
    }

    if (cleanNumber.length == 8) {
      final buffer = StringBuffer('+253');
      for (int i = 0; i < cleanNumber.length; i += 2) {
        buffer.write(' ${cleanNumber.substring(i, i + 2)}');
      }
      return buffer.toString();
    } else {
      return '+253 $cleanNumber';
    }
  }
}
