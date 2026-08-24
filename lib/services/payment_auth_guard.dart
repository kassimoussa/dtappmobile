import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../enums/payment_auth_method.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_verification_bottom_sheet.dart';
import 'biometric_auth_service.dart';
import 'user_session.dart';

/// Point de passage unique pour exiger l'authentification choisie dans
/// « Paramètres de paiement » avant de débiter l'utilisateur.
///
/// Centraliser cette logique évite d'en maintenir une copie par écran de
/// paiement : sur du code qui engage de l'argent, une copie oubliée lors d'une
/// évolution est un trou de sécurité silencieux.
class PaymentAuthGuard {
  /// Retourne `true` si le paiement peut se poursuivre.
  ///
  /// Se charge lui-même d'afficher le message d'erreur quand la biométrie
  /// échoue sans PIN de repli disponible. Une annulation volontaire de
  /// l'utilisateur reste silencieuse : elle est déjà explicite pour lui.
  static Future<bool> authorize(
    BuildContext context, {
    required String itemName,
    required double amount,
    required String currency,
    required String pinTitle,
  }) async {
    final authProvider = context.read<AuthProvider>();
    final phoneNumber = authProvider.phoneNumber;

    // Sans numéro connu on ne peut pas lire le réglage : on retombe sur la
    // biométrie, valeur par défaut et comportement historique.
    final method = phoneNumber == null
        ? PaymentAuthMethod.biometric
        : await UserSession.getPaymentAuthMethod(phoneNumber);
    if (!context.mounted) return false;

    if (method == PaymentAuthMethod.pin && phoneNumber != null) {
      return PinVerificationBottomSheet.show(
        context,
        phoneNumber: phoneNumber,
        title: pinTitle,
      );
    }

    final result = await BiometricAuthService.authenticateForPurchase(
      itemName: itemName,
      amount: amount,
      currency: currency,
    );
    if (result.success) return true;
    if (!context.mounted) return false;

    // Échec de la biométrie : le PIN sert de repli s'il est configuré.
    if (!authProvider.hasPin || phoneNumber == null) {
      if (result.errorType != BiometricAuthErrorType.userCancel) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  AppLocalizations.of(context)!.authFailed,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    return PinVerificationBottomSheet.show(
      context,
      phoneNumber: phoneNumber,
      title: pinTitle,
    );
  }
}
