import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme.dart';
import '../../../core/constants/icon_library.dart';
import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/repositories/wallet_repository.dart';
import '../../../core/utils/color_utils.dart';
import '../../common/presentation/moneybase_shell.dart';

class TransactionEditorArguments {
  TransactionEditorArguments({
    required this.transaction,
    required this.wallets,
    required this.categories,
  });

  final MoneyBaseTransaction transaction;
  final List<Wallet> wallets;
  final List<Category> categories;
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

enum _TransactionTypeFilter { all, expenses, income }

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TransactionRepository _transactionRepository;
  late final WalletRepository _walletRepository;
  late final CategoryRepository _categoryRepository;

  static const String _kAllFilterValue = '__all__';

  final TextEditingController _searchController = TextEditingController();
  _TransactionTypeFilter _typeFilter = _TransactionTypeFilter.all;
  String _walletFilter = _kAllFilterValue;
  String _categoryFilter = _kAllFilterValue;
  String _searchTerm = '';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _resetFilters() {
    setState(() {
      _typeFilter = _TransactionTypeFilter.all;
      _walletFilter = _kAllFilterValue;
      _categoryFilter = _kAllFilterValue;
      _searchTerm = '';
    });
    _searchController.clear();
  }

  void _clearSearch() {
    setState(() {
      _searchTerm = '';
    });
    _searchController.clear();
  }

  List<MoneyBaseTransaction> _applyFilters(
    List<MoneyBaseTransaction> transactions,
    Map<String, Wallet> walletById,
    Map<String, Category> categoryById,
  ) {
    final query = _searchTerm.trim().toLowerCase();

    return transactions.where((transaction) {
      if (_typeFilter == _TransactionTypeFilter.expenses &&
          transaction.isIncome) {
        return false;
      }
      if (_typeFilter == _TransactionTypeFilter.income &&
          !transaction.isIncome) {
        return false;
      }
      if (_walletFilter != _kAllFilterValue &&
          transaction.walletId != _walletFilter) {
        return false;
      }
      if (_categoryFilter != _kAllFilterValue &&
          transaction.categoryId != _categoryFilter) {
        return false;
      }

      if (query.isNotEmpty) {
        final walletName = walletById[transaction.walletId]?.name ?? '';
        final categoryName = categoryById[transaction.categoryId]?.name ?? '';
        final haystack =
            '${transaction.description} $walletName $categoryName'.toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _resolveCurrencyCode(MoneyBaseTransaction transaction) {
    final code = transaction.currencyCode.trim();
    if (code.isEmpty) {
      return 'USD';
    }
    return code.toUpperCase();
  }

  String _formatSummaryAmount(
    double amount,
    Set<String> currencies, {
    bool signed = false,
  }) {
    final sign = signed && amount != 0
        ? (amount >= 0 ? '+' : '-')
        : '';
    final magnitude = amount.abs().toStringAsFixed(2);
    if (currencies.isEmpty) {
      return '$sign$magnitude';
    }
    if (currencies.length == 1) {
      final currency = currencies.first;
      return '$sign$currency $magnitude';
    }
    return '$sign$magnitude';
  }

  String _walletNameFor(List<Wallet> wallets, String walletId) {
    for (final wallet in wallets) {
      if (wallet.id == walletId) {
        final name = wallet.name?.trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
        break;
      }
    }
    return 'Wallet';
  }

  String _categoryNameFor(List<Category> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        final name = category.name?.trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
        break;
      }
    }
    return 'Category';
  }

  Widget _buildFilterPanel(
    BuildContext context,
    MoneyBaseLayout layout,
    List<Wallet> wallets,
    List<Category> categories,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.moneyBaseColors;
    final hasActiveFilters = _typeFilter != _TransactionTypeFilter.all ||
        _walletFilter != _kAllFilterValue ||
        _categoryFilter != _kAllFilterValue ||
        _searchTerm.isNotEmpty;

    Widget buildSearchField() {
      return TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchTerm = value),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearSearch,
                )
              : null,
          hintText: 'Search description, wallet, or category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
    }

    Widget buildWalletDropdown() {
      return DropdownButtonFormField<String>(
        value: _walletFilter,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() => _walletFilter = value);
        },
        decoration: InputDecoration(
          labelText: 'Wallet',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        items: [
          const DropdownMenuItem(
            value: _kAllFilterValue,
            child: Text('All wallets'),
          ),
          ...wallets.map(
            (wallet) => DropdownMenuItem(
              value: wallet.id,
              child: Text(_walletNameFor(wallets, wallet.id)),
            ),
          ),
        ],
      );
    }

    Widget buildCategoryDropdown() {
      return DropdownButtonFormField<String>(
        value: _categoryFilter,
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() => _categoryFilter = value);
        },
        decoration: InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        items: [
          const DropdownMenuItem(
            value: _kAllFilterValue,
            child: Text('All categories'),
          ),
          ...categories.map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(_categoryNameFor(categories, category.id)),
            ),
          ),
        ],
      );
    }

    final filterControls = layout.isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildSearchField()),
              const SizedBox(width: 16),
              SizedBox(width: 220, child: buildWalletDropdown()),
              const SizedBox(width: 16),
              SizedBox(width: 220, child: buildCategoryDropdown()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSearchField(),
              const SizedBox(height: 12),
              buildWalletDropdown(),
              const SizedBox(height: 12),
              buildCategoryDropdown(),
            ],
          );

    final activeFilterChips = <Widget>[];
    if (_walletFilter != _kAllFilterValue) {
      activeFilterChips.add(
        Chip(
          label: Text(_walletNameFor(wallets, _walletFilter)),
          onDeleted: () => setState(() => _walletFilter = _kAllFilterValue),
        ),
      );
    }
    if (_categoryFilter != _kAllFilterValue) {
      activeFilterChips.add(
        Chip(
          label: Text(_categoryNameFor(categories, _categoryFilter)),
          onDeleted: () => setState(() => _categoryFilter = _kAllFilterValue),
        ),
      );
    }
    if (_searchTerm.isNotEmpty) {
      activeFilterChips.add(
        Chip(
          label: Text('“$_searchTerm”'),
          onDeleted: _clearSearch,
        ),
      );
    }

    return MoneyBaseFrostedPanel(
      padding: EdgeInsets.symmetric(
        horizontal: layout.isWide ? 32 : 22,
        vertical: layout.isWide ? 32 : 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter transactions',
            style: textTheme.titleMedium?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          filterControls,
          const SizedBox(height: 16),
          SegmentedButton<_TransactionTypeFilter>(
            segments: const [
              ButtonSegment(
                value: _TransactionTypeFilter.all,
                icon: Icon(Icons.all_inclusive),
                label: Text('All'),
              ),
              ButtonSegment(
                value: _TransactionTypeFilter.expenses,
                icon: Icon(Icons.trending_down),
                label: Text('Expenses'),
              ),
              ButtonSegment(
                value: _TransactionTypeFilter.income,
                icon: Icon(Icons.trending_up),
                label: Text('Income'),
              ),
            ],
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith(
                (states) => states.contains(MaterialState.selected)
                    ? colors.secondaryAccent.withOpacity(0.18)
                    : colors.surfaceBackground.withOpacity(0.6),
              ),
            ),
            selected: <_TransactionTypeFilter>{_typeFilter},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _typeFilter = selection.first),
          ),
          if (hasActiveFilters && activeFilterChips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: activeFilterChips,
            ),
          ],
        ],
      ),
    );
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
              backgroundColor: MoneyBaseColors.red,
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
    final result = await Navigator.of(context).pushNamed<MoneyBaseTransaction>(
      '/edit',
      arguments: TransactionEditorArguments(
        transaction: transaction,
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
    Navigator.of(context).pushNamed('/add');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return MoneyBaseScaffold(
        builder: (context, layout) {
          final textTheme = Theme.of(context).textTheme;
          final colors = context.moneyBaseColors;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transactions',
                style: textTheme.headlineMedium?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to review your MoneyBase transactions.',
                style: textTheme.bodyLarge?.copyWith(color: colors.mutedText),
              ),
              const SizedBox(height: 24),
              const _TransactionsMessagePanel(
                icon: Icons.lock_outline,
                title: 'Sign in required',
                message: 'Sign in to review your MoneyBase transactions.',
              ),
            ],
          );
        },
      );
    }

    return MoneyBaseScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add transaction'),
      ),
      builder: (context, layout) {
        final textTheme = Theme.of(context).textTheme;
        final colors = context.moneyBaseColors;

        Widget buildHeader() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review and manage your MoneyBase history with responsive filters.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (layout.isWide) ...[
                const SizedBox(width: 16),
                MoneyBaseGlassIconButton(
                  icon: Icons.add,
                  tooltip: 'Add transaction',
                  onPressed: _openAddTransaction,
                ),
              ],
            ],
          );
        }

        return StreamBuilder<List<Wallet>>(
          stream: _walletRepository.watchWallets(user.uid),
          builder: (context, walletSnapshot) {
            if (walletSnapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  const SizedBox(height: 24),
                  _TransactionsMessagePanel(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallets unavailable',
                    message: 'Unable to load wallets: ${walletSnapshot.error}',
                    isError: true,
                  ),
                ],
              );
            }

            final wallets = walletSnapshot.data ?? const <Wallet>[];

            return StreamBuilder<List<Category>>(
              stream: _categoryRepository.watchCategories(user.uid),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildHeader(),
                      const SizedBox(height: 24),
                      _TransactionsMessagePanel(
                        icon: Icons.category_outlined,
                        title: 'Categories unavailable',
                        message:
                            'Unable to load categories: ${categorySnapshot.error}',
                        isError: true,
                      ),
                    ],
                  );
                }

                final categories = categorySnapshot.data ?? const <Category>[];
                final walletById = {for (final wallet in wallets) wallet.id: wallet};
                final categoryById = {
                  for (final category in categories) category.id: category
                };

                return StreamBuilder<List<MoneyBaseTransaction>>(
                  stream: _transactionRepository.watchTransactions(user.uid),
                  builder: (context, transactionSnapshot) {
                    if (transactionSnapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildHeader(),
                          const SizedBox(height: 24),
                          _TransactionsMessagePanel(
                            icon: Icons.error_outline,
                            title: 'Transactions unavailable',
                            message:
                                'Unable to load transactions: ${transactionSnapshot.error}',
                            isError: true,
                          ),
                        ],
                      );
                    }

                    final transactions =
                        transactionSnapshot.data ?? const <MoneyBaseTransaction>[];
                    final loading = transactionSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        transactions.isEmpty;

                    final filteredTransactions =
                        _applyFilters(transactions, walletById, categoryById);
                    final hasActiveFilters =
                        _typeFilter != _TransactionTypeFilter.all ||
                            _walletFilter != _kAllFilterValue ||
                            _categoryFilter != _kAllFilterValue ||
                            _searchTerm.isNotEmpty;
                    final currencySet = (filteredTransactions.isEmpty &&
                            transactions.isNotEmpty)
                        ? transactions.map(_resolveCurrencyCode).toSet()
                        : filteredTransactions.map(_resolveCurrencyCode).toSet();
                    final incomeTransactions = filteredTransactions
                        .where((transaction) => transaction.isIncome)
                        .toList();
                    final expenseTransactions = filteredTransactions
                        .where((transaction) => !transaction.isIncome)
                        .toList();
                    final totalIncome = incomeTransactions.fold<double>(
                      0,
                      (sum, transaction) => sum + transaction.amount,
                    );
                    final totalExpense = expenseTransactions.fold<double>(
                      0,
                      (sum, transaction) => sum + transaction.amount,
                    );
                    final net = totalIncome - totalExpense;

                    final summaryBadges = <Widget>[
                      _SummaryBadge(
                        icon: Icons.receipt_long_outlined,
                        label: 'Transactions',
                        value: filteredTransactions.length.toString(),
                        detail:
                            hasActiveFilters ? 'Filtered view' : 'Showing full history',
                        accent: colors.primaryAccent,
                      ),
                      _SummaryBadge(
                        icon: Icons.trending_up,
                        label: 'Income',
                        value: _formatSummaryAmount(
                          totalIncome,
                          currencySet,
                          signed: true,
                        ),
                        detail: incomeTransactions.isEmpty
                            ? 'No income recorded'
                            : '${incomeTransactions.length} entr${incomeTransactions.length == 1 ? 'y' : 'ies'}',
                        accent: Colors.teal,
                      ),
                      _SummaryBadge(
                        icon: Icons.trending_down,
                        label: 'Expenses',
                        value: _formatSummaryAmount(
                          -totalExpense,
                          currencySet,
                          signed: true,
                        ),
                        detail: expenseTransactions.isEmpty
                            ? 'No expenses recorded'
                            : '${expenseTransactions.length} entr${expenseTransactions.length == 1 ? 'y' : 'ies'}',
                        accent: MoneyBaseColors.red,
                      ),
                      _SummaryBadge(
                        icon: Icons.ssid_chart_outlined,
                        label: net >= 0 ? 'Net inflow' : 'Net outflow',
                        value: _formatSummaryAmount(
                          net,
                          currencySet,
                          signed: true,
                        ),
                        detail: '${transactions.length} total records',
                        accent:
                            net >= 0 ? colors.secondaryAccent : MoneyBaseColors.red,
                      ),
                    ];

                    final children = <Widget>[
                      buildHeader(),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: summaryBadges,
                      ),
                      const SizedBox(height: 24),
                      _buildFilterPanel(context, layout, wallets, categories),
                      const SizedBox(height: 24),
                    ];

                    if (loading) {
                      children.add(
                        MoneyBaseFrostedPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 48,
                          ),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      );
                    }

                    if (transactions.isEmpty) {
                      children.add(
                        _TransactionsMessagePanel(
                          icon: Icons.inbox_outlined,
                          title: 'No transactions yet',
                          message:
                              'Capture a purchase or income entry to see it listed here.',
                          action: FilledButton.icon(
                            onPressed: _openAddTransaction,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add your first transaction'),
                          ),
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      );
                    }

                    if (filteredTransactions.isEmpty) {
                      children.add(
                        _TransactionsMessagePanel(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'No results match the current filters',
                          message:
                              'Adjust your filters or clear them to see your transactions again.',
                          action: TextButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Clear filters'),
                          ),
                        ),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      );
                    }

                    if (layout.isWide) {
                      children.add(
                        MoneyBaseFrostedPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.resolveWith(
                                (states) => Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.4),
                              ),
                              columnSpacing: 28,
                              dataRowMinHeight: 60,
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Wallet')),
                                DataColumn(label: Text('Amount'), numeric: true),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filteredTransactions.map((transaction) {
                                final amountColor = transaction.isIncome
                                    ? Colors.teal
                                    : Theme.of(context).colorScheme.error;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(_formatDate(transaction.date))),
                                    DataCell(Text(transaction.description)),
                                    DataCell(Text(
                                      _categoryNameFor(
                                        categories,
                                        transaction.categoryId,
                                      ),
                                    )),
                                    DataCell(Text(
                                      _walletNameFor(
                                        wallets,
                                        transaction.walletId,
                                      ),
                                    )),
                                    DataCell(
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          _formatAmount(transaction),
                                          style: TextStyle(
                                            color: amountColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MoneyBaseGlassIconButton(
                                            icon: Icons.edit_outlined,
                                            tooltip: 'Edit transaction',
                                            onPressed: () => _editTransaction(
                                              context,
                                              user.uid,
                                              transaction,
                                              wallets,
                                              categories,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          MoneyBaseGlassIconButton(
                                            icon: Icons.delete_outline,
                                            tooltip: 'Delete transaction',
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
                      );
                    } else {
                      children.add(
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTransactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            final category = categoryById[transaction.categoryId];
                            final wallet = walletById[transaction.walletId];

                            return _TransactionTile(
                              transaction: transaction,
                              category: category,
                              wallet: wallet,
                              dateLabel: _formatDate(transaction.date),
                              amountLabel: _formatAmount(transaction),
                              onEdit: () => _editTransaction(
                                context,
                                user.uid,
                                transaction,
                                wallets,
                                categories,
                              ),
                              onDelete: () => _deleteTransaction(
                                context,
                                user.uid,
                                transaction,
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TransactionsMessagePanel extends StatelessWidget {
  const _TransactionsMessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.isError = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;
    final accent = isError ? MoneyBaseColors.red : colors.primaryAccent;

    return MoneyBaseFrostedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: accent.withOpacity(0.16),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;
    final resolvedAccent = accent ?? colors.primaryAccent;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              resolvedAccent.withOpacity(0.22),
              resolvedAccent.withOpacity(0.1),
            ],
          ),
          border: Border.all(color: resolvedAccent.withOpacity(0.36)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: resolvedAccent),
            const SizedBox(height: 12),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: colors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: textTheme.bodySmall?.copyWith(color: colors.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.category,
    required this.wallet,
    required this.dateLabel,
    required this.amountLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final MoneyBaseTransaction transaction;
  final Category? category;
  final Wallet? wallet;
  final String dateLabel;
  final String amountLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;
    final categoryName = () {
      final raw = category?.name;
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
      return 'Uncategorised';
    }();
    final walletName = () {
      final raw = wallet?.name;
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
      return 'Unknown wallet';
    }();
    final accent = parseHexColor(category?.color) ??
        (transaction.isIncome
            ? Colors.teal
            : Theme.of(context).colorScheme.error);
    final amountColor = transaction.isIncome
        ? Colors.teal
        : Theme.of(context).colorScheme.error;
    final icon = IconLibrary.iconForCategory(category?.iconName);

    return MoneyBaseFrostedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: accent.withOpacity(0.18),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountLabel,
                    style: textTheme.titleMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoneyBaseGlassIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit transaction',
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      MoneyBaseGlassIconButton(
                        icon: Icons.delete_outline,
                        tooltip: 'Delete transaction',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _TransactionTag(
                icon: icon,
                label: categoryName,
                color: accent,
              ),
              _TransactionTag(
                icon: Icons.account_balance_wallet_outlined,
                label: walletName,
                color: colors.secondaryAccent,
              ),
              _TransactionTag(
                icon: transaction.isIncome
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                label: transaction.isIncome ? 'Income' : 'Expense',
                color: transaction.isIncome ? Colors.teal : MoneyBaseColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTag extends StatelessWidget {
  const _TransactionTag({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;
    final accent = color ?? colors.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionEditorDialog extends StatefulWidget {
  const TransactionEditorDialog({
    required this.initial,
    required this.wallets,
    required this.categories,
  });

  final MoneyBaseTransaction initial;
  final List<Wallet> wallets;
  final List<Category> categories;

  @override
  State<TransactionEditorDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionEditorDialog> {
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
