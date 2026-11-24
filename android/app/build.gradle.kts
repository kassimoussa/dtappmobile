import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing config from key.properties (kept out of source control).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.djiboutitelecom.dtappmobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.djiboutitelecom.dtappmobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Keystore debug PARTAGÉ (commité, mot de passe standard "android").
        // Toutes les machines produisent ainsi le même SHA-1 debug → un seul
        // SHA-1 à enregistrer sur la clé Google Maps, valable pour tous les devs.
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        // Configured only when key.properties exists, so checkouts without the
        // keystore (CI, fresh clones) still build without failing.
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sign with the upload keystore when key.properties is present;
            // otherwise fall back to debug keys so `flutter run --release` works.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

// La clé debug est commitée dans le dépôt : n'importe qui peut signer avec. Un
// bundle de publication (bundleRelease, envoyé à Google Play) ne doit donc jamais
// en sortir, et Play le refuserait de toute façon. `flutter run --release` et
// `flutter build apk --release` gardent le repli sur la clé debug pour les essais
// locaux, avec un avertissement : cet APK n'est pas à distribuer.
gradle.taskGraph.whenReady {
    if (!keystorePropertiesFile.exists()) {
        if (hasTask(":app:bundleRelease")) {
            throw GradleException(
                "android/key.properties est introuvable : un bundle de publication " +
                    "ne peut pas être signé avec la clé debug. Voir ANDROID_PLAY_STORE_GUIDE.md."
            )
        }
        if (hasTask(":app:assembleRelease")) {
            logger.warn(
                "ATTENTION : android/key.properties est introuvable, l'APK release est " +
                    "signé avec la clé debug (publique). Ne pas le distribuer."
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
