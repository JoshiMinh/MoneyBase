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
import androidx.navigation.compose.*

import com.thebase.moneybase.screens.*
import com.thebase.moneybase.ui.theme.*

private object Routes {
    const val AUTH = "auth"
    const val APP = "app"
    const val ACCOUNT = "account"
    const val HOME = "home"
    const val ADD = "add"
    const val SETTINGS = "settings"
}

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            // Persisted user ID and theme scheme
            val prefs = remember { getSharedPreferences("moneybase_prefs", MODE_PRIVATE) }
            var userId by rememberSaveable { mutableStateOf(prefs.getString(KEY_USER_ID, null)) }
            var colorScheme by rememberSaveable {
                mutableStateOf(
                    ColorScheme.valueOf(
                        prefs.getString(KEY_COLOR_SCHEME, ColorScheme.Dark.name)
                            .orEmpty()
                    )
                )
            }
            val navController = rememberNavController()

            // Redirect to auth if not logged in
            LaunchedEffect(userId) {
                if (userId.isNullOrEmpty()) {
                    navController.navigate(Routes.AUTH) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            }

            MoneyBaseTheme(colorScheme) {
                Scaffold(
                    bottomBar = { if (userId != null) Navigation(navController, colorScheme) }
                ) { padding ->
                    AppNavigation(
                        navController = navController,
                        userId = userId,
                        onLogin = { id ->
                            prefs.edit { putString(KEY_USER_ID, id) }
                            userId = id
                        },
                        onLogout = {
                            prefs.edit { remove(KEY_USER_ID) }
                            userId = null
                        },
                        onColorSchemeChange = { scheme ->
                            prefs.edit { putString(KEY_COLOR_SCHEME, scheme.name) }
                            colorScheme = scheme
                        },
                        modifier = Modifier.padding(padding)
                    )
                }
            }
        }
    }

    companion object {
        const val KEY_USER_ID = "userId"
        const val KEY_COLOR_SCHEME = "colorScheme"
        const val TEST_USER_ID = "ff5298cf-3218-4f44-8820-724361d38aad"
    }
}

@Composable
private fun AppNavigation(
    navController: NavHostController,
    userId: String?,
    onLogin: (String) -> Unit,
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController = navController,
        startDestination = if (userId.isNullOrEmpty()) Routes.AUTH else Routes.APP,
        modifier = modifier
    ) {
        authGraph(navController, onLogin)
        if (!userId.isNullOrEmpty()) {
            appGraph(navController, userId, onLogout, onColorSchemeChange)
        }
    }
}

/** Authentication flow with a single Account screen. */
private fun NavGraphBuilder.authGraph(
    navController: NavHostController,
    onLogin: (String) -> Unit
) = navigation(startDestination = Routes.ACCOUNT, route = Routes.AUTH) {
    composable(Routes.ACCOUNT) {
        AccountScreen(
            onTestLogin = {
                onLogin(MainActivity.TEST_USER_ID)
                navController.navigate(Routes.APP) {
                    popUpTo(Routes.AUTH) { inclusive = true }
                    launchSingleTop = true
                }
            },
            onLoginSuccess = { id ->
                onLogin(id)
                navController.navigate(Routes.APP) {
                    popUpTo(Routes.AUTH) { inclusive = true }
                    launchSingleTop = true
                }
            }
        )
    }
}

/** Main app flow: Add → Home → Settings screens. */
private fun NavGraphBuilder.appGraph(
    navController: NavHostController,
    userId: String,
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit
) = navigation(startDestination = Routes.HOME, route = Routes.APP) {
    composable(Routes.ADD) {
        AddScreen(userId, onBack = { navController.popBackStack() })
    }
    composable(Routes.HOME) {
        HomeScreen(userId)
    }
    composable(Routes.SETTINGS) {
        SettingsScreen(userId, onLogout, onColorSchemeChange)
    }
}