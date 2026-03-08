plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nearbygames.chess"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.nearbygames.chess"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // IMPORTANT: Before releasing to the Play Store, create a release keystore and
        // configure it here (or via environment variables / key.properties).
        // See: https://docs.flutter.dev/deployment/android#signing-the-app
        //
        // Example using a key.properties file:
        // create("release") {
        //     keyAlias = keystoreProperties["keyAlias"] as String
        //     keyPassword = keystoreProperties["keyPassword"] as String
        //     storeFile = file(keystoreProperties["storeFile"] as String)
        //     storePassword = keystoreProperties["storePassword"] as String
        // }
    }

    buildTypes {
        debug {
            isShrinkResources = false
            isMinifyEnabled = false
        }
        release {
            // ⚠️ Replace with your release signingConfig before submitting to the Play Store.
            // signingConfig = signingConfigs.getByName("release")
            signingConfig = signingConfigs.getByName("debug")
            isShrinkResources = false
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}
