// lib/screens/settings/language_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/language_provider.dart';
import '../../widgets/appbar_widget.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: l10n.changeLanguage,
        showAction: false,
        customActions: [
          TextButton(
            onPressed: _onSave,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveSize.getFontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusM),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                title: l10n.french,
                value: const Locale('fr'),
                groupValue: _selectedLocale,
                onChanged: (Locale? value) {
                  if (value != null) {
                    setState(() {
                      _selectedLocale = value;
                    });
                  }
                },
              ),
              Divider(height: 1, color: Colors.grey[200]),
              _buildLanguageOption(
                title: l10n.english,
                value: const Locale('en'),
                groupValue: _selectedLocale,
                onChanged: (Locale? value) {
                  if (value != null) {
                    setState(() {
                      _selectedLocale = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required Locale value,
    required Locale groupValue,
    required ValueChanged<Locale?> onChanged,
  }) {
    final isSelected = value.languageCode == groupValue.languageCode;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
          vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Radio<Locale>(
              value: value,
              groupValue: isSelected ? value : null,
              onChanged: onChanged,
              activeColor: AppTheme.dtBlue,
            ),
          ],
        ),
      ),
    );
  }
}
