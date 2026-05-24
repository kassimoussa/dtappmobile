import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../extensions/color_extensions.dart';
import '../../utils/responsive_size.dart';
import '../../services/profile_service.dart';
import '../../generated/l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;

  const EditProfileScreen({super.key, this.initialName, this.initialEmail});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final success = await ProfileService.updateUserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileUpdateSuccess),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
              ),
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde profil: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Nom optionnel
    }
    if (value.trim().length < 2) {
      return AppLocalizations.of(context)!.nameValidationError;
    }
    if (value.trim().length > 50) {
      return 'Le nom ne doit pas dépasser 50 caractères.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email optionnel
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppLocalizations.of(context)!.emailValidationError;
    }
    return null;
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
                    AppTheme.dtBlueDark.withOpacityValue(0.08),
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
                _buildGlassAppBar(context, l10n.personalInfo),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.nameLabel,
                  hintText: l10n.nameHint,
                  prefixIcon: Icon(Icons.person, color: AppTheme.dtBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
                    borderSide: const BorderSide(
                      color: AppTheme.dtBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                    currentLength > 40
                        ? Text('$currentLength/$maxLength',
                            style: TextStyle(
                              fontSize: 12,
                              color: currentLength >= maxLength!
                                  ? Colors.red
                                  : Colors.grey,
                            ))
                        : null,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  hintText: l10n.emailHint,
                  prefixIcon: Icon(Icons.email, color: AppTheme.dtBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
                    borderSide: const BorderSide(
                      color: AppTheme.dtBlue,
                      width: 2,
                    ),
                  ),
                ),
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
                          if (_errorMessage != null) _buildErrorMessage(),
                          _buildSaveButton(),
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

  Widget _buildGlassAppBar(BuildContext context, String title) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSize.getWidth(12),
            vertical: ResponsiveSize.getHeight(12),
          ),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusS),
          ),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 20),
            SizedBox(width: ResponsiveSize.getWidth(8)),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.dtBlue,
        foregroundColor: AppTheme.dtYellow,
        padding: EdgeInsets.symmetric(vertical: ResponsiveSize.getHeight(16)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusM),
          ),
        ),
        elevation: _isSaving ? 0 : 2,
      ),
      child:
          _isSaving
              ? SizedBox(
                width: ResponsiveSize.getWidth(20),
                height: ResponsiveSize.getHeight(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: ResponsiveSize.getFontSize(18)),
                  SizedBox(width: ResponsiveSize.getWidth(8)),
                  Text(
                    AppLocalizations.of(context)!.saveChanges,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
    );
  }
}
