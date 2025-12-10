import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../widgets/appbar_widget.dart';
import '../../../providers/auth_provider.dart';
import '../otp_screen.dart';
import '../../../routes/custom_route_transitions.dart';
import 'change_pin_screen.dart';

class PinManagementScreen extends StatelessWidget {
  const PinManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWidget(
        title: 'Gestion du code PIN',
        showAction: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          children: [
            _buildMenuOption(
              context,
              title: 'Modifier le code PIN',
              onTap: () {
                Navigator.of(context).push(
                  CustomRouteTransitions.slideRightRoute(
                    page: const ChangePinScreen(),
                  ),
                );
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            _buildMenuOption(
              context,
              title: 'Code PIN oublié',
              onTap: () {
                // Navigate to OTPScreen with key for resetting PIN
                // Assuming we use the current user's phone number
                final phoneNumber = authProvider.phoneNumber;
                if (phoneNumber != null) {
                  Navigator.of(context).push(
                    CustomRouteTransitions.slideRightRoute(
                      page: OTPScreen(phone: phoneNumber),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Numéro de téléphone introuvable'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: ResponsiveSize.getFontSize(16),
            ),
          ],
        ),
      ),
    );
  }
}
