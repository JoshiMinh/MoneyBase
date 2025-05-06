package com.thebase.moneybase.screens

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.filled.Download
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import coil.compose.rememberAsyncImagePainter
import com.thebase.moneybase.Routes
import com.thebase.moneybase.database.FirebaseRepositories
import com.thebase.moneybase.database.User
import com.thebase.moneybase.database.uploadImageToCloudinary
import com.thebase.moneybase.components.ChangePasswordDialog
import com.thebase.moneybase.components.EditProfileDialog
import com.thebase.moneybase.components.TimePickerDialog
import com.thebase.moneybase.notifications.NotificationHelper
import com.thebase.moneybase.ui.ColorScheme
import com.thebase.moneybase.ui.*
import com.thebase.moneybase.utils.CsvExporter
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    userId: String,
    currentScheme: ColorScheme,
    darkMode: Boolean,                          // ← new
    onLogout: () -> Unit,
    onColorSchemeChange: (ColorScheme) -> Unit,
    onDarkModeToggle: (Boolean) -> Unit,
    navController: NavController
) {
    // declare local state for which palette is selected
    var selectedScheme by remember { mutableStateOf(currentScheme) }
    val context = LocalContext.current
    val repo = remember { FirebaseRepositories() }
    var user by remember { mutableStateOf<User?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMsg by remember { mutableStateOf<String?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()

    // Notification helper
    val notificationHelper = remember { NotificationHelper(context) }
    
    // Notification settings state
    var notificationEnabled by remember { mutableStateOf(notificationHelper.isNotificationEnabled()) }
    var notificationHour by remember { mutableStateOf(notificationHelper.getNotificationHour()) }
    var notificationMinute by remember { mutableStateOf(notificationHelper.getNotificationMinute()) }
    var showTimePickerDialog by remember { mutableStateOf(false) }
    
    // Dialog states
    var showEditProfileDialog by remember { mutableStateOf(false) }
    var showChangePasswordDialog by remember { mutableStateOf(false) }
    var showPermissionDialog by remember { mutableStateOf(false) }
    
    // State để force refresh permissions
    var forceRefreshPermissions by remember { mutableStateOf(false) }
    
    // Notification settings
    LaunchedEffect(Unit) {
        notificationEnabled = notificationHelper.isNotificationEnabled()
        notificationHour = notificationHelper.getNotificationHour()
        notificationMinute = notificationHelper.getNotificationMinute()
        
        // Đồng bộ trạng thái thông báo từ cấp hệ thống
        if (notificationHelper.syncNotificationState()) {
            notificationEnabled = notificationHelper.isNotificationEnabled()
        }
    }
    
    // Theo dõi khi ứng dụng trở về từ cài đặt khác
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_RESUME) {
                // Khi từ cài đặt hệ thống quay lại, đồng bộ lại trạng thái thông báo
                if (notificationHelper.syncNotificationState()) {
                    notificationEnabled = notificationHelper.isNotificationEnabled()
                }
                
                // Làm mới trạng thái quyền
                // Chúng ta không thể làm mới permissions trực tiếp vì nó là remember state
                if (forceRefreshPermissions) {
                    forceRefreshPermissions = false
                } else {
                    forceRefreshPermissions = true
                }
            }
        }
        
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }
    
    // Launcher để xin quyền thông báo
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            // Quyền đã được cấp, kích hoạt thông báo
            notificationHelper.setNotificationEnabled(true)
            notificationEnabled = true
            coroutineScope.launch {
                snackbarHostState.showSnackbar("Notifications enabled")
            }
        } else {
            // Quyền bị từ chối
            notificationEnabled = false
            
            // Kiểm tra xem người dùng đã từ chối vĩnh viễn hay chưa
            val shouldShowRationale = androidx.core.app.ActivityCompat.shouldShowRequestPermissionRationale(
                context as androidx.activity.ComponentActivity, 
                Manifest.permission.POST_NOTIFICATIONS
            )
            
            if (!shouldShowRationale) {
                // Người dùng đã từ chối vĩnh viễn, hiển thị dialog hướng dẫn vào cài đặt
                showPermissionDialog = true
            } else {
                // Người dùng chỉ từ chối lần này
                coroutineScope.launch {
                    snackbarHostState.showSnackbar("Notifications need to be enabled")
                }
            }
        }
    }
    
    // Launcher để mở Gallery
    val pickImageLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        if (uri != null) {
            // Tải ảnh lên Cloudinary
            uploadImageToCloudinary(context, uri, userId, repo, coroutineScope, snackbarHostState) {
                // Cập nhật user state sau khi tải lên thành công
                coroutineScope.launch {
                    val updatedUser = repo.getUser(userId)
                    user = updatedUser
                }
            }
        }
    }

    LaunchedEffect(userId) {
        isLoading = true
        errorMsg = null
        try {
            val fetched = repo.getUser(userId)
            if (fetched != null) {
                user = fetched
            } else {
                errorMsg = "User data not found."
            }
        } catch (e: Exception) {
            errorMsg = e.localizedMessage ?: "Failed to load user"
        } finally {
            isLoading = false
        }
    }

    // Handle dialogs
    if (showEditProfileDialog) {
        EditProfileDialog(
            user = user,
            onDismiss = { showEditProfileDialog = false },
            onSave = { name ->
                coroutineScope.launch {
                    try {
                        isLoading = true
                        // Giữ nguyên email hiện tại
                        val email = user?.email ?: ""
                        val success = repo.updateUserProfile(userId, name, email)
                        if (success) {
                            // Refresh user data
                            val updatedUser = repo.getUser(userId)
                            user = updatedUser
                            snackbarHostState.showSnackbar("Profile updated successfully")
                        } else {
                            snackbarHostState.showSnackbar("Failed to update profile")
                        }
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Error: ${e.message}")
                    } finally {
                        isLoading = false
                    }
                }
                showEditProfileDialog = false
            }
        )
    }
    
    if (showChangePasswordDialog) {
        ChangePasswordDialog(
            onDismiss = { showChangePasswordDialog = false },
            onSave = { currentPassword, newPassword ->
                coroutineScope.launch {
                    try {
                        isLoading = true
                        val success = repo.updateUserPassword(userId, currentPassword, newPassword)
                        if (success) {
                            snackbarHostState.showSnackbar("Password changed successfully")
                        } else {
                            snackbarHostState.showSnackbar("Failed to change password")
                        }
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Error: ${e.message}")
                    } finally {
                        isLoading = false
                    }
                }
                showChangePasswordDialog = false
            }
        )
    }
    
    // Time Picker Dialog
    if (showTimePickerDialog) {
        TimePickerDialog(
            initialHour = notificationHour,
            initialMinute = notificationMinute,
            onDismiss = { showTimePickerDialog = false },
            onConfirm = { hour, minute ->
                notificationHour = hour
                notificationMinute = minute
                notificationHelper.setNotificationTime(hour, minute)
                showTimePickerDialog = false
            }
        )
    }
    
    // Permission Dialog
    if (showPermissionDialog) {
        AlertDialog(
            onDismissRequest = { showPermissionDialog = false },
            icon = { Icon(Icons.Default.Notifications, contentDescription = null) },
            title = {
                Text("Notifications need to be enabled")
            },
            text = {
                Column {
                    Text("To use the reminder feature, the app needs permission to send notifications. Please enable notifications in the app settings by:")
                    Spacer(Modifier.height(8.dp))
                    
                    Text("1. Press the \"Open settings\" button below")
                    Text("2. Select \"Notifications\" in the list of permissions")
                    Text("3. Turn on \"Allow notifications\"")
                    Text("4. Return to the app and turn on the reminder feature")
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        showPermissionDialog = false
                        // Mở cài đặt ứng dụng
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", context.packageName, null)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                    }
                ) {
                    Icon(
                        imageVector = Icons.Default.Settings,
                        contentDescription = null
                    )
                    Spacer(Modifier.width(8.dp))
                    Text("Open settings")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showPermissionDialog = false }
                ) {
                    Text("Later")
                }
            }
        )
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                when {
                    isLoading -> {
                        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    }
                    errorMsg != null -> {
                        Text(
                            text = errorMsg!!,
                            color = MaterialTheme.colorScheme.error,
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                    else -> {
                        // Profile card with elevation
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            elevation = CardDefaults.cardElevation(defaultElevation = 3.dp),
                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                            shape = MaterialTheme.shapes.medium
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    // Avatar cải thiện
                                    Box(
                                        modifier = Modifier
                                            .size(90.dp)
                                            .padding(4.dp)
                                            .border(
                                                width = 2.dp,
                                                color = MaterialTheme.colorScheme.primary,
                                                shape = CircleShape
                                            )
                                            .padding(4.dp)
                                            .background(
                                                color = MaterialTheme.colorScheme.surfaceVariant,
                                                shape = CircleShape
                                            )
                                            .clip(CircleShape)
                                            .clickable { pickImageLauncher.launch("image/*") },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        if (user?.profilePictureUrl.isNullOrEmpty()) {
                                            Icon(
                                                Icons.Default.AccountCircle,
                                                contentDescription = "Profile Picture",
                                                modifier = Modifier.size(50.dp),
                                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                                            )
                                        } else {
                                            Image(
                                                painter = rememberAsyncImagePainter(
                                                    model = user?.profilePictureUrl,
                                                    onError = {
                                                        android.util.Log.e("MoneyBase", "Error loading profile image: ${it.result.throwable.message}")
                                                    },
                                                    onSuccess = {
                                                        android.util.Log.d("MoneyBase", "Profile image loaded successfully")
                                                    }
                                                ),
                                                contentDescription = "Profile Picture",
                                                modifier = Modifier.fillMaxSize(),
                                                contentScale = ContentScale.Crop
                                            )
                                        }
                                    }
                                    
                                    Spacer(Modifier.width(16.dp))
                                    
                                    Column(modifier = Modifier.weight(1f)) {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            modifier = Modifier.fillMaxWidth()
                                        ) {
                                            Column(modifier = Modifier.weight(1f)) {
                                                Text(
                                                    text = user?.displayName ?: "Display Name",
                                                    style = MaterialTheme.typography.headlineMedium,
                                                    color = MaterialTheme.colorScheme.onBackground
                                                )
                                                
                                                Spacer(modifier = Modifier.height(4.dp))
                                                
                                                Row(
                                                    verticalAlignment = Alignment.CenterVertically
                                                ) {
                                                    Icon(
                                                        imageVector = Icons.Default.Email,
                                                        contentDescription = null,
                                                        modifier = Modifier.size(16.dp),
                                                        tint = MaterialTheme.colorScheme.primary
                                                    )
                                                    Spacer(modifier = Modifier.width(4.dp))
                                                    Text(
                                                        text = user?.email ?: "Email",
                                                        style = MaterialTheme.typography.bodyMedium,
                                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                                    )
                                                }
                                            }
                                            
                                            IconButton(
                                                onClick = { showEditProfileDialog = true },
                                                modifier = Modifier
                                                    .background(
                                                        color = MaterialTheme.colorScheme.primaryContainer,
                                                        shape = CircleShape
                                                    )
                                                    .size(40.dp)
                                            ) {
                                                Icon(
                                                    imageVector = Icons.Default.Edit,
                                                    contentDescription = "Edit Profile",
                                                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                                                )
                                            }
                                        }
                                    }
                                }
                                
                                if (user?.premium == true) {
                                    Spacer(Modifier.height(12.dp))
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .background(
                                                color = Color(0xFFFFF8E1),
                                                shape = MaterialTheme.shapes.small
                                            )
                                            .padding(12.dp)
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.Star,
                                            contentDescription = null,
                                            tint = Color(0xFFFFB300),
                                            modifier = Modifier.size(20.dp)
                                        )
                                        Spacer(Modifier.width(8.dp))
                                        Text(
                                            "Premium Account",
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = Color(0xFF7A5C00)
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(Modifier.height(8.dp))
                        
                        Divider(modifier = Modifier.padding(vertical = 16.dp))

                        // Account Settings Section
                        Text("Account Settings", style = MaterialTheme.typography.headlineMedium)
                        Spacer(Modifier.height(16.dp))
                        
                        // Change Password Button
                        OutlinedButton(
                            onClick = { showChangePasswordDialog = true },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Lock,
                                contentDescription = null
                            )
                            Spacer(Modifier.width(8.dp))
                            Text("Change Password")
                        }
                        
                        Spacer(Modifier.height(8.dp))
                        
                        // Export Transactions Button
                        val exportDirectoryPicker = rememberLauncherForActivityResult(
                            ActivityResultContracts.OpenDocumentTree()
                        ) { uri ->
                            if (uri != null) {
                                // Persist permission for later use
                                val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or 
                                              Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                                context.contentResolver.takePersistableUriPermission(uri, takeFlags)
                                
                                // Bắt đầu quá trình xuất dữ liệu
                                coroutineScope.launch {
                                    isLoading = true
                                    snackbarHostState.showSnackbar("Đang chuẩn bị xuất dữ liệu...")
                                    
                                    try {
                                        // Lấy danh sách giao dịch của người dùng
                                        val transactions = repo.getAllTransactions(userId)
                                        
                                        // Lấy danh sách categories và wallets
                                        val categories = repo.getAllCategories(userId)
                                        val wallets = repo.getAllWallets(userId)
                                        
                                        // Kiểm tra dữ liệu trước khi xuất
                                        if (transactions.isEmpty()) {
                                            snackbarHostState.showSnackbar("Không có giao dịch nào để xuất")
                                            return@launch
                                        }
                                        
                                        try {
                                            // Xuất ra CSV
                                            val fileUri = CsvExporter.exportTransactions(
                                                context, 
                                                transactions, 
                                                categories, 
                                                wallets, 
                                                uri
                                            )
                                            
                                            if (fileUri != null) {
                                                snackbarHostState.showSnackbar("Đã xuất thành công ra file CSV")
                                            } else {
                                                snackbarHostState.showSnackbar("Không thể xuất giao dịch, hãy thử lại")
                                            }
                                        } catch (e: Exception) {
                                            android.util.Log.e("SettingsScreen", "Lỗi xuất CSV: ${e.message}", e)
                                            snackbarHostState.showSnackbar("Lỗi: ${e.localizedMessage ?: "Không thể xuất file"}")
                                        }
                                    } catch (e: Exception) {
                                        snackbarHostState.showSnackbar("Lỗi: ${e.localizedMessage}")
                                    } finally {
                                        isLoading = false
                                    }
                                }
                            }
                        }
                        
                        OutlinedButton(
                            onClick = { exportDirectoryPicker.launch(null) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Download,
                                contentDescription = null
                            )
                            Spacer(Modifier.width(8.dp))
                            Text("Export Transactions to CSV")
                        }

                        Spacer(Modifier.height(24.dp))
                        
                        // Enable/Disable Notification
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Notifications,
                                contentDescription = null,
                                tint = if (notificationEnabled) 
                                    MaterialTheme.colorScheme.primary 
                                else 
                                    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                            )
                            Spacer(Modifier.width(16.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Expense Reminder",
                                    style = MaterialTheme.typography.bodyLarge
                                )
                                Text(
                                    text = if (notificationEnabled) 
                                        "On" 
                                    else 
                                        "Off",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = if (notificationEnabled) 
                                        MaterialTheme.colorScheme.primary 
                                    else 
                                        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                                )
                            }
                            Switch(
                                checked = notificationEnabled,
                                onCheckedChange = { isEnabled ->
                                    if (isEnabled) {
                                        // Kiểm tra quyền khi bật thông báo
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                            val hasPermission = context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == 
                                                android.content.pm.PackageManager.PERMISSION_GRANTED
                                            
                                            if (hasPermission) {
                                                // Đã có quyền, bật thông báo
                                                val success = notificationHelper.setNotificationEnabled(true)
                                                if (success) {
                                                    notificationEnabled = true
                                                } else {
                                                    // Thông báo bị tắt ở cấp hệ thống
                                                    coroutineScope.launch {
                                                        val result = snackbarHostState.showSnackbar(
                                                            message = "Cannot enable notifications because they are disabled at system level",
                                                            actionLabel = "Settings",
                                                            duration = androidx.compose.material3.SnackbarDuration.Long
                                                        )
                                                        
                                                        if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                                                            notificationHelper.openNotificationSettings()
                                                        }
                                                    }
                                                }
                                            } else {
                                                // Kiểm tra xem có nên hiển thị giải thích vì sao cần quyền không
                                                val shouldShowRationale = androidx.core.app.ActivityCompat.shouldShowRequestPermissionRationale(
                                                    context as androidx.activity.ComponentActivity,
                                                    Manifest.permission.POST_NOTIFICATIONS
                                                )
                                                
                                                if (shouldShowRationale) {
                                                    // Người dùng đã từ chối lần trước, hiển thị giải thích
                                                    coroutineScope.launch {
                                                        val result = snackbarHostState.showSnackbar(
                                                            message = "Notifications need to be enabled",
                                                            actionLabel = "Enable",
                                                            duration = androidx.compose.material3.SnackbarDuration.Long
                                                        )
                                                        if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                                                            permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                                        }
                                                    }
                                                } else {
                                                    // Đây là lần đầu tiên yêu cầu hoặc người dùng đã từ chối vĩnh viễn
                                                    // Thử yêu cầu quyền trực tiếp trước
                                                    permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                                }
                                            }
                                        } else {
                                            // Android < 13 không cần quyền riêng cho thông báo, nhưng vẫn cần kiểm tra cấp hệ thống
                                            val success = notificationHelper.setNotificationEnabled(true)
                                            if (success) {
                                                notificationEnabled = true
                                            } else {
                                                // Thông báo bị tắt ở cấp hệ thống
                                                coroutineScope.launch {
                                                    val result = snackbarHostState.showSnackbar(
                                                        message = "Cannot enable notifications because they are disabled at system level",
                                                        actionLabel = "Settings",
                                                        duration = androidx.compose.material3.SnackbarDuration.Long
                                                    )
                                                    
                                                    if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                                                        notificationHelper.openNotificationSettings()
                                                    }
                                                }
                                            }
                                        }
                                    } else {
                                        // Tắt thông báo
                                        notificationEnabled = false
                                        notificationHelper.setNotificationEnabled(false)
                                    }
                                }
                            )
                        }
                        
                        // Notification Time
                        AnimatedVisibility(visible = notificationEnabled) {
                            Column {
                                Spacer(Modifier.height(8.dp))
                                
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(start = 40.dp, top = 8.dp, bottom = 8.dp)
                                        .clickable { showTimePickerDialog = true },
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = "Reminder Time",
                                        style = MaterialTheme.typography.bodyMedium,
                                        modifier = Modifier.weight(1f)
                                    )
                                    
                                    val timeFormat = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }
                                    val calendar = remember { Calendar.getInstance() }
                                    calendar.set(Calendar.HOUR_OF_DAY, notificationHour)
                                    calendar.set(Calendar.MINUTE, notificationMinute)
                                    
                                    Text(
                                        text = timeFormat.format(calendar.time),
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                    
                                    Spacer(Modifier.width(8.dp))
                                    
                                    Icon(
                                        imageVector = Icons.Default.KeyboardArrowRight,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                        
                        Spacer(Modifier.height(24.dp))
                        
                        // App Settings Section
                        Text("App Settings", style = MaterialTheme.typography.headlineMedium)
                        Spacer(Modifier.height(16.dp))


                        // Dark Mode Toggle
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.DarkMode,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary
                            )
                            Spacer(Modifier.width(16.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text("Dark Mode", style = MaterialTheme.typography.bodyLarge)
                                Text(
                                    text = if (darkMode) "On" else "Off",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            Switch(
                                checked = darkMode,
                                onCheckedChange = onDarkModeToggle
                            )
                        }
                        Text("Select Color Scheme", style = MaterialTheme.typography.bodyLarge)
                        Spacer(Modifier.height(8.dp))

// Color Scheme Picker
                        Row(
                            Modifier
                                .horizontalScroll(rememberScrollState())
                                .padding(vertical = 8.dp)
                        ) {
                            ColorScheme.values().forEach { scheme ->
                                val isSelected = scheme == selectedScheme
                                val baseColor = getIconColorForScheme(scheme)
                                val displayColor = if (isSelected) baseColor.copy(alpha = 0.5f) else baseColor

                                IconButton(
                                    onClick = {
                                        selectedScheme = scheme
                                        onColorSchemeChange(scheme)
                                    },
                                    modifier = Modifier
                                        .padding(horizontal = 8.dp)
                                        .size(48.dp)
                                        .border(
                                            width = if (isSelected) 2.dp else 1.dp,
                                            color = if (isSelected)
                                                MaterialTheme.colorScheme.primary
                                            else Color.Gray,
                                            shape = CircleShape
                                        )
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxSize()
                                            .background(color = displayColor, shape = CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        if (isSelected) {
                                            Icon(
                                                imageVector = Icons.Default.Check,
                                                contentDescription = "Selected",
                                                tint = MaterialTheme.colorScheme.onPrimary
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        Spacer(Modifier.height(16.dp))
                        
                        // About Button
                        OutlinedButton(
                            onClick = { navController.navigate(Routes.ABOUT) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(
                                imageVector = Icons.Default.Info,
                                contentDescription = null
                            )
                            Spacer(Modifier.width(8.dp))
                            Text("About MoneyBase")
                        }
                        
                        Spacer(Modifier.height(16.dp))
                    }
                }
            }

            Column {
                Button(
                    onClick = onLogout,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer,
                        contentColor = MaterialTheme.colorScheme.onErrorContainer
                    ),
                    shape = MaterialTheme.shapes.medium
                ) {
                    Icon(
                        imageVector = Icons.Default.Logout,
                        contentDescription = null
                    )
                    Spacer(Modifier.width(8.dp))
                    Text("Logout")
                }

                Text(
                    "© 2025 MoneyBase",
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 16.dp),
                    style = MaterialTheme.typography.bodySmall,
                    textAlign = TextAlign.Center,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                )
            }
        }
    }
}