@file:Suppress("DEPRECATION")

package com.thebase.moneybase.screens

import android.app.Activity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.auth.api.signin.GoogleSignInStatusCodes
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import com.thebase.moneybase.R
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.screens.account.LoginScreen
import com.thebase.moneybase.screens.account.RegisterScreen

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
    onLoginSuccess: (String) -> Unit
) {
    var currentScreen by remember { mutableStateOf<AuthScreen>(AuthScreen.Main) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val activity = context as? Activity
    val firebaseAuth = Firebase.auth
    val googleSignInClient = remember {
        val webClientId = context.getString(R.string.default_web_client_id)
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(webClientId)
            .requestEmail()
            .build()
        GoogleSignIn.getClient(context, gso)
    }

    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            scope.launch {
                isLoading = true
                try {
                    val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
                    val account = task.getResult(ApiException::class.java)
                    val idToken = account?.idToken ?: return@launch
                    val credential = GoogleAuthProvider.getCredential(idToken, null)
                    val authResult = firebaseAuth.signInWithCredential(credential).await()
                    val user = authResult.user
                    user?.let {
                        val firebaseRepositories = FirebaseRepositories()
                        val saved = firebaseRepositories.ensureGoogleUserInDatabase(it)
                        snackbarHostState.showSnackbar(
                            if (saved) "Logged in as ${it.displayName}" else "Failed to save user data"
                        )
                        onLoginSuccess(it.uid)
                    }
                } catch (e: ApiException) {
                    val errorMessage = when (e.statusCode) {
                        GoogleSignInStatusCodes.SIGN_IN_CANCELLED -> "Sign in was cancelled"
                        GoogleSignInStatusCodes.NETWORK_ERROR -> "Network error occurred"
                        GoogleSignInStatusCodes.SIGN_IN_CURRENTLY_IN_PROGRESS -> "Sign in already in progress"
                        else -> "Google sign in failed: ${e.message}"
                    }
                    snackbarHostState.showSnackbar(errorMessage)
                } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Google sign in failed: ${e.message}")
                } finally {
                    isLoading = false
                }
            }
        } else {
            scope.launch {
                snackbarHostState.showSnackbar(
                    if (result.resultCode == Activity.RESULT_CANCELED) "Sign-in cancelled"
                    else "Sign-in failed with code: ${result.resultCode}"
                )
            }
        }
    }

    val handleGoogleSignIn: () -> Unit = {
        try {
            activity?.let {
                googleSignInLauncher.launch(googleSignInClient.signInIntent)
            } ?: scope.launch {
                snackbarHostState.showSnackbar("Error: Cannot access Activity")
            }
        } catch (e: Exception) {
            scope.launch {
                snackbarHostState.showSnackbar("Setup error: ${e.message}")
            }
        }
    }

    Scaffold(
        topBar = {
            when (currentScreen) {
                AuthScreen.Main -> CenterAlignedTopAppBar(title = { Text("Account") })
                AuthScreen.Login, AuthScreen.Register -> SmallTopAppBar(
                    title = { Text(if (currentScreen == AuthScreen.Login) "Login" else "Register") },
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
                    onShowLogin = { currentScreen = AuthScreen.Login },
                    onShowRegister = { currentScreen = AuthScreen.Register },
                    onGoogleSignIn = handleGoogleSignIn
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
    onShowLogin: () -> Unit,
    onShowRegister: () -> Unit,
    onGoogleSignIn: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        AuthProviderButton(
            icon = R.drawable.google_logo,
            text = "Continue with Google",
            onClick = onGoogleSignIn,
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
        )
        Button(onClick = onShowLogin, modifier = Modifier.fillMaxWidth()) {
            Text("Login", color = MaterialTheme.colorScheme.onPrimary)
        }
        Button(onClick = onShowRegister, modifier = Modifier.fillMaxWidth()) {
            Text("Register", color = MaterialTheme.colorScheme.onPrimary)
        }
        Text(
            "MoneyBase App",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
    }
}

@Suppress("SameParameterValue")
@Composable
private fun AuthProviderButton(
    icon: Int,
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    FilledTonalButton(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.large,
        enabled = enabled
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