package com.thebase.moneybase

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.currentBackStackEntryAsState

data class BottomNavItem(val route: String, val label: String, val icon: ImageVector)

@Composable
fun Navigation(navController: NavHostController) {
    val items = listOf(
        BottomNavItem("add", "Add", Icons.Filled.Add),
        BottomNavItem("home", "Home", Icons.Filled.Home),
        BottomNavItem("settings", "Settings", Icons.Filled.Settings)
    )
    val currentRoute = navController.currentBackStackEntryAsState().value?.destination?.route

    NavigationBar {
        items.forEach {
            NavigationBarItem(
                icon = { Icon(it.icon, contentDescription = it.label) },
                selected = currentRoute == it.route,
                onClick = {
                    if (currentRoute != it.route) {
                        navController.navigate(it.route) {
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