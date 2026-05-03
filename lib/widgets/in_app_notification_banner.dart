import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/app_notification.dart';

/// Bannière de notification affichée en overlay quand l'app est au premier plan.
class InAppNotificationBanner {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required String title,
    required String body,
    required NotificationChannel channel,
    VoidCallback? onTap,
  }) {
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (_) => _BannerWidget(
        title: title,
        body: body,
        channel: channel,
        onTap: onTap,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _BannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final NotificationChannel channel;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.title,
    required this.body,
    required this.channel,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  Color get _channelColor {
    switch (widget.channel) {
      case NotificationChannel.transactions:
        return AppTheme.dtBlue;
      case NotificationChannel.security:
        return const Color(0xFFD32F2F);
      case NotificationChannel.promotions:
        return const Color(0xFF2E7D32);
    }
  }

  IconData get _channelIcon {
    switch (widget.channel) {
      case NotificationChannel.transactions:
        return Icons.swap_horiz_rounded;
      case NotificationChannel.security:
        return Icons.shield_rounded;
      case NotificationChannel.promotions:
        return Icons.local_offer_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _dismiss();
                widget.onTap?.call();
              },
              onVerticalDragEnd: (d) {
                if (d.primaryVelocity != null && d.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(color: _channelColor, width: 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _channelColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _channelIcon,
                        color: _channelColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
