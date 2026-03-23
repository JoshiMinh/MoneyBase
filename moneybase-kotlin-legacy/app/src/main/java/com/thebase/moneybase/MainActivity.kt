package com.thebase.moneybase

import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.RequiresApi
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.core.content.edit
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.navigation
import androidx.navigation.compose.rememberNavController
import com.thebase.moneybase.screens.AccountScreen
import com.thebase.moneybase.screens.AddScreen
import com.thebase.moneybase.screens.HomeScreen
import com.thebase.moneybase.screens.SettingsScreen
import com.thebase.moneybase.screens.home.ReportScreen
import com.thebase.moneybase.screens.home.TransactionsScreen
import com.thebase.moneybase.ui.ColorScheme
import com.thebase.moneybase.ui.MoneyBaseTheme
import com.thebase.moneybase.ui.ColorPalette
import com.thebase.moneybase.ui.toHexString
import kotlinx.coroutines.flow.first

object Routes {
    const val AUTH = "auth"
    const val APP = "app"
    const val ACCOUNT = "account"
    const val HOME = "home"
    const val ADD = "add"
    const val SETTINGS = "settings"
    const val REPORT = "report"
    const val HISTORY = "history"
    const val ALL_TRANSACTION = "all_transaction"
}

class MainActivity : ComponentActivity() {

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            val prefs = remember { getSharedPreferences("moneybase_prefs", MODE_PRIVATE) }

            // Load userId from SharedPreferences and ensure it's not blank
            var rawUserId = prefs.getString(KEY_USER_ID, null)
            // Filter out blank userIds to prevent Firestore errors
            var userId by rememberSaveable { mutableStateOf(if (rawUserId.isNullOrBlank()) null else rawUserId) }
            
            var colorScheme by rememberSaveable {
                mutableStateOf(
                    ColorScheme.valueOf(
                        prefs.getString(KEY_COLOR_SCHEME, ColorScheme.Default.name).orEmpty()
                    )
                )
            }
            var darkMode by rememberSaveable { mutableStateOf(prefs.getBoolean(KEY_DARK_MODE, true)) }
            var customHex by rememberSaveable {
                mutableStateOf(
                    prefs.getString(KEY_CUSTOM_COLOR, ColorPalette.defaultColor.toHexString())
                        ?: ColorPalette.defaultColor.toHexString()
                )
            }

            val navController = rememberNavController()

            // React to userId changes and navigate accordingly without duplicate destinations
            LaunchedEffect(userId) {
                val targetRoute = if (userId.isNullOrEmpty()) Routes.AUTH else Routes.APP
                val currentRoute = navController.currentBackStackEntryFlow.first().destination.route
                if (currentRoute != targetRoute) {
                    navController.navigate(targetRoute) {
                        popUpTo(navController.graph.id) { inclusive = true }
                        launchSingleTop = true
                    }
                }
            }

            MoneyBaseTheme(colorScheme = colorScheme, darkMode = darkMode, customColorHex = customHex) {
                Scaffold(
                    bottomBar = { if (userId != null) Navigation(navController) }
                ) { padding ->
                    AppNavigation(
                        navController = navController,
                        userId = userId,
                        colorScheme = colorScheme,
                        darkMode = darkMode,
                        onLogin = {
                            if (it.isNotBlank()) {
                                prefs.edit { putString(KEY_USER_ID, it) }
                                userId = it
                            }
                        },
                        onLogout = {
                            prefs.edit { remove(KEY_USER_ID) }
                            userId = null
                        },
                        onColorSchemeChange = {
                            prefs.edit { putString(KEY_COLOR_SCHEME, it.name) }
                            colorScheme = it
                        },
                        onDarkModeToggle = {
                            prefs.edit { putBoolean(KEY_DARK_MODE, it) }
                            darkMode = it
                        },
                        customColorHex = customHex,
                        onCustomColorChange = {
                            prefs.edit { putString(KEY_CUSTOM_COLOR, it) }
                            customHex = it
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
        const val KEY_DARK_MODE = "darkMode"
        const val KEY_CUSTOM_COLOR = "customColorHex"
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
@Composable
private fun AppNavigation(
    navController: NavHostController,
    userId: String?,
    colorScheme: ColorScheme,
    darkMode: Boolean,
    onLogin: (String) -> Unit,
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit,
    onDarkModeToggle: (Boolean) -> Unit,
    customColorHex: String,
    onCustomColorChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController     = navController,
        startDestination  = if (userId.isNullOrEmpty()) Routes.AUTH else Routes.APP,
        modifier          = modifier
    ) {
        authGraph(navController, onLogin)
        appGraph(
            navController,
            userId ?: "",
            colorScheme,
            darkMode,
            onLogout,
            onColorSchemeChange,
            onDarkModeToggle,
            customColorHex,
            onCustomColorChange
        )
    }
}

private fun NavGraphBuilder.authGraph(
    navController: NavHostController,
    onLogin: (String) -> Unit
) = navigation(startDestination = Routes.ACCOUNT, route = Routes.AUTH) {
    composable(Routes.ACCOUNT) {
        AccountScreen(onLoginSuccess = {
            onLogin(it)
            navController.navigate(Routes.APP) {
                // pop everything under "auth" off the back stack
                popUpTo(Routes.AUTH) { inclusive = true }
                launchSingleTop = true
            }
        })
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
private fun NavGraphBuilder.appGraph(
    navController: NavHostController,
    userId: String,
    colorScheme: ColorScheme,
    darkMode: Boolean,
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit,
    onDarkModeToggle: (Boolean) -> Unit,
    customColorHex: String,
    onCustomColorChange: (String) -> Unit
) = navigation(startDestination = Routes.HOME, route = Routes.APP) {
    composable(Routes.ADD) {
        AddScreen(userId, onBack = { navController.popBackStack() })
    }
    composable(Routes.HOME) {
        HomeScreen(userId, navController)
    }
    composable(Routes.SETTINGS) {
        SettingsScreen(
            userId              = userId,
            currentScheme       = colorScheme,
            darkMode            = darkMode,
            onLogout            = onLogout,
            onColorSchemeChange = onColorSchemeChange,
            onDarkModeToggle    = onDarkModeToggle,
            customColorHex      = customColorHex,
            onCustomColorChange = onCustomColorChange,
            navController       = navController
        )
    }
    composable(Routes.ALL_TRANSACTION) {
        TransactionsScreen(userId, navController)
    }
    composable(Routes.REPORT) {
        ReportScreen(userId = userId, navController = navController)
    }
}
