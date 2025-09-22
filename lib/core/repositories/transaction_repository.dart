import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction.dart';

class TransactionRepository {
  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _transactionsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  Stream<List<MoneyBaseTransaction>> watchTransactions(
    String userId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query =
        _transactionsRef(userId).orderBy('date', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MoneyBaseTransaction.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                }),
              )
              .toList(),
        );
  }

  Future<MoneyBaseTransaction> addTransaction(
    String userId,
    MoneyBaseTransaction transaction,
  ) async {
    final collection = _transactionsRef(userId);
    final doc = collection.doc();
    final entry = transaction.copyWith(
      id: doc.id,
      userId: userId,
      createdAt: transaction.createdAt,
    );
    await doc.set(entry.toJson());
    return entry;
  }

  Future<void> updateTransaction(
    String userId,
    MoneyBaseTransaction transaction,
  ) async {
    if (transaction.id.isEmpty) {
      throw ArgumentError('Transaction id is required for updates.');
    }

    await _transactionsRef(userId)
        .doc(transaction.id)
        .set(transaction.copyWith(userId: userId).toJson());
  }

  Future<void> deleteTransaction(String userId, String transactionId) {
    return _transactionsRef(userId).doc(transactionId).delete();
  }
}
