plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.nikole.kidslauncher"
    compileSdk = 27

    defaultConfig {
        applicationId = "com.nikole.kidslauncher"
        minSdk = 26
        targetSdk = 27
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    lint {
        // targetSdk 27 намеренно: устройство на Android 8.1.
        disable += setOf("ExpiredTargetSdkVersion", "OldTargetApi")
    }
}

// Никаких сторонних библиотек: только Kotlin stdlib (подключается плагином автоматически).
