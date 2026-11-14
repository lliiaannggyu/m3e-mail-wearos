package com.workbuddy.m3e_mail

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/// 在原生侧处理应用内更新的安装环节：
/// - canInstall / requestInstallPermission：Android 8+ 的「未知来源应用」权限
/// - installApk：通过 FileProvider 拉起系统安装器
/// - appVersion / cacheDir：供 Dart 侧读取
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "m3e_mail/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstall" -> {
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                packageManager.canRequestPackageInstalls()
                            } else true
                        )
                    }
                    "requestInstallPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            )
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    "installApk" -> {
                        try {
                            val path = call.argument<String>("path") ?: ""
                            val file = File(path)
                            if (!file.exists()) throw IllegalStateException("APK 不存在: $path")
                            val uri = FileProvider.getUriForFile(
                                this, "$packageName.fileprovider", file
                            )
                            val intent = Intent(Intent.ACTION_VIEW)
                                .setDataAndType(uri, "application/vnd.android.package-archive")
                                .addFlags(
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_ACTIVITY_NEW_TASK
                                )
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("INSTALL_FAIL", e.message, null)
                        }
                    }
                    "appVersion" -> {
                        try {
                            result.success(
                                packageManager.getPackageInfo(packageName, 0).versionName
                            )
                        } catch (e: Exception) {
                            result.error("VERSION_FAIL", e.message, null)
                        }
                    }
                    "cacheDir" -> result.success(cacheDir.absolutePath)
                    else -> result.notImplemented()
                }
            }
    }
}
