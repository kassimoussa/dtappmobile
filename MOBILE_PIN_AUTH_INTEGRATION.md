# Guide d'intégration : Authentification par PIN Mobile

## Vue d'ensemble

Ce document décrit l'intégration du système d'authentification par PIN dans l'application mobile. Le PIN est une **alternative** au système OTP existant, permettant aux utilisateurs de se connecter rapidement avec un code à 4 chiffres.

### Caractéristiques

- 🔐 **PIN à 4 chiffres** numérique
- 🔄 **Alternative à l'OTP** (pas un remplacement)
- 🛡️ **Sécurité renforcée** : 5 tentatives max, verrouillage de 5 minutes
- 🔓 **Récupération par OTP** en cas d'oubli
- ⚡ **Rate limiting** : 5 tentatives/minute/IP sur la connexion

---

## Architecture des flux

### 1️⃣ Première connexion (Nouvel utilisateur)

```
┌─────────────┐
│   Utilisateur│
│ sans compte │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ Envoi OTP           │ POST /api/sms/otp/send
│ (existant)          │ { phone_number: "77123456" }
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Vérification OTP    │ POST /api/sms/otp/verify
│ (existant)          │ { to: "77123456", otp: "123456" }
└──────┬──────────────┘
       │
       ▼ Réponse: session_token
┌─────────────────────┐
│ Configuration PIN   │ POST /api/mobile/set-pin
│ (NOUVEAU - optionnel)│ { session_token, pin, pin_confirmation }
└─────────────────────┘
```

### 2️⃣ Connexions suivantes (Utilisateur existant)

```
┌─────────────┐
│ Utilisateur │
│ avec compte │
└──────┬──────┘
       │
       ├─────────────┐
       │             │
       ▼             ▼
  ┌────────┐    ┌────────┐
  │  OTP   │ OU │  PIN   │ (NOUVEAU)
  │(ancien)│    │(nouveau)│
  └────────┘    └────┬───┘
                     │
                     ▼
            POST /api/mobile/login-pin
            { phone_number, pin }
                     │
                     ▼
            Réponse: session_token
```

### 3️⃣ Oubli du PIN

```
┌──────────────┐
│ Utilisateur  │
│ a oublié PIN │
└──────┬───────┘
       │
       ▼
┌─────────────────────┐
│ Envoi OTP           │ POST /api/sms/otp/send
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Réinitialisation PIN│ POST /api/mobile/reset-pin
│ (NOUVEAU)           │ { phone_number, otp, new_pin, new_pin_confirmation }
└─────────────────────┘
```

---

## Endpoints API

Base URL: `https://votre-domaine.com/api`

### 1. Connexion avec PIN

**Endpoint:** `POST /api/mobile/login-pin`

**Rate Limit:** 5 requêtes/minute par IP

**Headers:**
```http
Content-Type: application/json
Accept: application/json
```

**Body:**
```json
{
  "phone_number": "77123456",
  "pin": "1234",
  "device_type": "android",
  "device_info": {
    "device_id": "unique-device-id",
    "model": "Samsung Galaxy S21",
    "os_version": "13",
    "app_version": "1.0.0"
  }
}
```

**Champs requis:**
- `phone_number` (string) : Numéro de téléphone (8 chiffres locaux ou 11 internationaux)
- `pin` (string) : Code PIN à 4 chiffres

**Champs optionnels:**
- `device_type` (string) : `android`, `ios`, ou `web`
- `device_info` (object) : Informations sur l'appareil

#### Réponse succès (200)

```json
{
  "status": "success",
  "message": "Connexion réussie",
  "data": {
    "session_token": "AbCdEf1234567890AbCdEf1234567890AbCdEf1234567890AbCdEf1234",
    "expires_at": "2026-01-08T10:30:00.000000Z",
    "user": {
      "id": 1,
      "phone_number": "77123456",
      "name": "John Doe",
      "email": "john@example.com",
      "is_active": true,
      "has_pin": true,
      "last_login_at": "2025-12-09T10:30:00.000000Z"
    }
  }
}
```

**💾 Stockez le `session_token` de manière sécurisée** (Keychain iOS / EncryptedSharedPreferences Android)

#### Réponses d'erreur

**❌ PIN incorrect (401)**
```json
{
  "status": "error",
  "message": "Code PIN incorrect",
  "data": {
    "remaining_attempts": 3
  }
}
```

**🔒 Compte verrouillé (429)**
```json
{
  "status": "error",
  "message": "Compte verrouillé suite à plusieurs tentatives échouées. Réessayez dans 5 minute(s).",
  "data": {
    "locked_until": "2025-12-09T10:35:00.000000Z",
    "remaining_seconds": 300
  }
}
```

**📵 Compte inactif (403)**
```json
{
  "status": "error",
  "message": "Compte désactivé. Contactez le 77141516."
}
```

**🔓 PIN non configuré (400)**
```json
{
  "status": "error",
  "message": "Aucun code PIN configuré. Veuillez vous connecter avec OTP."
}
```

**🔍 Utilisateur introuvable (404)**
```json
{
  "status": "error",
  "message": "Numéro de téléphone non trouvé"
}
```

---

### 2. Configurer le PIN (première fois)

**Endpoint:** `POST /api/mobile/set-pin`

**Authentication:** Session token requis

**Body:**
```json
{
  "session_token": "AbCdEf1234567890...",
  "pin": "1234",
  "pin_confirmation": "1234"
}
```

**Validation:**
- Les deux PINs doivent être identiques
- PIN doit être exactement 4 chiffres numériques
- Session doit être active
- Le PIN ne doit pas déjà exister

#### Réponse succès (200)

```json
{
  "status": "success",
  "message": "Code PIN configuré avec succès",
  "data": {
    "pin_set_at": "2025-12-09T10:30:00.000000Z"
  }
}
```

#### Réponses d'erreur

**❌ Session invalide (401)**
```json
{
  "status": "error",
  "message": "Session non valide"
}
```

**⚠️ PIN déjà configuré (400)**
```json
{
  "status": "error",
  "message": "Un code PIN est déjà configuré. Utilisez l'endpoint de modification de PIN."
}
```

**❌ Validation échouée (422)**
```json
{
  "message": "Le code PIN doit contenir exactement 4 chiffres",
  "errors": {
    "pin": ["Le code PIN doit contenir exactement 4 chiffres"],
    "pin_confirmation": ["Les codes PIN ne correspondent pas"]
  }
}
```

---

### 3. Modifier le PIN

**Endpoint:** `POST /api/mobile/change-pin`

**Authentication:** Session token requis

**Body:**
```json
{
  "session_token": "AbCdEf1234567890...",
  "old_pin": "1234",
  "new_pin": "5678",
  "new_pin_confirmation": "5678"
}
```

**Validation:**
- L'ancien PIN doit être correct
- Le nouveau PIN doit être différent de l'ancien
- Les nouveaux PINs doivent correspondre
- Chaque PIN doit être exactement 4 chiffres

#### Réponse succès (200)

```json
{
  "status": "success",
  "message": "Code PIN modifié avec succès",
  "data": {
    "pin_set_at": "2025-12-09T10:45:00.000000Z"
  }
}
```

#### Réponses d'erreur

**❌ Ancien PIN incorrect (401)**
```json
{
  "status": "error",
  "message": "L'ancien code PIN est incorrect"
}
```

---

### 4. Réinitialiser le PIN (récupération)

**Endpoint:** `POST /api/mobile/reset-pin`

**Authentication:** Nécessite un OTP valide (pas de session)

**Étapes:**
1. Envoyer OTP avec `POST /api/sms/otp/send`
2. Réinitialiser PIN avec le code OTP reçu

**Body:**
```json
{
  "phone_number": "77123456",
  "otp": "123456",
  "new_pin": "5678",
  "new_pin_confirmation": "5678"
}
```

#### Réponse succès (200)

```json
{
  "status": "success",
  "message": "Code PIN réinitialisé avec succès",
  "data": {
    "pin_set_at": "2025-12-09T11:00:00.000000Z"
  }
}
```

**✅ Avantages:** Cette méthode efface automatiquement le verrouillage du compte et reset le compteur de tentatives.

#### Réponses d'erreur

**❌ OTP invalide/expiré (401)**
```json
{
  "status": "error",
  "message": "Code OTP invalide ou expiré"
}
```

---

## Implémentation recommandée

### Flux UX recommandé

#### Écran de connexion

```
┌─────────────────────────────────┐
│  Logo de l'application          │
│                                 │
│  [Input: Numéro de téléphone]  │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Se connecter avec OTP   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Se connecter avec PIN   │   │
│  └─────────────────────────┘   │
│                                 │
│  Nouveau ? Créer un compte      │
└─────────────────────────────────┘
```

#### Écran saisie PIN

```
┌─────────────────────────────────┐
│          ← Retour               │
│                                 │
│  Entrez votre code PIN          │
│                                 │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐      │
│  │ • │ │ • │ │ • │ │ • │      │
│  └───┘ └───┘ └───┘ └───┘      │
│                                 │
│  [Clavier numérique]            │
│                                 │
│  PIN oublié ?                   │
└─────────────────────────────────┘
```

#### Écran verrouillage

```
┌─────────────────────────────────┐
│          🔒                      │
│                                 │
│  Compte verrouillé              │
│                                 │
│  Votre compte a été verrouillé  │
│  suite à plusieurs tentatives   │
│  échouées.                      │
│                                 │
│  Réessayez dans 4 min 32 sec    │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Réinitialiser le PIN    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Se connecter avec OTP   │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## Exemples de code

### Android (Kotlin + Retrofit)

#### 1. Modèles de données

```kotlin
// LoginPinRequest.kt
data class LoginPinRequest(
    @SerializedName("phone_number") val phoneNumber: String,
    @SerializedName("pin") val pin: String,
    @SerializedName("device_type") val deviceType: String = "android",
    @SerializedName("device_info") val deviceInfo: DeviceInfo
)

data class DeviceInfo(
    @SerializedName("device_id") val deviceId: String,
    @SerializedName("model") val model: String,
    @SerializedName("os_version") val osVersion: String,
    @SerializedName("app_version") val appVersion: String
)

// LoginPinResponse.kt
data class LoginPinResponse(
    val status: String,
    val message: String,
    val data: LoginData?
)

data class LoginData(
    @SerializedName("session_token") val sessionToken: String,
    @SerializedName("expires_at") val expiresAt: String,
    val user: User
)

data class User(
    val id: Int,
    @SerializedName("phone_number") val phoneNumber: String,
    val name: String?,
    val email: String?,
    @SerializedName("is_active") val isActive: Boolean,
    @SerializedName("has_pin") val hasPin: Boolean,
    @SerializedName("last_login_at") val lastLoginAt: String
)

// ErrorResponse.kt
data class ErrorResponse(
    val status: String,
    val message: String,
    val data: ErrorData?
)

data class ErrorData(
    @SerializedName("remaining_attempts") val remainingAttempts: Int? = null,
    @SerializedName("locked_until") val lockedUntil: String? = null,
    @SerializedName("remaining_seconds") val remainingSeconds: Int? = null
)
```

#### 2. Service API

```kotlin
// ApiService.kt
interface ApiService {
    @POST("mobile/login-pin")
    suspend fun loginWithPin(
        @Body request: LoginPinRequest
    ): Response<LoginPinResponse>

    @POST("mobile/set-pin")
    suspend fun setPin(
        @Body request: SetPinRequest
    ): Response<ApiResponse>

    @POST("mobile/change-pin")
    suspend fun changePin(
        @Body request: ChangePinRequest
    ): Response<ApiResponse>

    @POST("mobile/reset-pin")
    suspend fun resetPin(
        @Body request: ResetPinRequest
    ): Response<ApiResponse>
}

data class SetPinRequest(
    @SerializedName("session_token") val sessionToken: String,
    val pin: String,
    @SerializedName("pin_confirmation") val pinConfirmation: String
)

data class ChangePinRequest(
    @SerializedName("session_token") val sessionToken: String,
    @SerializedName("old_pin") val oldPin: String,
    @SerializedName("new_pin") val newPin: String,
    @SerializedName("new_pin_confirmation") val newPinConfirmation: String
)

data class ResetPinRequest(
    @SerializedName("phone_number") val phoneNumber: String,
    val otp: String,
    @SerializedName("new_pin") val newPin: String,
    @SerializedName("new_pin_confirmation") val newPinConfirmation: String
)
```

#### 3. Repository

```kotlin
// AuthRepository.kt
class AuthRepository(private val apiService: ApiService) {

    suspend fun loginWithPin(
        phoneNumber: String,
        pin: String
    ): Result<LoginData> {
        return try {
            val deviceInfo = DeviceInfo(
                deviceId = getDeviceId(),
                model = Build.MODEL,
                osVersion = Build.VERSION.RELEASE,
                appVersion = BuildConfig.VERSION_NAME
            )

            val request = LoginPinRequest(
                phoneNumber = phoneNumber,
                pin = pin,
                deviceType = "android",
                deviceInfo = deviceInfo
            )

            val response = apiService.loginWithPin(request)

            when {
                response.isSuccessful && response.body()?.status == "success" -> {
                    val data = response.body()?.data
                    if (data != null) {
                        Result.success(data)
                    } else {
                        Result.failure(Exception("Données de réponse nulles"))
                    }
                }
                response.code() == 401 -> {
                    val error = parseError(response.errorBody()?.string())
                    Result.failure(InvalidPinException(error?.data?.remainingAttempts))
                }
                response.code() == 429 -> {
                    val error = parseError(response.errorBody()?.string())
                    Result.failure(AccountLockedException(error?.data?.remainingSeconds))
                }
                else -> {
                    Result.failure(Exception(response.message()))
                }
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun getDeviceId(): String {
        // Récupérer un identifiant unique d'appareil
        return Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ANDROID_ID
        )
    }

    private fun parseError(json: String?): ErrorResponse? {
        return try {
            Gson().fromJson(json, ErrorResponse::class.java)
        } catch (e: Exception) {
            null
        }
    }
}

// Exceptions personnalisées
class InvalidPinException(val remainingAttempts: Int?) : Exception("PIN incorrect")
class AccountLockedException(val remainingSeconds: Int?) : Exception("Compte verrouillé")
```

#### 4. ViewModel

```kotlin
// LoginViewModel.kt
class LoginViewModel(
    private val repository: AuthRepository,
    private val sessionManager: SessionManager
) : ViewModel() {

    private val _loginState = MutableStateFlow<LoginState>(LoginState.Idle)
    val loginState: StateFlow<LoginState> = _loginState.asStateFlow()

    fun loginWithPin(phoneNumber: String, pin: String) {
        viewModelScope.launch {
            _loginState.value = LoginState.Loading

            val result = repository.loginWithPin(phoneNumber, pin)

            _loginState.value = when {
                result.isSuccess -> {
                    val data = result.getOrNull()!!
                    sessionManager.saveSession(data.sessionToken, data.user)
                    LoginState.Success(data.user)
                }
                result.exceptionOrNull() is InvalidPinException -> {
                    val exception = result.exceptionOrNull() as InvalidPinException
                    LoginState.Error.InvalidPin(exception.remainingAttempts)
                }
                result.exceptionOrNull() is AccountLockedException -> {
                    val exception = result.exceptionOrNull() as AccountLockedException
                    LoginState.Error.AccountLocked(exception.remainingSeconds)
                }
                else -> {
                    LoginState.Error.NetworkError(result.exceptionOrNull()?.message)
                }
            }
        }
    }
}

sealed class LoginState {
    object Idle : LoginState()
    object Loading : LoginState()
    data class Success(val user: User) : LoginState()

    sealed class Error : LoginState() {
        data class InvalidPin(val remainingAttempts: Int?) : Error()
        data class AccountLocked(val remainingSeconds: Int?) : Error()
        data class NetworkError(val message: String?) : Error()
    }
}
```

#### 5. UI (Compose)

```kotlin
// PinLoginScreen.kt
@Composable
fun PinLoginScreen(
    phoneNumber: String,
    viewModel: LoginViewModel = hiltViewModel(),
    onSuccess: () -> Unit,
    onForgotPin: () -> Unit
) {
    val loginState by viewModel.loginState.collectAsState()
    var pin by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Entrez votre code PIN",
            style = MaterialTheme.typography.h5,
            modifier = Modifier.padding(bottom = 32.dp)
        )

        // Affichage du PIN (4 ronds)
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(bottom = 32.dp)
        ) {
            repeat(4) { index ->
                Box(
                    modifier = Modifier
                        .size(50.dp)
                        .border(2.dp, Color.Gray, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    if (pin.length > index) {
                        Box(
                            modifier = Modifier
                                .size(12.dp)
                                .background(Color.Black, CircleShape)
                        )
                    }
                }
            }
        }

        // Clavier numérique
        NumericKeyboard(
            onNumberClick = { number ->
                if (pin.length < 4) {
                    pin += number
                    if (pin.length == 4) {
                        viewModel.loginWithPin(phoneNumber, pin)
                    }
                }
            },
            onDeleteClick = {
                if (pin.isNotEmpty()) {
                    pin = pin.dropLast(1)
                }
            }
        )

        // Gestion des états
        when (val state = loginState) {
            is LoginState.Loading -> {
                CircularProgressIndicator(modifier = Modifier.padding(16.dp))
            }
            is LoginState.Error.InvalidPin -> {
                pin = "" // Reset PIN
                Text(
                    text = "PIN incorrect. ${state.remainingAttempts ?: 0} tentative(s) restante(s)",
                    color = Color.Red,
                    modifier = Modifier.padding(16.dp)
                )
            }
            is LoginState.Error.AccountLocked -> {
                val minutes = (state.remainingSeconds ?: 0) / 60
                val seconds = (state.remainingSeconds ?: 0) % 60

                AlertDialog(
                    onDismissRequest = { },
                    title = { Text("Compte verrouillé") },
                    text = {
                        Text("Réessayez dans $minutes min $seconds sec")
                    },
                    confirmButton = {
                        Button(onClick = onForgotPin) {
                            Text("Réinitialiser le PIN")
                        }
                    }
                )
            }
            is LoginState.Success -> {
                LaunchedEffect(Unit) {
                    onSuccess()
                }
            }
            else -> {}
        }

        // Lien "PIN oublié"
        TextButton(
            onClick = onForgotPin,
            modifier = Modifier.padding(top = 16.dp)
        ) {
            Text("PIN oublié ?")
        }
    }
}

@Composable
fun NumericKeyboard(
    onNumberClick: (String) -> Unit,
    onDeleteClick: () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        for (row in 0..2) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                for (col in 1..3) {
                    val number = (row * 3 + col).toString()
                    Button(
                        onClick = { onNumberClick(number) },
                        modifier = Modifier.size(80.dp)
                    ) {
                        Text(number, fontSize = 24.sp)
                    }
                }
            }
        }

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Spacer(modifier = Modifier.size(80.dp))
            Button(
                onClick = { onNumberClick("0") },
                modifier = Modifier.size(80.dp)
            ) {
                Text("0", fontSize = 24.sp)
            }
            IconButton(
                onClick = onDeleteClick,
                modifier = Modifier.size(80.dp)
            ) {
                Icon(Icons.Default.ArrowBack, "Effacer")
            }
        }
    }
}
```

---

### iOS (Swift + Alamofire)

#### 1. Modèles de données

```swift
// LoginPinRequest.swift
struct LoginPinRequest: Codable {
    let phoneNumber: String
    let pin: String
    let deviceType: String
    let deviceInfo: DeviceInfo

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case pin
        case deviceType = "device_type"
        case deviceInfo = "device_info"
    }
}

struct DeviceInfo: Codable {
    let deviceId: String
    let model: String
    let osVersion: String
    let appVersion: String

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case model
        case osVersion = "os_version"
        case appVersion = "app_version"
    }
}

// LoginPinResponse.swift
struct LoginPinResponse: Codable {
    let status: String
    let message: String
    let data: LoginData?
}

struct LoginData: Codable {
    let sessionToken: String
    let expiresAt: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case expiresAt = "expires_at"
        case user
    }
}

struct User: Codable {
    let id: Int
    let phoneNumber: String
    let name: String?
    let email: String?
    let isActive: Bool
    let hasPin: Bool
    let lastLoginAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case phoneNumber = "phone_number"
        case name
        case email
        case isActive = "is_active"
        case hasPin = "has_pin"
        case lastLoginAt = "last_login_at"
    }
}

// ErrorResponse.swift
struct ErrorResponse: Codable {
    let status: String
    let message: String
    let data: ErrorData?
}

struct ErrorData: Codable {
    let remainingAttempts: Int?
    let lockedUntil: String?
    let remainingSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case remainingAttempts = "remaining_attempts"
        case lockedUntil = "locked_until"
        case remainingSeconds = "remaining_seconds"
    }
}
```

#### 2. Service API

```swift
// APIService.swift
import Alamofire

class APIService {
    static let shared = APIService()
    private let baseURL = "https://votre-domaine.com/api"

    private init() {}

    func loginWithPin(
        phoneNumber: String,
        pin: String,
        completion: @escaping (Result<LoginData, AuthError>) -> Void
    ) {
        let deviceInfo = DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "",
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        )

        let request = LoginPinRequest(
            phoneNumber: phoneNumber,
            pin: pin,
            deviceType: "ios",
            deviceInfo: deviceInfo
        )

        AF.request(
            "\(baseURL)/mobile/login-pin",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .responseDecodable(of: LoginPinResponse.self) { response in
            switch response.result {
            case .success(let loginResponse):
                if loginResponse.status == "success", let data = loginResponse.data {
                    completion(.success(data))
                } else {
                    completion(.failure(.unknownError))
                }

            case .failure:
                // Parser les erreurs spécifiques
                if let data = response.data,
                   let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {

                    if response.response?.statusCode == 401 {
                        completion(.failure(.invalidPin(remainingAttempts: errorResponse.data?.remainingAttempts)))
                    } else if response.response?.statusCode == 429 {
                        completion(.failure(.accountLocked(remainingSeconds: errorResponse.data?.remainingSeconds)))
                    } else {
                        completion(.failure(.networkError(errorResponse.message)))
                    }
                } else {
                    completion(.failure(.networkError("Erreur réseau")))
                }
            }
        }
    }

    func setPin(
        sessionToken: String,
        pin: String,
        pinConfirmation: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let parameters: [String: Any] = [
            "session_token": sessionToken,
            "pin": pin,
            "pin_confirmation": pinConfirmation
        ]

        AF.request(
            "\(baseURL)/mobile/set-pin",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        .validate()
        .response { response in
            if response.error == nil {
                completion(.success(()))
            } else {
                completion(.failure(response.error ?? AuthError.unknownError))
            }
        }
    }
}

// AuthError.swift
enum AuthError: Error {
    case invalidPin(remainingAttempts: Int?)
    case accountLocked(remainingSeconds: Int?)
    case networkError(String)
    case unknownError

    var localizedDescription: String {
        switch self {
        case .invalidPin(let remaining):
            if let attempts = remaining {
                return "PIN incorrect. \(attempts) tentative(s) restante(s)"
            }
            return "PIN incorrect"
        case .accountLocked(let seconds):
            if let secs = seconds {
                let minutes = secs / 60
                let remainingSecs = secs % 60
                return "Compte verrouillé. Réessayez dans \(minutes) min \(remainingSecs) sec"
            }
            return "Compte verrouillé"
        case .networkError(let message):
            return message
        case .unknownError:
            return "Une erreur est survenue"
        }
    }
}
```

#### 3. ViewModel

```swift
// LoginViewModel.swift
import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var loginState: LoginState = .idle
    @Published var pin: String = ""

    private var cancellables = Set<AnyCancellable>()

    enum LoginState {
        case idle
        case loading
        case success(User)
        case error(AuthError)
    }

    func loginWithPin(phoneNumber: String) {
        guard pin.count == 4 else { return }

        loginState = .loading

        APIService.shared.loginWithPin(phoneNumber: phoneNumber, pin: pin) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    SessionManager.shared.saveSession(
                        token: data.sessionToken,
                        user: data.user
                    )
                    self?.loginState = .success(data.user)

                case .failure(let error):
                    self?.pin = "" // Reset PIN
                    self?.loginState = .error(error)
                }
            }
        }
    }
}
```

#### 4. UI (SwiftUI)

```swift
// PinLoginView.swift
import SwiftUI

struct PinLoginView: View {
    let phoneNumber: String
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var showingLockedAlert = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Entrez votre code PIN")
                .font(.title)
                .padding(.top, 40)

            // Affichage du PIN (4 cercles)
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .fill(Color.black)
                                .frame(width: 12, height: 12)
                                .opacity(viewModel.pin.count > index ? 1 : 0)
                        )
                }
            }
            .padding(.bottom, 32)

            // Clavier numérique
            NumericKeypadView(
                pin: $viewModel.pin,
                maxLength: 4
            )
            .onChange(of: viewModel.pin) { newValue in
                if newValue.count == 4 {
                    viewModel.loginWithPin(phoneNumber: phoneNumber)
                }
            }

            Spacer()

            // Lien "PIN oublié"
            Button("PIN oublié ?") {
                // Navigation vers reset PIN
            }
            .padding(.bottom, 20)
        }
        .padding()
        .overlay {
            if case .loading = viewModel.loginState {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .onChange(of: viewModel.loginState) { state in
            handleLoginState(state)
        }
        .alert("Compte verrouillé", isPresented: $showingLockedAlert) {
            Button("Réinitialiser le PIN") {
                // Navigation vers reset PIN
            }
            Button("OK", role: .cancel) {}
        } message: {
            if case .error(let error) = viewModel.loginState {
                Text(error.localizedDescription)
            }
        }
    }

    private func handleLoginState(_ state: LoginViewModel.LoginState) {
        switch state {
        case .success:
            dismiss()
        case .error(let error):
            if case .accountLocked = error {
                showingLockedAlert = true
            }
        default:
            break
        }
    }
}

struct NumericKeypadView: View {
    @Binding var pin: String
    let maxLength: Int

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3) { row in
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { col in
                        let number = row * 3 + col
                        Button(action: {
                            if pin.count < maxLength {
                                pin += "\(number)"
                            }
                        }) {
                            Text("\(number)")
                                .font(.title)
                                .frame(width: 70, height: 70)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Color.clear
                    .frame(width: 70, height: 70)

                Button(action: {
                    if pin.count < maxLength {
                        pin += "0"
                    }
                }) {
                    Text("0")
                        .font(.title)
                        .frame(width: 70, height: 70)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }

                Button(action: {
                    if !pin.isEmpty {
                        pin.removeLast()
                    }
                }) {
                    Image(systemName: "delete.left")
                        .font(.title)
                        .frame(width: 70, height: 70)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }
}
```

---

## Sécurité et bonnes pratiques

### ✅ À FAIRE

1. **Stockage sécurisé du session_token**
   - iOS : Keychain
   - Android : EncryptedSharedPreferences
   - **JAMAIS** dans SharedPreferences/UserDefaults non chiffrés

2. **Validation du PIN côté client**
   ```kotlin
   fun isValidPin(pin: String): Boolean {
       return pin.length == 4 && pin.all { it.isDigit() }
   }
   ```

3. **Timer de verrouillage**
   - Afficher un compte à rebours quand le compte est verrouillé
   - Désactiver le bouton de connexion pendant le verrouillage

4. **Gestion du taux de rafraîchissement**
   - Implémenter un retry avec exponential backoff si rate limited

5. **UX des tentatives restantes**
   - Afficher clairement les tentatives restantes
   - Alerter visuellement à partir de 2 tentatives restantes

6. **Obfuscation du PIN**
   - Utiliser des cercles pleins (•) pour afficher le PIN
   - Ne jamais logger le PIN en clair

### ❌ À NE PAS FAIRE

1. **Ne JAMAIS stocker le PIN en clair**
   - Le PIN est seulement envoyé à l'API
   - L'API le hash avec bcrypt

2. **Ne pas permettre de PIN faibles**
   - Éviter 0000, 1234, 1111, etc.
   - Avertir l'utilisateur lors de la configuration

3. **Ne pas bypass le rate limiting**
   - Respecter les limites de l'API
   - Afficher un message approprié si rate limited

4. **Ne pas stocker les credentials de debugging**
   - Supprimer tout PIN hardcodé avant la production

---

## Gestion des erreurs

### Matrice de codes HTTP

| Code | Signification | Action recommandée |
|------|---------------|-------------------|
| 200 | Succès | Procéder à la navigation |
| 400 | Requête invalide | Afficher le message d'erreur |
| 401 | PIN incorrect | Afficher tentatives restantes |
| 403 | Compte désactivé | Rediriger vers support |
| 404 | Utilisateur introuvable | Proposer création de compte |
| 422 | Validation échouée | Afficher erreurs de champ |
| 429 | Rate limit / Verrouillé | Afficher timer de verrouillage |
| 500 | Erreur serveur | Réessayer + message générique |

---

## Tests recommandés

### Scénarios de test

1. **Connexion réussie**
   - PIN correct → session créée

2. **PIN incorrect**
   - 1 tentative échouée → message + 4 restantes
   - 2 tentatives échouées → message + 3 restantes
   - ...
   - 5 tentatives échouées → verrouillage 5 minutes

3. **Verrouillage**
   - Compte verrouillé → impossible de se connecter
   - Timer expiré → connexion à nouveau possible

4. **Configuration PIN**
   - Après OTP → PIN configuré avec succès
   - PIN déjà existant → erreur appropriée
   - Confirmation incorrecte → erreur de validation

5. **Modification PIN**
   - Ancien PIN correct → nouveau PIN accepté
   - Ancien PIN incorrect → erreur
   - Nouveau PIN identique à l'ancien → erreur

6. **Réinitialisation PIN**
   - OTP valide → PIN réinitialisé
   - OTP invalide → erreur
   - Verrouillage effacé après reset

---

## FAQ

### Q: Le PIN remplace-t-il l'OTP ?
**R:** Non, le PIN est une **alternative** à l'OTP. Les utilisateurs peuvent choisir leur méthode préférée.

### Q: Que se passe-t-il si l'utilisateur oublie son PIN ?
**R:** Il peut utiliser le flow de réinitialisation avec OTP (`/api/mobile/reset-pin`).

### Q: Le verrouillage est-il par appareil ou par compte ?
**R:** Par compte. Si un compte est verrouillé, il l'est sur tous les appareils.

### Q: Le session_token expire-t-il ?
**R:** Oui, après 30 jours. L'utilisateur devra se reconnecter.

### Q: Peut-on avoir plusieurs sessions actives ?
**R:** Oui, chaque connexion crée une nouvelle session. L'utilisateur peut être connecté sur plusieurs appareils.

### Q: Comment déconnecter l'utilisateur ?
**R:** Appelez `POST /api/mobile/logout` avec le `session_token`.

### Q: Faut-il vérifier le numéro de téléphone avant d'autoriser la création de PIN ?
**R:** Non, la vérification OTP initiale confirme le numéro. Le PIN est configuré après une session OTP valide.

### Q: Le PIN peut-il être alphanumérique ?
**R:** Non, actuellement seuls les PINs numériques à 4 chiffres sont acceptés.

---

## Support

Pour toute question ou problème :
- 📞 Support technique : **77141516**
- 📧 Email : support@votre-domaine.com
- 📚 Documentation API complète : https://votre-domaine.com/api/docs

---

**Version du document:** 1.0.0
**Dernière mise à jour:** 2025-12-09
**Auteur:** Équipe Backend dtapi
