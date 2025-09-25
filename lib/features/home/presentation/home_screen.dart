import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../common/presentation/moneybase_shell.dart';
import '../../common/presentation/currency_dropdown_field.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/constants/icon_library.dart';
import '../../../core/models/budget.dart';
import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/budget_repository.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/repositories/wallet_repository.dart';
import '../../../core/utils/color_utils.dart';
import 'ai_assistant_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onAddTransaction,
    required this.onViewReports,
    required this.onViewTransactions,
    super.key,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onViewReports;
  final VoidCallback onViewTransactions;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TransactionRepository _transactionRepository;
  late final WalletRepository _walletRepository;
  late final CategoryRepository _categoryRepository;
  late final BudgetRepository _budgetRepository;

  @override
  void initState() {
    super.initState();
    _transactionRepository = TransactionRepository();
    _walletRepository = WalletRepository();
    _categoryRepository = CategoryRepository();
    _budgetRepository = BudgetRepository();
  }

  void _openAiAssistant(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiAssistantSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return MoneyBaseScaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final horizontalPadding = width > 640 ? 32.0 : 20.0;
          return SizedBox(
            width: width,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  FloatingActionButton(
                    heroTag: 'aiChatFab',
                    onPressed: () => _openAiAssistant(context),
                    child: const Icon(Icons.smart_toy_outlined),
                  ),
                  const Spacer(),
                  FloatingActionButton.extended(
                    heroTag: 'addTransactionFab',
                    onPressed: widget.onAddTransaction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add transaction'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      builder: (context, layout) {
        return _HomeContent(
          onViewReports: widget.onViewReports,
          onViewTransactions: widget.onViewTransactions,
          userId: userId,
          transactionRepository: _transactionRepository,
          walletRepository: _walletRepository,
          categoryRepository: _categoryRepository,
          budgetRepository: _budgetRepository,
        );
      },
    );
  }
}

List<_BudgetView> _buildBudgetViews({
  required List<Budget> budgets,
  required List<Category> categories,
  required List<MoneyBaseTransaction> transactions,
}) {
  final categoryById = {
    for (final category in categories) category.id: category,
  };

  final now = DateTime.now();

  return budgets.map((budget) {
    final resolvedRange = _resolveBudgetRange(budget, now);
    final selectedCategories = budget.categoryIds
        .map((id) => categoryById[id])
        .whereType<Category>()
        .toList();

    final includeIncome =
        budget.flowType == BudgetFlowType.income || budget.flowType == BudgetFlowType.both;
    final includeExpenses =
        budget.flowType == BudgetFlowType.expenses || budget.flowType == BudgetFlowType.both;

    final relevantTransactions = transactions.where((transaction) {
      if (transaction.isIncome && !includeIncome) return false;
      if (!transaction.isIncome && !includeExpenses) return false;
      if (budget.currencyCode.isNotEmpty &&
          transaction.currencyCode.toUpperCase() !=
              budget.currencyCode.toUpperCase()) {
        return false;
      }

      if (budget.categoryIds.isNotEmpty &&
          !budget.categoryIds.contains(transaction.categoryId)) {
        return false;
      }

      if (!_isWithinRange(transaction.date, resolvedRange)) {
        return false;
      }

      return true;
    });

    final total = relevantTransactions.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );

    return _BudgetView(
      budget: budget,
      categories: selectedCategories,
      spent: total,
      range: resolvedRange,
    );
  }).toList();
}

class _BudgetAnalyticsCard extends StatelessWidget {
  const _BudgetAnalyticsCard({required this.views});

  final List<_BudgetView> views;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final mutedOnSurface = colors.mutedText;

    if (views.isEmpty) {
      return MoneyBaseSurface(
        padding: const EdgeInsets.all(28),
        backgroundColor: colors.surfaceElevated,
        borderColor: colors.surfaceBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budgets snapshot',
              style: textTheme.titleMedium?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a budget to visualise how your spending compares to plan.',
              style: textTheme.bodyMedium?.copyWith(color: mutedOnSurface),
            ),
          ],
        ),
      );
    }

    final totalLimit =
        views.fold<double>(0, (sum, view) => sum + view.budget.limit);
    final totalSpent =
        views.fold<double>(0, (sum, view) => sum + view.spent);
    final uniqueCurrencies = views.map((view) => view.currency).toSet();
    final segments = <_BudgetSegment>[];

    for (var index = 0; index < views.length; index++) {
      final view = views[index];
      final primaryCategory = view.primaryCategory;
      final color = parseHexColor(primaryCategory?.color) ??
          _budgetFallbackColors[index % _budgetFallbackColors.length];
      final limit = view.budget.limit;
      final spent = view.spent;
      final currency = view.currency;
      final name = view.budget.name.isNotEmpty
          ? view.budget.name
          : (primaryCategory?.name.isNotEmpty == true
              ? primaryCategory!.name
              : 'Budget ${index + 1}');

      segments.add(
        _BudgetSegment(
          label: name,
          amount:
              'Spent ${_formatCurrency(spent, currency)} of ${_formatCurrency(limit, currency)}',
          ratio: totalLimit <= 0 ? 0 : (limit / totalLimit),
          color: color,
        ),
      );
    }

    String totalLabel;
    String subtitle;
    if (uniqueCurrencies.length == 1) {
      final currency = uniqueCurrencies.first;
      totalLabel = _formatCurrency(totalSpent, currency);
      subtitle = 'Spent of ${_formatCurrency(totalLimit, currency)}';
    } else {
      totalLabel = '${views.length}';
      subtitle = 'Active budgets';
    }

    return MoneyBaseSurface(
      padding: const EdgeInsets.all(28),
      backgroundColor: colors.surfaceElevated,
      borderColor: colors.surfaceBorder,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 540;

          return Flex(
            direction: isStacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budgets snapshot',
                      style: textTheme.titleMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Monitor limits and keep spending aligned with your goals.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: mutedOnSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final segment in segments) ...[
                      _LegendRow(segment: segment),
                      if (segment != segments.last) const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              SizedBox(width: isStacked ? 0 : 32, height: isStacked ? 32 : 0),
              SizedBox(
                width: isStacked ? 200 : 240,
                height: isStacked ? 200 : 240,
                child: _DonutChart(
                  totalLabel: totalLabel,
                  subtitle: subtitle,
                  segments: segments,
                  overlayColor: colors.mutedText.withOpacity(0.08),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetsListCard extends StatelessWidget {
  const _BudgetsListCard({
    required this.views,
    required this.onAddBudget,
    required this.onEditBudget,
    required this.onDeleteBudget,
  });

  final List<_BudgetView> views;
  final VoidCallback onAddBudget;
  final void Function(Budget budget) onEditBudget;
  final void Function(Budget budget) onDeleteBudget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;

    return MoneyBaseSurface(
      padding: const EdgeInsets.all(28),
      backgroundColor: colors.surfaceBackground,
      borderColor: colors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage budgets',
                  style: textTheme.titleMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onAddBudget,
                icon: const Icon(Icons.addchart_outlined),
                label: const Text('Add budget'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (views.isEmpty)
            Text(
              'Budgets automatically pull in transactions to show real-time progress.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.mutedText,
              ),
            )
          else
            Column(
              children: [
                for (final view in views) ...[
                  _BudgetListTile(
                    view: view,
                    onEdit: () => onEditBudget(view.budget),
                    onDelete: () => onDeleteBudget(view.budget),
                  ),
                  if (view != views.last) const SizedBox(height: 20),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _BudgetListTile extends StatelessWidget {
  const _BudgetListTile({
    required this.view,
    required this.onEdit,
    required this.onDelete,
  });

  final _BudgetView view;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final primaryCategory = view.primaryCategory;
    final accent =
        parseHexColor(primaryCategory?.color) ?? colors.primaryAccent;
    final limit = view.budget.limit;
    final spent = view.spent;
    final remaining = limit - spent;
    final currency = view.currency;
    final progress = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final title = view.budget.name.isNotEmpty
        ? view.budget.name
        : (primaryCategory?.name.isNotEmpty == true
            ? primaryCategory!.name
            : 'Budget');
    final rangeLabel = _formatBudgetRange(
      view.budget,
      reference: DateTime.now(),
      resolvedRange: view.range,
    );
    final notes = view.budget.notes;
    final categoryLabel = view.budget.categoryIds.isEmpty
        ? 'All categories'
        : (view.categories.isNotEmpty
            ? view.categories
                .map((category) =>
                    category.name.isNotEmpty ? category.name : 'Unnamed category')
                .join(', ')
            : 'Selected categories');
    final flowLabel = _describeFlowType(view.budget.flowType);
    final subtitleParts = <String>[];
    if (flowLabel.isNotEmpty) {
      subtitleParts.add(flowLabel);
    }
    if (categoryLabel.isNotEmpty) {
      subtitleParts.add(categoryLabel);
    }
    final subtitle = subtitleParts.join(' · ');
    final remainingLabel = remaining >= 0
        ? '${_formatCurrency(remaining, currency)} remaining'
        : 'Over by ${_formatCurrency(remaining.abs(), currency)}';

    final surfaceColor = colors.surfaceElevated;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withOpacity(theme.brightness == Brightness.dark ? 0.55 : 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle.isNotEmpty ? subtitle : 'All categories',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_BudgetAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _BudgetAction.edit:
                        onEdit();
                        break;
                      case _BudgetAction.delete:
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _BudgetAction.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: _BudgetAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BudgetProgressBar(progress: progress, color: accent),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _BudgetChip(
                  icon: Icons.pie_chart_outline,
                  label:
                      '${_formatCurrency(spent, currency)} spent of ${_formatCurrency(limit, currency)}',
                  color: accent,
                ),
                _BudgetChip(
                  icon: Icons.timeline_outlined,
                  label: remainingLabel,
                  color: remaining >= 0 ? colors.positive : colors.negative,
                ),
                _BudgetChip(
                  icon: Icons.swap_vert_circle_outlined,
                  label: flowLabel,
                  color: colors.tertiaryAccent,
                ),
                if (rangeLabel.isNotEmpty)
                  _BudgetChip(
                    icon: Icons.calendar_today_outlined,
                    label: rangeLabel,
                    color: colors.info,
                  ),
                if (notes?.isNotEmpty == true)
                  _BudgetChip(
                    icon: Icons.note_outlined,
                    label: notes!,
                    color: colors.primaryAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 12,
        backgroundColor: color.withOpacity(0.16),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _BudgetChip extends StatelessWidget {
  const _BudgetChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BudgetAction { edit, delete }

class _ResolvedBudgetRange {
  const _ResolvedBudgetRange({this.start, this.end});

  final DateTime? start;
  final DateTime? end;
}

class _BudgetView {
  const _BudgetView({
    required this.budget,
    required this.categories,
    required this.spent,
    required this.range,
  });

  final Budget budget;
  final List<Category> categories;
  final double spent;
  final _ResolvedBudgetRange? range;

  Category? get primaryCategory =>
      categories.isNotEmpty ? categories.first : null;

  String get currency => budget.currencyCode.toUpperCase();
}

const List<Color> _budgetFallbackColors = [
  Color(0xFF4FF3B2),
  Color(0xFFFF6D8D),
  Color(0xFFFFC857),
  Color(0xFF7B5BFF),
  Color(0xFF5BD8FF),
];

String _formatCurrency(double value, String currency) {
  return '$currency ${value.toStringAsFixed(2)}';
}

const List<String> _monthNames = <String>[
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

_ResolvedBudgetRange? _resolveBudgetRange(Budget budget, DateTime reference) {
  DateTime endOfExclusive(DateTime exclusive) {
    return exclusive.subtract(const Duration(milliseconds: 1));
  }

  switch (budget.period) {
    case BudgetPeriod.day:
      final start = DateTime(reference.year, reference.month, reference.day);
      final end = endOfExclusive(start.add(const Duration(days: 1)));
      return _ResolvedBudgetRange(start: start, end: end);
    case BudgetPeriod.week:
      final startOfDay = DateTime(reference.year, reference.month, reference.day);
      final start =
          startOfDay.subtract(Duration(days: reference.weekday - DateTime.monday));
      final end = endOfExclusive(start.add(const Duration(days: 7)));
      return _ResolvedBudgetRange(start: start, end: end);
    case BudgetPeriod.month:
      final start = DateTime(reference.year, reference.month, 1);
      final end = endOfExclusive(DateTime(reference.year, reference.month + 1, 1));
      return _ResolvedBudgetRange(start: start, end: end);
    case BudgetPeriod.year:
      final start = DateTime(reference.year, 1, 1);
      final end = endOfExclusive(DateTime(reference.year + 1, 1, 1));
      return _ResolvedBudgetRange(start: start, end: end);
    case BudgetPeriod.custom:
      if (budget.startDate == null && budget.endDate == null) {
        return null;
      }
      return _ResolvedBudgetRange(start: budget.startDate, end: budget.endDate);
  }
}

bool _isWithinRange(DateTime date, _ResolvedBudgetRange? range) {
  if (range == null) {
    return true;
  }
  if (range.start != null && date.isBefore(range.start!)) {
    return false;
  }
  if (range.end != null && date.isAfter(range.end!)) {
    return false;
  }
  return true;
}

String _monthName(int month) {
  if (month < 1 || month > 12) {
    return '';
  }
  return _monthNames[month - 1];
}

String _formatMonthDay(DateTime date) {
  final month = _monthName(date.month);
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$month $day, $year';
}

String _formatMonthYear(DateTime date) {
  final month = _monthName(date.month);
  return '$month ${date.year}';
}

String _formatCustomBudgetRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) {
    return '';
  }
  if (start != null && end != null) {
    return '${_formatMonthDay(start)} – ${_formatMonthDay(end)}';
  }
  if (start != null) {
    return 'From ${_formatMonthDay(start)}';
  }
  return 'Until ${_formatMonthDay(end!)}';
}

String _formatBudgetRange(
  Budget budget, {
  required DateTime reference,
  _ResolvedBudgetRange? resolvedRange,
}) {
  resolvedRange ??= _resolveBudgetRange(budget, reference);
  switch (budget.period) {
    case BudgetPeriod.day:
      if (resolvedRange?.start != null) {
        return 'Today (${_formatMonthDay(resolvedRange!.start!)})';
      }
      return 'Today';
    case BudgetPeriod.week:
      if (resolvedRange?.start != null && resolvedRange?.end != null) {
        return 'This week (${_formatMonthDay(resolvedRange!.start!)} – '
            '${_formatMonthDay(resolvedRange.end!)})';
      }
      return 'This week';
    case BudgetPeriod.month:
      final start = resolvedRange?.start ?? reference;
      return 'This month (${_formatMonthYear(start)})';
    case BudgetPeriod.year:
      final start = resolvedRange?.start ?? reference;
      return 'This year (${start.year})';
    case BudgetPeriod.custom:
      return _formatCustomBudgetRange(budget.startDate, budget.endDate);
  }
}

String _describeFlowType(BudgetFlowType flowType) {
  switch (flowType) {
    case BudgetFlowType.expenses:
      return 'Expenses only';
    case BudgetFlowType.income:
      return 'Income only';
    case BudgetFlowType.both:
      return 'Income & expenses';
  }
}

String _periodLabel(BudgetPeriod period) {
  switch (period) {
    case BudgetPeriod.day:
      return 'Daily';
    case BudgetPeriod.week:
      return 'Weekly';
    case BudgetPeriod.month:
      return 'Monthly';
    case BudgetPeriod.year:
      return 'Yearly';
    case BudgetPeriod.custom:
      return 'Custom range';
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({
    required this.categories,
    this.initial,
  });

  final List<Category> categories;
  final Budget? initial;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late final TextEditingController _notesController;
  late final Set<String> _selectedCategoryIds;
  DateTime? _startDate;
  DateTime? _endDate;
  late String _currencyCode;
  late BudgetPeriod _period;
  late BudgetFlowType _flowType;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _limitController = TextEditingController(
      text: initial != null && initial.limit > 0
          ? initial.limit.toStringAsFixed(2)
          : '',
    );
    _currencyCode = currencyOptionFor(initial?.currencyCode).code;
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _selectedCategoryIds = {
      if (initial != null) ...initial.categoryIds,
    };
    _period = initial?.period ?? BudgetPeriod.month;
    _flowType = initial?.flowType ?? BudgetFlowType.expenses;
    if (_period == BudgetPeriod.custom) {
      _startDate = initial?.startDate;
      _endDate = initial?.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initialRange = (_startDate != null && _endDate != null)
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;

    final result = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange ??
          DateTimeRange(start: now, end: now.add(const Duration(days: 30))),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (result != null) {
      setState(() {
        _period = BudgetPeriod.custom;
        _startDate = result.start;
        _endDate = result.end;
      });
    }
  }

  void _clearRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final limitText = _limitController.text.trim();
    final parsedLimit = double.tryParse(limitText);
    if (parsedLimit == null || parsedLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a limit greater than zero.')),
      );
      return;
    }

    final currency = _currencyCode;

    final base = widget.initial ?? Budget();
    final notes = _notesController.text.trim();
    final categoryOrder = <String, int>{
      for (var i = 0; i < widget.categories.length; i++)
        widget.categories[i].id: i,
    };
    final selectedCategoryIds = _selectedCategoryIds.toList()
      ..sort(
        (a, b) => (categoryOrder[a] ?? widget.categories.length)
            .compareTo(categoryOrder[b] ?? widget.categories.length),
      );

    Navigator.of(context).pop(
      base.copyWith(
        name: _nameController.text.trim(),
        limit: parsedLimit,
        currencyCode: currency,
        categoryIds: selectedCategoryIds,
        period: _period,
        flowType: _flowType,
        notes: notes.isEmpty ? null : notes,
        startDate: _period == BudgetPeriod.custom ? _startDate : null,
        endDate: _period == BudgetPeriod.custom ? _endDate : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String categoryLabel(Category category) {
      return category.name.isNotEmpty ? category.name : 'Untitled category';
    }

    final sortedCategories = [...widget.categories]
      ..sort((a, b) {
        final nameA = a.name.toLowerCase();
        final nameB = b.name.toLowerCase();
        if (nameA.isEmpty && nameB.isEmpty) {
          return a.id.compareTo(b.id);
        }
        if (nameA.isEmpty) return 1;
        if (nameB.isEmpty) return -1;
        return nameA.compareTo(nameB);
      });

    final allowCustom =
        widget.initial?.period == BudgetPeriod.custom || _period == BudgetPeriod.custom;
    final periodOptions = <BudgetPeriod>[
      BudgetPeriod.day,
      BudgetPeriod.week,
      BudgetPeriod.month,
      BudgetPeriod.year,
      if (allowCustom) BudgetPeriod.custom,
    ];

    final customRangeLabel = _formatCustomBudgetRange(_startDate, _endDate);

    return AlertDialog(
      title: Text(widget.initial == null ? 'New budget' : 'Edit budget'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Budget name'),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a budget name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(labelText: 'Limit amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              CurrencyDropdownFormField(
                value: _currencyCode,
                labelText: 'Currency',
                onChanged: (code) => setState(() => _currencyCode = code),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BudgetPeriod>(
                value: _period,
                decoration: const InputDecoration(labelText: 'Budget period'),
                items: [
                  for (final period in periodOptions)
                    DropdownMenuItem<BudgetPeriod>(
                      value: period,
                      child: Text(_periodLabel(period)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _period = value;
                    if (_period != BudgetPeriod.custom) {
                      _startDate = null;
                      _endDate = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BudgetFlowType>(
                value: _flowType,
                decoration: const InputDecoration(labelText: 'Tracking'),
                items: [
                  for (final option in BudgetFlowType.values)
                    DropdownMenuItem<BudgetFlowType>(
                      value: option,
                      child: Text(_describeFlowType(option)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _flowType = value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All categories'),
                    selected: _selectedCategoryIds.isEmpty,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategoryIds.clear();
                        }
                      });
                    },
                  ),
                  for (final category in sortedCategories)
                    FilterChip(
                      label: Text(categoryLabel(category)),
                      selected: _selectedCategoryIds.contains(category.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategoryIds.add(category.id);
                          } else {
                            _selectedCategoryIds.remove(category.id);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Leave unselected to include every category.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.7) ??
                          Colors.grey,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              if (_period == BudgetPeriod.custom) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        customRangeLabel.isNotEmpty
                            ? customRangeLabel
                            : 'Select custom range',
                      ),
                    ),
                    if (_startDate != null || _endDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearRange,
                        tooltip: 'Clear range',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
              ],
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.onViewReports,
    required this.onViewTransactions,
    required this.userId,
    required this.transactionRepository,
    required this.walletRepository,
    required this.categoryRepository,
    required this.budgetRepository,
  });

  final VoidCallback onViewReports;
  final VoidCallback onViewTransactions;
  final String? userId;
  final TransactionRepository transactionRepository;
  final WalletRepository walletRepository;
  final CategoryRepository categoryRepository;
  final BudgetRepository budgetRepository;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onBackground = colors.primaryText;
    final mutedOnBackground = colors.mutedText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home',
                    style: textTheme.headlineMedium?.copyWith(
                      color: onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your August snapshot is synced across Android and web.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: mutedOnBackground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            MoneyBaseGlassIconButton(
              icon: Icons.analytics_outlined,
              tooltip: 'Reports',
              onPressed: widget.onViewReports,
            ),
            const SizedBox(width: 12),
            MoneyBaseGlassIconButton(
              icon: Icons.list_alt_outlined,
              tooltip: 'Transactions',
              onPressed: widget.onViewTransactions,
            ),
          ],
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            const sectionSpacing = 24.0;

            final graphsSection = _GraphsTab(
              userId: widget.userId,
              budgetRepository: widget.budgetRepository,
              transactionRepository: widget.transactionRepository,
              categoryRepository: widget.categoryRepository,
            );

            final trailingColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReportsTab(onViewReports: widget.onViewReports),
                const SizedBox(height: sectionSpacing),
                _RecentTransactionsCard(
                  onViewTransactions: widget.onViewTransactions,
                  userId: widget.userId,
                  transactionRepository: widget.transactionRepository,
                  walletRepository: widget.walletRepository,
                  categoryRepository: widget.categoryRepository,
                ),
              ],
            );

            if (constraints.maxWidth >= 1024) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: graphsSection,
                  ),
                  const SizedBox(width: sectionSpacing),
                  Expanded(
                    flex: 2,
                    child: trailingColumn,
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                graphsSection,
                const SizedBox(height: sectionSpacing),
                trailingColumn,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GraphsTab extends StatefulWidget {
  const _GraphsTab({
    required this.userId,
    required this.budgetRepository,
    required this.transactionRepository,
    required this.categoryRepository,
  });

  final String? userId;
  final BudgetRepository budgetRepository;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  @override
  State<_GraphsTab> createState() => _GraphsTabState();
}

class _GraphsTabState extends State<_GraphsTab> {
  Future<void> _createBudget(String userId, List<Category> categories) async {
    final result = await showDialog<Budget>(
      context: context,
      builder: (context) => _BudgetDialog(categories: categories),
    );

    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.budgetRepository.addBudget(userId, result);
      messenger.showSnackBar(
        const SnackBar(content: Text('Budget created.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to create budget: $error')),
      );
    }
  }

  Future<void> _editBudget(
    String userId,
    Budget budget,
    List<Category> categories,
  ) async {
    final result = await showDialog<Budget>(
      context: context,
      builder: (context) => _BudgetDialog(
        categories: categories,
        initial: budget,
      ),
    );

    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.budgetRepository.updateBudget(userId, result);
      messenger.showSnackBar(
        const SnackBar(content: Text('Budget updated.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update budget: $error')),
      );
    }
  }

  Future<void> _deleteBudget(String userId, Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text(
          'Remove "${budget.name.isEmpty ? 'Untitled budget' : budget.name}" and its insights?',
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

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.budgetRepository.deleteBudget(userId, budget.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Budget removed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete budget: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;

    if (userId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          MoneyBaseSurface(
            child: Text('Sign in to see personalised budget insights.'),
          ),
        ],
      );
    }

    return StreamBuilder<List<Budget>>(
      stream: widget.budgetRepository.watchBudgets(userId),
      builder: (context, budgetSnapshot) {
        if (budgetSnapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyBaseSurface(
                child: Text(
                  'Unable to load budgets: ${budgetSnapshot.error}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.moneyBaseColors.primaryText),
                ),
              ),
            ],
          );
        }

        final budgets = budgetSnapshot.data ?? const <Budget>[];

        return StreamBuilder<List<Category>>(
          stream: widget.categoryRepository.watchCategories(userId),
          builder: (context, categorySnapshot) {
            final categories = categorySnapshot.data ?? const <Category>[];

            return StreamBuilder<List<MoneyBaseTransaction>>(
              stream: widget.transactionRepository.watchTransactions(userId),
              builder: (context, transactionSnapshot) {
                final transactions = transactionSnapshot.data ?? const <MoneyBaseTransaction>[];
                final views = _buildBudgetViews(
                  budgets: budgets,
                  categories: categories,
                  transactions: transactions,
                );

                if (budgetSnapshot.connectionState == ConnectionState.waiting &&
                    budgets.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      MoneyBaseSurface(
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BudgetAnalyticsCard(views: views),
                    const SizedBox(height: 24),
                    _BudgetsListCard(
                      views: views,
                      onAddBudget: () => _createBudget(userId, categories),
                      onEditBudget: (budget) => _editBudget(userId, budget, categories),
                      onDeleteBudget: (budget) => _deleteBudget(userId, budget),
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

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.onViewReports});

  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final mutedOnSurface = colors.mutedText;

    return MoneyBaseSurface(
      padding: const EdgeInsets.all(28),
      backgroundColor: colors.surfaceBackground,
      borderColor: colors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly insights',
            style: textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _ReportInsightTile(
            icon: Icons.trending_up,
            title: 'Net income is up 12%',
            subtitle: 'You spent \$250 less compared to last month.',
            iconTint: colors.primaryAccent,
            textColor: onSurface,
            subtitleColor: mutedOnSurface,
          ),
          const SizedBox(height: 12),
          _ReportInsightTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Top category: Shopping',
            subtitle: 'Shopping accounts for 34% of this month’s expenses.',
            iconTint: colors.secondaryAccent,
            textColor: onSurface,
            subtitleColor: mutedOnSurface,
          ),
          const SizedBox(height: 12),
          _ReportInsightTile(
            icon: Icons.savings_outlined,
            title: 'Savings streak ongoing',
            subtitle: 'You have contributed to savings for 5 weeks straight.',
            iconTint: colors.tertiaryAccent,
            textColor: onSurface,
            subtitleColor: mutedOnSurface,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onViewReports,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Open full reports'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportInsightTile extends StatelessWidget {
  const _ReportInsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconTint,
    required this.textColor,
    required this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconTint;
  final Color textColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: iconTint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: iconTint),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({
    required this.onViewTransactions,
    required this.userId,
    required this.transactionRepository,
    required this.walletRepository,
    required this.categoryRepository,
  });

  final VoidCallback onViewTransactions;
  final String? userId;
  final TransactionRepository transactionRepository;
  final WalletRepository walletRepository;
  final CategoryRepository categoryRepository;

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

  Widget _buildSurface(
    BuildContext context,
    TextTheme textTheme,
    Widget body,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final mutedOnSurface = colors.mutedText;

    return MoneyBaseSurface(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      backgroundColor: colors.surfaceBackground,
      borderColor: colors.surfaceBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: textTheme.titleLarge?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: mutedOnSurface,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: userId == null ? null : onViewTransactions,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('See all'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primaryAccent,
                  textStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          body,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final onSurfaceMuted = context.moneyBaseColors.mutedText;

    if (userId == null) {
      return _buildSurface(
        context,
        textTheme,
        Text(
          'Sign in to see your latest MoneyBase activity at a glance.',
          style: textTheme.bodyMedium?.copyWith(
            color: onSurfaceMuted,
          ),
        ),
        'Sign in required',
      );
    }

    return StreamBuilder<List<MoneyBaseTransaction>>(
      stream: transactionRepository.watchTransactions(userId!, limit: 5),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.hasError) {
          return _buildSurface(
            context,
            textTheme,
            Text(
              'Unable to load recent transactions: ${transactionSnapshot.error}',
              style: textTheme.bodyMedium?.copyWith(
                color: context.moneyBaseColors.primaryText,
              ),
            ),
            'Something went wrong',
          );
        }

        final transactions =
            transactionSnapshot.data ?? const <MoneyBaseTransaction>[];
        final loading =
            transactionSnapshot.connectionState == ConnectionState.waiting &&
                transactions.isEmpty;

        return StreamBuilder<List<Wallet>>(
          stream: walletRepository.watchWallets(userId!),
          builder: (context, walletSnapshot) {
            final wallets = walletSnapshot.data ?? const <Wallet>[];

            return StreamBuilder<List<Category>>(
              stream: categoryRepository.watchCategories(userId!),
              builder: (context, categorySnapshot) {
                final categories = categorySnapshot.data ?? const <Category>[];

                if (loading) {
                  return _buildSurface(
                    context,
                    textTheme,
                    const Center(child: CircularProgressIndicator()),
                    'Loading the latest activity…',
                  );
                }

                if (transactions.isEmpty) {
                  return _buildSurface(
                    context,
                    textTheme,
                    Text(
                      'No transactions yet. Create one to start building insights.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.moneyBaseColors.mutedText,
                      ),
                    ),
                    'Nothing to show',
                  );
                }

                final walletById = {
                  for (final wallet in wallets) wallet.id: wallet,
                };
                final categoryById = {
                  for (final category in categories) category.id: category,
                };

                final updatedLabel = 'Updated ${_formatDate(transactions.first.date)}';

                return _buildSurface(
                  context,
                  textTheme,
                  _TransactionList(
                    entries: [
                      for (final transaction in transactions)
                        _TransactionEntry(
                          title: transaction.description.trim().isNotEmpty
                              ? transaction.description.trim()
                              : (categoryById[transaction.categoryId]?.name ??
                                  'Uncategorised'),
                          dateLabel: _formatDate(transaction.date),
                          categoryLabel:
                              categoryById[transaction.categoryId]?.name ??
                                  'Uncategorised',
                          walletLabel:
                              walletById[transaction.walletId]?.name ??
                                  'Unknown wallet',
                          amountLabel: _formatAmount(transaction),
                          icon: IconLibrary.iconForCategory(
                            categoryById[transaction.categoryId]?.iconName,
                          ),
                          accent:
                              parseHexColor(
                                    categoryById[transaction.categoryId]?.color,
                                  ) ??
                                  (transaction.isIncome
                                      ? context.moneyBaseColors.tertiaryAccent
                                      : context.moneyBaseColors.negative),
                          amountColor: transaction.isIncome
                              ? context.moneyBaseColors.tertiaryAccent
                              : context.moneyBaseColors.negative,
                          isIncome: transaction.isIncome,
                        ),
                    ],
                  ),
                  updatedLabel,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment});

  final _BudgetSegment segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final mutedOnSurface = colors.mutedText;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                segment.label,
                style: textTheme.titleMedium?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                segment.amount,
                style: textTheme.bodyMedium?.copyWith(
                  color: mutedOnSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.entries});

  final List<_TransactionEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _TransactionTile(entry: entries[i]),
          if (i != entries.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.entry});

  final _TransactionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final mutedOnSurface = colors.mutedText;
    final tileColor = colors.surfaceElevated;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.surfaceBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    color: entry.accent.withOpacity(
                      theme.brightness == Brightness.dark ? 0.35 : 0.2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: entry.accent.withOpacity(0.4),
                    ),
                  ),
                  child: Icon(entry.icon, color: entry.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: textTheme.titleMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.dateLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: mutedOnSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: entry.amountColor.withOpacity(
                      theme.brightness == Brightness.dark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: entry.amountColor.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    entry.amountLabel,
                    style: textTheme.titleMedium?.copyWith(
                      color: entry.amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _TransactionMetadataChip(
                  icon: Icons.sell_outlined,
                  label: entry.categoryLabel,
                  accent: entry.accent,
                ),
                _TransactionMetadataChip(
                  icon: Icons.account_balance_wallet_outlined,
                  label: entry.walletLabel,
                ),
                _TransactionMetadataChip(
                  icon:
                      entry.isIncome ? Icons.south_west : Icons.north_east,
                  label: entry.isIncome ? 'Money in' : 'Money out',
                  accent: entry.amountColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionMetadataChip extends StatelessWidget {
  const _TransactionMetadataChip({
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final hasAccent = accent != null;
    final chipBackground = hasAccent
        ? accent!.withOpacity(theme.brightness == Brightness.dark ? 0.24 : 0.14)
        : colors.surfaceBackground;
    final chipBorder = hasAccent
        ? accent!.withOpacity(0.38)
        : colors.surfaceBorder;
    final chipForeground = hasAccent
        ? accent!
        : colors.mutedText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipForeground),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: chipForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionEntry {
  const _TransactionEntry({
    required this.title,
    required this.dateLabel,
    required this.categoryLabel,
    required this.walletLabel,
    required this.amountLabel,
    required this.icon,
    required this.accent,
    required this.amountColor,
    required this.isIncome,
  });

  final String title;
  final String dateLabel;
  final String categoryLabel;
  final String walletLabel;
  final String amountLabel;
  final IconData icon;
  final Color accent;
  final Color amountColor;
  final bool isIncome;
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.segments,
    required this.totalLabel,
    required this.subtitle,
    required this.overlayColor,
  });

  final List<_BudgetSegment> segments;
  final String totalLabel;
  final String subtitle;
  final Color overlayColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final mutedOnSurface = colors.mutedText;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CustomPaint(
            painter: _DonutChartPainter(
              segments: segments,
              strokeWidth: 24,
              overlayColor: overlayColor,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              totalLabel,
              style: textTheme.titleLarge?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: mutedOnSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
    required this.overlayColor,
  });

  final List<_BudgetSegment> segments;
  final double strokeWidth;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) {
      return;
    }

    final total = segments.fold<double>(0, (sum, segment) => sum + segment.ratio);
    if (total == 0) {
      return;
    }

    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    double startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweepAngle = (segment.ratio / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    final innerPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(rect.center, radius - strokeWidth / 2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BudgetSegment {
  const _BudgetSegment({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String amount;
  final double ratio;
  final Color color;
}
