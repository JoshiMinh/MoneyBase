// MainActivity.kt
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
                val prefs = remember { getSharedPreferences("moneybase_prefs", MODE_PRIVATE) }
                var userId by rememberSaveable { mutableStateOf(prefs.getString(KEY_USER_ID, null)) }
                val navController = rememberNavController()

                LaunchedEffect(userId) {
                    if (userId == null) {
                        navController.navigate("auth") {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                }

                Scaffold(
                    bottomBar = {
                        if (userId != null) Navigation(navController)
                    }
                ) { padding ->
                    AppNavigation(
                        navController,
                        userId,
                        onLogin = { id ->
                            prefs.edit { putString(KEY_USER_ID, id) }
                            userId = id
                        },
                        onLogout = {
                            prefs.edit { remove(KEY_USER_ID) }
                            userId = null
                        },
                        modifier = Modifier.padding(padding)
                    )
                }
            }
        }
    }

    companion object {
        const val KEY_USER_ID = "userId"
        const val TEST_USER_ID = "ff5298cf-3218-4f44-8820-724361d38aad"
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
        navController,
        startDestination = if (userId == null) "auth" else "app",
        modifier = modifier
    ) {
        authGraph(navController, onLogin)
        if (userId != null) {
            appGraph(navController, userId, onLogout)
        }
    }
}

private fun NavGraphBuilder.authGraph(
    navController: NavHostController,
    onLogin: (String) -> Unit
) {
    navigation(startDestination = "account", route = "auth") {
        composable("account") {
            AccountScreen(
                onTestLogin = {
                    onLogin(MainActivity.TEST_USER_ID)
                    navController.navigate("app") {
                        popUpTo("auth") { inclusive = true }
                        launchSingleTop = true
                    }
                }
            )
        }
    }
}

private fun NavGraphBuilder.appGraph(
    navController: NavHostController,
    userId: String,
    onLogout: () -> Unit
) {
    navigation(startDestination = "home", route = "app") {
        composable("home") {
            HomeScreen(userId)
        }
        composable("add") {
            AddScreen(userId, onBack = { navController.popBackStack() })
        }
        composable("settings") {
            SettingsScreen(userId, onLogout = {
                onLogout()
                navController.navigate("auth") {
                    popUpTo("app") { inclusive = true }
                    launchSingleTop = true
                }
            })
        }
    }
}