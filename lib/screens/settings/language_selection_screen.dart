// lib/screens/settings/language_selection_screen.dart
import 'package:flutter/material.dart';
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
              decoration: BoxDecoration(
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
                _buildGlassAppBar(context, l10n.changeLanguage, l10n.save),
                Expanded(
                  child: Padding(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(BuildContext context, String title, String saveLabel) {
    return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(
            color: AppTheme.white95,
            border: Border(bottom: BorderSide(color: AppTheme.dtBlueO10, width: 0.5)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.white50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.dtBlueDark, size: 20),
                ),
              ),
              SizedBox(width: ResponsiveSize.getWidth(16)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: ResponsiveSize.getFontSize(22),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: _onSave,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.dtBlueDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    saveLabel,
                    style: TextStyle(
                      color: AppTheme.dtYellow,
                      fontSize: ResponsiveSize.getFontSize(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
