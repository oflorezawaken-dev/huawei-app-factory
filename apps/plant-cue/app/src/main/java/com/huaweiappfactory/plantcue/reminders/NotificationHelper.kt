package com.huaweiappfactory.plantcue.reminders

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.huaweiappfactory.plantcue.MainActivity
import com.huaweiappfactory.plantcue.R
import com.huaweiappfactory.plantcue.data.repository.DueItem

object NotificationHelper {

    const val CHANNEL_ID = "care_reminders"
    const val NOTIFICATION_ID = 1001
    const val EXTRA_FROM_NOTIFICATION = "from_notification"

    fun ensureChannel(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.notif_channel_name),
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply { description = context.getString(R.string.notif_channel_desc) }
            )
        }
    }

    fun canPost(context: Context): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    fun showDailySummary(context: Context, due: List<DueItem>) {
        if (due.isEmpty() || !canPost(context)) return
        ensureChannel(context)

        val plantNames = due.map { it.plant.name }.distinct()
        val title = context.resources.getQuantityString(R.plurals.notif_title_plants_need_care, plantNames.size, plantNames.size)
        val body = plantNames.take(4).joinToString(", ") + if (plantNames.size > 4) " +${plantNames.size - 4}" else ""

        val open = PendingIntent.getActivity(
            context, 0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(EXTRA_FROM_NOTIFICATION, true)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val doneAll = PendingIntent.getBroadcast(
            context, 1, Intent(context, CareActionReceiver::class.java).setAction(CareActionReceiver.ACTION_DONE_ALL),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val snoozeAll = PendingIntent.getBroadcast(
            context, 2, Intent(context, CareActionReceiver::class.java).setAction(CareActionReceiver.ACTION_SNOOZE_ALL),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_leaf)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .addAction(0, context.getString(R.string.notif_action_done_all), doneAll)
            .addAction(0, context.getString(R.string.notif_action_snooze), snoozeAll)
            .build()

        runCatching { NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification) }
    }

    fun cancel(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }
}
