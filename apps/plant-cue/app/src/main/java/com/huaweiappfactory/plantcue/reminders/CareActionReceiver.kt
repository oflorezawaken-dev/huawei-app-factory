package com.huaweiappfactory.plantcue.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.huaweiappfactory.plantcue.PlantCueApplication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** "Done all" / "Snooze" buttons on the daily notification. */
class CareActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_DONE_ALL = "com.huaweiappfactory.plantcue.ACTION_DONE_ALL"
        const val ACTION_SNOOZE_ALL = "com.huaweiappfactory.plantcue.ACTION_SNOOZE_ALL"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val repo = (context.applicationContext as PlantCueApplication).container.plantRepository
        val pending = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                when (action) {
                    ACTION_DONE_ALL -> repo.markAllDueDone()
                    ACTION_SNOOZE_ALL -> repo.snoozeAllDue()
                }
                NotificationHelper.cancel(context)
            } finally {
                pending.finish()
            }
        }
    }
}
