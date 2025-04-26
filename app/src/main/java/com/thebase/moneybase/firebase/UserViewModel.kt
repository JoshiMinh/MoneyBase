package com.thebase.moneybase.firebase

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.google.firebase.Timestamp
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * Represents a user profile in Firestore.
 */
data class User(
    val id: String = "",
    val displayName: String = "",
    val email: String = "",
    val createdAt: Timestamp = Timestamp.now(),
    val lastLoginAt: Timestamp = Timestamp.now(),
    val isPremium: Boolean = false,
    val language: String = "en",
    val profilePictureUrl: String = "",
    val theme: String = "light"
)

/**
 * ViewModel for loading & creating the Firestore User document.
 */
class UserViewModel(
    private val userRepository: UserRepository
) : ViewModel() {

    private val _user = MutableStateFlow<User?>(null)
    /** Current user data or null if not yet loaded. */
    val user: StateFlow<User?> = _user

    private val _error = MutableStateFlow<String?>(null)
    /** Emits any error message occurred during fetch/create. */
    val error: StateFlow<String?> = _error

    /**
     * Ensure a /users/{userId} document exists:
     * 1) Try to get it.
     * 2) If null, create it from FirebaseAuth.currentUser.
     * Updates [user] or [error] accordingly.
     */
    fun fetchUser(userId: String) {
        viewModelScope.launch {
            try {
                val existing = userRepository.getUser(userId)
                if (existing != null) {
                    _user.value = existing
                } else {
                    createUserFromAuth(userId)
                }
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    /**
     * One-off fetch, returning the User or null.
     */
    suspend fun getUser(userId: String): User? =
        userRepository.getUser(userId)

    /**
     * Pulls data from FirebaseAuth.currentUser and writes a new User doc.
     */
    private suspend fun createUserFromAuth(userId: String) {
        Firebase.auth.currentUser?.let { fUser ->
            val now = Timestamp.now()
            val newUser = User(
                id          = userId,
                displayName = fUser.displayName.orEmpty(),
                email       = fUser.email.orEmpty(),
                createdAt   = now,
                lastLoginAt = now,
                isPremium   = false,
                language    = "en",
                profilePictureUrl = fUser.photoUrl?.toString() ?: "",
                theme       = "light"
            )
            userRepository.createUser(newUser)
            _user.value = newUser
        } ?: run {
            _error.value = "No FirebaseAuth user available"
        }
    }
}

/**
 * Simple factory to provide UserRepository into UserViewModel.
 */
class UserViewModelFactory(
    private val userRepository: UserRepository
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(UserViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return UserViewModel(userRepository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}