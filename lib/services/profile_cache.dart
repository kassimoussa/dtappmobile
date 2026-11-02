// lib/services/profile_cache.dart
import 'package:flutter/foundation.dart';

/// Dernier profil chargé (le `data` de `/mobile/profile`), gardé en mémoire.
///
/// Partagé entre l'écran profil et l'accueil. [profile] est un
/// [ValueNotifier] : l'accueil affiche le prénom dès qu'il est connu et suit
/// un changement de nom fait depuis le profil. Il est vidé avec la session
/// (`UserSession.clearSession`), sinon un autre compte verrait le prénom du
/// précédent.
class ProfileCache {
  ProfileCache._();

  static final ValueNotifier<Map<String, dynamic>?> profile = ValueNotifier(
    null,
  );

  static void clear() => profile.value = null;

  /// Prénom d'après [data], ou `null` si le profil n'a pas de nom.
  ///
  /// Le backend ne stocke qu'un champ `name` libre : le prénom est son
  /// premier mot.
  static String? firstName(Map<String, dynamic>? data) {
    final user = data?['user'];
    final name = user is Map ? user['name'] : null;
    if (name is! String) return null;
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? null : first;
  }
}
