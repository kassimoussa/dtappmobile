// lib/widgets/phone_number_selector.dart
import 'package:dtservices/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide PermissionStatus;
import 'package:permission_handler/permission_handler.dart';
import '../generated/l10n/app_localizations.dart';

class PhoneNumberSelector extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool showCountryCode;
  final String countryCode;

  const PhoneNumberSelector({
    super.key,
    required this.controller,
    this.hintText = '77 XX XX XX',
    this.labelText,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.showCountryCode = true,
    this.countryCode = '+253',
  });

  @override
  State<PhoneNumberSelector> createState() => _PhoneNumberSelectorState();
}

class _PhoneNumberSelectorState extends State<PhoneNumberSelector> {
  final FocusNode _phoneFocusNode = FocusNode();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filtre les contacts selon le texte de recherche
  void _filterContacts() {
    final String query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        _filteredContacts = _contacts.where((contact) {
          final String name = (contact.displayName ?? '').toLowerCase();
          final String phone = contact.phones.isNotEmpty
              ? contact.phones.first.number.replaceAll(RegExp(r'[^0-9]'), '')
              : '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      }
    });
  }

  // Demande la permission d'accéder aux contacts
  Future<bool> _requestContactPermission() async {
    PermissionStatus permissionStatus = await Permission.contacts.status;

    if (permissionStatus != PermissionStatus.granted) {
      permissionStatus = await Permission.contacts.request();
    }

    return permissionStatus == PermissionStatus.granted;
  }

  // Charge les contacts du téléphone
  Future<void> _getPhoneContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool permissionGranted = await _requestContactPermission();

      if (permissionGranted) {
        final contacts = await FlutterContacts.getAll(
          properties: {
            ContactProperty.name,
            ContactProperty.phone,
            ContactProperty.photoThumbnail,
          },
        );

        setState(() {
          _contacts = contacts;
          _filteredContacts = List.from(_contacts);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          _showErrorMessage(AppLocalizations.of(context)!.contactPermissionDenied);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorMessage('${AppLocalizations.of(context)!.contactRetrievalError}: $e');
      }
    }
  }

  // Extraction du numéro de téléphone pour Djibouti
  String _extractPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.startsWith('253')) {
      cleanNumber = cleanNumber.substring(3);
    }

    if (cleanNumber.length > 8) {
      cleanNumber = cleanNumber.substring(cleanNumber.length - 8);
    }

    return cleanNumber;
  }

  // Affiche un message d'erreur
  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Affiche la feuille de contacts
  Future<void> _showContactsBottomSheet() async {
    if (_contacts.isEmpty) {
      await _getPhoneContacts();
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.selectContact,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Barre de recherche
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchContact,
                    border: InputBorder.none,
                    icon: const Icon(Icons.search),
                  ),
                  onChanged: (_) {
                    setModalState(() {
                      _filterContacts();
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Liste des contacts
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredContacts.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noContactFound,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : _buildContactsList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construit la liste des contacts
  Widget _buildContactsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final Contact contact = _filteredContacts[index];

        String phoneNumber = '';
        if (contact.phones.isNotEmpty) {
          phoneNumber = contact.phones.first.number;
          phoneNumber = _extractPhoneNumber(phoneNumber);
        }

        final photoBytes = contact.photo?.thumbnail;
        final name = contact.displayName ?? '';
        return ListTile(
          leading: photoBytes != null
              ? CircleAvatar(
                  backgroundImage: MemoryImage(photoBytes),
                  radius: 20,
                )
              : CircleAvatar(
                  backgroundColor: AppTheme.dtBlue2.withValues(alpha: 0.1),
                  radius: 20,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dtBlue2,
                    ),
                  ),
                ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: phoneNumber.isNotEmpty
              ? Text('${widget.countryCode} $phoneNumber')
              : Text(l10n.noNumber),
          trailing: phoneNumber.isNotEmpty
              ? const Icon(
                  Icons.phone,
                  color: AppTheme.dtBlue2,
                  size: 20,
                )
              : null,
          onTap: () {
            if (phoneNumber.isNotEmpty) {
              widget.controller.text = phoneNumber;
              if (widget.onChanged != null) {
                widget.onChanged!(phoneNumber);
              }
              Navigator.pop(context);
            } else {
              _showErrorMessage(l10n.contactNoPhone);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],

        Container(
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.grey[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Indicatif du pays
              if (widget.showCountryCode) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Text(
                    widget.countryCode,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.enabled ? AppTheme.dtBlue2 : Colors.grey,
                    ),
                  ),
                ),

                // Ligne de séparation
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey[300],
                ),
              ],

              // Champ de saisie
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _phoneFocusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.enabled ? Colors.black87 : Colors.grey,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                    _PhoneNumberFormatter(), // Formatter personnalisé pour l'affichage
                  ],
                  onChanged: widget.onChanged,
                  validator: widget.validator,
                ),
              ),

              // Bouton contacts
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.enabled ? _showContactsBottomSheet : null,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.contacts,
                      color: widget.enabled ? AppTheme.dtBlue2 : Colors.grey,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Formatter pour afficher le numéro au format XX XX XX XX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length <= 2) {
      return newValue;
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4 || i == 6) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Utilitaire pour valider les numéros djiboutiens
class DjiboutiPhoneValidator {
  // Note: This validator cannot use l10n since it's a static utility.
  // Callers should provide their own l10n-based validator when possible.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir un numéro de téléphone';
    }

    // Enlever les espaces pour la validation
    final cleanNumber = value.replaceAll(' ', '');

    if (cleanNumber.length != 8) {
      return 'Le numéro doit contenir 8 chiffres';
    }

    if (!cleanNumber.startsWith('77')) {
      return 'Les numéros mobiles djiboutiens commencent par 77';
    }

    return null;
  }

  static String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(' ', '');
  }
}
