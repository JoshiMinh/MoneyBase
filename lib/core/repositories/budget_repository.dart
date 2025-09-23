import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget.dart';

class BudgetRepository {
  BudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _budgetsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  Stream<List<Budget>> watchBudgets(String userId) {
    return _budgetsRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Budget.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                }),
              )
              .toList(),
        );
  }

  Future<Budget> addBudget(String userId, Budget budget) async {
    final ref = _budgetsRef(userId).doc();
    final now = DateTime.now();
    final entry = budget.copyWith(
      id: ref.id,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(entry.toJson());
    return entry;
  }

  Future<void> updateBudget(String userId, Budget budget) async {
    if (budget.id.isEmpty) {
      throw ArgumentError('Budget id is required for updates.');
    }

    final entry = budget.copyWith(
      userId: userId,
      updatedAt: DateTime.now(),
    );

    await _budgetsRef(userId)
        .doc(budget.id)
        .set(entry.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteBudget(String userId, String budgetId) async {
    await _budgetsRef(userId).doc(budgetId).delete();
  }
}
