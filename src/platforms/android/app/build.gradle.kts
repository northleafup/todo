plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.todo_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 优化的小米澎湃OS 3适配
        applicationId = "com.beautiful_todo.app"
        minSdk = 24  // Android 7.0 (澎湃OS 3基于Android 13)
        targetSdk = 34  // 支持Android 14和澎湃OS 3
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 澎化配置
        resConfig("zh", "zh-rCN", "zh-rTW", "zh-rHK", "en")

        // 支持的CPU架构 (小米14主要使用arm64)
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
        }

        // 权限配置
        vectorDrawables.useSupportLibrary = true

        // 小米澎湃OS 3特殊配置
        // 启用edge-to-edge和全面屏支持
        manifestPlaceholders += mapOf(
            "android.permission.WRITE_EXTERNAL_STORAGE" to "\${false}",
            "android.permission.READ_EXTERNAL_STORAGE" to "\${false}",
            "android.permission.USE_BIOMETRIC" to "\${false}",
        )
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
