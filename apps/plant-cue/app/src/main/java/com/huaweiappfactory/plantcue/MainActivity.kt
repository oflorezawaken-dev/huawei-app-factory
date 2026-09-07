package com.huaweiappfactory.plantcue

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.huaweiappfactory.plantcue.reminders.NotificationHelper
import com.huaweiappfactory.plantcue.ui.PlantCueApp

class MainActivity : ComponentActivity() {

    /** A session that started from the reminder notification never shows an interstitial. */
    var launchedFromNotification: Boolean = false
        private set

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchedFromNotification = intent?.getBooleanExtra(NotificationHelper.EXTRA_FROM_NOTIFICATION, false) == true
        enableEdgeToEdge()
        setContent {
            PlantCueApp(launchedFromNotification = launchedFromNotification)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(NotificationHelper.EXTRA_FROM_NOTIFICATION, false)) {
            launchedFromNotification = true
        }
    }
}
