package com.thebase.moneybase.screens.settings

import android.Manifest
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.RequiresApi
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SnackbarResult
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.thebase.moneybase.utils.dialogs.TimePickerDialog
import com.thebase.moneybase.utils.notifications.NotificationHelper
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
@Composable
fun NotificationSettings(
    notificationEnabled: Boolean,
    notificationHour: Int,
    notificationMinute: Int,
    onNotificationToggle: (Boolean) -> Unit,
    onTimeChanged: (hour: Int, minute: Int) -> Unit,
    snackbarHostState: SnackbarHostState,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val notificationHelper = remember { NotificationHelper(context) }
    val scope = rememberCoroutineScope()

    var localEnabled by rememberSaveable { mutableStateOf(notificationEnabled) }
    var localHour by rememberSaveable { mutableIntStateOf(notificationHour) }
    var localMinute by rememberSaveable { mutableIntStateOf(notificationMinute) }
    var showTimePickerDialog by remember { mutableStateOf(false) }
    var showPermissionDialog by remember { mutableStateOf(false) }

    // Launcher for POST_NOTIFICATIONS permission
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            notificationHelper.setNotificationEnabled(true)
            localEnabled = true
            onNotificationToggle(true)
        } else {
            localEnabled = false
            onNotificationToggle(false)

            val shouldShowRationale = androidx.core.app.ActivityCompat
                .shouldShowRequestPermissionRationale(
                    context as ComponentActivity,
                    Manifest.permission.POST_NOTIFICATIONS
                )

            if (!shouldShowRationale) {
                showPermissionDialog = true
            } else {
                scope.launch {
                    snackbarHostState.showSnackbar("Notifications need to be enabled")
                }
            }
        }
    }

    Column(modifier = modifier) {
        // Toggle row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Filled.Notifications,
                contentDescription = null,
                tint = if (localEnabled)
                    MaterialTheme.colorScheme.primary
                else
                    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
            Spacer(Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text("Expense Reminder", style = MaterialTheme.typography.bodyLarge)
                Text(
                    text = if (localEnabled) "On" else "Off",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (localEnabled)
                        MaterialTheme.colorScheme.primary
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                )
            }
            Switch(
                checked = localEnabled,
                onCheckedChange = { enabled ->
                    if (enabled) {
                        val hasPermission = context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                                android.content.pm.PackageManager.PERMISSION_GRANTED
                        if (hasPermission) {
                            val success = notificationHelper.setNotificationEnabled(true)
                            if (success) {
                                localEnabled = true
                                onNotificationToggle(true)
                            } else {
                                scope.launch {
                                    val result = snackbarHostState.showSnackbar(
                                        message = "Cannot enable notifications at system level",
                                        actionLabel = "Settings"
                                    )
                                    if (result == SnackbarResult.ActionPerformed) {
                                        notificationHelper.openNotificationSettings()
                                    }
                                }
                            }
                        } else {
                            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        }
                    } else {
                        localEnabled = false
                        notificationHelper.setNotificationEnabled(false)
                        onNotificationToggle(false)
                    }
                }
            )
        }

        // Time picker row
        AnimatedVisibility(visible = localEnabled) {
            Column {
                Spacer(Modifier.height(8.dp))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(start = 40.dp, top = 8.dp, bottom = 8.dp)
                        .clickable { showTimePickerDialog = true },
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Reminder Time",
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f)
                    )

                    val calendar = Calendar.getInstance().apply {
                        set(Calendar.HOUR_OF_DAY, localHour)
                        set(Calendar.MINUTE, localMinute)
                    }
                    val timeFormat = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }

                    Text(
                        text = timeFormat.format(calendar.time),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.primary
                    )

                    Spacer(Modifier.width(8.dp))

                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        // TimePickerDialog
        if (showTimePickerDialog) {
            TimePickerDialog(
                initialHour = localHour,
                initialMinute = localMinute,
                onDismiss = { showTimePickerDialog = false },
                onConfirm = { hour, minute ->
                    localHour = hour
                    localMinute = minute
                    notificationHelper.setNotificationTime(hour, minute)
                    onTimeChanged(hour, minute)
                    showTimePickerDialog = false
                }
            )
        }

        // Permission rationale dialog
        if (showPermissionDialog) {
            AlertDialog(
                onDismissRequest = { showPermissionDialog = false },
                icon = { Icon(Icons.Filled.Notifications, contentDescription = null) },
                title = { Text("Notifications need to be enabled") },
                text = {
                    Column {
                        Text("To use reminders, the app needs notification permission. Please enable it manually:")
                        Spacer(Modifier.height(8.dp))
                        Text("1. Tap \"Open settings\"\n2. Choose \"Notifications\"\n3. Enable \"Allow notifications\"\n4. Return here to re-enable reminders")
                    }
                },
                confirmButton = {
                    TextButton(onClick = {
                        showPermissionDialog = false
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = android.net.Uri.fromParts("package", context.packageName, null)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                    }) {
                        Text("Open settings")
                    }
                },
                dismissButton = {
                    TextButton(onClick = { showPermissionDialog = false }) {
                        Text("Later")
                    }
                }
            )
        }
    }
}