package com.huaweiappfactory.habitcue

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.huaweiappfactory.habitcue.reminders.NotificationHelper
import com.huaweiappfactory.habitcue.ui.HabitCueApp

class MainActivity : ComponentActivity() {

    /** A session that started from the reminder notification never shows an interstitial. */
    var launchedFromNotification: Boolean = false
        private set

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchedFromNotification = intent?.getBooleanExtra(NotificationHelper.EXTRA_FROM_NOTIFICATION, false) == true
        enableEdgeToEdge()
        setContent {
            HabitCueApp(launchedFromNotification = launchedFromNotification)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(NotificationHelper.EXTRA_FROM_NOTIFICATION, false)) {
            launchedFromNotification = true
        }
    }
}
