package com.thebase.moneybase

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState

sealed class Screen(val route: String, val label: String, val icon: ImageVector) {
    object Home : Screen("home", "Home", Icons.Filled.Home)
    object Add : Screen("add", "Add", Icons.Filled.Add)
    object Settings : Screen("settings", "Settings", Icons.Filled.Settings)

    companion object {
        val bottomNavItems = listOf(Home, Add, Settings)

        fun fromRoute(route: String?): Screen = when (route?.substringBefore("/")) {
            Home.route -> Home
            Add.route -> Add
            Settings.route -> Settings
            else -> Home
        }
    }
}

@Composable
fun Navigation(navController: NavHostController) {
    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route
    val currentScreen = Screen.fromRoute(currentRoute)

    NavigationBar {
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
                }
            )
        }
    }
}