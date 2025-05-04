package com.thebase.moneybase.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver để khởi động lại thông báo sau khi thiết bị khởi động lại
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received intent: ${intent.action}")
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed, checking notification settings")
            try {
                val notificationHelper = NotificationHelper(context)
                if (notificationHelper.isNotificationEnabled()) {
                    Log.d(TAG, "Notifications enabled, rescheduling")
                    notificationHelper.scheduleNotification()
                } else {
                    Log.d(TAG, "Notifications disabled, not rescheduling")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error rescheduling notifications after boot", e)
            }
        }
    }
} 