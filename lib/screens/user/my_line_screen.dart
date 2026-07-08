// lib/pages/my_line_page.dart
import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/screens/core/home_screen.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/widgets/balance_card.dart';
import 'package:dtservices/widgets/bills_section.dart';
import 'package:dtservices/widgets/consumption_section.dart';
import 'package:dtservices/widgets/fixed_line_info_card.dart';
import 'package:dtservices/widgets/fixed_line_input.dart';
import 'package:dtservices/widgets/line_info_header.dart';
import 'package:dtservices/widgets/packages_section.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';

class MyLineScreen extends StatefulWidget {
  final String phoneNumber;

  const MyLineScreen({super.key, required this.phoneNumber});

  @override
  _MyLineScreenState createState() => _MyLineScreenState();
}

class _MyLineScreenState extends State<MyLineScreen> {
  final int _currentNavIndex = 2;
  // Couleurs de Djibouti Telecom
  final Color djiboutiYellow = AppTheme.dtYellow;

  String? _fixedLineNumber;
  bool _isFixedLineEntered = false;
  bool _showAllSections =
      false; // Toggle pour afficher/masquer certaines sections

  void _setFixedLineNumber(String number) {
    setState(() {
      _fixedLineNumber = number;
      _isFixedLineEntered = true;
    });
  }

  void _resetFixedLineNumber() {
    setState(() {
      _isFixedLineEntered = false;
    });
  }

  void _toggleSectionsVisibility() {
    setState(() {
      _showAllSections = !_showAllSections;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myLineTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.dtBlue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // Action pour les paramètres de la ligne
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations du téléphone
            LineInfoHeader(phoneNumber: widget.phoneNumber),

            const SizedBox(height: 16),

            // Affichage conditionnel basé sur la saisie du numéro fixe
            if (!_isFixedLineEntered)
              FixedLineInput(onSubmit: _setFixedLineNumber)
            else
              Column(
                children: [
                  // Informations de la ligne fixe
                  FixedLineInfoCard(
                    fixedLineNumber: _fixedLineNumber ?? '',
                    onEdit: _resetFixedLineNumber,
                  ),

                  const SizedBox(height: 16),

                  // Solde et bouton de recharge
                  const BalanceCard(),

                  const SizedBox(height: 16),

                  // Toggle pour afficher/masquer plus de sections
                  _buildToggle(),

                  // Sections supplémentaires qui peuvent être masquées
                  if (_showAllSections) ...[
                    const SizedBox(height: 16),
                    const PackagesSection(),
                    const SizedBox(height: 16),
                    const ConsumptionSection(),
                    const SizedBox(height: 16),
                    const BillsSection(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildToggle() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _toggleSectionsVisibility,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _showAllSections
                  ? l10n.toggleHideDetails
                  : l10n.toggleShowDetails,
              style: const TextStyle(
                color: AppTheme.dtBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              _showAllSections
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: AppTheme.dtBlue,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    final l10n = AppLocalizations.of(context)!;
    return BottomNavigationBar(
      currentIndex: _currentNavIndex, // Indice 2 pour la page Ma ligne
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.dtBlue,
      backgroundColor: Colors.white,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        // Navigation vers les écrans correspondants
        if (index == 2) {
          // Accueil - Déjà sur cet écran, ne rien faire
        } else if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      const HomeScreen(/* phoneNumber: widget.phoneNumber */),
            ),
          );
        } else if (index == 1) {
          // Historique
          _showComingSoonDialog(l10n.historyTransactions);
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view),
          label: l10n.navHome,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.description_outlined),
          label: l10n.navHistory,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline_rounded),
          label: l10n.navMyLine,
        ),
      ],
    );
  }

  void _showComingSoonDialog(String feature) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              feature,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtBlue,
              ),
            ),
            content: Text(
              l10n.comingSoonMessage,
              style: TextStyle(fontSize: ResponsiveSize.getFontSize(16)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.ok,
                  style: TextStyle(
                    color: AppTheme.dtBlue,
                    fontSize: ResponsiveSize.getFontSize(16),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveSize.getWidth(AppTheme.radiusM),
              ),
            ),
          ),
    );
  }
}
