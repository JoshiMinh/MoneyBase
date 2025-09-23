import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/shopping_item.dart';
import '../models/shopping_list.dart';

class ShoppingListRepository {
  ShoppingListRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _listsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('shopping_lists');
  }

  CollectionReference<Map<String, dynamic>> _itemsRef(
    String userId,
    String listId,
  ) {
    if (listId.isEmpty) {
      throw ArgumentError('listId must be provided to access shopping items.');
    }
    return _listsRef(userId).doc(listId).collection('shopping_items');
  }

  Stream<List<ShoppingList>> watchShoppingLists(String userId) {
    return _listsRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ShoppingList.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                }),
              )
              .toList(),
        );
  }

  Future<ShoppingList> addShoppingList(String userId, ShoppingList list) async {
    final ref = _listsRef(userId).doc();
    final now = DateTime.now();
    final entry = list.copyWith(
      id: ref.id,
      userId: userId,
      createdAt: now,
    );
    await ref.set(entry.toJson());
    return entry;
  }

  Future<void> updateShoppingList(String userId, ShoppingList list) async {
    if (list.id.isEmpty) {
      throw ArgumentError('Shopping list id is required for updates.');
    }

    await _listsRef(userId)
        .doc(list.id)
        .set(list.copyWith(userId: userId).toJson(), SetOptions(merge: true));
  }

  Future<void> deleteShoppingList(String userId, String listId) async {
    final itemsSnapshot = await _itemsRef(userId, listId).get();
    final batch = _firestore.batch();

    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_listsRef(userId).doc(listId));
    await batch.commit();
  }

  Stream<List<ShoppingItem>> watchItems(String userId, String listId) {
    return _itemsRef(userId, listId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ShoppingItem.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                  'listId': listId,
                }),
              )
              .toList(),
        );
  }

  Future<ShoppingItem> addItem(
    String userId,
    String listId,
    ShoppingItem item,
  ) async {
    final ref = _itemsRef(userId, listId).doc();
    final now = DateTime.now();
    final entry = item.copyWith(
      id: ref.id,
      userId: userId,
      listId: listId,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(entry.toJson());
    return entry;
  }

  Future<void> updateItem(
    String userId,
    String listId,
    ShoppingItem item,
  ) async {
    if (item.id.isEmpty) {
      throw ArgumentError('Shopping item id is required for updates.');
    }

    final updated = item.copyWith(
      userId: userId,
      listId: listId,
      updatedAt: DateTime.now(),
    );

    await _itemsRef(userId, listId)
        .doc(item.id)
        .set(updated.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteItem(String userId, String listId, String itemId) async {
    await _itemsRef(userId, listId).doc(itemId).delete();
  }

  Future<void> setItemBought(
    String userId,
    String listId,
    String itemId,
    bool bought,
  ) async {
    await _itemsRef(userId, listId).doc(itemId).update({
      'bought': bought,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
