package com.thebase.moneybase.screens.account

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import com.thebase.moneybase.database.FirebaseRepositories
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(
    onLoginSuccess: (String) -> Unit,
    onNavigateToRegister: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(false) }
    val firebaseRepositories = remember { FirebaseRepositories() }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        errorMessage?.let {
            Text(
                text = it,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }

        OutlinedTextField(
            value = email,
            onValueChange = {
                email = it
                errorMessage = null
            },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(16.dp))
        OutlinedTextField(
            value = password,
            onValueChange = {
                password = it
                errorMessage = null
            },
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation(),
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = {
                scope.launch {
                    isLoading = true
                    try {
                        if (email.isBlank() || password.isBlank()) {
                            errorMessage = "Email and password are required"
                            return@launch
                        }

                        val success = firebaseRepositories.loginUser(email, password)
                        if (success) {
                            val userId = Firebase.auth.currentUser?.uid.orEmpty()
                            if (userId.isNotEmpty()) {
                                onLoginSuccess(userId)
                            } else {
                                errorMessage = "Login successful but failed to get user ID"
                            }
                        } else {
                            errorMessage = "Invalid email or password"
                        }
                    } catch (e: Exception) {
                        Log.e("LoginScreen", "Login error: ${e.message}", e)
                        errorMessage = when {
                            e.message?.contains("network") == true -> "Network error. Check your connection."
                            e.message?.contains("user-not-found") == true -> "Email is not registered"
                            e.message?.contains("wrong-password") == true -> "Incorrect password"
                            e.message?.contains("too-many-requests") == true -> "Too many failed attempts. Try again later."
                            else -> "Login failed: ${e.message}"
                        }
                    } finally {
                        isLoading = false
                    }
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary
                )
            } else {
                Text("Login")
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        TextButton(onClick = onNavigateToRegister, enabled = !isLoading) {
            Text("Don't have an account? Register")
        }
    }
}