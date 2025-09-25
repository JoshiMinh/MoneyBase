import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _categoriesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  Stream<List<Category>> watchCategories(String userId) {
    return _categoriesRef(userId).snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map(
            (doc) => Category.fromJson({
              ...doc.data(),
              'id': doc.id,
              'userId': userId,
            }),
          )
          .toList();

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
    await doc.set(categoryToSave.toJson());
    return categoryToSave;
  }

  Future<void> updateCategory(String userId, Category category) async {
    if (category.id.isEmpty) {
      throw ArgumentError('Category id is required for updates.');
    }
    await _categoriesRef(userId)
        .doc(category.id)
        .set(category.copyWith(userId: userId).toJson());
  }

  Future<void> deleteCategory(String userId, String categoryId) {
    return _categoriesRef(userId).doc(categoryId).delete();
  }
}
