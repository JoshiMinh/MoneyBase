package com.thebase.moneybase

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.thebase.moneybase.screens.AddScreen
import com.thebase.moneybase.screens.HomeScreen
import com.thebase.moneybase.screens.SettingsScreen
import com.thebase.moneybase.ui.theme.MoneyBaseTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MoneyBaseTheme {
                FinanceApp()
            }
        }
    }
}

@Composable
fun FinanceApp() {
    val navController = rememberNavController()
    val defaultUserId = "0123"

    Scaffold(
        bottomBar = { Navigation(navController) }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = "home",
            modifier = Modifier.padding(padding)
        ) {
            composable("home") { HomeScreen(userId = defaultUserId) }
            composable("add") { AddScreen { navController.popBackStack() } }
            composable("settings") { SettingsScreen() }
        }
    }
}