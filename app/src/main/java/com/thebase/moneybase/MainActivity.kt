

package com.thebase.moneybase

import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.RequiresApi
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
import com.thebase.moneybase.screens.home.AllTransactionScreen
import com.thebase.moneybase.screens.home.HistoryScreen
import com.thebase.moneybase.screens.home.ReportScreen
import com.thebase.moneybase.ui.ColorScheme
import com.thebase.moneybase.ui.MoneyBaseTheme

object Routes {
    const val AUTH = "auth"
    const val APP = "app"
    const val ACCOUNT = "account"
    const val HOME = "home"
    const val ADD = "add"
    const val SETTINGS = "settings"
    const val ABOUT = "about"
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

            var userId by rememberSaveable { mutableStateOf(prefs.getString(KEY_USER_ID, null)) }
            var colorScheme by rememberSaveable {
                mutableStateOf(
                    ColorScheme.valueOf(
                        prefs.getString(KEY_COLOR_SCHEME, ColorScheme.Purple.name).orEmpty()
                    )
                )
            }
            var darkMode by rememberSaveable { mutableStateOf(prefs.getBoolean(KEY_DARK_MODE, true)) }

            val navController = rememberNavController()

            LaunchedEffect(userId) {
                if (userId.isNullOrEmpty()) {
                    navController.navigate(Routes.AUTH) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            }

            MoneyBaseTheme(colorScheme = colorScheme, darkMode = darkMode) {
                Scaffold(
                    bottomBar = { if (userId != null) Navigation(navController) }
                ) { padding ->
                    AppNavigation(
                        navController = navController,
                        userId = userId,
                        colorScheme = colorScheme,
                        darkMode = darkMode,           // ← pass it here
                        onLogin = {
                            prefs.edit { putString(KEY_USER_ID, it) }
                            userId = it
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
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
@Composable
private fun AppNavigation(
    navController: NavHostController,
    userId: String?,
    colorScheme: ColorScheme,
    darkMode: Boolean,                            // ← add here
    onLogin: (String) -> Unit,
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit,
    onDarkModeToggle: (Boolean) -> Unit,
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
            darkMode,                           // ← and here
            onLogout,
            onColorSchemeChange,
            onDarkModeToggle
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
                popUpTo(0) { inclusive = true }
            }
        })
    }
}

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
private fun NavGraphBuilder.appGraph(
    navController: NavHostController,
    userId: String,
    colorScheme: ColorScheme,                      // ← add here
    darkMode: Boolean,                             // ← add here
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit,
    onDarkModeToggle: (Boolean) -> Unit
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
            darkMode            = darkMode,          // ← and finally here
            onLogout            = onLogout,
            onColorSchemeChange = onColorSchemeChange,
            onDarkModeToggle    = onDarkModeToggle,
            navController       = navController
        )
    }
    composable(Routes.ABOUT) {
        AboutScreen(navController)
    }

    composable(Routes.REPORT) {
        ReportScreen(userId)
    }

    composable(Routes.HISTORY) {
        HistoryScreen(userId, navController)
    }

    composable(Routes.ALL_TRANSACTION) {
        AllTransactionScreen(userId, navController)
    }


}