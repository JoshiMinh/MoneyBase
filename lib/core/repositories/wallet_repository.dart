import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wallet.dart';

class WalletRepository {
  WalletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _walletsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('wallets');
  }

  Stream<List<Wallet>> watchWallets(String userId) {
    return _walletsRef(userId)
        .orderBy('position')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
              (doc) => Wallet.fromJson({
                ...doc.data(),
                'id': doc.id,
                'userId': userId,
              }),
            )
            .toList());
  }

  Future<Wallet> addWallet(String userId, Wallet wallet) async {
    final collection = _walletsRef(userId);
    final doc = collection.doc();
    final sortPosition = wallet.position != 0
        ? wallet.position
        : DateTime.now().microsecondsSinceEpoch;
    final walletToSave =
        wallet.copyWith(id: doc.id, userId: userId, position: sortPosition);
    await doc.set(walletToSave.toJson());
    return walletToSave;
  }

  Future<void> updateWallet(String userId, Wallet wallet) async {
    if (wallet.id.isEmpty) {
      throw ArgumentError('Wallet id is required for updates.');
    }
    await _walletsRef(userId)
        .doc(wallet.id)
        .set(
          wallet
              .copyWith(
                userId: userId,
                position: wallet.position != 0
                    ? wallet.position
                    : DateTime.now().microsecondsSinceEpoch,
              )
              .toJson(),
        );
  }

  Future<void> deleteWallet(String userId, String walletId) {
    return _walletsRef(userId).doc(walletId).delete();
  }

  Future<void> reorderWallets(String userId, List<Wallet> wallets) async {
    final batch = _firestore.batch();
    for (var index = 0; index < wallets.length; index++) {
      final wallet = wallets[index];
      final position = index + 1;
      batch.set(
        _walletsRef(userId).doc(wallet.id),
        wallet.copyWith(position: position, userId: userId).toJson(),
      );
    }
    await batch.commit();
  }
}
