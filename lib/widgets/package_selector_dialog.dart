// lib/widgets/package_selector_dialog.dart
import 'package:dtservices/widgets/package_payment_dialog.dart';
import 'package:dtservices/constants/app_theme.dart';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';

class PackageSelectorDialog extends StatelessWidget {
  const PackageSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final Color djiboutiBlue = AppTheme.dtBlue;
    final l10n = AppLocalizations.of(context)!;

    return SimpleDialog(
      title: Text(
        l10n.choosePackageType,
        style: TextStyle(
          color: djiboutiBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            _showBuyPackageDialog(context, 'internet');
          },
          child: ListTile(
            leading: const Icon(Icons.wifi, color: AppTheme.dtYellow),
            title: Text(l10n.internetPackage),
            subtitle: Text(l10n.dataForBrowsing),
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            Navigator.pop(context);
            _showBuyPackageDialog(context, 'voice');
          },
          child: ListTile(
            leading: const Icon(Icons.call, color: AppTheme.dtYellow),
            title: Text(l10n.voicePackage),
            subtitle: Text(l10n.minutesForCalls),
          ),
        ),
      ],
    );
  }

  void _showBuyPackageDialog(BuildContext context, String packageType) {
    // Liste des forfaits disponibles selon le type
    final List<Map<String, dynamic>> availablePackages = packageType == 'internet'
        ? [
            {
              'name': 'Forfait Internet 5 Go',
              'price': '500',
              'validity': '7 jours',
              'description': 'Idéal pour une utilisation modérée',
            },
            {
              'name': 'Forfait Internet 10 Go',
              'price': '1000',
              'validity': '30 jours',
              'description': 'Pour vos besoins quotidiens',
            },
            {
              'name': 'Forfait Internet 20 Go',
              'price': '1800',
              'validity': '30 jours',
              'description': 'Utilisation intensive, streaming inclus',
            },
            {
              'name': 'Forfait Internet Illimité',
              'price': '3000',
              'validity': '30 jours',
              'description': 'Navigation illimitée pour tout usage',
            },
          ]
        : [
            {
              'name': 'Forfait Appels 100 min',
              'price': '500',
              'validity': '15 jours',
              'description': 'Pour les appels occasionnels',
            },
            {
              'name': 'Forfait Appels 250 min',
              'price': '1200',
              'validity': '30 jours',
              'description': 'Pour vos appels réguliers',
            },
            {
              'name': 'Forfait Appels 500 min',
              'price': '2000',
              'validity': '30 jours',
              'description': 'Solution économique pour utilisation intense',
            },
            {
              'name': 'Forfait Appels Illimités',
              'price': '2500',
              'validity': '30 jours',
              'description': 'Liberté totale pour vos appels',
            },
          ];

    showDialog(
      context: context,
      builder: (context) => PackageDialog(
        packageType: packageType,
        availablePackages: availablePackages,
      ),
    );
  }
}

class PackageDialog extends StatefulWidget {
  final String packageType;
  final List<Map<String, dynamic>> availablePackages;

  const PackageDialog({
    super.key,
    required this.packageType,
    required this.availablePackages,
  });

  @override
  State<PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends State<PackageDialog> {
  late String selectedPackage;
  late Map<String, dynamic> selectedPackageDetails;

  @override
  void initState() {
    super.initState();
    selectedPackage = widget.availablePackages[0]['name'];
    selectedPackageDetails = widget.availablePackages[0];
  }

  @override
  Widget build(BuildContext context) {
    final Color djiboutiBlue = AppTheme.dtBlue;
    final Color djiboutiYellow = AppTheme.dtYellow;
    final l10n = AppLocalizations.of(context)!;

    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: size.width > 600 ? 500 : null,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.packageType == 'internet' ? l10n.internetPackages : l10n.voicePackages,
                style: TextStyle(
                  color: djiboutiBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...widget.availablePackages.map(
                        (package) => Card(
                          elevation: selectedPackage == package['name'] ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: selectedPackage == package['name'] ? djiboutiYellow : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedPackage = package['name'];
                                selectedPackageDetails = package;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: isSmallScreen ? 8 : 12,
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: package['name'],
                                    groupValue: selectedPackage,
                                    activeColor: djiboutiYellow,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedPackage = value!;
                                        selectedPackageDetails = package;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          package['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: djiboutiBlue,
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              widget.packageType == 'internet' ? Icons.wifi : Icons.call,
                                              size: isSmallScreen ? 14 : 16,
                                              color: djiboutiYellow,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                package['description'],
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 12 : 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.dtBlueO05,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${package['price']} DJF',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: djiboutiBlue,
                                                  fontSize: isSmallScreen ? 11 : 13,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${l10n.validityRow} ${package['validity']}',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: isSmallScreen ? 11 : 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.packageSummary,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: djiboutiBlue,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(l10n.packageRow, selectedPackage, isSmallScreen),
                            const SizedBox(height: 4),
                            _buildInfoRow(l10n.priceRow, '${selectedPackageDetails['price']} DJF', isSmallScreen),
                            const SizedBox(height: 4),
                            _buildInfoRow(l10n.validityRow, selectedPackageDetails['validity'], isSmallScreen),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: djiboutiYellow,
                      foregroundColor: djiboutiBlue,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => PackagePaymentDialog(packageDetails: selectedPackageDetails),
                      );
                    },
                    child: Text(
                      l10n.continueAction,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey[700],
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
