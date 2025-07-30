// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../services/profile_service.dart';
import '../widgets/appbar_widget.dart';
import '../extensions/color_extensions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Données utilisateur
  String? _phoneNumber;
  String? _currentName;
  String? _currentEmail;
  DateTime? _lastLoginAt;
  DateTime? _createdAt;
  String? _deviceType;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les données du profil
      final profileData = await ProfileService.getUserProfile();
      
      if (profileData != null && mounted) {
        final userData = profileData['user'];
        final sessionData = profileData['session'];
        
        setState(() {
          _phoneNumber = userData['phone_number'];
          _currentName = userData['name'];
          _currentEmail = userData['email'];
          _lastLoginAt = userData['last_login_at'] != null 
              ? DateTime.tryParse(userData['last_login_at']) 
              : null;
          _createdAt = userData['created_at'] != null 
              ? DateTime.tryParse(userData['created_at']) 
              : null;
          _deviceType = sessionData['device_type'];
          
          // Pré-remplir les champs de formulaire
          _nameController.text = _currentName ?? '';
          _emailController.text = _currentEmail ?? '';
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement du profil';
          _isLoading = false;
        });
      }
    }
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
          setState(() {
            _currentName = _nameController.text.trim();
            _currentEmail = _emailController.text.trim();
          });
          
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
          setState(() {
            _errorMessage = 'Erreur lors de la mise à jour';
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde profil: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la sauvegarde';
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non disponible';
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
      body: _isLoading 
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                    _buildPersonalInfoSection(),
                    SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                    _buildAccountInfoSection(),
                    SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
                    if (_errorMessage != null) _buildErrorMessage(),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

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

  Widget _buildProfileHeader() {
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
              _currentName?.isNotEmpty == true 
                  ? _currentName!.substring(0, 1).toUpperCase()
                  : _phoneNumber?.substring(_phoneNumber!.length - 4) ?? '?',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(24),
                fontWeight: FontWeight.bold,
                color: AppTheme.dtYellow,
              ),
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            _currentName?.isNotEmpty == true ? _currentName! : 'Utilisateur',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(20),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            _phoneNumber ?? '',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildAccountInfoSection() {
    return _buildSection(
      title: 'Informations du compte',
      children: [
        _buildInfoRow('Numéro de téléphone', _phoneNumber ?? 'Non disponible'),
        _buildInfoRow('Dernière connexion', _formatDate(_lastLoginAt)),
        _buildInfoRow('Compte créé le', _formatDate(_createdAt)),
        _buildInfoRow('Type d\'appareil', _deviceType ?? 'Non disponible'),
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

  Widget _buildErrorMessage() {
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
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveSize.getHeight(16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusM),
          ),
        ),
        elevation: _isSaving ? 0 : 2,
      ),
      child: _isSaving
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