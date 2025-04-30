package com.thebase.moneybase.screens

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import com.thebase.moneybase.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SmallTopAppBar(
    title: @Composable () -> Unit,
    navigationIcon: (@Composable () -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {}
) {
    navigationIcon?.let {
        TopAppBar(title = title, navigationIcon = it, actions = actions)
    }
}

private sealed class AuthScreen {
    object Main : AuthScreen()
    object Login : AuthScreen()
    object Register : AuthScreen()
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountScreen(
    onTestLogin: () -> Unit,
    onLoginSuccess: (String) -> Unit
) {
    var currentScreen by remember { mutableStateOf<AuthScreen>(AuthScreen.Main) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            when (currentScreen) {
                AuthScreen.Main -> CenterAlignedTopAppBar(title = { Text("Account") })
                AuthScreen.Login -> SmallTopAppBar(
                    title = { Text("Login") },
                    navigationIcon = {
                        IconButton(onClick = { currentScreen = AuthScreen.Main }) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
                AuthScreen.Register -> SmallTopAppBar(
                    title = { Text("Register") },
                    navigationIcon = {
                        IconButton(onClick = { currentScreen = AuthScreen.Main }) {
                            Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                        }
                    }
                )
            }
        },
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(24.dp),
            contentAlignment = Alignment.Center
        ) {
            when (currentScreen) {
                AuthScreen.Main -> MainAccountView(
                    isLoading = isLoading,
                    onTestLogin = {
                        scope.launch {
                            isLoading = true
                            try {
                                Firebase.auth.signOut()
                                onTestLogin()
                                snackbarHostState.showSnackbar("Logged in as test user")
                            } catch (e: Exception) {
                                Log.e("AccountScreen", "Test login failed", e)
                                snackbarHostState.showSnackbar("Test login failed")
                            } finally {
                                isLoading = false
                            }
                        }
                    },
                    onShowLogin = { currentScreen = AuthScreen.Login },
                    onShowRegister = { currentScreen = AuthScreen.Register }
                )
                AuthScreen.Login -> LoginScreen(
                    onLoginSuccess = { userId -> onLoginSuccess(userId) },
                    onNavigateToRegister = { currentScreen = AuthScreen.Register }
                )
                AuthScreen.Register -> RegisterScreen(
                    onRegisterSuccess = { userId -> onLoginSuccess(userId) },
                    onNavigateToLogin = { currentScreen = AuthScreen.Login }
                )
            }
        }
    }
}

@Composable
private fun MainAccountView(
    isLoading: Boolean,
    onTestLogin: () -> Unit,
    onShowLogin: () -> Unit,
    onShowRegister: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Button(
            onClick = onTestLogin,
            enabled = !isLoading,
            modifier = Modifier.fillMaxWidth()
        ) {
            if (isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp
                )
            } else {
                Text("Test Account Login")
            }
        }
        Button(onClick = onShowLogin, modifier = Modifier.fillMaxWidth()) {
            Text("Login")
        }
        Button(onClick = onShowRegister, modifier = Modifier.fillMaxWidth()) {
            Text("Register")
        }
        AuthProviderButton(
            icon = R.drawable.google_logo,
            text = "Continue with Google",
            onClick = { /* TODO: Implement Google auth */ },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            "MoneyBase App",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
    }
}

@Composable
fun LoginScreen(
    onLoginSuccess: (String) -> Unit,
    onNavigateToRegister: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(16.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation()
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = {
                scope.launch {
                    try {
                        val userId = Firebase.auth.currentUser?.uid ?: ""
                        onLoginSuccess(userId)
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Login failed: ${e.message}")
                    }
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Login")
        }
        Spacer(modifier = Modifier.height(8.dp))
        TextButton(onClick = onNavigateToRegister) {
            Text("Don't have an account? Register")
        }
    }
}

@Composable
fun RegisterScreen(
    onRegisterSuccess: (String) -> Unit,
    onNavigateToLogin: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(16.dp))
        OutlinedTextField(
            value = password,
            onValueChange = { password = it },
            label = { Text("Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation()
        )
        Spacer(modifier = Modifier.height(16.dp))
        OutlinedTextField(
            value = confirmPassword,
            onValueChange = { confirmPassword = it },
            label = { Text("Confirm Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation()
        )
        Spacer(modifier = Modifier.height(16.dp))
        Button(
            onClick = {
                scope.launch {
                    if (password == confirmPassword) {
                        try {
                            val user = Firebase.auth.createUserWithEmailAndPassword(email, password).await().user
                            val userId = user?.uid ?: ""
                            onRegisterSuccess(userId)
                        } catch (e: Exception) {
                            snackbarHostState.showSnackbar("Registration failed: ${e.message}")
                        }
                    } else {
                        snackbarHostState.showSnackbar("Passwords do not match")
                    }
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Register")
        }
        Spacer(modifier = Modifier.height(8.dp))
        TextButton(onClick = onNavigateToLogin) {
            Text("Already have an account? Login")
        }
    }
}

@Composable
private fun AuthProviderButton(
    icon: Int,
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    FilledTonalButton(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium
    ) {
        Icon(
            painter = painterResource(id = icon),
            contentDescription = null,
            modifier = Modifier.size(18.dp)
        )
        Spacer(Modifier.width(8.dp))
        Text(text)
    }
}