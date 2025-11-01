import 'dart:convert';

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

  Stream<ShoppingList?> watchShoppingList(String userId, String listId) {
    if (listId.isEmpty) {
      return const Stream<ShoppingList?>.empty();
    }

    return _listsRef(userId).doc(listId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return ShoppingList.fromJson({
        ...data,
        'id': snapshot.id,
        'userId': userId,
      });
    });
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

  Future<List<ShoppingItem>> fetchItems(String userId, String listId) async {
    final snapshot = await _itemsRef(userId, listId)
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map(
          (doc) => ShoppingItem.fromJson({
            ...doc.data(),
            'id': doc.id,
            'userId': userId,
            'listId': listId,
          }),
        )
        .toList();
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

  Future<ShoppingListImportSummary> importItemsFromJson({
    required String userId,
    required ShoppingList list,
    required String rawJson,
  }) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Import payload is empty.');
    }

    Map<String, dynamic> decodeRoot() {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Import payload must be a JSON object.');
      }
      return decoded;
    }

    List<dynamic> resolveResults(Map<String, dynamic> root) {
      final results = root['results'];
      if (results is! List) {
        throw const FormatException('Import payload is missing a results array.');
      }
      return results;
    }

    ShoppingItemPriority resolvePriority(String? value) {
      if (value == null) return ShoppingItemPriority.medium;
      final normalized = value.toLowerCase();
      if (normalized.isEmpty) return ShoppingItemPriority.medium;
      if (normalized.contains('high') ||
          normalized.contains('urgent') ||
          normalized.contains('critical') ||
          normalized.contains('top') ||
          normalized.contains('dream')) {
        return ShoppingItemPriority.high;
      }
      if (normalized.contains('low') ||
          normalized.contains('someday') ||
          normalized.contains('later') ||
          normalized.contains('wishlist')) {
        return ShoppingItemPriority.low;
      }
      return ShoppingItemPriority.medium;
    }

    bool resolveBought(Map<String, dynamic>? status) {
      final name = status?['name'] as String?;
      if (name == null) return false;
      final normalized = name.toLowerCase();
      const purchasedKeywords = <String>{
        'purchased',
        'bought',
        'done',
        'completed',
        'received',
        'acquired',
        'delivered',
        'ordered',
        'paid',
      };
      return purchasedKeywords.contains(normalized);
    }

    DateTime? parseDateProperty(Map<String, dynamic>? property) {
      if (property == null) return null;
      final date = property['date'];
      if (date is Map<String, dynamic>) {
        final start = date['start'] as String?;
        return start != null ? DateTime.tryParse(start) : null;
      }
      if (date is String) {
        return DateTime.tryParse(date);
      }
      return null;
    }

    String resolveTitle(Map<String, dynamic>? property) {
      if (property == null) return '';
      final titles = property['title'];
      if (titles is List) {
        for (final element in titles) {
          if (element is Map<String, dynamic>) {
            final text = element['plain_text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
      }
      return '';
    }

    double resolvePrice(Map<String, dynamic>? property) {
      if (property == null) return 0.0;
      final number = property['number'];
      if (number is num) {
        return number.toDouble();
      }
      return 0.0;
    }

    String? resolveImageUrl(Map<String, dynamic>? property) {
      if (property == null) return null;
      final files = property['files'];
      if (files is! List) return null;
      for (final entry in files) {
        if (entry is Map<String, dynamic>) {
          final type = entry['type'];
          if (type == 'external') {
            final external = entry['external'];
            if (external is Map<String, dynamic>) {
              final url = external['url'] as String?;
              if (url != null && url.trim().isNotEmpty) {
                return url.trim();
              }
            }
          } else if (type == 'file') {
            final file = entry['file'];
            if (file is Map<String, dynamic>) {
              final url = file['url'] as String?;
              if (url != null && url.trim().isNotEmpty) {
                return url.trim();
              }
            }
          }
        }
      }
      return null;
    }

    List<String> resolveRelationIds(Map<String, dynamic>? property) {
      if (property == null) return const [];
      final relations = property['relation'];
      if (relations is! List) return const [];
      return relations
          .whereType<Map<String, dynamic>>()
          .map((relation) => relation['id'] as String?)
          .whereType<String>()
          .toList(growable: false);
    }

    String? resolveEmoji(Map<String, dynamic>? icon) {
      if (icon == null) return null;
      final type = icon['type'];
      if (type == 'emoji') {
        return icon['emoji'] as String?;
      }
      return null;
    }

    final root = decodeRoot();
    final rawResults = resolveResults(root);
    if (rawResults.isEmpty) {
      return const ShoppingListImportSummary(totalItems: 0, importedItems: 0, skippedItems: 0);
    }

    final defaultCurrency = list.currency.isNotEmpty ? list.currency : 'USD';
    final pendingItems = <_PendingShoppingItem>[];
    var skipped = 0;

    for (final entry in rawResults) {
      if (entry is! Map<String, dynamic>) {
        skipped++;
        continue;
      }

      final notionId = entry['id'] as String?;
      if (notionId == null || notionId.isEmpty) {
        skipped++;
        continue;
      }

      final properties = entry['properties'];
      if (properties is! Map<String, dynamic>) {
        skipped++;
        continue;
      }

      final title = resolveTitle(properties['Name'] as Map<String, dynamic>?);
      if (title.isEmpty) {
        skipped++;
        continue;
      }

      final createdAt = DateTime.tryParse(entry['created_time'] as String? ?? '') ?? DateTime.now();
      final updatedAt = DateTime.tryParse(entry['last_edited_time'] as String? ?? '') ?? createdAt;

      final statusProperty = properties['Status'] as Map<String, dynamic>?;
      final statusValue = statusProperty != null
          ? statusProperty['status'] as Map<String, dynamic>?
          : null;

      final priorityProperty = properties['Priority'] as Map<String, dynamic>?;
      final priorityValue = priorityProperty != null
          ? priorityProperty['select'] as Map<String, dynamic>?
          : null;

      final purchaseProperty = properties['Purchase Date'] as Map<String, dynamic>?;
      final expiryProperty = properties['Expiry Date'] as Map<String, dynamic>?;

      final emoji = resolveEmoji(entry['icon'] as Map<String, dynamic>?);
      final imageUrl = resolveImageUrl(properties['Images'] as Map<String, dynamic>?);
      final relationParents =
          resolveRelationIds(properties['Parent item'] as Map<String, dynamic>?);
      final relationChildren =
          resolveRelationIds(properties['Sub-item'] as Map<String, dynamic>?);

      final price = resolvePrice(properties['Price'] as Map<String, dynamic>?);
      final item = ShoppingItem(
        title: title,
        bought: resolveBought(statusValue),
        priority: resolvePriority(priorityValue?['name'] as String?),
        price: price,
        currency: defaultCurrency,
        iconEmoji: emoji,
        iconUrl: imageUrl,
        purchaseDate: parseDateProperty(purchaseProperty),
        expiryDate: parseDateProperty(expiryProperty),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      pendingItems.add(
        _PendingShoppingItem(
          notionId: notionId,
          item: item,
          parentNotionIds: relationParents,
          childNotionIds: relationChildren,
        ),
      );
    }

    if (pendingItems.isEmpty) {
      return ShoppingListImportSummary(
        totalItems: rawResults.length,
        importedItems: 0,
        skippedItems: skipped,
      );
    }

    final itemsRef = _itemsRef(userId, list.id);
    final importedRecords = <String, _ImportedShoppingItem>{};

    for (final pending in pendingItems) {
      final doc = itemsRef.doc();
      final resolvedItem = pending.item.copyWith(
        id: doc.id,
        userId: userId,
        listId: list.id,
        createdAt: pending.item.createdAt,
        updatedAt: pending.item.updatedAt,
      );

      await doc.set(resolvedItem.toJson());

      importedRecords[pending.notionId] = _ImportedShoppingItem(
        notionId: pending.notionId,
        item: resolvedItem,
        reference: doc,
        parentNotionIds: pending.parentNotionIds,
        childNotionIds: pending.childNotionIds,
      );
    }

    if (importedRecords.isNotEmpty) {
      final aggregatedChildren = <String, Set<DocumentReference<Map<String, dynamic>>>>{};

      for (final record in importedRecords.values) {
        for (final parentId in record.parentNotionIds) {
          final parentRecord = importedRecords[parentId];
          if (parentRecord == null) continue;
          aggregatedChildren
              .putIfAbsent(parentId, () => <DocumentReference<Map<String, dynamic>>>{})
              .add(record.reference);
        }
      }

      for (final record in importedRecords.values) {
        DocumentReference<Map<String, dynamic>>? parentRef;
        if (record.parentNotionIds.isNotEmpty) {
          final parentRecord = importedRecords[record.parentNotionIds.first];
          parentRef = parentRecord?.reference;
        }

        final childRefs = <DocumentReference<Map<String, dynamic>>>{};
        for (final childId in record.childNotionIds) {
          final childRecord = importedRecords[childId];
          if (childRecord != null) {
            childRefs.add(childRecord.reference);
          }
        }
        final aggregated = aggregatedChildren[record.notionId];
        if (aggregated != null) {
          childRefs.addAll(aggregated);
        }

        if (parentRef != null || childRefs.isNotEmpty) {
          await record.reference.set({
            'relations': {
              'parentItemRef': parentRef,
              'subItemRefs': childRefs.toList(),
            },
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          }, SetOptions(merge: true));
        }
      }
    }

    final skippedItems = rawResults.length - pendingItems.length;

    return ShoppingListImportSummary(
      totalItems: rawResults.length,
      importedItems: importedRecords.length,
      skippedItems: skippedItems,
    );
  }
}

class ShoppingListImportSummary {
  const ShoppingListImportSummary({
    required this.totalItems,
    required this.importedItems,
    required this.skippedItems,
  });

  final int totalItems;
  final int importedItems;
  final int skippedItems;
}

class _PendingShoppingItem {
  _PendingShoppingItem({
    required this.notionId,
    required this.item,
    required this.parentNotionIds,
    required this.childNotionIds,
  });

  final String notionId;
  final ShoppingItem item;
  final List<String> parentNotionIds;
  final List<String> childNotionIds;
}

class _ImportedShoppingItem {
  _ImportedShoppingItem({
    required this.notionId,
    required this.item,
    required this.reference,
    required this.parentNotionIds,
    required this.childNotionIds,
  });

  final String notionId;
  final ShoppingItem item;
  final DocumentReference<Map<String, dynamic>> reference;
  final List<String> parentNotionIds;
  final List<String> childNotionIds;
}
