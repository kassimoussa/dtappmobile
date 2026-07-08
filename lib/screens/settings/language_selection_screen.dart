// lib/screens/settings/language_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:dtservices/widgets/settings_card.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/language_provider.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    // Initialize with the current locale from the provider
    _selectedLocale = context.read<LanguageProvider>().currentLocale;
  }

  void _onSave() {
    context.read<LanguageProvider>().changeLanguage(_selectedLocale);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.success),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

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
                GlassAppBar(title: l10n.changeLanguage),
                Padding(
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                  child: RadioGroup<Locale>(
                    groupValue: _selectedLocale,
                    onChanged: (Locale? value) {
                      if (value != null) {
                        setState(() => _selectedLocale = value);
                      }
                    },
                    child: SettingsCard(
                      children: [
                        _buildLanguageOption(
                          title: l10n.french,
                          value: const Locale('fr'),
                        ),
                        _buildLanguageOption(
                          title: l10n.english,
                          value: const Locale('en'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveSize.getWidth(AppTheme.spacingM),
                    0,
                    ResponsiveSize.getWidth(AppTheme.spacingM),
                    ResponsiveSize.getHeight(AppTheme.spacingL),
                  ),
                  child: DtButton.primary(
                    label: l10n.save,
                    onPressed: _onSave,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLanguageOption({
    required String title,
    required Locale value,
  }) {
    return SettingsTile(
      label: title,
      onTap: () => setState(() => _selectedLocale = value),
      trailing: Radio<Locale>(
        value: value,
        activeColor: AppTheme.dtBlue,
      ),
    );
  }
}
