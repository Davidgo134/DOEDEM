import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

val yandexApiKey: String = localProperties.getProperty("YANDEX_MAPKIT_API_KEY")
    ?: System.getenv("YANDEX_MAPKIT_API_KEY")
    ?: ""

android {
    namespace = "ru.marshrutka.marshrutka"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "ru.marshrutka.marshrutka"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        buildConfigField("String", "YANDEX_MAPKIT_API_KEY", "\"$yandexApiKey\"")
        manifestPlaceholders["YANDEX_MAPKIT_API_KEY"] = yandexApiKey
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.yandex.android:maps.mobile:4.4.0-lite")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
