import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("io.sentry.android.gradle")
}

// key.properties dosyası varsa oku (lokal geliştirme)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.saydin.saydin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.saydin.saydin"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
                ?: System.getenv("KEY_ALIAS") ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String?
                ?: System.getenv("KEY_PASSWORD") ?: ""
            storeFile = (keystoreProperties["storeFile"] as String?
                ?: System.getenv("STORE_FILE"))?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
                ?: System.getenv("STORE_PASSWORD") ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

// Release R8 mapping UUID'sini artifact'e gömer ve yalnız gerekli CI
// credential'ları mevcutsa mapping'i Sentry'ye yükler. Plugin'in farklı bir
// Sentry Android SDK sürümü auto-install etmesi kapalıdır; runtime SDK
// sentry_flutter tarafından yönetilir. Kaynak kodu/telemetry upload edilmez.
sentry {
    includeProguardMapping.set(true)
    includeSourceContext.set(false)
    uploadNativeSymbols.set(false)
    includeDependenciesReport.set(false)
    telemetry.set(false)
    ignoredBuildTypes.set(setOf("debug", "profile"))
    autoInstallation {
        enabled.set(false)
    }

    val sentryAuthToken = System.getenv("SENTRY_AUTH_TOKEN")
    val sentryOrg = System.getenv("SENTRY_ORG")
    val sentryProject = System.getenv("SENTRY_PROJECT")
    autoUploadProguardMapping.set(
        !sentryAuthToken.isNullOrBlank() &&
            !sentryOrg.isNullOrBlank() &&
            !sentryProject.isNullOrBlank(),
    )
    sentryAuthToken?.takeIf { it.isNotBlank() }?.let(authToken::set)
    sentryOrg?.takeIf { it.isNotBlank() }?.let(org::set)
    sentryProject?.takeIf { it.isNotBlank() }?.let(projectName::set)
}
