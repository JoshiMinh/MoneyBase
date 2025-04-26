plugins {
    // Android application & Kotlin support
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)

    // Jetpack Compose
    alias(libs.plugins.kotlin.compose)

    // Firebase & Google services
    id("com.google.gms.google-services")

    // Kotlin annotation processing
    id("kotlin-kapt")
}

@Suppress("UnstableApiUsage")
android {
    namespace           = "com.thebase.moneybase"
    compileSdk          = 35

    defaultConfig {
        applicationId        = "com.thebase.moneybase"
        minSdk               = 26
        targetSdk            = 35
        versionCode          = 1
        versionName          = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Use support library for vector drawables on older devices
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.3"
    }

    packaging.resources {
        // Exclude duplicate licence files from dependencies
        excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

dependencies {
    // --- AndroidX Core & Lifecycle ---
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    // --- AndroidX WorkManager ---
    implementation(libs.androidx.work.runtime.ktx)

    // --- Jetpack Compose BOM & UI modules ---
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)

    // --- Material Design 3 & Icons ---
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.extended)

    // --- Navigation ---
    implementation(libs.androidx.navigation.compose)

    // --- Kotlin Coroutines ---
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.coroutines.play.services)

    // --- Firebase (BOM, Analytics, Firestore, Auth) ---
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.analytics)
    implementation(libs.firebase.firestore.ktx)
    implementation(libs.firebase.auth.ktx)

    // --- Google Sign-In & Credentials API ---
    implementation(libs.androidx.credentials)
    implementation(libs.androidx.credentials.play.services.auth)
    implementation(libs.googleid)

    // --- Networking (Retrofit + Gson converter) ---
    implementation(libs.retrofit)
    implementation(libs.converter.gson)

    // --- Testing ---
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)

    // Use Compose BOM for androidTest as well
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.ui.test.junit4)

    // --- Debug-only tools ---
    debugImplementation(libs.androidx.ui.tooling)
    debugImplementation(libs.androidx.ui.test.manifest)
}