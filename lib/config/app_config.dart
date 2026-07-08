/// Configuration globale de l'application.
/// Modifier uniquement ici pour changer l'environnement.
///
/// IP en dur temporaire : le DNS de mydtapp.djiboutitelecom.dj est
/// instable côté serveur (serveurs faisant autorité injoignables).
/// Repasser sur le nom de domaine une fois le DNS corrigé, car l'IP
/// peut changer sans préavis lors d'une migration d'infra.
class AppConfig {
  static const String baseUrl = 'https://196.201.193.252/api';
  static const String serverBase = 'https://196.201.193.252';
}
