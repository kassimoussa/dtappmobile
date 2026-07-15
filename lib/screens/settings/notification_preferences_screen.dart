import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/settings_card.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/notification_preferences_service.dart';
import '../../generated/l10n/app_localizations.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await NotificationPreferencesService.load();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
  }

  void _update(NotificationPreferences next) {
    setState(() => _prefs = next);
    NotificationPreferencesService.save(next);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          _bgGlow(),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: l10n.notificationPreferences),
                Expanded(
                  child: _loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppTheme.dtBlue),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(
                            ResponsiveSize.getWidth(AppTheme.spacingL),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: ResponsiveSize.getWidth(
                                      AppTheme.spacingXS),
                                  bottom: ResponsiveSize.getHeight(
                                      AppTheme.spacingM),
                                ),
                                child: Text(
                                  l10n.notificationsIntro,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: ResponsiveSize.getFontSize(14),
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              SettingsCard(
                                children: [
                                  _toggle(
                                    Icons.receipt_long_rounded,
                                    l10n.notifTransactions,
                                    l10n.notifTransactionsDesc,
                                    _prefs.transactions,
                                    (v) => _update(
                                        _prefs.copyWith(transactions: v)),
                                  ),
                                  _toggle(
                                    Icons.local_offer_rounded,
                                    l10n.notifOffers,
                                    l10n.notifOffersDesc,
                                    _prefs.offers,
                                    (v) => _update(_prefs.copyWith(offers: v)),
                                  ),
                                  _toggle(
                                    Icons.account_balance_wallet_rounded,
                                    l10n.notifBalance,
                                    l10n.notifBalanceDesc,
                                    _prefs.balance,
                                    (v) => _update(_prefs.copyWith(balance: v)),
                                  ),
                                  _toggle(
                                    Icons.shield_rounded,
                                    l10n.notifSecurity,
                                    l10n.notifSecurityDesc,
                                    _prefs.security,
                                    (v) => _update(_prefs.copyWith(security: v)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bgGlow() => Positioned(
        top: -100,
        left: -100,
        right: -100,
        child: Container(
          height: 350,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppTheme.dtBlueO08, Colors.transparent],
              radius: 0.8,
            ),
          ),
        ),
      );

  Widget _toggle(
    IconData icon,
    String label,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? AppTheme.dtBlue : Colors.grey[500],
            size: ResponsiveSize.getFontSize(22),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: ResponsiveSize.getFontSize(15),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(2)),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: ResponsiveSize.getFontSize(12.5),
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.dtBlue,
          ),
        ],
      ),
    );
  }
}
