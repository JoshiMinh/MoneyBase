package com.thebase.moneybase.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver để hỗ trợ đặt lịch thông báo hàng ngày trên Android mới
 * 
 * Android 6.0+ (Marshmallow) không cho phép setRepeating hoạt động chính xác, thay vào đó
 * ta phải sử dụng setExactAndAllowWhileIdle và lên lịch lại hàng ngày
 */
class DailyAlarmRescheduleReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "DailyRescheduleReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received event to reschedule daily notification")
        try {
            val notificationHelper = NotificationHelper(context)
            if (notificationHelper.isNotificationEnabled()) {
                Log.d(TAG, "Rescheduling daily notification")
                notificationHelper.scheduleNotification()
            } else {
                Log.d(TAG, "Notifications disabled, not rescheduling")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error rescheduling notification", e)
        }
    }
} 