import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/wallet_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(),
);
