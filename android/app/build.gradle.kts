plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val flavorAppNames = mapOf(
    "original" to "Lexivo",
    "clone2" to "Lexivo C2",
    "clone3" to "Lexivo C3",
    "clone4" to "Lexivo C4",
    "clone5" to "Lexivo C5",
    "clone6" to "Lexivo C6",
)

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
            resValue("string", "app_name", flavorAppNames.getValue("original"))
        }
        create("clone2") {
            dimension = "account"
            applicationIdSuffix = ".clone2"
            resValue("string", "app_name", flavorAppNames.getValue("clone2"))
        }
        create("clone3") {
            dimension = "account"
            applicationIdSuffix = ".clone3"
            resValue("string", "app_name", flavorAppNames.getValue("clone3"))
        }
        create("clone4") {
            dimension = "account"
            applicationIdSuffix = ".clone4"
            resValue("string", "app_name", flavorAppNames.getValue("clone4"))
        }
        create("clone5") {
            dimension = "account"
            applicationIdSuffix = ".clone5"
            resValue("string", "app_name", flavorAppNames.getValue("clone5"))
        }
        create("clone6") {
            dimension = "account"
            applicationIdSuffix = ".clone6"
            resValue("string", "app_name", flavorAppNames.getValue("clone6"))
        }
    }
}

// Debug builds share the release build's app_name via the flavor above, which
// makes the debug install indistinguishable from the release one on the home
// screen (e.g. two icons both named "Lexivo"). Override app_name for every
// debug variant here so it reads "<Flavor Name> (Dev)" instead.
androidComponents {
    onVariants(selector().withBuildType("debug")) { variant ->
        val baseName = flavorAppNames[variant.flavorName] ?: variant.flavorName
        variant.resValues.put(
            variant.makeResValueKey("string", "app_name"),
            com.android.build.api.variant.ResValue("$baseName (Dev)", null),
        )
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