// 1. DEFINICIÓN DE VERSIONES (Añade esto al principio)
def flutterVersionCode = project.findProperty('flutter.versionCode') ?: '1'
def flutterVersionName = project.findProperty('flutter.versionName') ?: '1.0'

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.login_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Actualizado a Java 17 para coincidir con tu Flutter 3.38
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.login_app"
        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion      
        
        // Ahora estas variables sí están definidas arriba
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}