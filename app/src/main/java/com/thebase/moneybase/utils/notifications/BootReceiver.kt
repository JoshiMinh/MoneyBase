package com.thebase.moneybase.utils.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received intent: ${intent.action}")
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed, checking notification settings")
            runCatching {
                NotificationHelper(context).apply {
                    if (isNotificationEnabled()) {
                        Log.d(TAG, "Notifications enabled, rescheduling")
                        scheduleNotification()
                    } else {
                        Log.d(TAG, "Notifications disabled, not rescheduling")
                    }
                }
            }.onFailure {
                Log.e(TAG, "Error rescheduling notifications after boot", it)
            }
        }
    }
}