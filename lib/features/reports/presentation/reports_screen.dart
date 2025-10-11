import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/category.dart';
import '../../../core/models/wallet.dart';
import '../../../core/models/transaction.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/color_utils.dart';
import '../../common/presentation/moneybase_shell.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  static const _uncategorizedKey = '__uncategorized__';
  static const _unassignedWalletKey = '__unassigned_wallet__';
  static const List<Color> _fallbackSegmentColors = [
    MoneyBaseColors.pink,
    MoneyBaseColors.purple,
    MoneyBaseColors.yellow,
    MoneyBaseColors.blue,
    MoneyBaseColors.green,
    MoneyBaseColors.orange,
  ];
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  _ReportPeriod _selectedPeriod = _ReportPeriod.month;
  _ReportDimension _selectedDimension = _ReportDimension.categories;

  DateTimeRange? _periodRange(_ReportPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case _ReportPeriod.day:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case _ReportPeriod.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case _ReportPeriod.month:
        final start = DateTime(now.year, now.month);
        final end = DateTime(now.year, now.month + 1);
        return DateTimeRange(start: start, end: end);
      case _ReportPeriod.quarter:
        final quarterIndex = (now.month - 1) ~/ 3;
        final startMonth = quarterIndex * 3 + 1;
        final start = DateTime(now.year, startMonth);
        final end = DateTime(now.year, startMonth + 3);
        return DateTimeRange(start: start, end: end);
      case _ReportPeriod.custom:
      case _ReportPeriod.all:
        return null;
    }
  }

  List<MoneyBaseTransaction> _filterTransactions(
    List<MoneyBaseTransaction> transactions,
    DateTimeRange? range,
  ) {
    if (range == null) {
      return transactions;
    }

    return transactions
        .where(
          (transaction) =>
              !transaction.date.isBefore(range.start) &&
              transaction.date.isBefore(range.end),
        )
        .toList();
  }

  String _resolveCurrency(List<MoneyBaseTransaction> transactions) {
    for (final transaction in transactions) {
      final code = transaction.currencyCode.trim();
      if (code.isNotEmpty) {
        return code.toUpperCase();
      }
    }
    return 'USD';
  }

  NumberFormat _currencyFormatter(String currency) {
    final code = currency.isEmpty ? 'USD' : currency.toUpperCase();
    return NumberFormat.simpleCurrency(name: code);
  }

  String _formatSegmentAmount(double amount, double ratio, String currency) {
    final formatter = _currencyFormatter(currency);
    final percent = (ratio * 100).clamp(0, 100);
    final percentText = percent >= 10
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);
    final formattedAmount = formatter.format(amount);
    return '$formattedAmount ($percentText%)';
  }

  _ReportBreakdown _buildCategoryBreakdown(
    List<MoneyBaseTransaction> transactions,
    Map<String, Category> categories,
    _ReportPeriod period,
  ) {
    final range = _periodRange(period);
    final scoped = _filterTransactions(transactions, range);
    if (scoped.isEmpty) {
      return _ReportBreakdown(
        segments: const [],
        total: 0,
        currency: _resolveCurrency(transactions),
        range: range,
      );
    }

    final currency = _resolveCurrency(scoped);
    double total = 0;
    double incomeTotal = 0;
    final expenseTotals = <String, double>{};

    for (final transaction in scoped) {
      final amount = transaction.amount.abs();
      if (amount == 0) {
        continue;
      }

      total += amount;
      if (transaction.isIncome) {
        incomeTotal += amount;
      } else {
        final key = transaction.categoryId.isNotEmpty
            ? transaction.categoryId
            : _uncategorizedKey;
        expenseTotals[key] = (expenseTotals[key] ?? 0) + amount;
      }
    }

    if (total == 0) {
      return _ReportBreakdown(
        segments: const [],
        total: 0,
        currency: currency,
        range: range,
      );
    }

    final segments = <_ReportSegment>[];
    if (incomeTotal > 0) {
      final ratio = incomeTotal / total;
      segments.add(
        _ReportSegment(
          label: 'Income',
          amount: _formatSegmentAmount(incomeTotal, ratio, currency),
          ratio: ratio,
          color: MoneyBaseColors.green,
        ),
      );
    }

    var fallbackIndex = 0;
    final expenseEntries = expenseTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in expenseEntries) {
      final category = categories[entry.key];
      final label = category != null && category.name.isNotEmpty
          ? category.name
          : 'Other';
      final color = parseHexColor(category?.color) ??
          _fallbackSegmentColors[fallbackIndex % _fallbackSegmentColors.length];
      fallbackIndex++;
      final ratio = entry.value / total;
      segments.add(
        _ReportSegment(
          label: label,
          amount: _formatSegmentAmount(entry.value, ratio, currency),
          ratio: ratio,
          color: color,
        ),
      );
    }

    return _ReportBreakdown(
      segments: segments,
      total: total,
      currency: currency,
      range: range,
    );
  }

  _ReportBreakdown _buildWalletBreakdown(
    List<MoneyBaseTransaction> transactions,
    Map<String, Wallet> wallets,
    _ReportPeriod period,
  ) {
    final range = _periodRange(period);
    final scoped = _filterTransactions(transactions, range);
    if (scoped.isEmpty) {
      return _ReportBreakdown(
        segments: const [],
        total: 0,
        currency: _resolveCurrency(transactions),
        range: range,
      );
    }

    final currency = _resolveCurrency(scoped);
    final totalsByWallet = <String, double>{};

    for (final transaction in scoped) {
      final amount = transaction.amount.abs();
      if (amount == 0) {
        continue;
      }

      final key =
          transaction.walletId.isNotEmpty ? transaction.walletId : _unassignedWalletKey;
      totalsByWallet[key] = (totalsByWallet[key] ?? 0) + amount;
    }

    if (totalsByWallet.isEmpty) {
      return _ReportBreakdown(
        segments: const [],
        total: 0,
        currency: currency,
        range: range,
      );
    }

    final total =
        totalsByWallet.values.fold<double>(0, (sum, value) => sum + value);
    if (total == 0) {
      return _ReportBreakdown(
        segments: const [],
        total: 0,
        currency: currency,
        range: range,
      );
    }

    final entries = totalsByWallet.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final segments = <_ReportSegment>[];
    var fallbackIndex = 0;

    for (final entry in entries) {
      final wallet = wallets[entry.key];
      final label = wallet != null && wallet.name.isNotEmpty
          ? wallet.name
          : 'Unassigned wallet';
      final color = parseHexColor(wallet?.color) ??
          _fallbackSegmentColors[fallbackIndex % _fallbackSegmentColors.length];
      fallbackIndex++;
      final ratio = entry.value / total;
      segments.add(
        _ReportSegment(
          label: label,
          amount: _formatSegmentAmount(entry.value, ratio, currency),
          ratio: ratio,
          color: color,
        ),
      );
    }

    return _ReportBreakdown(
      segments: segments,
      total: total,
      currency: currency,
      range: range,
    );
  }

  String _periodTitle(DateTimeRange? range, _ReportPeriod period) {
    if (period == _ReportPeriod.all) {
      return 'All activity';
    }
    if (period == _ReportPeriod.custom) {
      return 'Custom range';
    }
    if (range == null) {
      return period.label;
    }

    final start = range.start;
    final end = range.end.subtract(const Duration(seconds: 1));
    switch (period) {
      case _ReportPeriod.day:
        return '${_monthNames[start.month - 1]} ${start.day}, ${start.year}';
      case _ReportPeriod.week:
        final startLabel =
            '${_monthNames[start.month - 1]} ${start.day}, ${start.year}';
        final endLabel =
            '${_monthNames[end.month - 1]} ${end.day}, ${end.year}';
        return '$startLabel – $endLabel';
      case _ReportPeriod.month:
        return '${_monthNames[start.month - 1]} ${start.year}';
      case _ReportPeriod.quarter:
        final quarter = ((start.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${start.year}';
      case _ReportPeriod.custom:
      case _ReportPeriod.all:
        return 'All activity';
    }
  }

  String _comparisonSubtitle(_ReportPeriod period) {
    switch (period) {
      case _ReportPeriod.day:
        return 'Compared to yesterday';
      case _ReportPeriod.week:
        return 'Compared to last week';
      case _ReportPeriod.month:
        return 'Compared to last month';
      case _ReportPeriod.quarter:
        return 'Compared to last quarter';
      case _ReportPeriod.custom:
        return 'Custom insights';
      case _ReportPeriod.all:
        return 'Lifetime summary';
    }
  }

  Future<void> _shareBreakdown(_ReportBreakdown breakdown) async {
    final subject =
        'MoneyBase ${_selectedDimension.label.toLowerCase()} report';
    final periodLabel = _periodTitle(breakdown.range, _selectedPeriod);
    if (breakdown.segments.isEmpty) {
      await Share.share(
        '$subject for $periodLabel\nNo activity recorded yet.',
        subject: subject,
      );
      return;
    }

    final formatter = _currencyFormatter(breakdown.currency);
    final buffer = StringBuffer()
      ..writeln('$subject for $periodLabel')
      ..writeln('Total: ${formatter.format(breakdown.total)}')
      ..writeln('Breakdown:');

    for (final segment in breakdown.segments) {
      buffer.writeln('- ${segment.label}: ${segment.amount}');
    }

    await Share.share(buffer.toString(), subject: subject);
  }

  @override
  Widget build(BuildContext context) {
    final transactionRepository = ref.watch(transactionRepositoryProvider);
    final categoryRepository = ref.watch(categoryRepositoryProvider);
    final walletRepository = ref.watch(walletRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return MoneyBaseScaffold(
        builder: (context, layout) {
          return Center(
            child: Text(
              'Sign in to view your MoneyBase activity reports.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
          );
        },
      );
    }

    return MoneyBaseScaffold(
      builder: (context, layout) {
        return StreamBuilder<List<MoneyBaseTransaction>>(
          stream: transactionRepository.watchTransactions(user.uid),
          builder: (context, transactionSnapshot) {
            if (transactionSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load transactions: ${transactionSnapshot.error}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                         ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final transactions =
                transactionSnapshot.data ?? const <MoneyBaseTransaction>[];
            final transactionLoading = transactionSnapshot.connectionState ==
                    ConnectionState.waiting &&
                transactions.isEmpty;

            return StreamBuilder<List<Category>>(
              stream: categoryRepository.watchCategories(user.uid),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load categories: ${categorySnapshot.error}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                             ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final categories = {
                  for (final category
                      in categorySnapshot.data ?? const <Category>[])
                    category.id: category,
                };
                final categoryLoading =
                    categorySnapshot.connectionState == ConnectionState.waiting &&
                        categories.isEmpty;
                return StreamBuilder<List<Wallet>>(
                  stream: walletRepository.watchWallets(user.uid),
                  builder: (context, walletSnapshot) {
                    if (walletSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Unable to load wallets: ${walletSnapshot.error}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                 ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final wallets =
                        walletSnapshot.data ?? const <Wallet>[];
                    final walletLoading =
                        walletSnapshot.connectionState == ConnectionState.waiting &&
                            wallets.isEmpty;

                    final walletMap = {
                      for (final wallet in wallets) wallet.id: wallet,
                      _unassignedWalletKey: const Wallet(name: 'Unassigned wallet'),
                    };

                    final breakdown = _selectedDimension ==
                            _ReportDimension.categories
                        ? _buildCategoryBreakdown(
                            transactions,
                            categories,
                            _selectedPeriod,
                          )
                        : _buildWalletBreakdown(
                            transactions,
                            walletMap,
                            _selectedPeriod,
                          );

                    final loading =
                        transactionLoading || categoryLoading || walletLoading;

                    return _ReportsContent(
                      segments: breakdown.segments,
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: (period) {
                        setState(() => _selectedPeriod = period);
                      },
                      selectedDimension: _selectedDimension,
                      onDimensionChanged: (dimension) {
                        setState(() => _selectedDimension = dimension);
                      },
                      totalAmount: breakdown.total,
                      currencyCode: breakdown.currency,
                      loading: loading,
                      periodLabel:
                          _periodTitle(breakdown.range, _selectedPeriod),
                      periodSubtitle: _comparisonSubtitle(_selectedPeriod),
                      hasTransactions: transactions.isNotEmpty,
                      onShare: () => _shareBreakdown(breakdown),
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

class _ReportBreakdown {
  const _ReportBreakdown({
    required this.segments,
    required this.total,
    required this.currency,
    required this.range,
  });

  final List<_ReportSegment> segments;
  final double total;
  final String currency;
  final DateTimeRange? range;
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({
    required this.segments,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.selectedDimension,
    required this.onDimensionChanged,
    required this.totalAmount,
    required this.currencyCode,
    required this.loading,
    required this.periodLabel,
    required this.periodSubtitle,
    required this.hasTransactions,
    required this.onShare,
  });

  final List<_ReportSegment> segments;
  final _ReportPeriod selectedPeriod;
  final ValueChanged<_ReportPeriod> onPeriodChanged;
  final _ReportDimension selectedDimension;
  final ValueChanged<_ReportDimension> onDimensionChanged;
  final double totalAmount;
  final String currencyCode;
  final bool loading;
  final String periodLabel;
  final String periodSubtitle;
  final bool hasTransactions;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final surfaceTextColor = Theme.of(context).colorScheme.onSurface;
    final formatter = NumberFormat.simpleCurrency(
      name: currencyCode.isEmpty ? 'USD' : currencyCode.toUpperCase(),
    );
    final totalLabel = formatter.format(totalAmount);

    Widget visualization;
    if (loading) {
      visualization = const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (segments.isEmpty) {
      final message = hasTransactions
          ? 'No transactions match this period yet. Try selecting a different range.'
          : 'Add your first transaction to unlock MoneyBase spending insights.';
      visualization = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          message,
          style: textTheme.bodyLarge?.copyWith(
            color: surfaceTextColor.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      visualization = LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 720;

          final legend = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final segment in segments) ...[
                _LegendRow(segment: segment),
                if (segment != segments.last) const SizedBox(height: 18),
              ],
            ],
          );

          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 280,
                  child: _DonutChart(
                    segments: segments,
                    totalLabel: totalLabel,
                    subtitle: 'Total activity',
                  ),
                ),
                const SizedBox(height: 32),
                legend,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: _DonutChart(
                  segments: segments,
                  totalLabel: totalLabel,
                  subtitle: 'Total activity',
                ),
              ),
              const SizedBox(width: 32),
              Expanded(child: legend),
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MoneyBaseGlassIconButton(
              icon: Icons.arrow_back_ios_new,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Reports',
                    style: textTheme.headlineSmall?.copyWith(
                      color: surfaceTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time insights across your connected wallets.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: surfaceTextColor.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            MoneyBaseGlassIconButton(
              icon: Icons.ios_share,
              tooltip: 'Share report',
              onPressed: onShare,
            ),
          ],
        ),
        const SizedBox(height: 28),
        MoneyBaseSurface(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<_ReportDimension>(
                segments: const [
                  ButtonSegment(
                    value: _ReportDimension.categories,
                    icon: Icon(Icons.auto_graph_outlined),
                    label: Text('By categories'),
                  ),
                  ButtonSegment(
                    value: _ReportDimension.wallets,
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    label: Text('By wallets'),
                  ),
                ],
                selected: {selectedDimension},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    onDimensionChanged(selection.first);
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  MoneyBaseGlassIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Previous period',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          periodLabel,
                          style: textTheme.titleLarge?.copyWith(
                            color: surfaceTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          periodSubtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: surfaceTextColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  MoneyBaseGlassIconButton(
                    icon: Icons.arrow_forward,
                    tooltip: 'Next period',
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
              visualization,
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final period in _ReportPeriod.values)
                      ChoiceChip(
                      showCheckmark: false,
                      selected: selectedPeriod == period,
                      label: Text(
                        period.label,
                        style: textTheme.labelLarge?.copyWith(
                          color: selectedPeriod == period
                              ? MoneyBaseColors.grey
                              : surfaceTextColor,
                        ),
                      ),
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      selectedColor: MoneyBaseColors.yellow,
                      onSelected: (_) => onPeriodChanged(period),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: selectedPeriod == period
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment});

  final _ReportSegment segment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                segment.label,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                segment.amount,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.68),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.segments,
    required this.totalLabel,
    required this.subtitle,
  });

  final List<_ReportSegment> segments;
  final String totalLabel;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sections = [
      for (final segment in segments)
        PieChartSectionData(
          color: segment.color,
          value: segment.ratio,
          showTitle: false,
          radius: 56,
        ),
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: PieChart(
            PieChartData(
              sections: sections,
              startDegreeOffset: -90,
              sectionsSpace: 3,
              centerSpaceRadius: 72,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              totalLabel,
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReportSegment {
  const _ReportSegment({
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

enum _ReportPeriod {
  day('Day'),
  week('Week'),
  month('Month'),
  quarter('Quarter'),
  custom('Custom'),
  all('All');

  const _ReportPeriod(this.label);

  final String label;
}

enum _ReportDimension {
  categories('Categories'),
  wallets('Wallets');

  const _ReportDimension(this.label);

  final String label;
}
