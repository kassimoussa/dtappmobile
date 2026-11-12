import 'dart:convert';

import 'package:dtservices/services/user_session.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un numéro déjà utilisé comme destinataire (transfert, forfait offert,
/// recharge pour un tiers).
@immutable
class SavedRecipient {
  /// Numéro local à 8 chiffres, sans indicatif.
  final String number;

  /// Nom du contact, seulement si l'utilisateur l'a choisi dans son répertoire.
  final String? name;

  final bool favorite;

  /// Dernière utilisation, en millisecondes depuis l'époque.
  final int usedAt;

  const SavedRecipient({
    required this.number,
    this.name,
    this.favorite = false,
    required this.usedAt,
  });

  SavedRecipient copyWith({String? name, bool? favorite, int? usedAt}) =>
      SavedRecipient(
        number: number,
        name: name ?? this.name,
        favorite: favorite ?? this.favorite,
        usedAt: usedAt ?? this.usedAt,
      );

  Map<String, dynamic> toJson() => {
    'n': number,
    if (name != null) 'name': name,
    'fav': favorite,
    't': usedAt,
  };

  static SavedRecipient? fromJson(Object? json) {
    if (json is! Map) return null;
    final number = json['n'];
    if (number is! String || !RecipientBook.isLocalNumber(number)) return null;
    final name = json['name'];
    final usedAt = json['t'];
    return SavedRecipient(
      number: number,
      name: name is String && name.trim().isNotEmpty ? name.trim() : null,
      favorite: json['fav'] == true,
      usedAt: usedAt is int ? usedAt : 0,
    );
  }
}

/// Règles de la liste, sans accès au stockage (testables seules).
class RecipientBook {
  /// Destinataires non favoris gardés ; les plus anciens sortent en premier.
  static const maxRecents = 8;

  /// Les favoris sont choisis par l'utilisateur, mais la liste reste bornée.
  static const maxFavorites = 12;

  /// Ramène « +253 77 12 34 56 », « 25377123456 » ou « 77 12 34 56 » à
  /// « 77123456 ». Renvoie null si ce n'est pas un numéro local à 8 chiffres.
  static String? normalize(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('253')) {
      digits = digits.substring(3);
    }
    return isLocalNumber(digits) ? digits : null;
  }

  static bool isLocalNumber(String value) => RegExp(r'^\d{8}$').hasMatch(value);

  /// Favoris d'abord, puis du plus récent au plus ancien.
  static List<SavedRecipient> sorted(Iterable<SavedRecipient> list) {
    final copy = list.toList();
    copy.sort((a, b) {
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      return b.usedAt.compareTo(a.usedAt);
    });
    return copy;
  }

  /// Ajoute ou remet en tête [number] (favori et nom déjà connus conservés).
  static List<SavedRecipient> record(
    List<SavedRecipient> list,
    String number, {
    String? name,
    required int now,
  }) {
    final existing = list.where((r) => r.number == number).firstOrNull;
    final cleanName = name?.trim();
    final updated =
        existing == null
            ? SavedRecipient(
              number: number,
              name: cleanName == null || cleanName.isEmpty ? null : cleanName,
              usedAt: now,
            )
            : existing.copyWith(
              name: cleanName == null || cleanName.isEmpty ? null : cleanName,
              usedAt: now,
            );
    return _bounded([
      for (final r in list)
        if (r.number != number) r,
      updated,
    ]);
  }

  static List<SavedRecipient> setFavorite(
    List<SavedRecipient> list,
    String number,
    bool favorite,
  ) {
    return _bounded([
      for (final r in list)
        r.number == number ? r.copyWith(favorite: favorite) : r,
    ]);
  }

  static List<SavedRecipient> remove(
    List<SavedRecipient> list,
    String number,
  ) => [
    for (final r in list)
      if (r.number != number) r,
  ];

  static List<SavedRecipient> _bounded(List<SavedRecipient> list) {
    final ordered = sorted(list);
    final favorites = ordered.where((r) => r.favorite).take(maxFavorites);
    final recents = ordered.where((r) => !r.favorite).take(maxRecents);
    return [...favorites, ...recents];
  }
}

/// Destinataires récents et favoris, gardés sur le téléphone (jamais envoyés
/// au serveur). La liste est propre à chaque compte : un autre numéro connecté
/// sur le même téléphone ne voit pas celle-ci.
class RecentRecipientsService {
  static const _keyPrefix = 'recent_recipients_';

  // Noms de contacts choisis dans le répertoire, retenus en mémoire seulement :
  // ils ne sont écrits sur le téléphone que si l'opération aboutit.
  static final Map<String, String> _nameHints = {};

  /// À appeler quand l'utilisateur choisit [name] dans son répertoire.
  static void noteContactName(String rawNumber, String name) {
    final number = RecipientBook.normalize(rawNumber);
    if (number == null || name.trim().isEmpty) return;
    _nameHints[number] = name.trim();
  }

  /// Liste du compte connecté (ou de [owner]), favoris d'abord.
  static Future<List<SavedRecipient>> load({String? owner}) async {
    final key = await _key(owner);
    if (key == null) return const [];
    return RecipientBook.sorted(await _read(key));
  }

  /// Retient [rawNumber] après une opération réussie. Sans effet pour son
  /// propre numéro ou pour un numéro invalide.
  static Future<void> record(String rawNumber, {String? owner}) async {
    final number = RecipientBook.normalize(rawNumber);
    if (number == null) return;
    final ownerNumber = owner ?? await UserSession.getPhoneNumber();
    if (ownerNumber == null || RecipientBook.normalize(ownerNumber) == number) {
      return;
    }
    final key = _keyFor(ownerNumber);
    await _write(
      key,
      RecipientBook.record(
        await _read(key),
        number,
        // Sans nom de contact, le nom déjà retenu est conservé.
        name: _nameHints.remove(number),
        now: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  static Future<void> setFavorite(
    String number,
    bool favorite, {
    String? owner,
  }) async {
    final key = await _key(owner);
    if (key == null) return;
    await _write(
      key,
      RecipientBook.setFavorite(await _read(key), number, favorite),
    );
  }

  static Future<void> remove(String number, {String? owner}) async {
    final key = await _key(owner);
    if (key == null) return;
    await _write(key, RecipientBook.remove(await _read(key), number));
  }

  static Future<String?> _key(String? owner) async {
    final ownerNumber = owner ?? await UserSession.getPhoneNumber();
    return ownerNumber == null || ownerNumber.isEmpty
        ? null
        : _keyFor(ownerNumber);
  }

  static String _keyFor(String owner) =>
      '$_keyPrefix${RecipientBook.normalize(owner) ?? owner}';

  static Future<List<SavedRecipient>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (SavedRecipient.fromJson(item) case final r?) r,
      ];
    } on FormatException {
      return [];
    }
  }

  static Future<void> _write(String key, List<SavedRecipient> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode([for (final r in list) r.toJson()]));
  }
}
