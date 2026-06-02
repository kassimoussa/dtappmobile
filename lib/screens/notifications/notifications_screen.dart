import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/app_notification.dart';
import '../../services/notification_store.dart';
import '../../utils/responsive_size.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationStore();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _store.markAllRead();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _channelColor(NotificationChannel ch) {
    switch (ch) {
      case NotificationChannel.transactions:
        return AppTheme.dtBlue;
      case NotificationChannel.security:
        return const Color(0xFFD32F2F);
      case NotificationChannel.promotions:
        return const Color(0xFF2E7D32);
    }
  }

  IconData _channelIcon(NotificationChannel ch) {
    switch (ch) {
      case NotificationChannel.transactions:
        return Icons.swap_horiz_rounded;
      case NotificationChannel.security:
        return Icons.shield_rounded;
      case NotificationChannel.promotions:
        return Icons.local_offer_rounded;
    }
  }

  String _channelLabel(NotificationChannel ch) {
    switch (ch) {
      case NotificationChannel.transactions:
        return 'Transaction';
      case NotificationChannel.security:
        return 'Sécurité';
      case NotificationChannel.promotions:
        return 'Promotion';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} j';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final notifications = _store.notifications;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.dtBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Tout effacer'),
                    content: const Text(
                        'Supprimer tout l\'historique des notifications ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Effacer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await _store.clearAll();
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white70, size: 18),
              label: const Text(
                'Tout effacer',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveSize.getHeight(12),
                horizontal: ResponsiveSize.getWidth(16),
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: ResponsiveSize.getHeight(8)),
              itemBuilder: (_, i) => _NotificationTile(
                notif: notifications[i],
                channelColor: _channelColor(notifications[i].channel),
                channelIcon: _channelIcon(notifications[i].channel),
                channelLabel: _channelLabel(notifications[i].channel),
                timeAgo: _timeAgo(notifications[i].receivedAt),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: ResponsiveSize.getFontSize(64),
            color: Colors.grey[300],
          ),
          SizedBox(height: ResponsiveSize.getHeight(16)),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(8)),
          Text(
            'Vos notifications apparaîtront ici',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tuile de notification ─────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  final Color channelColor;
  final IconData channelIcon;
  final String channelLabel;
  final String timeAgo;

  const _NotificationTile({
    required this.notif,
    required this.channelColor,
    required this.channelIcon,
    required this.channelLabel,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border(
          left: BorderSide(color: channelColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black04,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: channelColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(channelIcon, color: channelColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: channelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          channelLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: channelColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
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
}
