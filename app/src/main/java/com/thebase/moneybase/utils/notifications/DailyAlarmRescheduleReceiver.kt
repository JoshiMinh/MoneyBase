package com.thebase.moneybase.utils.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class DailyAlarmRescheduleReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "DailyRescheduleReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received event to reschedule daily notification")
        runCatching {
            NotificationHelper(context).apply {
                if (isNotificationEnabled()) {
                    Log.d(TAG, "Rescheduling daily notification")
                    scheduleNotification()
                } else {
                    Log.d(TAG, "Notifications disabled, not rescheduling")
                }
            }
        }.onFailure {
            Log.e(TAG, "Error rescheduling notification", it)
        }
    }
}