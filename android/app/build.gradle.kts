import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = keystoreProperties.isNotEmpty()
val hasCompleteReleaseKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all { keystoreProperties.containsKey(it) }

android {
    namespace = "com.bilalcavus.woodenblock"
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
        applicationId = "com.bilalcavus.woodenblock"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 19
        versionName = "1.0.7"
    }

    signingConfigs {
        if (hasReleaseKeystore && hasCompleteReleaseKeys) {
            create("release") {
                val storeFilePath = keystoreProperties["storeFile"] as String?
                    ?: throw GradleException("Missing storeFile in key.properties")
                storeFile = rootProject.file(storeFilePath)
                storePassword = keystoreProperties["storePassword"] as String?
                    ?: throw GradleException("Missing storePassword in key.properties")
                keyAlias = keystoreProperties["keyAlias"] as String?
                    ?: throw GradleException("Missing keyAlias in key.properties")
                keyPassword = keystoreProperties["keyPassword"] as String?
                    ?: throw GradleException("Missing keyPassword in key.properties")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore && hasCompleteReleaseKeys) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                println("⚠️  key.properties missing or incomplete. Release build will use debug signing. Create android/key.properties for Play Store upload.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-games-v2:+")
}
