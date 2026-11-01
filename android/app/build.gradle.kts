import java.net.URI
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// This file is local-only. CI/debug builds do not require release credentials.
val releasePropertiesFile = rootProject.file(
    providers.gradleProperty("localmate.signingProperties").orNull ?: "key.properties"
)
val releaseProperties = Properties().apply {
    if (releasePropertiesFile.isFile) {
        releasePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "vn.io.localmate.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "vn.io.localmate.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseProperties.getProperty("keyAlias")
            keyPassword = releaseProperties.getProperty("keyPassword")
            storeFile = releaseProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = releaseProperties.getProperty("storePassword")
            storeType = releaseProperties.getProperty("storeType", "PKCS12")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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

// A domain name, never an IP literal ([::1] keeps its brackets in URI.host) or a local name.
// A numeric last label also catches loopback shorthands such as 127.1 or 127.0.0.2.
fun isPublicDomain(host: String?): Boolean {
    val labels = host.orEmpty().lowercase().removeSuffix(".").split('.')
    return labels.size >= 2 && labels.none { it.isEmpty() } &&
        Regex("[a-z][a-z0-9-]*").matches(labels.last()) && labels.last() != "localhost"
}

// Fail before producing a distributable APK with missing signing or local/mock data.
// Values are intentionally omitted from diagnostics to avoid leaking credentials.
val validateLocalMateRelease = tasks.register("validateLocalMateRelease") {
    group = "verification"
    description = "Require private signing material and an HTTPS production API."
    doLast {
        check(releasePropertiesFile.isFile) {
            "Release signing is missing. Configure android/key.properties; see docs/ANDROID_RELEASE.md."
        }
        for (name in listOf("storeFile", "storePassword", "keyAlias", "keyPassword")) {
            check(!releaseProperties.getProperty(name).isNullOrBlank()) {
                "Release signing property '$name' is missing."
            }
        }
        check(file(releaseProperties.getProperty("storeFile")).isFile) {
            "The configured release keystore does not exist."
        }
        val defines = providers.gradleProperty("dart-defines").orNull.orEmpty()
            .split(',').filter { it.isNotBlank() }.associate { encoded ->
                val decoded = try {
                    String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
                } catch (_: IllegalArgumentException) {
                    error("Invalid encoded Dart defines.")
                }
                decoded.substringBefore('=') to decoded.substringAfter('=', "")
            }
        val appKeys = setOf("APP_ENV", "API_BASE_URL", "GOOGLE_SERVER_CLIENT_ID")
        check(defines.keys.all { it in appKeys || it.startsWith("FLUTTER_") || it == "DART_VERSION" }) {
            "Release allows only app config and Flutter build metadata; keep server credentials out of Dart defines."
        }
        check(defines["APP_ENV"] == "production") {
            "Release requires APP_ENV=production. Use config/dart_defines.production.local.json."
        }
        val api = runCatching { URI(defines["API_BASE_URL"].orEmpty()) }.getOrNull()
        check(api != null && api.scheme == "https" && isPublicDomain(api.host) &&
            api.userInfo == null && api.query == null && api.fragment == null &&
            api.path.orEmpty() in setOf("", "/")) {
            "Release requires the public HTTPS backend origin without /api, credentials or query parameters."
        }
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateLocalMateRelease)
}
