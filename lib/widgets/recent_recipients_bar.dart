import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/services/recent_recipients_service.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';

/// Rangée de destinataires déjà utilisés (favoris d'abord), à toucher pour
/// remplir le champ du numéro. Invisible tant que la liste est vide.
class RecentRecipientsBar extends StatefulWidget {
  /// Reçoit le numéro local à 8 chiffres du destinataire choisi.
  final ValueChanged<String> onSelected;

  const RecentRecipientsBar({super.key, required this.onSelected});

  /// « 77123456 » → « 77 12 34 56 ».
  static String format(String number) =>
      number.replaceAllMapped(RegExp(r'(\d{2})(?=\d)'), (m) => '${m[1]} ');

  @override
  State<RecentRecipientsBar> createState() => _RecentRecipientsBarState();
}

class _RecentRecipientsBarState extends State<RecentRecipientsBar> {
  List<SavedRecipient> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await RecentRecipientsService.load();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _toggleFavorite(SavedRecipient r) async {
    await RecentRecipientsService.setFavorite(r.number, !r.favorite);
    await _load();
  }

  Future<void> _forget(SavedRecipient r) async {
    await RecentRecipientsService.remove(r.number);
    await _load();
  }

  Future<void> _showActions(SavedRecipient r) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    r.name ?? RecentRecipientsBar.format(r.number),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      r.name == null
                          ? null
                          : Text(
                            '+253 ${RecentRecipientsBar.format(r.number)}',
                          ),
                ),
                ListTile(
                  leading: Icon(
                    r.favorite ? Icons.star_border_rounded : Icons.star_rounded,
                    color: AppTheme.dtBlue2,
                  ),
                  title: Text(
                    r.favorite
                        ? l10n.recipientRemoveFavorite
                        : l10n.recipientAddFavorite,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _toggleFavorite(r);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red[600],
                  ),
                  title: Text(l10n.recipientForget),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _forget(r);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentRecipientsTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _chip(_items[index], l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(SavedRecipient r, AppLocalizations l10n) {
    final label = r.name ?? RecentRecipientsBar.format(r.number);
    final initial = r.name != null ? r.name![0].toUpperCase() : null;

    return Material(
      color: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: Colors.grey[300]!)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => widget.onSelected(r.number),
        onLongPress: () => _showActions(r),
        child: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.dtBlue2.withValues(alpha: 0.1),
                child:
                    initial != null
                        ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dtBlue2,
                          ),
                        )
                        : const Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: AppTheme.dtBlue2,
                        ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Tooltip(
                message:
                    r.favorite
                        ? l10n.recipientRemoveFavorite
                        : l10n.recipientAddFavorite,
                child: InkResponse(
                  onTap: () => _toggleFavorite(r),
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      r.favorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 20,
                      color: r.favorite ? AppTheme.dtYellow : Colors.grey[500],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
