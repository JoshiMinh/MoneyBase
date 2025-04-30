package com.thebase.moneybase

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState
import com.thebase.moneybase.ui.theme.ColorScheme
import com.thebase.moneybase.ui.theme.*

sealed class Screen(val route: String, val label: String, val icon: ImageVector) {
    object Add : Screen("add", "Add", Icons.Filled.Add)
    object Home : Screen("home", "Home", Icons.Filled.Home)
    object Settings : Screen("settings", "Settings", Icons.Filled.Settings)

    companion object {
        val bottomNavItems = listOf(Home, Add, Settings)

        fun fromRoute(route: String?): Screen = when (route?.substringBefore("/")) {
            Add.route -> Add
            Home.route -> Home
            Settings.route -> Settings
            else -> Home
        }
    }
}

@Composable
fun Navigation(navController: NavHostController, colorScheme: ColorScheme) {
    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route
    val currentScreen = Screen.fromRoute(currentRoute)

    val colors = when (colorScheme) {
        ColorScheme.Light -> LightThemeColors
        ColorScheme.Dark -> DarkThemeColors
        ColorScheme.Blue -> BlueThemeColors
        ColorScheme.Green -> GreenThemeColors
        ColorScheme.Red -> RedThemeColors
    }

    NavigationBar(containerColor = colors.background) {
        Screen.bottomNavItems.forEach { screen ->
            NavigationBarItem(
                icon = { Icon(screen.icon, contentDescription = screen.label) },
                label = { Text(screen.label) },
                selected = currentScreen == screen,
                onClick = {
                    if (currentScreen != screen) {
                        navController.navigate(screen.route) {
                            popUpTo(navController.graph.startDestinationId) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = colors.primary,
                    unselectedIconColor = Color.Gray,
                    selectedTextColor = colors.primary,
                    unselectedTextColor = Color.Gray,
                    indicatorColor = colors.primary.copy(alpha = 0.2f)
                )
            )
        }
    }
}