import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/icon_library.dart';
import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/repositories/wallet_repository.dart';
import '../../../core/utils/color_utils.dart';
import '../../common/presentation/moneybase_shell.dart';

enum _TransactionType { expense, income }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  _TransactionType _type = _TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedWalletId;
  bool _submitting = false;
  late final WalletRepository _walletRepository;
  late final CategoryRepository _categoryRepository;
  late final TransactionRepository _transactionRepository;

  @override
  void initState() {
    super.initState();
    _walletRepository = WalletRepository();
    _categoryRepository = CategoryRepository();
    _transactionRepository = TransactionRepository();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7B5BFF),
              surface: Color(0xFF1B1232),
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() => _selectedDate = result);
    }
  }

  String get _formattedDate {
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    return '$month/$day/$year';
  }

  void _syncSelections(List<Wallet> wallets, List<Category> categories) {
    String? walletId = _selectedWalletId;
    if (walletId == null && wallets.isNotEmpty) {
      walletId = wallets.first.id;
    } else if (walletId != null && wallets.every((wallet) => wallet.id != walletId)) {
      walletId = wallets.isNotEmpty ? wallets.first.id : null;
    }

    String? categoryId = _selectedCategoryId;
    if (categoryId == null && categories.isNotEmpty) {
      categoryId = categories.first.id;
    } else if (categoryId != null &&
        categories.every((category) => category.id != categoryId)) {
      categoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    if (walletId != _selectedWalletId || categoryId != _selectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedWalletId = walletId;
          _selectedCategoryId = categoryId;
        });
      });
    }
  }

  Future<void> _openWalletDialog(
    BuildContext context,
    String userId, {
    Wallet? wallet,
  }) async {
    final result = await showDialog<Wallet>(
      context: context,
      builder: (context) => _WalletDialog(initial: wallet),
    );

    if (result == null) {
      return;
    }

    try {
      if (wallet == null) {
        await _walletRepository.addWallet(userId, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet added successfully.')),
        );
      } else {
        await _walletRepository.updateWallet(userId, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet updated successfully.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save wallet: $error')),
      );
    }
  }

  Future<void> _confirmDeleteWallet(
    BuildContext context,
    String userId,
    Wallet wallet,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete wallet?'),
        content: Text(
          'This will remove "${wallet.name.isEmpty ? 'Untitled wallet' : wallet.name}" and any linked balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE54C4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _walletRepository.deleteWallet(userId, wallet.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete wallet: $error')),
      );
    }
  }

  Future<void> _openCategoryDialog(
    BuildContext context,
    String userId,
    List<Category> categories, {
    Category? category,
  }) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => _CategoryDialog(
        initial: category,
        categories: categories,
      ),
    );

    if (result == null) {
      return;
    }

    try {
      if (category == null) {
        await _categoryRepository.addCategory(userId, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully.')),
        );
      } else {
        await _categoryRepository.updateCategory(userId, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save category: $error')),
      );
    }
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    String userId,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'This will remove "${category.name.isEmpty ? 'Untitled category' : category.name}" from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE54C4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _categoryRepository.deleteCategory(userId, category.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete category: $error')),
      );
    }
  }

  Future<void> _showWalletActions(
    BuildContext context,
    String userId,
    Wallet wallet,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit wallet'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openWalletDialog(context, userId, wallet: wallet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete wallet'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeleteWallet(context, userId, wallet);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCategoryActions(
    BuildContext context,
    String userId,
    List<Category> categories,
    Category category,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit category'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openCategoryDialog(
                    context,
                    userId,
                    categories,
                    category: category,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete category'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDeleteCategory(context, userId, category);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    String userId,
    List<Wallet> wallets,
    List<Category> categories,
  ) async {
    if (_submitting) {
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than zero.')),
      );
      return;
    }

    final walletId = _selectedWalletId;
    final categoryId = _selectedCategoryId;

    if (walletId == null || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both a wallet and category.')),
      );
      return;
    }

    final wallet = wallets.firstWhere((element) => element.id == walletId);
    final description = _noteController.text.trim();
    final currency = wallet.currencyCode.isNotEmpty
        ? wallet.currencyCode.toUpperCase()
        : 'USD';

    final transaction = MoneyBaseTransaction(
      description: description.isEmpty ? 'Transaction' : description,
      amount: amount,
      currencyCode: currency,
      isIncome: _type == _TransactionType.income,
      categoryId: categoryId,
      walletId: walletId,
      date: _selectedDate,
    );

    setState(() => _submitting = true);

    try {
      await _transactionRepository.addTransaction(userId, transaction);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _noteController.clear();
        _amountController.clear();
        _type = _TransactionType.expense;
        _selectedDate = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transaction: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return MoneyBaseScaffold(
        builder: (context, layout) {
          return Center(
            child: Text(
              'Sign in to create and sync transactions.',
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
    }

    return MoneyBaseScaffold(
      maxContentWidth: 960,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      builder: (context, layout) {
        return StreamBuilder<List<Wallet>>(
          stream: _walletRepository.watchWallets(user.uid),
          builder: (context, walletSnapshot) {
            final wallets = walletSnapshot.data ?? const <Wallet>[];
            final walletLoading =
                walletSnapshot.connectionState == ConnectionState.waiting &&
                    wallets.isEmpty;
            final walletError = walletSnapshot.error;

            return StreamBuilder<List<Category>>(
              stream: _categoryRepository.watchCategories(user.uid),
              builder: (context, categorySnapshot) {
                final categories = categorySnapshot.data ?? const <Category>[];
                final categoryLoading =
                    categorySnapshot.connectionState == ConnectionState.waiting &&
                        categories.isEmpty;
                final categoryError = categorySnapshot.error;

                final loading = walletLoading || categoryLoading;
                final errorMessage =
                    walletError?.toString() ?? categoryError?.toString();

                _syncSelections(wallets, categories);

                Widget panelChild;
                if (errorMessage != null) {
                  panelChild = _InlineNotice(
                    message:
                        'Unable to load your MoneyBase data. Please try again.\nDetails: $errorMessage',
                    isError: true,
                  );
                } else if (loading) {
                  panelChild = const Center(child: CircularProgressIndicator());
                } else {
                  final missingWallets = wallets.isEmpty;
                  final missingCategories = categories.isEmpty;
                  final canSubmit = !missingWallets && !missingCategories;

                  final selectedWallet = !missingWallets
                      ? wallets.firstWhere(
                          (wallet) => wallet.id == _selectedWalletId,
                          orElse: () => wallets.first,
                        )
                      : const Wallet();
                  final currencyPrefix = selectedWallet.currencyCode.isEmpty
                      ? 'USD'
                      : selectedWallet.currencyCode.toUpperCase();

                  panelChild = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction type',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_TransactionType>(
                        segments: const [
                          ButtonSegment(
                            value: _TransactionType.expense,
                            label: Text('Expense'),
                            icon: Icon(Icons.south_east),
                          ),
                          ButtonSegment(
                            value: _TransactionType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.north_east),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (selection) {
                          setState(() => _type = selection.first);
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.08),
                          foregroundColor: Colors.white.withOpacity(0.72),
                          selectedForegroundColor: Colors.white,
                          selectedBackgroundColor:
                              const Color(0xFF7B5BFF).withOpacity(0.65),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          textStyle: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _GlassField(
                        label: 'Date',
                        onTap: () => _pickDate(context),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formattedDate,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _GlassField(
                        label: 'Note',
                        child: TextField(
                          controller: _noteController,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration.collapsed(
                            hintText: 'Enter a note',
                            hintStyle: textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _GlassField(
                        label: 'Amount',
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                currencyPrefix,
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration.collapsed(
                                  hintText: 'Enter amount',
                                  hintStyle: textTheme.headlineSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Text(
                            'Categories',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => _openCategoryDialog(
                              context,
                              user.uid,
                              categories,
                            ),
                            icon: const Icon(Icons.category_outlined),
                            label: const Text('New category'),
                          ),
                        ],
                      ),
                      if (!missingCategories) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Long press a category to edit or remove it.',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (missingCategories)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _InlineNotice(
                              message:
                                  'Create a category to organise this transaction.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => _openCategoryDialog(
                                context,
                                user.uid,
                                categories,
                              ),
                              icon: const Icon(Icons.add_outlined),
                              label: const Text('Create category'),
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final category in categories)
                              _CategoryChip(
                                category: category,
                                selected: category.id == _selectedCategoryId,
                                onTap: () =>
                                    setState(() => _selectedCategoryId = category.id),
                                onLongPress: () => _showCategoryActions(
                                  context,
                                  user.uid,
                                  categories,
                                  category,
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Text(
                            'Wallets',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => _openWalletDialog(
                              context,
                              user.uid,
                            ),
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            label: const Text('New wallet'),
                          ),
                        ],
                      ),
                      if (!missingWallets) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Long press a wallet to edit or remove it.',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (missingWallets)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _InlineNotice(
                              message:
                                  'Add a wallet to track where the money moves.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => _openWalletDialog(
                                context,
                                user.uid,
                              ),
                              icon: const Icon(Icons.add_outlined),
                              label: const Text('Create wallet'),
                            ),
                          ],
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final wallet in wallets) ...[
                                _WalletCard(
                                  wallet: wallet,
                                  selected: wallet.id == _selectedWalletId,
                                  onTap: () =>
                                      setState(() => _selectedWalletId = wallet.id),
                                  onLongPress: () =>
                                      _showWalletActions(context, user.uid, wallet),
                                ),
                                const SizedBox(width: 16),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: const Color(0xFF7B5BFF),
                                foregroundColor: Colors.white,
                                textStyle: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: canSubmit && !_submitting
                                  ? () => _handleSubmit(
                                        context,
                                        user.uid,
                                        wallets,
                                        categories,
                                      )
                                  : null,
                              child: _submitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Submit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add transaction',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture new spending in the refreshed MoneyBase glass surface shared between Android and web.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    MoneyBaseFrostedPanel(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.isWide ? 36 : 28,
                        vertical: layout.isWide ? 36 : 28,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 32,
                          offset: Offset(0, 24),
                        ),
                      ],
                      child: panelChild,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              color: Colors.white.withOpacity(0.06),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = IconLibrary.iconForCategory(category.iconName);
    final accent = parseHexColor(category.color);
    final label =
        category.name.isNotEmpty ? category.name : 'Untitled category';

    final borderColor =
        selected ? (accent ?? Colors.white) : Colors.white.withOpacity(0.18);
    final backgroundColor = selected
        ? (accent ?? Colors.white).withOpacity(0.18)
        : Colors.white.withOpacity(0.05);

    final Color iconColor;
    if (accent != null) {
      iconColor = selected ? Colors.white : accent.withOpacity(0.9);
    } else {
      iconColor = selected ? Colors.white : Colors.white.withOpacity(0.75);
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          color: backgroundColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final Wallet wallet;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = parseHexColor(wallet.color) ?? const Color(0xFF7B5BFF);
    final gradient = [
      accent,
      Color.lerp(accent, Colors.black, 0.3)!,
    ];
    final icon = IconLibrary.iconForWallet(wallet.iconName);
    final name = wallet.name.isNotEmpty ? wallet.name : 'Untitled wallet';
    final balanceText = wallet.balance == 0
        ? 'Balance not set'
        : '${wallet.currencyCode.isEmpty ? 'USD' : wallet.currencyCode.toUpperCase()} ${wallet.balance.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              balanceText,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final background =
        isError ? const Color(0x44E54C4C) : Colors.white.withOpacity(0.06);
    final borderColor =
        isError ? const Color(0x66E54C4C) : Colors.white.withOpacity(0.12);
    final textColor =
        isError ? Colors.white : Colors.white.withOpacity(0.78);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
            ),
      ),
    );
  }
}

String _walletTypeLabel(WalletType type) {
  switch (type) {
    case WalletType.physical:
      return 'Physical';
    case WalletType.bankAccount:
      return 'Bank account';
    case WalletType.crypto:
      return 'Crypto';
    case WalletType.investment:
      return 'Investment';
    case WalletType.other:
      return 'Other';
  }
}

class _WalletDialog extends StatefulWidget {
  const _WalletDialog({this.initial});

  final Wallet? initial;

  @override
  State<_WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<_WalletDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _colorController;
  late final TextEditingController _currencyController;
  late WalletType _selectedType;
  late String _selectedIconName;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    final initialBalance = widget.initial?.balance ?? 0;
    _balanceController = TextEditingController(
      text: initialBalance == 0 ? '' : initialBalance.toString(),
    );
    _colorController = TextEditingController(text: widget.initial?.color ?? '');
    _currencyController =
        TextEditingController(text: widget.initial?.currencyCode ?? 'USD');
    _selectedType = widget.initial?.type ?? WalletType.physical;
    final initialIcon = widget.initial?.iconName ?? 'account_balance_wallet';
    _selectedIconName = IconLibrary.walletIcons.containsKey(initialIcon)
        ? initialIcon
        : IconLibrary.walletIcons.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _colorController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final balanceText = _balanceController.text.trim();
    final balance = balanceText.isEmpty ? 0.0 : double.parse(balanceText);
    final iconName = _selectedIconName;
    final color = _colorController.text.trim();
    final currency = _currencyController.text.trim().isEmpty
        ? 'USD'
        : _currencyController.text.trim().toUpperCase();

    final wallet = (widget.initial ?? const Wallet()).copyWith(
      name: name,
      balance: balance,
      iconName: iconName,
      color: color,
      type: _selectedType,
      currencyCode: currency,
    );

    Navigator.of(context).pop(wallet);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit wallet' : 'New wallet'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a wallet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WalletType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final type in WalletType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(_walletTypeLabel(type)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currencyController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Currency code'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a currency code';
                  }
                  if (value.trim().length != 3) {
                    return 'Currency codes are 3 letters (e.g. USD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Balance (optional)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _IconChooser(
                label: 'Icon',
                options: IconLibrary.walletOptions(),
                selected: _selectedIconName,
                onSelected: (value) => setState(() => _selectedIconName = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color hex (optional)',
                  hintText: '#7B5BFF',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save changes' : 'Create'),
        ),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.initial, required this.categories});

  final Category? initial;
  final List<Category> categories;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _colorController;
  late String _selectedIconName;
  String? _parentCategoryId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _colorController = TextEditingController(text: widget.initial?.color ?? '');
    _parentCategoryId = widget.initial?.parentCategoryId;
    final initialIcon = widget.initial?.iconName ?? 'shopping_bag';
    _selectedIconName = IconLibrary.categoryIcons.containsKey(initialIcon)
        ? initialIcon
        : IconLibrary.categoryIcons.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final iconName = _selectedIconName;
    final color = _colorController.text.trim();

    final category = (widget.initial ?? const Category()).copyWith(
      name: name,
      iconName: iconName,
      color: color,
      parentCategoryId: _parentCategoryId,
    );

    Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    final parentOptions = widget.categories
        .where((category) => category.id != widget.initial?.id)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      title: Text(isEditing ? 'Edit category' : 'New category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _IconChooser(
                label: 'Icon',
                options: IconLibrary.categoryOptions(),
                selected: _selectedIconName,
                onSelected: (value) => setState(() => _selectedIconName = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color hex (optional)',
                  hintText: '#FF6D8D',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _parentCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Parent category (optional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None'),
                  ),
                  for (final category in parentOptions)
                    DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(
                        category.name.isNotEmpty
                            ? category.name
                            : 'Untitled category',
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _parentCategoryId = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save changes' : 'Create'),
        ),
      ],
    );
  }
}

class _IconChooser extends StatelessWidget {
  const _IconChooser({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Iterable<MapEntry<String, IconData>> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedLabel = selected.replaceAll('_', ' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedLabel,
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in options)
              _IconChoice(
                name: entry.key,
                icon: entry.value,
                selected: entry.key == selected,
                onTap: () => onSelected(entry.key),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = selected
        ? Colors.white.withOpacity(0.24)
        : Colors.white.withOpacity(0.08);
    final borderColor = selected
        ? colorScheme.primary
        : Colors.white.withOpacity(0.16);

    return Tooltip(
      message: name.replaceAll('_', ' '),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            color: background,
          ),
          child: Icon(
            icon,
            color: selected ? colorScheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}
