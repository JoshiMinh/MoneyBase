package com.thebase.moneybase.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.rememberAsyncImagePainter
import com.thebase.moneybase.firebase.Repositories
import com.thebase.moneybase.firebase.User
import com.thebase.moneybase.ui.theme.ColorScheme
import com.thebase.moneybase.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    userId: String,
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit
) {
    val repo = remember { Repositories() }
    var user by remember { mutableStateOf<User?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMsg by remember { mutableStateOf<String?>(null) }
    var selectedColorScheme by remember { mutableStateOf(ColorScheme.Dark) }

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

    Column(
        Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            when {
                isLoading -> {
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
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .background(Color.Gray, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        if (user?.profilePictureUrl.isNullOrEmpty()) {
                            Icon(
                                Icons.Default.AccountCircle,
                                contentDescription = null,
                                modifier = Modifier.size(80.dp),
                                tint = MaterialTheme.colorScheme.onSurface
                            )
                        } else {
                            Image(
                                painter = rememberAsyncImagePainter(model = user?.profilePictureUrl),
                                contentDescription = null,
                                modifier = Modifier.size(80.dp),
                                contentScale = ContentScale.Crop
                            )
                        }
                    }

                    Spacer(Modifier.height(16.dp))

                    Text(
                        text = user?.displayName ?: "Display Name",
                        style = MaterialTheme.typography.headlineMedium
                    )

                    Text(
                        text = userId,
                        style = MaterialTheme.typography.bodyMedium
                    )

                    Text(
                        text = user?.email ?: "Email",
                        style = MaterialTheme.typography.bodyMedium
                    )

                    Icon(
                        imageVector = Icons.Default.Star,
                        contentDescription = null,
                        tint = if (user?.isPremium == true) Color(0xFFFFD700) else Color.Gray,
                        modifier = Modifier.size(24.dp)
                    )

                    Spacer(Modifier.height(24.dp))

                    Text("Settings", style = MaterialTheme.typography.headlineMedium)

                    Text("Select Color Scheme", style = MaterialTheme.typography.bodyLarge)
                    Spacer(Modifier.height(8.dp))
                    Row(
                        Modifier
                            .horizontalScroll(rememberScrollState())
                            .padding(vertical = 8.dp)
                    ) {
                        listOf(ColorScheme.Light, ColorScheme.Dark, ColorScheme.Blue, ColorScheme.Green, ColorScheme.Red).forEach { scheme ->
                            IconButton(
                                onClick = {
                                    selectedColorScheme = scheme
                                    onColorSchemeChange(scheme)
                                },
                                modifier = Modifier
                                    .padding(horizontal = 8.dp)
                                    .size(48.dp)
                                    .border(1.dp, Color.Gray, CircleShape) // Added grey border
                            ) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxSize()
                                        .aspectRatio(1f)
                                        .background(
                                            color = getIconColorForScheme(scheme),
                                            shape = CircleShape
                                        )
                                )
                            }
                        }
                    }
                }
            }
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