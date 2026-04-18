plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // FlutterFire
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mening.hamshiram.mening_hamshiram"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true     // ← This fixes flutter_local_notifications error
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.mening.hamshiram.mening_hamshiram"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true                    // Recommended
    }

    signingConfigs {
        create("release") {
            // Set these via environment variables or key.properties for CI/CD:
            // KEYSTORE_PATH, KEY_ALIAS, KEY_PASSWORD, STORE_PASSWORD
            val keystorePath = System.getenv("KEYSTORE_PATH") ?: project.findProperty("keystorePath") as String?
            val keyAlias = System.getenv("KEY_ALIAS") ?: project.findProperty("keyAlias") as String?
            val keyPassword = System.getenv("KEY_PASSWORD") ?: project.findProperty("keyPassword") as String?
            val storePassword = System.getenv("STORE_PASSWORD") ?: project.findProperty("storePassword") as String?
            if (keystorePath != null) {
                storeFile = file(keystorePath)
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
                this.storePassword = storePassword
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            signingConfig = if (releaseConfig.storeFile != null) releaseConfig
                           else signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.yandex.android:maps.mobile:4.22.0-lite")
}

flutter {
    source = "../.."
}