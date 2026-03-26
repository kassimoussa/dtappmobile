import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/popup.dart';
import '../services/popup_service.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';

class PromoPopupDialog {
  static Future<void> showIfAvailable(BuildContext context) async {
    final popup = await PopupService.getPopup();
    if (popup == null) return;
    if (!context.mounted) return;

    // Délai de 1 seconde avant d'afficher le popup
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return;

    _show(context, popup);
  }

  static void _show(BuildContext context, PromoPopup popup) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.getWidth(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton fermer
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppTheme.dtBlue,
                    size: ResponsiveSize.getFontSize(22),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Image
            GestureDetector(
              onTap: () => _onTap(context, popup),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  ResponsiveSize.getWidth(AppTheme.radiusM),
                ),
                child: CachedNetworkImage(
                  imageUrl: popup.imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  placeholder: (context, url) => SizedBox(
                    height: ResponsiveSize.getHeight(300),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.dtYellow,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    // Fermer le dialog si l'image ne charge pas
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) Navigator.of(context).pop();
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _onTap(BuildContext context, PromoPopup popup) async {
    if (popup.link == null || popup.link!.isEmpty) return;
    final uri = Uri.tryParse(popup.link!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
