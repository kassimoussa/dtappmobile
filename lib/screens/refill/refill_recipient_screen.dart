import 'package:dtapp3/constants/app_theme.dart';
import 'package:dtapp3/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';

class RefillRecipientScreen extends StatelessWidget {
  final String? phoneNumber;
  const RefillRecipientScreen({super.key, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Rechage de crédit',
        showAction: false, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisir le destinataire',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildOptionCard(
                    context,
                    'Mon numéro',
                    AppTheme.dtBlue2,
                    Icons.arrow_upward,
                    onTap: () { 
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionCard(
                    context,
                    'Autre numéro',
                    AppTheme.dtBlue2,
                    Icons.arrow_outward,
                    onTap: () {
                       
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    Color iconColor,
    IconData cardIcon, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dtYellow),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: AppTheme.dtYellow),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.smartphone,
                    size: 30,
                    color: AppTheme.dtBlue2,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.dtBlue2,
                    ),
                    child: Icon(cardIcon, color: AppTheme.dtYellow, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Acheter pour',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
