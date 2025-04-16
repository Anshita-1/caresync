plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    // Import the Firebase BoM.
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Add other dependencies as needed.
}

android {
    namespace = "com.example.caresync"
    compileSdk = 35
    ndkVersion = "27.0.12077973" // or use flutter.ndkVersion if defined in your project

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // Force all Kotlin dependencies to use version "1.8.10"
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("1.8.10")
            }
        }
    }

    defaultConfig {
        applicationId = "com.example.caresync"
        minSdk = 23
        targetSdk = 33
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing config for release build. (Currently using the debug signingConfig)
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
