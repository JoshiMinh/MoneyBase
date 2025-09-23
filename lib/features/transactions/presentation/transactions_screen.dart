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
import '../../add_transaction/presentation/add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TransactionRepository _transactionRepository;
  late final WalletRepository _walletRepository;
  late final CategoryRepository _categoryRepository;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _transactionRepository = TransactionRepository();
    _walletRepository = WalletRepository();
    _categoryRepository = CategoryRepository();
  }

  String _formatDate(DateTime date) {
    final month = _months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month $day, $year';
  }

  String _formatAmount(MoneyBaseTransaction transaction) {
    final prefix = transaction.isIncome ? '+' : '-';
    final currency =
        transaction.currencyCode.isEmpty ? 'USD' : transaction.currencyCode;
    return '$prefix${currency.toUpperCase()} ${transaction.amount.toStringAsFixed(2)}';
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    String userId,
    MoneyBaseTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This will remove the transaction permanently from MoneyBase.',
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

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _transactionRepository.deleteTransaction(userId, transaction.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaction deleted.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $error')),
      );
    }
  }

  Future<void> _editTransaction(
    BuildContext context,
    String userId,
    MoneyBaseTransaction transaction,
    List<Wallet> wallets,
    List<Category> categories,
  ) async {
    final result = await showDialog<MoneyBaseTransaction>(
      context: context,
      builder: (context) => _TransactionDialog(
        initial: transaction,
        wallets: wallets,
        categories: categories,
      ),
    );

    if (result == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _transactionRepository.updateTransaction(userId, result);
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaction updated.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update transaction: $error')),
      );
    }
  }

  void _openAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AddTransactionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transactions')),
        body: const _CenteredMessage(
          message: 'Sign in to review your MoneyBase transactions.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
      body: StreamBuilder<List<Wallet>>(
        stream: _walletRepository.watchWallets(user.uid),
        builder: (context, walletSnapshot) {
          if (walletSnapshot.hasError) {
            return _CenteredMessage(
              message:
                  'Unable to load wallets: ${walletSnapshot.error}',
              isError: true,
            );
          }

          final wallets = walletSnapshot.data ?? const <Wallet>[];

          return StreamBuilder<List<Category>>(
            stream: _categoryRepository.watchCategories(user.uid),
            builder: (context, categorySnapshot) {
              if (categorySnapshot.hasError) {
                return _CenteredMessage(
                  message:
                      'Unable to load categories: ${categorySnapshot.error}',
                  isError: true,
                );
              }

              final categories = categorySnapshot.data ?? const <Category>[];

              return StreamBuilder<List<MoneyBaseTransaction>>(
                stream: _transactionRepository.watchTransactions(user.uid),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.hasError) {
                    return _CenteredMessage(
                      message:
                          'Unable to load transactions: ${transactionSnapshot.error}',
                      isError: true,
                    );
                  }

                  final transactions =
                      transactionSnapshot.data ?? const <MoneyBaseTransaction>[];
                  final loading =
                      transactionSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          transactions.isEmpty;

                  if (loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (transactions.isEmpty) {
                    return const _CenteredMessage(
                      message:
                          'No transactions yet. Capture a purchase to see it listed here.',
                    );
                  }

                  final walletById = {
                    for (final wallet in wallets) wallet.id: wallet,
                  };
                  final categoryById = {
                    for (final category in categories) category.id: category,
                  };

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final padding = EdgeInsets.symmetric(
                        horizontal: isWide ? 48 : 24,
                        vertical: 32,
                      );

                      if (isWide) {
                        return Center(
                          child: SingleChildScrollView(
                            padding: padding,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: DataTable(
                                  headingRowColor:
                                      WidgetStateProperty.resolveWith<Color?>(
                                    (_) => Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.4),
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Description')),
                                    DataColumn(label: Text('Category')),
                                    DataColumn(label: Text('Wallet')),
                                    DataColumn(
                                      label: Text('Amount'),
                                      numeric: true,
                                    ),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: transactions.map((transaction) {
                                    final rawCategoryName =
                                        categoryById[transaction.categoryId]?.name;
                                    final displayCategoryName =
                                        (rawCategoryName?.trim().isNotEmpty ?? false)
                                            ? rawCategoryName!
                                            : 'Uncategorised';
                                    final rawWalletName =
                                        walletById[transaction.walletId]?.name;
                                    final displayWalletName =
                                        (rawWalletName?.trim().isNotEmpty ?? false)
                                            ? rawWalletName!
                                            : 'Unknown wallet';

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(_formatDate(transaction.date)),
                                        ),
                                        DataCell(Text(transaction.description)),
                                        DataCell(
                                          Text(displayCategoryName),
                                        ),
                                        DataCell(
                                          Text(displayWalletName),
                                        ),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              _formatAmount(transaction),
                                              style: TextStyle(
                                                color: transaction.isIncome
                                                    ? Colors.teal
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit',
                                                icon:
                                                    const Icon(Icons.edit_outlined),
                                                onPressed: () => _editTransaction(
                                                  context,
                                                  user.uid,
                                                  transaction,
                                                  wallets,
                                                  categories,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete',
                                                icon: const Icon(
                                                    Icons.delete_outline),
                                                onPressed: () => _deleteTransaction(
                                                  context,
                                                  user.uid,
                                                  transaction,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: padding,
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final category = categoryById[transaction.categoryId];
                          final wallet = walletById[transaction.walletId];
                          final categoryName = category?.name;
                          final displayCategoryName =
                              (categoryName?.trim().isNotEmpty ?? false)
                                  ? categoryName!
                                  : 'Uncategorised';
                          final walletName = wallet?.name;
                          final displayWalletName =
                              (walletName?.trim().isNotEmpty ?? false)
                                  ? walletName!
                                  : 'Unknown wallet';
                          final amountColor = transaction.isIncome
                              ? Colors.teal
                              : Theme.of(context).colorScheme.error;
                          final icon = IconLibrary.iconForCategory(
                            category?.iconName,
                          );
                          final accent =
                              parseHexColor(category?.color) ?? amountColor;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: accent.withOpacity(0.18),
                              child: Icon(icon, color: accent),
                            ),
                            title: Text(transaction.description),
                            subtitle: Text(
                              '${_formatDate(transaction.date)} • '
                              '$displayWalletName • $displayCategoryName',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatAmount(transaction),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: amountColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _editTransaction(
                                        context,
                                        user.uid,
                                        transaction,
                                        wallets,
                                        categories,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteTransaction(
                                        context,
                                        user.uid,
                                        transaction,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color:
                    isError ? Theme.of(context).colorScheme.error : Colors.white,
              ),
        ),
      ),
    );
  }
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({
    required this.initial,
    required this.wallets,
    required this.categories,
  });

  final MoneyBaseTransaction initial;
  final List<Wallet> wallets;
  final List<Category> categories;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late DateTime _date;
  late bool _isIncome;
  String? _selectedWalletId;
  String? _selectedCategoryId;
  final _formKey = GlobalKey<FormState>();
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.initial.description);
    _amountController =
        TextEditingController(text: widget.initial.amount.toString());
    _date = widget.initial.date;
    _isIncome = widget.initial.isIncome;
    _selectedWalletId = widget.initial.walletId.isNotEmpty
        ? widget.initial.walletId
        : (widget.wallets.isNotEmpty ? widget.wallets.first.id : null);
    _selectedCategoryId = widget.initial.categoryId.isNotEmpty
        ? widget.initial.categoryId
        : (widget.categories.isNotEmpty ? widget.categories.first.id : null);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
    );

    if (result != null) {
      setState(() => _date = result);
    }
  }

  String _formatDate(DateTime date) {
    final month = _months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$month $day, $year';
  }

  @override
  Widget build(BuildContext context) {
    final wallets = widget.wallets;
    final categories = widget.categories;

    final walletItems = [
      for (final wallet in wallets)
        DropdownMenuItem<String>(
          value: wallet.id,
          child: Text(
            wallet.name.isNotEmpty ? wallet.name : 'Untitled wallet',
          ),
        ),
    ];

    final categoryItems = [
      for (final category in categories)
        DropdownMenuItem<String>(
          value: category.id,
          child: Text(
            category.name.isNotEmpty ? category.name : 'Untitled category',
          ),
        ),
    ];

    // Ensure the current values remain selectable even if the wallet/category
    // was deleted after the transaction was created.
    if (_selectedWalletId != null &&
        walletItems.every((item) => item.value != _selectedWalletId)) {
      walletItems.insert(
        0,
        DropdownMenuItem<String>(
          value: _selectedWalletId,
          child: Text('Unknown wallet (${_selectedWalletId!.substring(0, 5)}…)'),
        ),
      );
    }

    if (_selectedCategoryId != null &&
        categoryItems.every((item) => item.value != _selectedCategoryId)) {
      categoryItems.insert(
        0,
        DropdownMenuItem<String>(
          value: _selectedCategoryId,
          child:
              Text('Uncategorised (${_selectedCategoryId!.substring(0, 5)}…)'),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Edit transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an amount';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedWalletId,
                decoration: const InputDecoration(labelText: 'Wallet'),
                items: walletItems,
                onChanged: (value) => setState(() => _selectedWalletId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categoryItems,
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_formatDate(_date)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Expense')),
                  ButtonSegment(value: true, label: Text('Income')),
                ],
                selected: {_isIncome},
                onSelectionChanged: (selection) {
                  setState(() => _isIncome = selection.first);
                },
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
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            final amount = double.parse(_amountController.text.trim());
            final description = _descriptionController.text.trim();
            final walletId = _selectedWalletId ?? widget.initial.walletId;
            final categoryId = _selectedCategoryId ?? widget.initial.categoryId;
            final wallet = widget.wallets.firstWhere(
              (wallet) => wallet.id == walletId,
              orElse: () => widget.wallets.isNotEmpty
                  ? widget.wallets.first
                  : const Wallet(),
            );

            final updated = widget.initial.copyWith(
              description: description,
              amount: amount,
              walletId: walletId,
              categoryId: categoryId,
              date: _date,
              isIncome: _isIncome,
              currencyCode: wallet.currencyCode.isNotEmpty
                  ? wallet.currencyCode.toUpperCase()
                  : widget.initial.currencyCode,
            );

            Navigator.of(context).pop(updated);
          },
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}
