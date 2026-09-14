package com.dobino.feple

import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

private const val SETTINGS_CHANNEL = "com.dobino.feple/settings"

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openNotificationChannelSettings") {
                    openNotificationChannelSettings(call.argument("channelId"))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    // 알림 채널 설정 화면까지 정확히 이동시켜, 사용자가 앱 알림 설정 안에서
    // 채널을 직접 찾아 들어갈 필요가 없게 한다. 채널이 아직 시스템에
    // 등록되지 않았으면(FCM 초기화 실패 등) 일부 OEM에서 빈 화면이 뜨므로
    // 채널 존재 여부를 먼저 확인하고, 없으면 앱 알림 설정으로 대체한다.
    private fun openNotificationChannelSettings(channelId: String?) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            && channelId != null && channelExists(channelId)
        ) {
            Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                .putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            appDetailsSettingsIntent()
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            startActivity(appDetailsSettingsIntent())
        }
    }

    private fun channelExists(channelId: String): Boolean {
        val manager = getSystemService(NotificationManager::class.java)
        return manager?.getNotificationChannel(channelId) != null
    }

    private fun appDetailsSettingsIntent(): Intent =
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", packageName, null))
}
