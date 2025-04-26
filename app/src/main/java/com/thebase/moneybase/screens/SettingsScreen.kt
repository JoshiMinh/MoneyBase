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
import androidx.lifecycle.viewmodel.compose.viewModel
import com.thebase.moneybase.firebase.UserRepository
import com.thebase.moneybase.firebase.UserViewModel
import com.thebase.moneybase.firebase.UserViewModelFactory
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun SettingsScreen(
    userId: String,
    onLogout: () -> Unit,
    userViewModel: UserViewModel = viewModel(factory = UserViewModelFactory(UserRepository()))
) {
    val user by userViewModel.user.collectAsState()
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault()) }

    LaunchedEffect(userId) {
        if (userId.isNotBlank()) {
            userViewModel.fetchUser(userId)
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            // Safe user info display
            UserInfoItem("UUID:", userId)
            UserInfoItem("Display Name:", user?.displayName ?: "Not available")
            UserInfoItem("Email:", user?.email ?: "Not available")
            UserInfoItem("Created At:", user?.createdAt?.toDate()?.let { dateFormat.format(it) } ?: "Unknown")
            UserInfoItem("Last Login At:", user?.lastLoginAt?.toDate()?.let { dateFormat.format(it) } ?: "Unknown")
            UserInfoItem("Language:", user?.language ?: "en")
            UserInfoItem("Theme:", user?.theme ?: "light")
            UserInfoItem("Premium User:", if (user?.isPremium == true) "Yes" else "No")
            UserInfoItem("Profile Picture:", user?.profilePictureUrl?.takeIf { it.isNotEmpty() } ?: "Not set")

            Spacer(Modifier.height(24.dp))

            Text("Settings", style = MaterialTheme.typography.headlineMedium)
            SettingsRow(icon = Icons.Default.AccountCircle, text = "Account")
        }

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
private fun UserInfoItem(label: String, value: String?) {
    Column(Modifier.padding(vertical = 4.dp)) {
        Text(label, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
        Text(value ?: "Loading...", style = MaterialTheme.typography.bodyMedium)
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
        Icon(icon, contentDescription = null, modifier = Modifier.size(24.dp),
            tint = MaterialTheme.colorScheme.primary)
        Spacer(Modifier.width(16.dp))
        Text(text, style = MaterialTheme.typography.bodyLarge.copy(fontSize = 18.sp))
    }
}