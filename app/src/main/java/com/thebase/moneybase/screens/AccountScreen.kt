package com.thebase.moneybase.screens

import android.util.Log
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.PasswordVisualTransformation
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
import com.thebase.moneybase.firebase.Repositories
import android.app.Activity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts

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
    
    // Google Sign-In setup
    val context = LocalContext.current
    val activity = context as? Activity
    val firebaseAuth = Firebase.auth
    
    // Configure Google Sign In with hardcoded web client ID for testing
    val googleSignInClient = remember {
        // Thông tin debug cho đăng nhập Google
        val webClientId = context.getString(R.string.default_web_client_id)
        val isGoogleAccountAvailable = GoogleSignIn.getLastSignedInAccount(context) != null
        
        Log.d("GoogleSignIn", "================================")
        Log.d("GoogleSignIn", "Debug Google Sign-In Information")
        Log.d("GoogleSignIn", "Web Client ID: $webClientId")
        Log.d("GoogleSignIn", "Last signed in account available: $isGoogleAccountAvailable")
        Log.d("GoogleSignIn", "Running on device: ${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}")
        Log.d("GoogleSignIn", "================================")
        
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(webClientId)
            .requestEmail()
            .build()
        
        GoogleSignIn.getClient(context, gso)
    }
    
    // Activity result launcher for Google Sign-In
    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        Log.d("GoogleSignIn", "Received result: ${result.resultCode}")
        
        if (result.resultCode == Activity.RESULT_OK) {
            scope.launch {
                isLoading = true
                try {
                    val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
                    Log.d("GoogleSignIn", "Attempting to get account")
                    
                    val account = task.getResult(ApiException::class.java)
                    Log.d("GoogleSignIn", "Got account: ${account.email}")
                    
                    val idToken = account.idToken
                    if (idToken == null) {
                        Log.e("GoogleSignIn", "ID token is null")
                        snackbarHostState.showSnackbar("Failed: ID token is null")
                        isLoading = false
                        return@launch
                    }
                    
                    // Firebase Authentication with Google
                    Log.d("GoogleSignIn", "Starting Firebase auth")
                    val credential = GoogleAuthProvider.getCredential(idToken, null)
                    val authResult = firebaseAuth.signInWithCredential(credential).await()
                    Log.d("GoogleSignIn", "Firebase auth completed")
                    
                    val user = authResult.user
                    if (user != null) {
                        // Lưu thông tin người dùng vào Firestore
                        Log.d("GoogleSignIn", "Got user: ${user.displayName}, saving to database")
                        val repositories = Repositories()
                        val saved = repositories.ensureGoogleUserInDatabase(user)
                        if (saved) {
                            Log.d("GoogleSignIn", "User saved to database")
                            snackbarHostState.showSnackbar("Logged in as ${user.displayName}")
                            onLoginSuccess(user.uid)
                        } else {
                            Log.e("GoogleSignIn", "Failed to save user data")
                            snackbarHostState.showSnackbar("Logged in but failed to save user data")
                            onLoginSuccess(user.uid)
                        }
                    } else {
                        Log.e("GoogleSignIn", "User is null")
                        snackbarHostState.showSnackbar("Failed to get user information")
                    }
                } catch (e: ApiException) {
                    // Handle specific Google Sign-In API exceptions
                    Log.e("GoogleSignIn", "Google sign in failed with API exception: ${e.statusCode}", e)
                    val errorMessage = when(e.statusCode) {
                        GoogleSignInStatusCodes.SIGN_IN_CANCELLED -> "Sign in was cancelled"
                        GoogleSignInStatusCodes.NETWORK_ERROR -> "Network error occurred"
                        GoogleSignInStatusCodes.SIGN_IN_CURRENTLY_IN_PROGRESS -> "Sign in already in progress"
                        else -> "Google sign in failed: ${e.message} (code: ${e.statusCode})"
                    }
                    snackbarHostState.showSnackbar(errorMessage)
                } catch (e: Exception) {
                    Log.e("GoogleSignIn", "Google sign in failed", e)
                    snackbarHostState.showSnackbar("Google sign in failed: ${e.message}")
                } finally {
                    isLoading = false
                }
            }
        } else if (result.resultCode == Activity.RESULT_CANCELED) {
            Log.d("GoogleSignIn", "Sign in was cancelled by user")
            scope.launch {
                snackbarHostState.showSnackbar("Sign-in cancelled")
            }
        } else {
            Log.e("GoogleSignIn", "Sign in failed with result code: ${result.resultCode}")
            scope.launch {
                snackbarHostState.showSnackbar("Sign-in failed with code: ${result.resultCode}")
            }
        }
    }

    // Function to handle Google Sign-In
    val handleGoogleSignIn: () -> Unit = {
        try {
            // Kiểm tra thiết lập Google Sign-In trong Firebase Auth
            val providers = firebaseAuth.fetchSignInMethodsForEmail("test@example.com").addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    val isGoogleEnabled = task.result?.signInMethods?.contains("google.com") ?: false
                    Log.d("GoogleSignIn", "Google Sign-In enabled in Firebase: $isGoogleEnabled")
                } else {
                    Log.e("GoogleSignIn", "Failed to check sign-in methods: ${task.exception?.message}")
                }
            }

            activity?.let {
                try {
                    Log.d("GoogleSignIn", "Starting Google sign in with client ID: ${context.getString(R.string.default_web_client_id)}")
                    googleSignInLauncher.launch(googleSignInClient.signInIntent)
                } catch (e: Exception) {
                    Log.e("GoogleSignIn", "Error launching sign in", e)
                    scope.launch {
                        snackbarHostState.showSnackbar("Error starting Google Sign-In: ${e.message}")
                    }
                }
            } ?: run {
                Log.e("GoogleSignIn", "Activity context is null")
                scope.launch {
                    snackbarHostState.showSnackbar("Error: Cannot access Activity")
                }
            }
        } catch (e: Exception) {
            Log.e("GoogleSignIn", "Error in sign-in setup", e)
            scope.launch {
                snackbarHostState.showSnackbar("Setup error: ${e.message}")
            }
        }
    }

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
                                // Không hiển thị snackbar vì onTestLogin sẽ điều hướng qua màn hình khác
                            } catch (e: Exception) {
                                Log.e("AccountScreen", "Test login failed", e)
                                snackbarHostState.showSnackbar("Test login failed: ${e.message}")
                            } finally {
                                isLoading = false
                            }
                        }
                    },
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
    onTestLogin: () -> Unit,
    onShowLogin: () -> Unit,
    onShowRegister: () -> Unit,
    onGoogleSignIn: () -> Unit
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
            onClick = onGoogleSignIn,
            modifier = Modifier.fillMaxWidth(),
            enabled = !isLoading
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
    var isLoading by remember { mutableStateOf(false) }
    val repositories = remember { Repositories() }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        if (errorMessage != null) {
            Text(
                text = errorMessage!!,
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
                            isLoading = false
                            return@launch
                        }
                        
                        try {
                            val success = repositories.loginUser(email, password)
                            if (success) {
                        val userId = Firebase.auth.currentUser?.uid ?: ""
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

@Composable
fun RegisterScreen(
    onRegisterSuccess: (String) -> Unit,
    onNavigateToLogin: () -> Unit
) {
    var username by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    
    // Error states
    var usernameError by remember { mutableStateOf<String?>(null) }
    var emailError by remember { mutableStateOf<String?>(null) }
    var passwordError by remember { mutableStateOf<String?>(null) }
    var confirmPasswordError by remember { mutableStateOf<String?>(null) }
    var generalError by remember { mutableStateOf<String?>(null) }
    
    var isLoading by remember { mutableStateOf(false) }
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val repositories = remember { Repositories() }

    // Email validation regex
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
            onValueChange = { 
                username = it
                usernameError = null
            },
            label = { Text("Username") },
            modifier = Modifier.fillMaxWidth(),
            isError = usernameError != null,
            supportingText = { usernameError?.let { Text(it) } },
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(12.dp))

        OutlinedTextField(
            value = email,
            onValueChange = { 
                email = it
                emailError = null
            },
            label = { Text("Email") },
            modifier = Modifier.fillMaxWidth(),
            isError = emailError != null,
            supportingText = { emailError?.let { Text(it) } },
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(12.dp))

        OutlinedTextField(
            value = password,
            onValueChange = { 
                password = it
                passwordError = null
            },
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
            onValueChange = { 
                confirmPassword = it
                confirmPasswordError = null
            },
            label = { Text("Confirm Password") },
            modifier = Modifier.fillMaxWidth(),
            visualTransformation = PasswordVisualTransformation(),
            isError = confirmPasswordError != null,
            supportingText = { confirmPasswordError?.let { Text(it) } },
            enabled = !isLoading
        )
        Spacer(modifier = Modifier.height(16.dp))

        if (generalError != null) {
            Text(
                text = generalError!!,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodySmall,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
            )
        }

        Button(
            onClick = {
                // Reset all error states
                usernameError = null
                emailError = null
                passwordError = null
                confirmPasswordError = null
                generalError = null
                
                // Validate input fields
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
                            val success = repositories.registerUser(email, password, username)
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
        shape = MaterialTheme.shapes.medium,
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