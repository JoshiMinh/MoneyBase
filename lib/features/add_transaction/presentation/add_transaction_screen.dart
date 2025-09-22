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
                      Text(
                        'Category',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (missingCategories)
                        const _InlineNotice(
                          message:
                              'Create a category from Settings to categorise this transaction.',
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
                              ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      Text(
                        'Wallet',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (missingWallets)
                        const _InlineNotice(
                          message:
                              'Add a wallet in Settings to track where the money moves.',
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
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

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
  });

  final Wallet wallet;
  final bool selected;
  final VoidCallback onTap;

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
