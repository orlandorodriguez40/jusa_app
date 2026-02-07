plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de Android y Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.login_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // 👇 Leer versionCode y versionName desde local.properties
    val flutterVersionCode = project.findProperty("flutter.versionCode")?.toString()?.toInt() ?: 1
    val flutterVersionName = project.findProperty("flutter.versionName")?.toString() ?: "1.0.0"

    defaultConfig {
        applicationId = "com.example.login_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // ⚠️ Ajusta esto con tu signingConfig real cuando uses tu keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
