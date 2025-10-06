# Guide d'intégration FCM pour applications mobiles

Ce guide explique comment intégrer les notifications push Firebase Cloud Messaging (FCM) dans votre application mobile pour recevoir les notifications de transaction de l'API Djibouti Telecom.

## 📋 Prérequis

- ✅ Projet Firebase configuré
- ✅ FCM SDK intégré dans l'application
- ✅ Permissions de notification accordées
- ✅ Session utilisateur active dans l'API

## 🔧 Étape 1 : Configuration initiale

### Android (Kotlin)

**1. Ajout des dépendances dans `build.gradle` :**
```kotlin
dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
    implementation 'com.squareup.okhttp3:okhttp:4.9.0'
}
```

**2. Permissions dans `AndroidManifest.xml` :**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**3. Service FCM dans `AndroidManifest.xml` :**
```xml
<service
    android:name=".FCMService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### iOS (Swift)

**1. Configuration dans `AppDelegate.swift` :**
```swift
import Firebase
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Permission granted: \(granted)")
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
}
```

## 📱 Étape 2 : Récupération et envoi du token FCM

### Android

**1. Créer la classe `FCMTokenManager.kt` :**
```kotlin
import com.google.firebase.messaging.FirebaseMessaging
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException

class FCMTokenManager {
    
    companion object {
        private const val API_BASE_URL = "https://your-api-domain.com"
        private const val UPDATE_TOKEN_ENDPOINT = "/api/mobile/fcm/update-token"
        private const val CLEAR_TOKEN_ENDPOINT = "/api/mobile/fcm/clear-token"
    }
    
    private val client = OkHttpClient()
    
    /**
     * Récupère le token FCM et l'envoie au serveur
     */
    fun updateTokenOnServer(sessionToken: String) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                println("Échec récupération token FCM: ${task.exception}")
                return@addOnCompleteListener
            }
            
            val fcmToken = task.result
            println("Token FCM récupéré: $fcmToken")
            
            sendTokenToServer(sessionToken, fcmToken)
        }
    }
    
    /**
     * Envoie le token FCM au serveur
     */
    private fun sendTokenToServer(sessionToken: String, fcmToken: String) {
        val json = JSONObject().apply {
            put("session_token", sessionToken)
            put("fcm_token", fcmToken)
        }
        
        val requestBody = json.toString().toRequestBody("application/json".toMediaType())
        
        val request = Request.Builder()
            .url("$API_BASE_URL$UPDATE_TOKEN_ENDPOINT")
            .post(requestBody)
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                if (response.isSuccessful) {
                    println("✅ Token FCM envoyé avec succès")
                } else {
                    println("❌ Erreur envoi token: ${response.code}")
                }
            }
            
            override fun onFailure(call: Call, e: IOException) {
                println("❌ Échec réseau envoi token: ${e.message}")
            }
        })
    }
    
    /**
     * Supprime le token FCM du serveur (lors de la déconnexion)
     */
    fun clearTokenOnServer(sessionToken: String) {
        val json = JSONObject().apply {
            put("session_token", sessionToken)
        }
        
        val requestBody = json.toString().toRequestBody("application/json".toMediaType())
        
        val request = Request.Builder()
            .url("$API_BASE_URL$CLEAR_TOKEN_ENDPOINT")
            .post(requestBody)
            .build()
        
        client.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                if (response.isSuccessful) {
                    println("✅ Token FCM supprimé du serveur")
                }
            }
            
            override fun onFailure(call: Call, e: IOException) {
                println("❌ Échec suppression token: ${e.message}")
            }
        })
    }
}
```

**2. Créer le service `FCMService.kt` :**
```kotlin
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class FCMService : FirebaseMessagingService() {
    
    /**
     * Appelé quand un nouveau token est généré
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        println("Nouveau token FCM: $token")
        
        // Récupérer le session token depuis les préférences ou session
        val sessionToken = getSessionToken()
        if (sessionToken != null) {
            FCMTokenManager().updateTokenOnServer(sessionToken)
        }
    }
    
    /**
     * Appelé quand une notification est reçue (app en premier plan)
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        // Notification avec titre et corps
        remoteMessage.notification?.let { notification ->
            showNotification(
                title = notification.title ?: "Djibouti Telecom",
                body = notification.body ?: "Nouvelle notification"
            )
        }
        
        // Données personnalisées
        if (remoteMessage.data.isNotEmpty()) {
            handleNotificationData(remoteMessage.data)
        }
    }
    
    private fun getSessionToken(): String? {
        // Récupérer depuis SharedPreferences ou votre système de session
        return getSharedPreferences("user_session", MODE_PRIVATE)
            .getString("session_token", null)
    }
    
    private fun showNotification(title: String, body: String) {
        // Implémenter l'affichage de notification locale
        // (NotificationManager, NotificationCompat.Builder, etc.)
    }
    
    private fun handleNotificationData(data: Map<String, String>) {
        // Traiter les données personnalisées selon le type de transaction
        when (data["type"]) {
            "offer_purchase" -> handleOfferPurchase(data)
            "credit_transfer" -> handleCreditTransfer(data)
            "voucher_refill" -> handleVoucherRefill(data)
            // etc.
        }
    }
    
    private fun handleOfferPurchase(data: Map<String, String>) {
        // Logique spécifique aux achats d'offres
    }
    
    private fun handleCreditTransfer(data: Map<String, String>) {
        // Logique spécifique aux transferts de crédit
    }
    
    private fun handleVoucherRefill(data: Map<String, String>) {
        // Logique spécifique aux recharges
    }
}
```

### iOS (Swift)

**1. Créer `FCMTokenManager.swift` :**
```swift
import Foundation
import FirebaseMessaging

class FCMTokenManager {
    
    static let shared = FCMTokenManager()
    private let apiBaseURL = "https://your-api-domain.com"
    
    private init() {}
    
    /**
     * Met à jour le token FCM sur le serveur
     */
    func updateTokenOnServer(sessionToken: String) {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Erreur récupération token FCM: \(error)")
                return
            }
            
            guard let fcmToken = token else {
                print("❌ Token FCM vide")
                return
            }
            
            print("✅ Token FCM récupéré: \(fcmToken)")
            self.sendTokenToServer(sessionToken: sessionToken, fcmToken: fcmToken)
        }
    }
    
    /**
     * Envoie le token au serveur
     */
    private func sendTokenToServer(sessionToken: String, fcmToken: String) {
        guard let url = URL(string: "\(apiBaseURL)/api/mobile/fcm/update-token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "session_token": sessionToken,
            "fcm_token": fcmToken
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Erreur sérialisation JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Token FCM envoyé avec succès")
                } else {
                    print("❌ Erreur serveur: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    /**
     * Supprime le token du serveur
     */
    func clearTokenOnServer(sessionToken: String) {
        guard let url = URL(string: "\(apiBaseURL)/api/mobile/fcm/clear-token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["session_token": sessionToken]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Erreur sérialisation JSON: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau: \(error)")
                return
            }
            
            print("✅ Token FCM supprimé du serveur")
        }.resume()
    }
}
```

**2. Étendre `AppDelegate.swift` :**
```swift
extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {
    
    /**
     * Appelé quand le token FCM change
     */
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Nouveau token FCM: \(fcmToken)")
        
        // Récupérer le session token et envoyer au serveur
        if let sessionToken = getSessionToken() {
            FCMTokenManager.shared.updateTokenOnServer(sessionToken: sessionToken)
        }
    }
    
    /**
     * Gestion des notifications reçues
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Afficher la notification même si l'app est au premier plan
        completionHandler([.alert, .badge, .sound])
    }
    
    /**
     * Gestion du tap sur notification
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    private func getSessionToken() -> String? {
        // Récupérer depuis UserDefaults ou votre système de session
        return UserDefaults.standard.string(forKey: "session_token")
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Traiter le tap sur notification selon le type
        if let type = userInfo["type"] as? String {
            switch type {
            case "offer_purchase":
                // Naviguer vers l'écran des offres
                break
            case "credit_transfer":
                // Naviguer vers l'écran de solde
                break
            case "voucher_refill":
                // Naviguer vers l'écran de recharge
                break
            default:
                break
            }
        }
    }
}
```

## 🔄 Étape 3 : Intégration dans le flux d'authentification

### Lors de la connexion

**Android :**
```kotlin
// Après une connexion réussie
class LoginActivity {
    
    private val fcmTokenManager = FCMTokenManager()
    
    private fun onLoginSuccess(sessionToken: String) {
        // Sauvegarder le session token
        saveSessionToken(sessionToken)
        
        // Envoyer le token FCM au serveur
        fcmTokenManager.updateTokenOnServer(sessionToken)
        
        // Naviguer vers l'écran principal
        startActivity(Intent(this, MainActivity::class.java))
    }
}
```

**iOS :**
```swift
// Après une connexion réussie
func onLoginSuccess(sessionToken: String) {
    // Sauvegarder le session token
    UserDefaults.standard.set(sessionToken, forKey: "session_token")
    
    // Envoyer le token FCM au serveur
    FCMTokenManager.shared.updateTokenOnServer(sessionToken: sessionToken)
    
    // Naviguer vers l'écran principal
    // ...
}
```

### Lors de la déconnexion

**Android :**
```kotlin
private fun logout() {
    val sessionToken = getSessionToken()
    if (sessionToken != null) {
        // Supprimer le token FCM du serveur
        fcmTokenManager.clearTokenOnServer(sessionToken)
    }
    
    // Supprimer les données locales
    clearSessionData()
}
```

**iOS :**
```swift
func logout() {
    if let sessionToken = getSessionToken() {
        // Supprimer le token FCM du serveur
        FCMTokenManager.shared.clearTokenOnServer(sessionToken: sessionToken)
    }
    
    // Supprimer les données locales
    UserDefaults.standard.removeObject(forKey: "session_token")
}
```

## 📬 Étape 4 : Types de notifications reçues

Votre application recevra automatiquement des notifications pour :

### 1. Achat d'offre
```json
{
  "title": "Achat confirmé ! 🎉",
  "body": "Votre offre Classic a été activée pour 1000 DJF",
  "data": {
    "type": "offer_purchase",
    "amount": 1000,
    "offer_name": "Classic",
    "action": "view_offers"
  }
}
```

### 2. Transfert de crédit
```json
{
  "title": "Transfert réussi ! 💸",
  "body": "Vous avez envoyé 500 DJF au 77123456",
  "data": {
    "type": "credit_transfer",
    "amount": 500,
    "receiver_msisdn": "77123456",
    "action": "view_balance"
  }
}
```

### 3. Recharge voucher
```json
{
  "title": "Recharge confirmée ! 🔋",
  "body": "Votre compte a été rechargé de 2000 DJF",
  "data": {
    "type": "voucher_refill",
    "amount": 2000,
    "action": "view_balance"
  }
}
```

### 4. Cadeau reçu
```json
{
  "title": "Cadeau reçu ! 🎁",
  "body": "Vous avez reçu une offre de 77654321",
  "data": {
    "type": "offer_gift",
    "sender_msisdn": "77654321",
    "action": "view_offers"
  }
}
```

## ✅ Étape 5 : Tests et validation

### 1. Test depuis l'interface admin
- Accédez à `https://your-api-domain.com/fcm/test`
- Votre utilisateur apparaîtra dans la liste avec son token
- Utilisez le bouton "Utiliser" pour tester

### 2. Test manuel via API
```bash
curl -X POST https://your-api-domain.com/api/fcm/test/send \
  -H "Content-Type: application/json" \
  -d '{
    "token": "VOTRE_TOKEN_FCM",
    "title": "Test depuis mobile",
    "body": "Ceci est un test de notification"
  }'
```

### 3. Logs à surveiller
- **Android :** Vérifiez les logs avec `adb logcat`
- **iOS :** Vérifiez la console Xcode
- **Serveur :** Consultez les logs Laravel

## 🔧 Dépannage courant

### Token non reçu côté serveur
- Vérifiez les permissions de notification
- Vérifiez la connexion réseau
- Vérifiez que le session_token est valide

### Notifications non reçues
- Vérifiez la configuration Firebase
- Vérifiez que l'app n'est pas en mode "Ne pas déranger"
- Testez avec l'interface admin d'abord

### Token qui change fréquemment
- C'est normal, le service `onNewToken` gère automatiquement
- Assurez-vous que la mise à jour est bien envoyée au serveur

## 📞 Support

Pour toute question technique, contactez l'équipe de développement de l'API Djibouti Telecom avec :
- Version de l'application
- Logs d'erreur
- Token FCM (tronqué pour sécurité)