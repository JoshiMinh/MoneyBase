package com.thebase.moneybase

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState

sealed class Screen(val route: String, val label: String, val icon: ImageVector) {
    object Add : Screen("add", "Add", Icons.Filled.Add)
    object Home : Screen("home", "Home", Icons.Filled.Home)
    object Settings : Screen("settings", "Settings", Icons.Filled.Settings)

    companion object {
        // Reordered: Add, Home, Settings
        val bottomNavItems = listOf(Add, Home, Settings)

        fun fromRoute(route: String?) = when (route?.substringBefore("/")) {
            Add.route      -> Add
            Home.route     -> Home
            Settings.route -> Settings
            Routes.REPORT  -> Home
            Routes.HISTORY -> Home
            Routes.ALL_TRANSACTION -> Home
            else           -> Add
        }
    }
}

@Composable
fun Navigation(navController: NavHostController) {
    val backStackEntry = navController.currentBackStackEntryAsState().value
    val currentRoute   = backStackEntry?.destination?.route
    val currentScreen  = Screen.fromRoute(currentRoute)

    // Use the theme's primary color directly
    val primaryColor = MaterialTheme.colorScheme.primary

    NavigationBar(
        modifier       = Modifier.fillMaxWidth(),
        containerColor = MaterialTheme.colorScheme.background
    ) {
        Screen.bottomNavItems.forEach { screen ->
            val selected = (currentScreen == screen)
            NavigationBarItem(
                icon = { Icon(screen.icon, contentDescription = screen.label) },
                label = { Text(screen.label) },
                selected = selected,
                onClick = {
                    if (!selected) {
                        navController.navigate(screen.route) {
                            popUpTo(navController.graph.startDestinationId) { saveState = true }
                            launchSingleTop = true
                            restoreState   = true
                        }
                    }
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor   = primaryColor,
                    unselectedIconColor = Color.Gray,
                    selectedTextColor   = primaryColor,
                    unselectedTextColor = Color.Gray,
                    indicatorColor      = primaryColor.copy(alpha = 0.2f)
                )
            )
        }
    }
}