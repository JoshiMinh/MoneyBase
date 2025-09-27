package com.thebase.moneybase.database.extensions

import com.google.firebase.firestore.CollectionReference
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.FirebaseFirestore

internal fun FirebaseFirestore.userDocument(userId: String): DocumentReference =
    collection("users").document(userId)

internal fun FirebaseFirestore.userCollection(
    userId: String,
    collectionPath: String
): CollectionReference = userDocument(userId).collection(collectionPath)

internal fun FirebaseFirestore.userCategories(userId: String): CollectionReference =
    userCollection(userId, "categories")

internal fun FirebaseFirestore.userWallets(userId: String): CollectionReference =
    userCollection(userId, "wallets")

internal fun FirebaseFirestore.userTransactions(userId: String): CollectionReference =
    userCollection(userId, "transactions")
