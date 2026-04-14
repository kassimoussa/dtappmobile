import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';
import '../providers/auth_provider.dart';
import '../generated/l10n/app_localizations.dart';
import 'pin_dots.dart';
import 'pin_keyboard.dart';
import '../services/pin_service.dart';

class PinVerificationBottomSheet extends StatefulWidget {
  final Future<void> Function(String pin)? onPinVerified;
  final String phoneNumber;
  final String? customTitle;
  final String? customMessage;

  const PinVerificationBottomSheet({
    super.key,
    this.onPinVerified,
    required this.phoneNumber,
    this.customTitle,
    this.customMessage,
  });

  /// Affiche le BottomSheet et retourne `true` si le PIN a été validé avec succès
  static Future<bool> show(
    BuildContext context, {
    required String phoneNumber,
    String? title,
    String? message,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinVerificationBottomSheet(
        phoneNumber: phoneNumber,
        customTitle: title,
        customMessage: message,
      ),
    );
    return result ?? false;
  }

  @override
  State<PinVerificationBottomSheet> createState() => _PinVerificationBottomSheetState();
}

class _PinVerificationBottomSheetState extends State<PinVerificationBottomSheet> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _handleNumberPressed(String number) {
    if (_pin.length < 4 && !_isLoading) {
      setState(() {
        _pin += number;
        _errorMessage = null; // Clear error when typing
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _handleDeletePressed() {
    if (_pin.isNotEmpty && !_isLoading) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();

    // Test du login local avec le PIN via PinService
    // On utilise PinService directement pour ne pas altérer le status d'activité / session de l'AuthProvider
    // sauf si vous voulez que ça reset l'inactivité, utiliser authProvider.loginWithPin
    
    // Vu que l'utilisateur est déjà connecté, on va juste valider le PIN
    final success = await authProvider.loginWithPin(widget.phoneNumber, _pin);

    if (!mounted) return;

    if (success) {
      // Succès
      if (widget.onPinVerified != null) {
        await widget.onPinVerified!(_pin);
      }
      if (mounted) Navigator.pop(context, true);
    } else {
      // Erreur
      setState(() {
        _isLoading = false;
        _pin = '';
        _errorMessage = authProvider.errorMessage ?? AppLocalizations.of(context)!.authFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;
    final title = widget.customTitle ?? l10n.pleaseReenterPin;
    final message = widget.customMessage ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveSize.getWidth(AppTheme.radiusL)),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: ResponsiveSize.getHeight(12)),
              width: ResponsiveSize.getWidth(40),
              height: ResponsiveSize.getHeight(5),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(10)),
              ),
            ),

            SizedBox(height: ResponsiveSize.getHeight(24)),
            
            // Icon
            Container(
              padding: EdgeInsets.all(ResponsiveSize.getWidth(16)),
              decoration: BoxDecoration(
                color: AppTheme.dtBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppTheme.dtBlue,
                size: ResponsiveSize.getFontSize(32),
              ),
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(16)),

            // Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(AppTheme.spacingL)),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ),

            if (message.isNotEmpty) ...[
              SizedBox(height: ResponsiveSize.getHeight(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(AppTheme.spacingL)),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],

            SizedBox(height: ResponsiveSize.getHeight(24)),

            // Loading / Dots / Error
            if (_isLoading)
               SizedBox(
                height: ResponsiveSize.getHeight(24),
                width: ResponsiveSize.getHeight(24),
                child: CircularProgressIndicator(color: AppTheme.dtBlue, strokeWidth: 3),
              )
            else ...[
              PinDots(pinLength: _pin.length, maxLength: 4),

              if (_errorMessage != null) ...[
                SizedBox(height: ResponsiveSize.getHeight(16)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.getWidth(AppTheme.spacingL)),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: ResponsiveSize.getFontSize(14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],

            SizedBox(height: ResponsiveSize.getHeight(32)),

            // Custom Keyboard
            PinKeyboard(
              onNumberPressed: _handleNumberPressed,
              onDeletePressed: _handleDeletePressed,
            ),
            
            SizedBox(height: ResponsiveSize.getHeight(24)),
          ],
        ),
      ),
    );
  }
}
