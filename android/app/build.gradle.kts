plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
namespace = "com.lexivo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true
}

buildFeatures {
    resValues = true
}

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.lexivo.app"
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
        debug {
            applicationIdSuffix = ".debug"
        }
    }

    flavorDimensions += "account"
    productFlavors {
        create("original") {
            dimension = "account"
            resValue("string", "app_name", "Lexivo")
        }
        create("clone2") {
            dimension = "account"
            applicationIdSuffix = ".clone2"
            resValue("string", "app_name", "Lexivo C2")
        }
        create("clone3") {
            dimension = "account"
            applicationIdSuffix = ".clone3"
            resValue("string", "app_name", "Lexivo C3")
        }
        create("clone4") {
            dimension = "account"
            applicationIdSuffix = ".clone4"
            resValue("string", "app_name", "Lexivo C4")
        }
        create("clone5") {
            dimension = "account"
            applicationIdSuffix = ".clone5"
            resValue("string", "app_name", "Lexivo C5")
        }
        create("clone6") {
            dimension = "account"
            applicationIdSuffix = ".clone6"
            resValue("string", "app_name", "Lexivo C6")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.appcompat:appcompat:1.7.0")
}