plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.workbuddy.m3e_mail"
    compileSdk = flutter.compileSdkVersion
    // 纯 Dart 项目无需 NDK，省去 600MB+ 的 NDK 下载
    // ndkVersion = flutter.ndkVersion
    buildToolsVersion = "34.0.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.workbuddy.m3e_mail"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 应用最低支持 Android 7.1（API 25），覆盖 Wear OS 2.0 及以上
        minSdk = 25
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 压缩打包 so 库：进一步缩小 APK 下载体积
    // 代价：安装后原生库需解压，安装占用略增（约 12MB）；运行性能无差异
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            // R8 压缩（shrink）+ 混淆（obfuscate）+ 资源收缩
            isMinifyEnabled = true
            isShrinkResources = true
            // Flutter Gradle 插件会在开启 minify 时自动追加：
            //   - proguard-android-optimize.txt
            //   - Flutter 自带的 flutter_proguard_rules.pro
            //   - 本目录下的 proguard-rules.pro
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // TODO: 换成正式签名配置；演示包先用 debug 签名
            signingConfig = signingConfigs.getByName("debug")
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
    // 应用内更新：FileProvider 把缓存目录里的 APK 暴露给系统安装器
    implementation("androidx.core:core-ktx:1.13.1")
}
