package com.thebase.moneybase.screens.account

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
fun RegisterScreen(
    onRegisterSuccess: (String) -> Unit,
    onNavigateToLogin: () -> Unit
) {
    var username by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var usernameError by remember { mutableStateOf<String?>(null) }
    var emailError by remember { mutableStateOf<String?>(null) }
    var passwordError by remember { mutableStateOf<String?>(null) }
    var confirmPasswordError by remember { mutableStateOf<String?>(null) }
    var generalError by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val firebaseRepositories = remember { FirebaseRepositories() }
    val emailRegex = remember { Regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Create Account",
            style = MaterialTheme.typography.headlineMedium,
            modifier = Modifier.padding(bottom = 24.dp)
        )
        OutlinedTextField(
            value = username,
            onValueChange = { username = it; usernameError = null },
            label = { Text("Username") },
            modifier = Modifier.fillMaxWidth(),
            isError = usernameError != null,
            supportingText = { usernameError?.let { Text(it) } },
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = email,
            onValueChange = { email = it; emailError = null },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth(),
            isError = emailError != null,
            supportingText = { emailError?.let { Text(it) } },
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it; passwordError = null },
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation(),
            isError = passwordError != null,
            supportingText = { passwordError?.let { Text(it) } },
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(12.dp))
        OutlinedTextField(
            value = confirmPassword,
            onValueChange = { confirmPassword = it; confirmPasswordError = null },
            label = { Text("Confirm Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation(),
            isError = confirmPasswordError != null,
            supportingText = { confirmPasswordError?.let { Text(it) } },
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(16.dp))
        generalError?.let {
            Text(
                text = it,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
            )
        }
        Button(
            onClick = {
                usernameError = null
                emailError = null
                passwordError = null
                confirmPasswordError = null
                generalError = null
                var isValid = true
                if (username.isBlank()) {
                    usernameError = "Username is required"
                    isValid = false
                } else if (username.length < 3) {
                    usernameError = "Username must be at least 3 characters"
                    isValid = false
                }
                if (email.isBlank()) {
                    emailError = "Email is required"
                    isValid = false
                } else if (!emailRegex.matches(email)) {
                    emailError = "Invalid email format"
                    isValid = false
                }
                if (password.isBlank()) {
                    passwordError = "Password is required"
                    isValid = false
                } else if (password.length < 6) {
                    passwordError = "Password must be at least 6 characters"
                    isValid = false
                }
                if (confirmPassword.isBlank()) {
                    confirmPasswordError = "Please confirm your password"
                    isValid = false
                } else if (password != confirmPassword) {
                    confirmPasswordError = "Passwords do not match"
                    isValid = false
                }
                if (isValid) {
                    scope.launch {
                        isLoading = true
                        try {
                            val success = firebaseRepositories.registerUser(email, password, username)
                            if (success) {
                                val user = Firebase.auth.currentUser
                                val userId = user?.uid ?: ""
                                if (userId.isNotEmpty()) {
                                    onRegisterSuccess(userId)
                                } else {
                                    generalError = "Registration successful but failed to get user ID"
                                }
                            } else {
                                generalError = "Registration failed. Please try again."
                            }
                        } catch (e: Exception) {
                            Log.e("RegisterScreen", "Registration error: ${e.message}", e)
                            generalError = when {
                                e.message?.contains("email-already-in-use") == true ->
                                    "Email is already registered"
                                e.message?.contains("weak-password") == true ->
                                    "Password is too weak"
                                e.message?.contains("invalid-email") == true ->
                                    "Invalid email format"
                                e.message?.contains("network") == true ->
                                    "Network error. Check your connection."
                                else -> "Registration failed: ${e.message}"
                            }
                        } finally {
                            isLoading = false
                        }
                    }
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    strokeWidth = 2.dp,
                    color = MaterialTheme.colorScheme.onPrimary
                )
            } else {
                Text("Register")
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        TextButton(
            onClick = onNavigateToLogin,
            enabled = !isLoading
        ) {
            Text("Already have an account? Login")
        }
    }
}