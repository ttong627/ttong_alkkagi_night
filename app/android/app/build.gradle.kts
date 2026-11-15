plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 올리기용 서명(업로드 키). 값은 저장소에 두지 않고 환경 변수(GitHub Actions 비밀값)로만 받는다.
// 없으면 디버그 키로 서명한다(시험 설치용, 플레이 스토어에는 못 올림).
val uploadKeystore = System.getenv("ALKKAGI_KEYSTORE_PATH")
val hasUploadKey = !uploadKeystore.isNullOrBlank() && file(uploadKeystore).exists()

android {
    namespace = "TTong.alkkagi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "TTong.alkkagi.night"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(uploadKeystore!!)
                storePassword = System.getenv("ALKKAGI_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ALKKAGI_KEY_ALIAS")
                keyPassword = System.getenv("ALKKAGI_KEY_PASSWORD")
            }
        }
    }

    flavorDimensions += "channel"
    productFlavors {
        create("sideload") { dimension = "channel" }
        create("play") {
            dimension = "channel"
            applicationId = "ttong.alkkagi.night"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasUploadKey) "upload" else "debug")
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
