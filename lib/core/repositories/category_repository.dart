import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _categoriesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  Map<String, dynamic> _writePayload(String userId, Category category) {
    return category.toFirestoreMap(userIdOverride: userId);
  }

  Stream<List<Category>> watchCategories(String userId) {
    return _categoriesRef(userId).snapshots().map((snapshot) {
      final categories = snapshot.docs.map((doc) {
        final raw = Map<String, dynamic>.from(doc.data());
        final storedUserId = (raw['userId'] as String?)?.trim();
        raw
          ..remove('id')
          ..remove('userId');
        return Category.fromJson({
          ...raw,
          'id': doc.id,
          'userId': storedUserId?.isNotEmpty == true ? storedUserId : userId,
        });
      }).toList();

      categories.sort((a, b) {
        final nameComparison = a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            );
        if (nameComparison != 0) {
          return nameComparison;
        }
        return a.id.compareTo(b.id);
      });

      return categories;
    });
  }

  Future<Category> addCategory(String userId, Category category) async {
    final collection = _categoriesRef(userId);
    final doc = collection.doc();
    final categoryToSave = category.copyWith(id: doc.id, userId: userId);
    await doc.set(_writePayload(userId, categoryToSave));
    return categoryToSave;
  }

  Future<void> updateCategory(String userId, Category category) async {
    if (category.id.isEmpty) {
      throw ArgumentError('Category id is required for updates.');
    }
    final payload = _writePayload(userId, category.copyWith(userId: userId));
    await _categoriesRef(userId).doc(category.id).set(payload);
  }

  Future<void> deleteCategory(String userId, String categoryId) {
    return _categoriesRef(userId).doc(categoryId).delete();
  }
}
