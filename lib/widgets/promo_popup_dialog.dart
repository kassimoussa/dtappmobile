import 'package:flutter/material.dart';
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
    _show(context, popup);
  }

  static void _show(BuildContext context, PromoPopup popup) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
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
                child: Image.network(
                  popup.imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: ResponsiveSize.getHeight(300),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.dtYellow,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
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
