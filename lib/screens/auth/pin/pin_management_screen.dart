import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_theme.dart';
import '../../../utils/responsive_size.dart';
import '../../../providers/auth_provider.dart';
import '../otp_screen.dart';
import '../../../routes/custom_route_transitions.dart';
import 'change_pin_screen.dart';
import '../../../../generated/l10n/app_localizations.dart';

class PinManagementScreen extends StatefulWidget {
  const PinManagementScreen({super.key});

  @override
  State<PinManagementScreen> createState() => _PinManagementScreenState();
}

class _PinManagementScreenState extends State<PinManagementScreen> {
  bool _isSendingOtp = false;

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueO08,
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: AppLocalizations.of(context)!.pinManagementTitle),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                        child: Column(
                          children: [
                            _buildMenuOption(
                              context,
                              title: AppLocalizations.of(context)!.changePinTitle,
                              onTap: () {
                                if (_isSendingOtp) return;
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
                              title: AppLocalizations.of(context)!.forgotPinOption,
                              onTap: _handleForgotPin,
                              showLoading: _isSendingOtp,
                            ),
                          ],
                        ),
                      ),
                      if (_isSendingOtp)
                        const ModalBarrier(dismissible: false, color: Colors.black12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _handleForgotPin() async {
    if (_isSendingOtp) return;

    final authProvider = context.read<AuthProvider>();
    final phoneNumber = authProvider.phoneNumber;

    if (phoneNumber != null) {
      setState(() {
        _isSendingOtp = true;
      });

      authProvider.clearError();
      final success = await authProvider.sendOtp(phoneNumber);

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });

        if (success) {
          Navigator.of(context).push(
            CustomRouteTransitions.slideRightRoute(
              page: OTPScreen(phone: phoneNumber),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ??
                    AppLocalizations.of(context)!.otpSendError,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.phoneNotFound)),
      );
    }
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    bool showLoading = false,
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
            if (showLoading)
              SizedBox(
                width: ResponsiveSize.getWidth(16),
                height: ResponsiveSize.getHeight(16),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else
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
