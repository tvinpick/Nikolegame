plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}
android {
    namespace = "com.nikolegame"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.nikolegame"
        minSdk = 26
        targetSdk = 35
        versionCode = 27
        versionName = "0.15.1"
    }

    // -Ppreview creates a side-by-side test installation, preserving the
    // player's previous install and local save data.
    buildTypes {
        getByName("debug") {
            // Explicit build-time test switch, not dependent on Context.packageName.
            buildConfigField("boolean", "FREE_SHOP_TESTING", "true")
            if(project.hasProperty("preview")) {
                applicationIdSuffix = ".preview"
                manifestPlaceholders["appLabel"] = "Домик Николь (тест)"
            } else {
                manifestPlaceholders["appLabel"] = "Домик Николь"
            }
        }
        getByName("release") {
            buildConfigField("boolean", "FREE_SHOP_TESTING", "false")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.09.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.13.0")
    testImplementation("junit:junit:4.13.2")
}
