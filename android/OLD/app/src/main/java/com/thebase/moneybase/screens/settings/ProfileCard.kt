@file:Suppress("unused")

package com.thebase.moneybase.screens.settings

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import coil.compose.rememberAsyncImagePainter
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.User
import com.thebase.moneybase.database.uploadImageToCloudinary
import kotlinx.coroutines.launch

@Composable
fun ProfileCard(
    user: User?,
    userId: String,
    repo: FirebaseRepositories,
    snackbarHostState: SnackbarHostState,
    onUserUpdated: (User?) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    // Dialog visibility & form state
    var showDialog by remember { mutableStateOf(false) }
    var nameField by rememberSaveable { mutableStateOf(user?.displayName.orEmpty()) }
    var currentPwd by rememberSaveable { mutableStateOf("") }
    var newPwd by rememberSaveable { mutableStateOf("") }
    var confirmPwd by rememberSaveable { mutableStateOf("") }
    var isSaving by remember { mutableStateOf(false) }

    // Image picker
    val pickImageLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            uploadImageToCloudinary(
                context, it, userId, repo, coroutineScope, snackbarHostState
            ) {
                coroutineScope.launch {
                    val updated = repo.getUser(userId)
                    onUserUpdated(updated)
                    nameField = updated?.displayName.orEmpty()
                }
            }
        }
    }

    // Use the extracted layout
    ProfileCardLayout(
        user = user,
        onClick = { showDialog = true },
        onAvatarClick = { pickImageLauncher.launch("image/*") },
        modifier = modifier
    )

    if (showDialog) {
        AlertDialog(
            onDismissRequest = { if (!isSaving) showDialog = false },
            title = {
                Text(
                    "Account Info",
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            text = {
                Column {
                    // Avatar again in dialog
                    Box(
                        modifier = Modifier
                            .size(90.dp)
                            .align(Alignment.CenterHorizontally)
                            .border(2.dp, MaterialTheme.colorScheme.primary, CircleShape)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.surface)
                            .clickable { pickImageLauncher.launch("image/*") },
                        contentAlignment = Alignment.Center
                    ) {
                        user?.profilePictureUrl
                            ?.takeIf { it.isNotEmpty() }
                            ?.let {
                                Image(
                                    painter = rememberAsyncImagePainter(it),
                                    contentDescription = "Profile picture",
                                    contentScale = ContentScale.Crop,
                                    modifier = Modifier.fillMaxSize()
                                )
                            }
                            ?: Icon(
                                Icons.Default.AccountCircle,
                                contentDescription = "Avatar placeholder",
                                modifier = Modifier.size(56.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                    }

                    Spacer(Modifier.height(16.dp))

                    OutlinedTextField(
                        value = nameField,
                        onValueChange = { nameField = it },
                        label = { Text("Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(Modifier.height(8.dp))

                    OutlinedTextField(
                        value = user?.email.orEmpty(),
                        onValueChange = {},
                        label = { Text("Email") },
                        enabled = false,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(Modifier.height(16.dp))
                    Divider()
                    Spacer(Modifier.height(8.dp))

                    Text("Change Password", style = MaterialTheme.typography.labelLarge)
                    Spacer(Modifier.height(8.dp))

                    OutlinedTextField(
                        value = currentPwd,
                        onValueChange = { currentPwd = it },
                        label = { Text("Current Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(Modifier.height(8.dp))

                    OutlinedTextField(
                        value = newPwd,
                        onValueChange = { newPwd = it },
                        label = { Text("New Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(Modifier.height(8.dp))

                    OutlinedTextField(
                        value = confirmPwd,
                        onValueChange = { confirmPwd = it },
                        label = { Text("Confirm New Password") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null) },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                val pwValid = currentPwd.isNotBlank() &&
                        newPwd.isNotBlank() &&
                        newPwd == confirmPwd
                val nameChanged = nameField != user?.displayName
                val canSave = !isSaving && (nameChanged || pwValid)

                TextButton(
                    onClick = {
                        isSaving = true
                        coroutineScope.launch {
                            if (nameChanged) {
                                repo.updateUserProfile(userId, nameField, user?.email.orEmpty())
                            }
                            if (pwValid) {
                                repo.updateUserPassword(userId, currentPwd, newPwd)
                                snackbarHostState.showSnackbar("Password updated")
                            }
                            val updated = repo.getUser(userId)
                            onUserUpdated(updated)
                            snackbarHostState.showSnackbar("Profile updated")
                            isSaving = false
                            showDialog = false
                        }
                    },
                    enabled = canSave
                ) {
                    Text(if (isSaving) "Saving..." else "Save")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { if (!isSaving) showDialog = false },
                    enabled = !isSaving
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun ProfileCardLayout(
    user: User?,
    onClick: () -> Unit,
    onAvatarClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .clickable { onClick() }
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .border(2.dp, MaterialTheme.colorScheme.primary, CircleShape)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.surface)
                        .clickable { onAvatarClick() },
                    contentAlignment = Alignment.Center
                ) {
                    user?.profilePictureUrl
                        ?.takeIf { it.isNotEmpty() }
                        ?.let {
                            Image(
                                painter = rememberAsyncImagePainter(it),
                                contentDescription = "Profile picture",
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                        ?: Icon(
                            Icons.Default.AccountCircle,
                            contentDescription = "Avatar placeholder",
                            modifier = Modifier.size(48.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                }

                Spacer(Modifier.width(16.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = user?.displayName.orEmpty(),
                        style = MaterialTheme.typography.headlineSmall
                    )
                    Text(
                        text = user?.email.orEmpty(),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (user?.premium == true) {
                Divider()
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFFFFF8E1), shape = MaterialTheme.shapes.small)
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Star,
                        contentDescription = "Premium badge",
                        tint = Color(0xFFFFB300)
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(
                        text = "Premium Account",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color(0xFF7A5C00)
                    )
                }
            }
        }
    }
}