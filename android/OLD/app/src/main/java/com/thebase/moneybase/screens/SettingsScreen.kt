@file:Suppress("unused")

package com.thebase.moneybase.screens

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.User
import com.thebase.moneybase.screens.settings.AppThemeSection
import com.thebase.moneybase.screens.settings.ExportDataButton
import com.thebase.moneybase.screens.settings.NotificationSettings
import com.thebase.moneybase.screens.settings.ProfileCard
import com.thebase.moneybase.ui.ColorScheme
import com.thebase.moneybase.utils.notifications.NotificationHelper

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    userId: String,
    currentScheme: ColorScheme,
    darkMode: Boolean,
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit,
    onDarkModeToggle: (Boolean) -> Unit,
    customColorHex: String,
    onCustomColorChange: (String) -> Unit,
    navController: NavController
) {
    val context = LocalContext.current
    val repo = remember { FirebaseRepositories() }

    var user by remember { mutableStateOf<User?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    val snackbarHostState = remember { SnackbarHostState() }
    var selectedScheme by rememberSaveable { mutableStateOf(currentScheme) }
    var customColor by rememberSaveable { mutableStateOf(customColorHex) }

    val notificationHelper = remember { NotificationHelper(context) }
    var notificationEnabled by rememberSaveable { mutableStateOf(notificationHelper.isNotificationEnabled()) }
    var notificationHour by rememberSaveable { mutableIntStateOf(notificationHelper.getNotificationHour()) }
    var notificationMinute by rememberSaveable { mutableIntStateOf(notificationHelper.getNotificationMinute()) }

    LaunchedEffect(userId) {
        isLoading = true
        errorMsg = null
        try {
            user = repo.getUser(userId)
            if (user == null) errorMsg = "User data not found."
        } catch (e: Exception) {
            errorMsg = e.localizedMessage ?: "Failed to load user"
        } finally {
            isLoading = false
        }
    }

    Scaffold(snackbarHost = { SnackbarHost(snackbarHostState) }) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            when {
                isLoading -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 64.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }

                errorMsg != null -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 64.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = errorMsg!!,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyLarge,
                            textAlign = TextAlign.Center
                        )
                    }
                }

                else -> {
                    ProfileCard(
                        user = user,
                        userId = userId,
                        repo = repo,
                        snackbarHostState = snackbarHostState,
                        onUserUpdated = { updated -> user = updated },
                        modifier = Modifier.fillMaxWidth()
                    )

                    NotificationSettings(
                        notificationEnabled = notificationEnabled,
                        notificationHour = notificationHour,
                        notificationMinute = notificationMinute,
                        onNotificationToggle = {
                            notificationEnabled = it
                            notificationHelper.setNotificationEnabled(it)
                        },
                        onTimeChanged = { h, m ->
                            notificationHour = h
                            notificationMinute = m
                            notificationHelper.setNotificationTime(h, m)
                        },
                        snackbarHostState = snackbarHostState,
                        modifier = Modifier.fillMaxWidth()
                    )

                    AppThemeSection(
                        selectedScheme = selectedScheme,
                        onSchemeChange = {
                            selectedScheme = it
                            onColorSchemeChange(it)
                        },
                        darkMode = darkMode,
                        onDarkModeToggle = onDarkModeToggle,
                        customColorHex = customColor,
                        onCustomColorChange = {
                            customColor = it
                            onCustomColorChange(it)
                        },
                        modifier = Modifier.fillMaxWidth()
                    )

                    Divider(modifier = Modifier.padding(top = 16.dp))

                    ExportDataButton(
                        userId = userId,
                        repo = repo,
                        snackbarHostState = snackbarHostState,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Button(
                            onClick = onLogout,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(48.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer,
                                contentColor = MaterialTheme.colorScheme.onErrorContainer
                            ),
                            shape = MaterialTheme.shapes.medium
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Icon(Icons.AutoMirrored.Filled.Logout, contentDescription = "Logout")
                                Spacer(Modifier.width(8.dp))
                                Text("Log out")
                            }
                        }

                        Text(
                            text = "© 2025 MoneyBase",
                            modifier = Modifier.fillMaxWidth(),
                            textAlign = TextAlign.Center,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
            }
        }
    }
}