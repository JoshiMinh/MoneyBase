package com.thebase.moneybase.utils.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NotificationReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received broadcast event: ${intent.action}")
        runCatching {
            NotificationHelper(context).sendReminderNotification()
        }.onSuccess {
            Log.d(TAG, "Notification sent successfully")
        }.onFailure {
            Log.e(TAG, "Error showing notification", it)
        }
    }
}