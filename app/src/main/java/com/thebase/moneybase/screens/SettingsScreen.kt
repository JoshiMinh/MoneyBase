package com.thebase.moneybase.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.thebase.moneybase.firebase.Repositories
import com.thebase.moneybase.firebase.User
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    userId: String,
    onLogout: () -> Unit
) {
    val repo = remember { Repositories() }
    var user by remember { mutableStateOf<User?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    // Fetch once when the screen appears or userId changes
    LaunchedEffect(userId) {
        isLoading = true
        errorMsg = null
        try {
            val fetched = repo.getUser(userId)
            if (fetched != null) {
                user = fetched
            } else {
                errorMsg = "User data not found."
            }
        } catch (e: Exception) {
            errorMsg = e.localizedMessage ?: "Failed to load user"
        } finally {
            isLoading = false
        }
    }

    val dateFormat = remember {
        SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())
    }

    Column(
        Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            when {
                isLoading -> {
                    // Centered spinner while loading
                    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                errorMsg != null -> {
                    Text(
                        text = errorMsg!!,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                else -> {
                    // Data loaded successfully
                    UserInfoItem("UUID:", userId)
                    UserInfoItem("Display Name:", user?.displayName ?: "")
                    UserInfoItem("Email:", user?.email ?: "")
                    UserInfoItem(
                        "Created At:",
                        user?.createdAt ?: "Unknown"
                    )
                    UserInfoItem(
                        "Last Login At:",
                        user?.lastLoginAt ?: "Unknown"
                    )
                    UserInfoItem("Language:", user?.language ?: "")
                    UserInfoItem("Theme:", user?.theme ?: "")
                    UserInfoItem("Premium User:", if (user?.isPremium == true) "Yes" else "No")
                    UserInfoItem(
                        "Profile Picture:",
                        user?.profilePictureUrl?.takeIf { it.isNotEmpty() } ?: "Not set"
                    )

                    Spacer(Modifier.height(24.dp))

                    Text("Settings", style = MaterialTheme.typography.headlineMedium)
                    SettingsRow(icon = Icons.Default.AccountCircle, text = "Account")
                }
            }
        }

        // Logout button + footer
        Column {
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
                Text("Logout")
            }

            Text(
                "© 2025 MoneyBase",
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp),
                style = MaterialTheme.typography.bodySmall,
                color = Color.Gray,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun UserInfoItem(label: String, value: String) {
    Column(Modifier.padding(vertical = 4.dp)) {
        Text(
            label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
        Text(value, style = MaterialTheme.typography.bodyMedium)
    }
    Spacer(Modifier.height(8.dp))
}

@Composable
private fun SettingsRow(icon: ImageVector, text: String) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            icon,
            contentDescription = null,
            modifier = Modifier.size(24.dp),
            tint = MaterialTheme.colorScheme.primary
        )
        Spacer(Modifier.width(16.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge.copy(fontSize = 18.sp))
    }
}