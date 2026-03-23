@file:Suppress("unused")

package com.thebase.moneybase.utils.notifications

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.edit
import com.thebase.moneybase.MainActivity
import com.thebase.moneybase.R
import java.util.Calendar
import kotlin.math.abs

class NotificationHelper(private val context: Context) {

    companion object {
        const val TAG = "NotificationHelper"
        const val CHANNEL_ID = "moneybase_reminder_channel"
        const val NOTIFICATION_ID = 1001
        const val PREF_NAME = "notification_preferences"
        const val PREF_ENABLED = "notification_enabled"
        const val PREF_TIME_HOUR = "notification_hour"
        const val PREF_TIME_MINUTE = "notification_minute"
        const val DEFAULT_HOUR = 20
        const val DEFAULT_MINUTE = 0
        const val REQUEST_CODE = 100
    }

    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val preferences: SharedPreferences =
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
    private val alarmManager =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Reminder to record expenses",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Reminder to record expenses daily"
            enableVibration(true)
        }
        notificationManager.createNotificationChannel(channel)
    }

    fun sendReminderNotification() {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Reminder to record expenses")
            .setContentText("It's time to record your daily expenses!")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }

    fun isReminderTimeSoon(): Boolean {
        val now = Calendar.getInstance()
        val reminder = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, getNotificationHour())
            set(Calendar.MINUTE, getNotificationMinute())
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val diff = abs(now.timeInMillis - reminder.timeInMillis)
        return diff <= 2 * 60 * 1000
    }

    fun scheduleNotification() {
        if (!isNotificationEnabled()) {
            cancelScheduledNotification()
            return
        }
        if (!areNotificationsEnabled()) return

        val intent = Intent(context, NotificationReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val now = System.currentTimeMillis()
        val calendar = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, getNotificationHour())
            set(Calendar.MINUTE, getNotificationMinute())
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= now) add(Calendar.DAY_OF_YEAR, 1)
        }
        val scheduled = calendar.timeInMillis

        when {
            Build.VERSION.SDK_INT >= 34 -> if (hasExactAlarmPermissionForAndroid14()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduled, pi)
            } else {
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    scheduled,
                    AlarmManager.INTERVAL_DAY,
                    pi
                )
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduled, pi)
            } else {
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    scheduled,
                    AlarmManager.INTERVAL_DAY,
                    pi
                )
            }
            true ->
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, scheduled, pi)
            else ->
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    scheduled,
                    AlarmManager.INTERVAL_DAY,
                    pi
                )
        }

        scheduleNotificationReschedule(scheduled)

        val check = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
        )
        Log.d(TAG, "Alarm exists: ${check != null}")
    }

    private fun scheduleNotificationReschedule(triggerTime: Long) {
        val tomorrowIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE + 1,
            Intent(context, DailyAlarmRescheduleReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val cal = Calendar.getInstance().apply {
            timeInMillis = triggerTime
            add(Calendar.MINUTE, 1)
        }
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            cal.timeInMillis,
            tomorrowIntent
        )
    }

    fun cancelScheduledNotification() {
        val intent = Intent(context, NotificationReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE
        )
        if (pi != null) {
            alarmManager.cancel(pi)
            pi.cancel()
        }
    }

    fun isNotificationEnabled(): Boolean =
        preferences.getBoolean(PREF_ENABLED, false)

    fun setNotificationEnabled(enabled: Boolean): Boolean {
        if (enabled && !areNotificationsEnabled()) return false
        preferences.edit { putBoolean(PREF_ENABLED, enabled) }
        if (enabled) scheduleNotification() else cancelScheduledNotification()
        return true
    }

    fun getNotificationHour(): Int =
        preferences.getInt(PREF_TIME_HOUR, DEFAULT_HOUR)

    fun getNotificationMinute(): Int =
        preferences.getInt(PREF_TIME_MINUTE, DEFAULT_MINUTE)

    fun setNotificationTime(hour: Int, minute: Int) {
        preferences.edit {
            putInt(PREF_TIME_HOUR, hour)
                .putInt(PREF_TIME_MINUTE, minute)
        }
        if (isNotificationEnabled()) scheduleNotification()
    }

    fun checkPermissions(): Map<String, Boolean> {
        val results = mutableMapOf<String, Boolean>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            results["POST_NOTIFICATIONS"] =
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                        PackageManager.PERMISSION_GRANTED
        } else {
            results["NOTIFICATIONS_ENABLED"] = areNotificationsEnabled()
        }
        if (Build.VERSION.SDK_INT >= 34) {
            results["USE_EXACT_ALARM"] = hasExactAlarmPermissionForAndroid14()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            results["SCHEDULE_EXACT_ALARM"] = alarmManager.canScheduleExactAlarms()
        } else {
            results["ALARM_PERMISSION"] = true
        }
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        results["IGNORE_BATTERY_OPTIMIZATION"] =
            pm.isIgnoringBatteryOptimizations(context.packageName)
        results["APP_NOTIFICATIONS"] = isNotificationEnabled()
        return results
    }

    fun areNotificationsEnabled(): Boolean {
        return when {
            true -> {
                val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (!mgr.areNotificationsEnabled()) return false
                mgr.notificationChannels.any { it.id == CHANNEL_ID && it.importance != NotificationManager.IMPORTANCE_NONE }
            }

            true ->
                (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                    .areNotificationsEnabled()

            else -> true
        }
    }

    private fun hasExactAlarmPermissionForAndroid14(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        return try {
            val method = AlarmManager::class.java.getMethod("canScheduleExactAlarms")
            method.invoke(alarmManager) as Boolean
        } catch (_: Exception) {
            false
        }
    }

    fun hasNotificationPermission(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                    PackageManager.PERMISSION_GRANTED
        else true

    fun syncNotificationState(): Boolean {
        val appEnabled = isNotificationEnabled()
        val sysEnabled = areNotificationsEnabled()
        if (appEnabled && !sysEnabled) {
            setNotificationEnabled(false)
            return true
        }
        return false
    }

    fun openNotificationSettings() {
        val intent = Intent().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            } else {
                action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                data = Uri.fromParts("package", context.packageName, null)
            }
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    fun resetNotificationSettings() {
        cancelScheduledNotification()
        preferences.edit()
            .remove(PREF_ENABLED)
            .remove(PREF_TIME_HOUR)
            .remove(PREF_TIME_MINUTE)
            .apply()
    }

    fun isNotificationSettingsDefault(): Boolean =
        !preferences.contains(PREF_ENABLED) &&
                !preferences.contains(PREF_TIME_HOUR) &&
                !preferences.contains(PREF_TIME_MINUTE)

    fun openAlarmPermissionSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent().apply {
                action = Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM
                data = Uri.fromParts("package", context.packageName, null)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        }
    }

    fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(context.packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            }
        }
    }
}
