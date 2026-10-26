package com.pmorales.michi.link

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val criticalChannel = NotificationChannel(
                "michi_critical_channel",
                "Alertas Críticas de Collares",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificaciones de geocerca y batería crítica"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val warningChannel = NotificationChannel(
                "michi_warning_channel",
                "Advertencias de Collares",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Advertencias de batería baja, señal débil y pérdida de GPS"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 200, 250)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val infoChannel = NotificationChannel(
                "michi_info_channel",
                "Información de Collares",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notificaciones informativas de estado y reconexión"
                enableVibration(true)
                setShowBadge(true)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(criticalChannel)
            notificationManager.createNotificationChannel(warningChannel)
            notificationManager.createNotificationChannel(infoChannel)
        }
    }
}
