/// Configuration globale de l'application.
/// Modifier uniquement ici pour changer l'environnement.
///
/// ⚠️ CONTOURNEMENT TEMPORAIRE : le HTTPS (443) vers l'IP brute est reseté par
/// le réseau mobile DT (firewall côté serveur bloquant le 443 depuis les plages
/// mobiles — cf. diagnostic). Le port 80 (HTTP) fonctionne partout, donc on
/// passe en HTTP sur l'IP. Le trafic est ALORS EN CLAIR (token de session, PIN,
/// solde). Dès que le firewall/DNS est corrigé : basculer [serverBase] sur
/// [domainBase] et retirer l'autorisation cleartext (network_security_config.xml
/// côté Android, NSAppTransportSecurity côté iOS).
class AppConfig {
  /// HTTP sur l'IP — actif tant que le 443 vers l'IP est bloqué en 4G.
  static const String ipBase = 'http://196.201.193.252';

  /// HTTPS sur le domaine — cible finale, dès que le DNS de
  /// mydtapp.djiboutitelecom.dj résout.
  static const String domainBase = 'https://mydtapp.djiboutitelecom.dj';

  /// Base active. Basculer sur [domainBase] une fois le firewall/DNS corrigé.
  static const String serverBase = ipBase;
  static const String baseUrl = '$serverBase/api';
}
