package com.thebase.moneybase

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.core.content.edit
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.navigation
import androidx.navigation.compose.rememberNavController
import com.thebase.moneybase.screens.*
import com.thebase.moneybase.ui.theme.MoneyBaseTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MoneyBaseTheme {
                // --- Hold onto userId in SharedPreferences + Compose state
                val prefs = remember { getSharedPreferences("moneybase_prefs", MODE_PRIVATE) }
                var userId by rememberSaveable { mutableStateOf(prefs.getString("userId", null)) }

                // NavController for all your @Composable destinations
                val navController = rememberNavController()

                // Whenever userId flips to null, force back to the auth graph
                LaunchedEffect(userId) {
                    if (userId == null) {
                        navController.navigate("auth") {
                            popUpTo(navController.graph.startDestinationId) { inclusive = true }
                            launchSingleTop = true
                        }
                    }
                }

                Scaffold(
                    bottomBar = {
                        // only show bottom nav after login
                        if (userId != null) Navigation(navController)
                    }
                ) { paddingValues ->
                    AppNavigation(
                        navController = navController,
                        userId = userId,
                        onLogin = { id ->
                            prefs.edit { putString("userId", id) }
                            userId = id
                        },
                        onLogout = {
                            prefs.edit { remove("userId") }
                            userId = null
                        },
                        modifier = Modifier.padding(paddingValues)
                    )
                }
            }
        }
    }
}

@Composable
private fun AppNavigation(
    navController: NavHostController,
    userId: String?,
    onLogin: (String) -> Unit,
    onLogout: () -> Unit,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController = navController,
        startDestination = if (userId == null) "auth" else "app",
        modifier = modifier
    ) {
        authGraph(navController, onLogin)
        if (userId != null) {
            appGraph(navController, userId, onLogout)
        }
    }
}

// --- Authentication Graph ---
private fun NavGraphBuilder.authGraph(
    navController: NavHostController,
    onLogin: (String) -> Unit
) {
    navigation(startDestination = "account", route = "auth") {
        composable("account") {
            AccountScreen(
                onTestLogin = {
                    // TODO: replace with real Firebase Auth flow
                    val testUserId = "ff5298cf-3218-4f44-8820-724361d38aad"
                    onLogin(testUserId)
                    navController.navigate("app") {
                        popUpTo("auth") { inclusive = true }
                        launchSingleTop = true
                    }
                }
            )
        }
    }
}

// --- Main App Graph (after login) ---
private fun NavGraphBuilder.appGraph(
    navController: NavHostController,
    userId: String,
    onLogout: () -> Unit
) {
    navigation(startDestination = "home", route = "app") {
        composable("home") {
            HomeScreen(userId = userId)
        }
        composable("add") {
            AddScreen(
                userId = userId,
                onBack = { navController.popBackStack() }
            )
        }
        composable("settings") {
            SettingsScreen(
                userId = userId,
                onLogout = {
                    onLogout()
                    navController.navigate("auth") {
                        popUpTo("app") { inclusive = true }
                        launchSingleTop = true
                    }
                }
            )
        }
    }
}