plugins {
    // Applying Android application plugin
    alias(libs.plugins.android.application)

    // Applying Kotlin Android plugin
    alias(libs.plugins.kotlin.android)

    // Applying Kotlin Compose plugin
    alias(libs.plugins.kotlin.compose)

    // Google services plugin
    id("com.google.gms.google-services")

    // Kotlin KAPT plugin for annotation processing
    id("kotlin-kapt")
}

@Suppress("UnstableApiUsage")
android {
    namespace = "com.thebase.moneybase"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.thebase.moneybase"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // Enable support for vector drawables
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        release {
            // Disable code minification for release build
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        // Set Java compatibility to version 11
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Set JVM target for Kotlin
        jvmTarget = "11"
    }

    buildFeatures {
        // Enable Jetpack Compose
        compose = true
    }

    composeOptions {
        // Specify Compose compiler extension version
        kotlinCompilerExtensionVersion = "1.5.3"
    }

    packaging.resources {
        // Exclude specific resources from packaging
        excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

dependencies {
    // Core AndroidX and lifecycle dependencies
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    // WorkManager dependency
    implementation(libs.androidx.work.runtime.ktx)

    // Compose dependencies
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)

    // Material3 and icons
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.extended)

    // Image loading library
    implementation(libs.coil.compose)
    // Navigation component for Compose
    implementation(libs.androidx.navigation.compose)

    // Coroutines dependencies
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.coroutines.play.services)

    // Firebase dependencies
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.analytics)
    implementation(libs.firebase.firestore.ktx)
    implementation(libs.firebase.auth.ktx)
    implementation(libs.google.firebase.auth)
    implementation(libs.play.services.auth)

    // Credentials and authentication
    implementation(libs.androidx.credentials)
    implementation(libs.androidx.credentials.play.services.auth)
    implementation(libs.googleid)

    // Networking with Retrofit and Gson converter
    implementation(libs.retrofit)
    implementation(libs.converter.gson)
    
    // Cloudinary for image storage
    implementation("com.cloudinary:cloudinary-android:2.3.1")
    implementation("com.cloudinary:cloudinary-core:1.34.0")

    // Testing dependencies
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)

    // Compose testing dependencies
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.ui.test.junit4)

    // Debugging tools
    debugImplementation(libs.androidx.ui.tooling)
    debugImplementation(libs.androidx.ui.test.manifest)
}