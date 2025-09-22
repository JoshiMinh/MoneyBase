import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';
import '../../../core/constants/icon_library.dart';
import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/repositories/wallet_repository.dart';
import '../../../core/utils/color_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onViewReports,
    required this.onViewTransactions,
    super.key,
  });

  final VoidCallback onViewReports;
  final VoidCallback onViewTransactions;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TransactionRepository _transactionRepository;
  late final WalletRepository _walletRepository;
  late final CategoryRepository _categoryRepository;

  @override
  void initState() {
    super.initState();
    _transactionRepository = TransactionRepository();
    _walletRepository = WalletRepository();
    _categoryRepository = CategoryRepository();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return MoneyBaseScaffold(
      builder: (context, layout) {
        return _HomeContent(
          onViewReports: widget.onViewReports,
          onViewTransactions: widget.onViewTransactions,
          userId: userId,
          transactionRepository: _transactionRepository,
          walletRepository: _walletRepository,
          categoryRepository: _categoryRepository,
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.onViewReports,
    required this.onViewTransactions,
    required this.userId,
    required this.transactionRepository,
    required this.walletRepository,
    required this.categoryRepository,
  });

  final VoidCallback onViewReports;
  final VoidCallback onViewTransactions;
  final String? userId;
  final TransactionRepository transactionRepository;
  final WalletRepository walletRepository;
  final CategoryRepository categoryRepository;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your August snapshot is synced across Android and web.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            MoneyBaseGlassIconButton(
              icon: Icons.analytics_outlined,
              tooltip: 'Reports',
              onPressed: onViewReports,
            ),
            const SizedBox(width: 12),
            MoneyBaseGlassIconButton(
              icon: Icons.list_alt_outlined,
              tooltip: 'Transactions',
              onPressed: onViewTransactions,
            ),
          ],
        ),
        const SizedBox(height: 32),
        const _OverviewCard(),
        const SizedBox(height: 24),
        _RecentTransactionsCard(
          onViewTransactions: onViewTransactions,
          userId: userId,
          transactionRepository: transactionRepository,
          walletRepository: walletRepository,
          categoryRepository: categoryRepository,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard();

  static const _segments = [
    _BudgetSegment(
      label: 'Income',
      amount: r'$5000 (76%)',
      ratio: 0.76,
      color: Color(0xFF4FF3B2),
    ),
    _BudgetSegment(
      label: 'Shopping',
      amount: r'$1050 (16%)',
      ratio: 0.16,
      color: Color(0xFFFF6D8D),
    ),
    _BudgetSegment(
      label: 'Car Fix',
      amount: r'$500 (7%)',
      ratio: 0.07,
      color: Color(0xFFFFC857),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MoneyBaseSurface(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aug 2025',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
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
                          'Budget Overview',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'A quick glance at where your money is flowing this month.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        for (final segment in _segments) ...[
                          _LegendRow(segment: segment),
                          if (segment != _segments.last)
                            const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: isStacked ? 0 : 32, height: isStacked ? 32 : 0),
                  SizedBox(
                    width: isStacked ? 200 : 240,
                    height: isStacked ? 200 : 240,
                    child: const _DonutChart(
                      totalLabel: r'$6,550',
                      subtitle: 'Total flow',
                      segments: _segments,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
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

  Widget _buildSurface(TextTheme textTheme, Widget body, String subtitle) {
    return MoneyBaseSurface(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: userId == null ? null : onViewTransactions,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('See all'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
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
    final textTheme = Theme.of(context).textTheme;

    if (userId == null) {
      return _buildSurface(
        textTheme,
        Text(
          'Sign in to see your latest MoneyBase activity at a glance.',
          style: textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.72),
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
            textTheme,
            Text(
              'Unable to load recent transactions: ${transactionSnapshot.error}',
              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
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
                    textTheme,
                    const Center(child: CircularProgressIndicator()),
                    'Loading the latest activity…',
                  );
                }

                if (transactions.isEmpty) {
                  return _buildSurface(
                    textTheme,
                    Text(
                      'No transactions yet. Create one to start building insights.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.72),
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
                  textTheme,
                  Column(
                    children: List.generate(transactions.length, (index) {
                      final transaction = transactions[index];
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
                      final amountColor = transaction.isIncome
                          ? Colors.teal
                          : Theme.of(context).colorScheme.error;
                      final accent = parseHexColor(
                            categoryById[transaction.categoryId]?.color,
                          ) ??
                          amountColor;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == transactions.length - 1 ? 0 : 12,
                        ),
                        child: _TransactionTile(
                          entry: _TransactionEntry(
                            title:
                                '$displayCategoryName · $displayWalletName',
                            subtitle: _formatDate(transaction.date),
                            amount: _formatAmount(transaction),
                            icon: IconLibrary.iconForCategory(
                              categoryById[transaction.categoryId]?.iconName,
                            ),
                            accent: accent,
                            amountColor: amountColor,
                          ),
                        ),
                      );
                    }),
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
    final textTheme = Theme.of(context).textTheme;

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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.entry});

  final _TransactionEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: entry.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
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
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            entry.amount,
            style: textTheme.titleMedium?.copyWith(
              color: entry.amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.segments,
    required this.totalLabel,
    required this.subtitle,
  });

  final List<_BudgetSegment> segments;
  final String totalLabel;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CustomPaint(
            painter: _DonutChartPainter(
              segments: segments,
              strokeWidth: 24,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              totalLabel,
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.6),
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
  });

  final List<_BudgetSegment> segments;
  final double strokeWidth;

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
      ..color = Colors.white.withOpacity(0.05)
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

class _TransactionEntry {
  const _TransactionEntry({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.accent,
    required this.amountColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color accent;
  final Color amountColor;
}
