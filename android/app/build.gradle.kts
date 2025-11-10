plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.event.marketplace.customer"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // CHANGED FROM VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_17  // CHANGED FROM VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "17"  // CHANGED FROM "1.8"
    }

    defaultConfig {
        applicationId = "com.event.marketplace.customer"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    buildFeatures {
        dataBinding = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")

    // Paymob SDK
    implementation("com.paymob.sdk:Paymob-SDK:1.6.11")
}

apply(plugin = "com.google.gms.google-services")
