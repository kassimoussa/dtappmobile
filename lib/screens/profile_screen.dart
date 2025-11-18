// lib/screens/profile_screen.dart
// VERSION MIGRÉE AVEC PROVIDER
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../widgets/appbar_widget.dart';
import '../extensions/color_extensions.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ Charger le profil au démarrage AVEC listen: false
    Future.microtask(() {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      profileProvider.fetchProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Sauvegarde le profil en utilisant le provider
  Future<void> _saveProfile(ProfileProvider profileProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await profileProvider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileProvider.error ?? 'Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
          ),
        ),
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Nom optionnel
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email optionnel
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez saisir un email valide';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Mon Profil',
        showAction: false,
        showCancelToHome: true,
      ),
      // ✅ CONSUMER pour écouter les changements du provider
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          // Pré-remplir les champs quand les données arrivent
          if (profileProvider.hasData && _nameController.text.isEmpty) {
            _nameController.text = profileProvider.name ?? '';
            _emailController.text = profileProvider.email ?? '';
          }

          // État de chargement
          if (profileProvider.isLoading) {
            return _buildLoadingState();
          }

          // État d'erreur
          if (profileProvider.error != null && !profileProvider.hasData) {
            return _buildErrorState(profileProvider);
          }

          // État avec données
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(profileProvider),
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildPersonalInfoSection(),
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                  _buildAccountInfoSection(profileProvider),
                  SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
                  if (profileProvider.error != null) _buildErrorMessage(profileProvider),
                  _buildSaveButton(profileProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// État de chargement
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.dtBlue),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            'Chargement du profil...',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// État d'erreur
  Widget _buildErrorState(ProfileProvider profileProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveSize.iconSize(64),
              color: Colors.red[400],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(18),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
            Text(
              profileProvider.error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
            ElevatedButton.icon(
              onPressed: () => profileProvider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dtBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tête du profil avec avatar
  Widget _buildProfileHeader(ProfileProvider profileProvider) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: AppTheme.dtBlue.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(
          color: AppTheme.dtBlue.withOpacityValue(0.3),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: ResponsiveSize.getWidth(40),
            backgroundColor: AppTheme.dtBlue,
            child: Text(
              profileProvider.getInitial(),
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(24),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtYellow,
              ),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            profileProvider.getDisplayName(),
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(20),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            profileProvider.phoneNumber ?? '',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Section informations personnelles (formulaire)
  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Informations personnelles',
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nom complet',
            hintText: 'Entrez votre nom',
            prefixIcon: Icon(Icons.person, color: AppTheme.dtBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
              borderSide: BorderSide(color: AppTheme.dtBlue, width: 2),
            ),
          ),
          validator: _validateName,
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'exemple@email.com',
            prefixIcon: Icon(Icons.email, color: AppTheme.dtBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
              borderSide: BorderSide(color: AppTheme.dtBlue, width: 2),
            ),
          ),
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  /// Section informations du compte (lecture seule)
  Widget _buildAccountInfoSection(ProfileProvider profileProvider) {
    return _buildSection(
      title: 'Informations du compte',
      children: [
        _buildInfoRow('Numéro de téléphone', profileProvider.phoneNumber ?? 'Non disponible'),
        _buildInfoRow('Dernière connexion', profileProvider.formatDate(profileProvider.lastLoginAt)),
        _buildInfoRow('Compte créé le', profileProvider.formatDate(profileProvider.createdAt)),
        _buildInfoRow('Type d\'appareil', profileProvider.deviceType ?? 'Non disponible'),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingS)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Message d'erreur
  Widget _buildErrorMessage(ProfileProvider profileProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingM)),
      child: Container(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 20),
            SizedBox(width: ResponsiveSize.getWidth(8)),
            Expanded(
              child: Text(
                profileProvider.error!,
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

  /// Bouton de sauvegarde
  Widget _buildSaveButton(ProfileProvider profileProvider) {
    return ElevatedButton(
      onPressed: profileProvider.isSaving ? null : () => _saveProfile(profileProvider),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.dtBlue,
        foregroundColor: AppTheme.dtYellow,
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveSize.getHeight(16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusM),
          ),
        ),
        elevation: profileProvider.isSaving ? 0 : 2,
      ),
      child: profileProvider.isSaving
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
                Icon(
                  Icons.save,
                  size: ResponsiveSize.getFontSize(18),
                ),
                SizedBox(width: ResponsiveSize.getWidth(8)),
                Text(
                  'Enregistrer les modifications',
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
