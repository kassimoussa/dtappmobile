// lib/providers/profile_provider.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

/// Provider centralisé pour gérer le profil utilisateur
/// Offre chargement, mise à jour et cache des données de profil
class ProfileProvider extends ChangeNotifier {
  // État du profil
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  DateTime? _lastFetch;

  // Durée de validité du cache (15 minutes - profil change rarement)
  static const Duration _cacheDuration = Duration(minutes: 15);

  // Getters pour l'état
  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  DateTime? get lastFetch => _lastFetch;
  bool get hasData => _profileData != null;

  // Getters pour les données utilisateur
  String? get phoneNumber => _profileData?['user']?['phone_number'];
  String? get name => _profileData?['user']?['name'];
  String? get email => _profileData?['user']?['email'];
  DateTime? get lastLoginAt {
    final dateStr = _profileData?['user']?['last_login_at'];
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }
  DateTime? get createdAt {
    final dateStr = _profileData?['user']?['created_at'];
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }
  String? get deviceType => _profileData?['session']?['device_type'];

  /// Vérifie si le cache est encore valide
  bool get isCacheValid {
    if (_lastFetch == null) return false;
    final now = DateTime.now();
    return now.difference(_lastFetch!) < _cacheDuration;
  }

  /// Charge le profil utilisateur depuis l'API
  /// Si useCache = false, force un rechargement
  Future<void> fetchProfile({bool forceRefresh = false}) async {
    // Si le cache est valide et qu'on ne force pas le refresh, ne rien faire
    if (!forceRefresh && isCacheValid) {
      debugPrint('👤 Utilisation du cache pour le profil (valide pendant ${_cacheDuration.inMinutes - DateTime.now().difference(_lastFetch!).inMinutes} min)');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('👤 Récupération du profil depuis l\'API...');

      final data = await ProfileService.getUserProfile();

      if (data != null) {
        _profileData = data;
        _lastFetch = DateTime.now();
        _error = null;

        debugPrint('✅ Profil récupéré: ${name ?? phoneNumber}');
      } else {
        _error = 'Aucune donnée de profil disponible';
      }
    } catch (e) {
      _error = 'Erreur lors du chargement du profil: $e';
      debugPrint('❌ $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchit le profil (force un nouvel appel API)
  Future<void> refresh() async {
    return fetchProfile(forceRefresh: true);
  }

  /// Met à jour le profil utilisateur
  Future<bool> updateProfile({
    String? name,
    String? email,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('👤 Mise à jour du profil...');

      final success = await ProfileService.updateUserProfile(
        name: name,
        email: email,
      );

      if (success) {
        // Mettre à jour les données locales
        if (_profileData != null) {
          _profileData!['user']['name'] = name;
          _profileData!['user']['email'] = email;
        }

        _error = null;
        debugPrint('✅ Profil mis à jour avec succès');
        notifyListeners();
        return true;
      } else {
        _error = 'Échec de la mise à jour du profil';
        debugPrint('❌ $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour: $e';
      debugPrint('❌ $_error');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Invalide le cache et efface le profil
  /// Utile après déconnexion
  void invalidateCache() {
    _profileData = null;
    _lastFetch = null;
    _error = null;
    debugPrint('🔄 Cache du profil invalidé');
    notifyListeners();
  }

  /// Efface toutes les données du profil
  void clear() {
    _profileData = null;
    _lastFetch = null;
    _error = null;
    _isLoading = false;
    _isSaving = false;
    debugPrint('🗑️ Données de profil effacées');
    notifyListeners();
  }

  /// Efface l'erreur actuelle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Formate une date pour l'affichage
  String formatDate(DateTime? date) {
    if (date == null) return 'Non disponible';
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Récupère l'initiale pour l'avatar
  String getInitial() {
    if (name?.isNotEmpty == true) {
      return name!.substring(0, 1).toUpperCase();
    }
    if (phoneNumber != null && phoneNumber!.length >= 4) {
      return phoneNumber!.substring(phoneNumber!.length - 4);
    }
    return '?';
  }

  /// Récupère le nom d'affichage
  String getDisplayName() {
    return name?.isNotEmpty == true ? name! : 'Utilisateur';
  }
}
