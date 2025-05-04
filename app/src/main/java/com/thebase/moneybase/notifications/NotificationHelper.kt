package com.thebase.moneybase.notifications

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import android.util.Log
import com.thebase.moneybase.MainActivity
import com.thebase.moneybase.R
import java.util.Calendar
import java.lang.Math

/**
 * Quản lý thông báo nhắc nhở ghi chép chi tiêu
 */
class NotificationHelper(private val context: Context) {

    companion object {
        const val TAG = "NotificationHelper"
        const val CHANNEL_ID = "moneybase_reminder_channel"
        const val NOTIFICATION_ID = 1001
        
        const val PREF_NAME = "notification_preferences"
        const val PREF_ENABLED = "notification_enabled"
        const val PREF_TIME_HOUR = "notification_hour" 
        const val PREF_TIME_MINUTE = "notification_minute"
        
        const val DEFAULT_HOUR = 20 // 8 PM
        const val DEFAULT_MINUTE = 0
        
        const val REQUEST_CODE = 100
    }

    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val preferences: SharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    
    /**
     * Tạo kênh thông báo (bắt buộc trên Android 8.0+)
     */
    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "Creating notification channel")
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Reminder to record expenses",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Reminder to record expenses daily"
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        } else {
            Log.d(TAG, "Notification channel not needed for this Android version")
        }
    }
    
    /**
     * Gửi thông báo nhắc nhở
     */
    fun sendReminderNotification() {
        Log.d(TAG, "Sending reminder notification")
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Reminder to record expenses")
            .setContentText("It's time to record your daily expenses!")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
        
        try {
            notificationManager.notify(NOTIFICATION_ID, builder.build())
            Log.d(TAG, "Notification sent successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending notification", e)
        }
    }
    
    /**
     * Kiểm tra thông báo ngay lập tức (dùng cho debug)
     */
    fun testNotification() {
        Log.d(TAG, "Sending reminder notification")
        sendReminderNotification()
    }
    
    /**
     * Kiểm tra xem thời gian nhắc nhở có sắp đến không (trong khoảng 2 phút tới)
     * Hữu ích để debug thông báo
     */
    fun isReminderTimeSoon(): Boolean {
        val now = Calendar.getInstance()
        val reminderTime = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, getNotificationHour())
            set(Calendar.MINUTE, getNotificationMinute())
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        
        // Nếu thời gian đã qua trong ngày, kiểm tra xem có phải là trong 2 phút vừa qua không
        val diff = Math.abs(now.timeInMillis - reminderTime.timeInMillis)
        val twoMinutesInMillis = 2 * 60 * 1000
        
        return diff <= twoMinutesInMillis
    }
    
    /**
     * Lên lịch thông báo nhắc nhở hàng ngày
     */
    fun scheduleNotification() {
        if (!isNotificationEnabled()) {
            Log.d(TAG, "Notifications disabled, not scheduling")
            cancelScheduledNotification()
            return
        }
        
        // Kiểm tra xem thông báo có bị tắt ở cấp hệ thống không
        if (!areNotificationsEnabled()) {
            Log.w(TAG, "Cannot schedule notification because notifications are disabled at system level")
            return
        }
        
        val intent = Intent(context, NotificationReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent, 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val now = System.currentTimeMillis()
        
        val calendar = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, getNotificationHour())
            set(Calendar.MINUTE, getNotificationMinute())
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            
            // Nếu thời gian đã qua, đặt cho ngày mai
            if (timeInMillis <= now) {
                add(Calendar.DAY_OF_YEAR, 1)
                Log.d(TAG, "Time already passed today, scheduling for tomorrow")
            } else {
                Log.d(TAG, "Scheduling for today")
            }
        }
        
        val scheduledTime = calendar.timeInMillis
        
        try {
            // Xử lý khác nhau cho từng phiên bản Android
            when {
                Build.VERSION.SDK_INT >= 34 -> { // Android 14+
                    if (hasExactAlarmPermissionForAndroid14()) {
                        Log.d(TAG, "Using setExactAndAllowWhileIdle for Android 14+")
                        // Sử dụng setExact cho Android 14+
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTime,
                            pendingIntent
                        )
                    } else {
                        Log.w(TAG, "Cannot use exact alarms on Android 14+, using inexact")
                        alarmManager.setInexactRepeating(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTime,
                            AlarmManager.INTERVAL_DAY,
                            pendingIntent
                        )
                    }
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> { // Android 12-13
                    if (alarmManager.canScheduleExactAlarms()) {
                        Log.d(TAG, "Using setExactAndAllowWhileIdle for Android 12-13")
                        // Sử dụng setExact cho Android 12-13
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTime,
                            pendingIntent
                        )
                    } else {
                        Log.w(TAG, "Cannot schedule exact alarms on Android 12-13, using inexact")
                        alarmManager.setInexactRepeating(
                            AlarmManager.RTC_WAKEUP,
                            scheduledTime,
                            AlarmManager.INTERVAL_DAY,
                            pendingIntent
                        )
                    }
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> { // Android 6.0-11
                    Log.d(TAG, "Using setExactAndAllowWhileIdle for Android 6-11")
                    // Sử dụng setExact cho Android 6-11
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        scheduledTime,
                        pendingIntent
                    )
                }
                else -> { // Android < 6.0
                    Log.d(TAG, "Using setRepeating for older Android versions")
                    alarmManager.setRepeating(
                        AlarmManager.RTC_WAKEUP,
                        scheduledTime,
                        AlarmManager.INTERVAL_DAY,
                        pendingIntent
                    )
                }
            }
            
            // Xử lý lặp lại hàng ngày cho Android M+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                scheduleNotificationReschedule(scheduledTime)
            }
            
            val notificationTime = java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss", java.util.Locale.getDefault())
                .format(java.util.Date(scheduledTime))
            Log.d(TAG, "Notification scheduled for $notificationTime")
            
            // Thêm bước kiểm tra xem đã đặt lịch thành công chưa
            val checkPendingIntent = PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent, 
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
            )
            Log.d(TAG, "Alarm exists: ${checkPendingIntent != null}")
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling notification", e)
        }
    }
    
    /**
     * Lên lịch cho việc lập lịch lại thông báo (giải pháp cho việc lập lịch hàng ngày trên Android mới)
     */
    private fun scheduleNotificationReschedule(triggerTimeMillis: Long) {
        val tomorrowIntent = PendingIntent.getBroadcast(
            context, 
            REQUEST_CODE + 1, 
            Intent(context, DailyAlarmRescheduleReceiver::class.java), 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        // Đặt alarm vào ngày mai để đặt lại thông báo hàng ngày
        val tomorrowCalendar = Calendar.getInstance().apply {
            timeInMillis = triggerTimeMillis
            add(Calendar.MINUTE, 1) // Thêm 1 phút sau khi thông báo được hiển thị
        }
        
        try {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                tomorrowCalendar.timeInMillis,
                tomorrowIntent
            )
            Log.d(TAG, "Scheduled notification reschedule for tomorrow")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule notification reschedule", e)
        }
    }
    
    /**
     * Hủy thông báo đã lên lịch
     */
    fun cancelScheduledNotification() {
        Log.d(TAG, "Cancelling scheduled notification")
        val intent = Intent(context, NotificationReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, REQUEST_CODE, intent, 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
        )
        
        pendingIntent?.let {
            try {
                alarmManager.cancel(it)
                it.cancel()
                Log.d(TAG, "Notification cancelled successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error cancelling notification", e)
            }
        } ?: run {
            Log.d(TAG, "No pending notification found to cancel")
        }
    }
    
    /**
     * Kiểm tra xem thông báo có được bật không
     */
    fun isNotificationEnabled(): Boolean {
        val isEnabled = preferences.getBoolean(PREF_ENABLED, false)
        Log.d(TAG, "Notifications enabled: $isEnabled")
        return isEnabled
    }
    
    /**
     * Bật/tắt thông báo
     * @return liệu thao tác có thành công không
     */
    fun setNotificationEnabled(enabled: Boolean): Boolean {
        Log.d(TAG, "Setting notification enabled: $enabled")
        
        // Nếu đang cố bật thông báo, kiểm tra xem thông báo có được cho phép ở cấp hệ thống không
        if (enabled) {
            val notificationsAllowed = areNotificationsEnabled()
            if (!notificationsAllowed) {
                Log.w(TAG, "Cannot enable notifications because they are disabled at system level")
                return false
            }
        }
        
        preferences.edit().putBoolean(PREF_ENABLED, enabled).apply()
        
        if (enabled) {
            scheduleNotification()
        } else {
            cancelScheduledNotification()
        }
        
        return true
    }
    
    /**
     * Lấy giờ thông báo
     */
    fun getNotificationHour(): Int {
        val hour = preferences.getInt(PREF_TIME_HOUR, DEFAULT_HOUR)
        Log.d(TAG, "Notification hour: $hour")
        return hour
    }
    
    /**
     * Lấy phút thông báo
     */
    fun getNotificationMinute(): Int {
        val minute = preferences.getInt(PREF_TIME_MINUTE, DEFAULT_MINUTE)
        Log.d(TAG, "Notification minute: $minute")
        return minute
    }
    
    /**
     * Đặt thời gian thông báo
     */
    fun setNotificationTime(hour: Int, minute: Int) {
        Log.d(TAG, "Setting notification time to $hour:$minute")
        preferences.edit()
            .putInt(PREF_TIME_HOUR, hour)
            .putInt(PREF_TIME_MINUTE, minute)
            .apply()
        
        if (isNotificationEnabled()) {
            scheduleNotification()
        }
    }
    
    /**
     * Kiểm tra các quyền cần thiết cho việc lập lịch thông báo
     */
    fun checkPermissions(): Map<String, Boolean> {
        val results = mutableMapOf<String, Boolean>()
        
        // Trên Android 13+, kiểm tra quyền POST_NOTIFICATIONS
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val notificationPermission = context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)
            results["POST_NOTIFICATIONS"] = notificationPermission == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            // Trên Android < 13, kiểm tra xem thông báo có bị tắt ở cấp hệ thống không
            val notificationEnabled = areNotificationsEnabled()
            results["NOTIFICATIONS_ENABLED"] = notificationEnabled
        }
        
        // Kiểm tra quyền lên lịch chính xác
        if (Build.VERSION.SDK_INT >= 34) { // Android 14+
            results["USE_EXACT_ALARM"] = hasExactAlarmPermissionForAndroid14()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // Android 12-13
            results["SCHEDULE_EXACT_ALARM"] = alarmManager.canScheduleExactAlarms()
        } else {
            results["ALARM_PERMISSION"] = true // Android 11 trở xuống không cần xin quyền riêng
        }
        
        // Kiểm tra quyền tắt tối ưu hóa pin (không bắt buộc nhưng hữu ích)
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        results["IGNORE_BATTERY_OPTIMIZATION"] = powerManager.isIgnoringBatteryOptimizations(context.packageName)
        
        // Kiểm tra trạng thái bật/tắt thông báo trong ứng dụng
        results["APP_NOTIFICATIONS"] = isNotificationEnabled()
        
        Log.d(TAG, "Permission check results: $results")
        return results
    }
    
    /**
     * Kiểm tra xem thông báo có bị tắt ở cấp hệ thống không
     * Hoạt động cho tất cả các phiên bản Android
     */
    fun areNotificationsEnabled(): Boolean {
        // Từ Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (!manager.areNotificationsEnabled()) {
                return false
            }
            
            // Kiểm tra kênh thông báo
            val channels = manager.notificationChannels
            for (channel in channels) {
                if (channel.id == CHANNEL_ID) {
                    return channel.importance != NotificationManager.IMPORTANCE_NONE
                }
            }
            // Kênh chưa được tạo, coi như bật
            return true
        } 
        // Android 7.0-7.1
        else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return manager.areNotificationsEnabled()
        }
        // Android 6.0 trở xuống coi như bật
        return true
    }
    
    /**
     * Kiểm tra quyền USE_EXACT_ALARM trên Android 14+
     */
    private fun hasExactAlarmPermissionForAndroid14(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        
        // Cách kiểm tra quyền USE_EXACT_ALARM trên Android 14+
        return try {
            val alarmPermissionMethod = AlarmManager::class.java.getMethod("canScheduleExactAlarms")
            alarmPermissionMethod.invoke(alarmManager) as Boolean
        } catch (e: Exception) {
            Log.e(TAG, "Error checking USE_EXACT_ALARM permission", e)
            false
        }
    }
    
    /**
     * Kiểm tra xem có quyền thông báo hay không (Android 13+)
     */
    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == 
                android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true // Các phiên bản Android cũ không cần quyền riêng
        }
    }
    
    /**
     * Đồng bộ hóa trạng thái thông báo trong ứng dụng với trạng thái cấp hệ thống
     * Nếu thông báo bị tắt ở cấp hệ thống, nhưng vẫn bật trong ứng dụng, tắt trong ứng dụng
     * @return true nếu có thay đổi trạng thái, false nếu không có thay đổi
     */
    fun syncNotificationState(): Boolean {
        Log.d(TAG, "Syncing notification state with system settings")
        val appEnabled = isNotificationEnabled()
        val systemEnabled = areNotificationsEnabled()
        
        // Nếu thông báo bật trong ứng dụng nhưng tắt ở cấp hệ thống
        if (appEnabled && !systemEnabled) {
            Log.d(TAG, "Notifications enabled in app but disabled at system level, syncing state")
            setNotificationEnabled(false)
            return true
        }
        
        return false
    }
    
    /**
     * Mở cài đặt ứng dụng để người dùng có thể cấp quyền thông báo
     */
    fun openNotificationSettings() {
        try {
            val intent = android.content.Intent().apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    action = android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS
                    putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, context.packageName)
                } else {
                    action = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                    val uri = android.net.Uri.fromParts("package", context.packageName, null)
                    data = uri
                }
                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            Log.d(TAG, "Opened notification settings")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open notification settings", e)
        }
    }
    
    /**
     * Đặt lại cài đặt thông báo về giá trị mặc định
     */
    fun resetNotificationSettings() {
        Log.d(TAG, "Resetting notification settings to default")
        
        try {
            // Hủy thông báo hiện tại nếu có
            cancelScheduledNotification()
            
            // Xóa tất cả các cài đặt thông báo
            preferences.edit()
                .remove(PREF_ENABLED)
                .remove(PREF_TIME_HOUR)
                .remove(PREF_TIME_MINUTE)
                .apply()
            
            Log.d(TAG, "Notification settings reset to default values")
        } catch (e: Exception) {
            Log.e(TAG, "Error resetting notification settings", e)
        }
    }
    
    /**
     * Kiểm tra xem cài đặt thông báo có giá trị mặc định không
     */
    fun isNotificationSettingsDefault(): Boolean {
        val hasCustomSettings = preferences.contains(PREF_ENABLED) ||
                               preferences.contains(PREF_TIME_HOUR) || 
                               preferences.contains(PREF_TIME_MINUTE)
        return !hasCustomSettings
    }
    
    /**
     * Mở cài đặt quyền đặt lịch chính xác
     */
    fun openAlarmPermissionSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val intent = Intent().apply {
                    action = android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM
                    data = android.net.Uri.fromParts("package", context.packageName, null)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                Log.d(TAG, "Opened alarm permission settings")
            } else {
                // Các phiên bản Android cũ hơn không cần xin quyền riêng
                Log.d(TAG, "No need for alarm permission on this Android version")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open alarm permission settings", e)
        }
    }
    
    /**
     * Yêu cầu tắt tối ưu hóa pin cho ứng dụng
     */
    fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                if (!powerManager.isIgnoringBatteryOptimizations(context.packageName)) {
                    val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = android.net.Uri.parse("package:${context.packageName}")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                    Log.d(TAG, "Requested to ignore battery optimizations")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to request ignore battery optimizations", e)
            }
        }
    }
} 