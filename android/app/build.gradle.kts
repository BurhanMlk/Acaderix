import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = if (file("key.properties").exists()) {
    file("key.properties")
} else {
    rootProject.file("key.properties")
}
if (keystorePropertiesFile.exists()) {
    val signingProperties = keystorePropertiesFile.readLines().joinToString(System.lineSeparator()) { line ->
        val storeFileProperty = Regex("""^(\s*storeFile\s*[=:]\s*)(.*)$""").matchEntire(line)
        if (storeFileProperty == null) {
            line
        } else {
            storeFileProperty.groupValues[1] + storeFileProperty.groupValues[2].replace('\\', '/')
        }
    }
    keystoreProperties.load(signingProperties.reader())
}

val requiredSigningProperties = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val releaseStoreFilePath = keystoreProperties.getProperty("storeFile")
val releaseStoreFile = releaseStoreFilePath?.let { path ->
    val inRoot = rootProject.file(path)
    if (inRoot.exists()) inRoot else file(path)
}

android {
    namespace = "com.acadrix.academy_management"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.acadrix.academy_management"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = releaseStoreFile
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseTasksRequested = allTasks.any {
        it.project == project && it.name.contains("release", ignoreCase = true)
    }
    if (releaseTasksRequested) {
        require(keystorePropertiesFile.exists()) {
            "Missing android/app/key.properties"
        }
        require(
            requiredSigningProperties.all {
                keystoreProperties.getProperty(it)?.isNotBlank() == true
            }
        ) {
            "Missing or empty release signing properties"
        }
        require(releaseStoreFile?.exists() == true) {
            "Release keystore does not exist: ${releaseStoreFile ?: releaseStoreFilePath}"
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
