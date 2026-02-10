Modifications effectuées
1. fcm_token_service.dart
Nouvelle méthode registerTokenWithPhone(phoneNumber) - Enregistre le token FCM avec le numéro de téléphone (sans session requise)
Modifié updateTokenOnServer() - Utilise le numéro enregistré si pas de session
Modifié listenToTokenRefresh() - Fonctionne même sans session
Supprimé clearTokenOnServer() - Plus nécessaire
2. user_session.dart
Nouvelle méthode setLastUsedPhoneForFCM(phoneNumber) - Sauvegarde le numéro pour FCM
Nouvelle méthode getLastUsedPhoneForFCM() - Récupère le numéro enregistré
3. logout_service.dart
Supprimé l'appel à clearTokenOnServer() - Le token FCM reste associé au numéro
4. auth_provider.dart
Modifié sendOtp() - Enregistre le token FCM dès l'envoi de l'OTP
Nouvel endpoint API requis

POST /mobile/fcm/register-token
{
  "phone_number": "253XXXXXXXX",
  "fcm_token": "..."
}
Flux FCM
Demande OTP → Token FCM enregistré avec le numéro
Login réussi → Token FCM mis à jour (avec session)
Logout → Token FCM conservé (notifications possibles)
Token refresh → Mise à jour automatique (avec ou sans session)