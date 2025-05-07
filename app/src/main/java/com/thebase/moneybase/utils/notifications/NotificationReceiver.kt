package com.thebase.moneybase.utils.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver để nhận sự kiện từ AlarmManager và hiển thị thông báo
 */
class NotificationReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "NotificationReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received broadcast event: ${intent.action}")
        try {
            val notificationHelper = NotificationHelper(context)
            notificationHelper.sendReminderNotification()
            Log.d(TAG, "Notification sent successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing notification", e)
        }
    }
} 