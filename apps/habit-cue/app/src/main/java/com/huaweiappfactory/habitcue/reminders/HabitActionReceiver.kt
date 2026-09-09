package com.huaweiappfactory.habitcue.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.huaweiappfactory.habitcue.HabitCueApplication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** "Done all" button on the daily reminder notification. */
class HabitActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_DONE_ALL = "com.huaweiappfactory.habitcue.ACTION_DONE_ALL"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_DONE_ALL) return
        val repo = (context.applicationContext as HabitCueApplication).container.habitRepository
        val pending = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                repo.markAllDueDone()
                NotificationHelper.cancel(context)
            } finally {
                pending.finish()
            }
        }
    }
}
