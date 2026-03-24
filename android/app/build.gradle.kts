plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

task("generateGoogleServices") {
    val templateFile = file("google-services.template.json")
    val outputFile = file("google-services.json")
    val envFile = file("../../.env")

    inputs.file(templateFile)
    if (envFile.exists()) {
        inputs.file(envFile)
    }
    outputs.file(outputFile)

    doLast {
        if (!envFile.exists()) {
            println("WARNING: .env file not found at ${envFile.absolutePath}. Using template as is.")
            outputFile.writeText(templateFile.readText())
            return@doLast
        }

        val env = mutableMapOf<String, String>()
        envFile.forEachLine { line ->
            if (line.isNotBlank() && !line.trimStart().startsWith("#") && line.contains("=")) {
                val parts = line.split("=", limit = 2)
                if (parts.size == 2) {
                    env[parts[0].trim()] = parts[1].trim()
                }
            }
        }

        var content = templateFile.readText()
        env.forEach { (key, value) ->
            content = content.replace("\${$key}", value)
        }
        outputFile.writeText(content)
        println("Generated google-services.json from template.")
    }
}

tasks.matching { it.name.contains("GoogleServices") }.configureEach {
    dependsOn("generateGoogleServices")
}

android {
    namespace = "com.thebase.moneybase"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.thebase.moneybase"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
