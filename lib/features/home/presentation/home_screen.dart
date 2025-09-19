import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      builder: (context, layout) {
        return _HomeContent(
          onAddTransaction: onAddTransaction,
          onViewReports: onViewReports,
          onViewTransactions: onViewTransactions,
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.onAddTransaction,
    required this.onViewReports,
    required this.onViewTransactions,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onViewReports;
  final VoidCallback onViewTransactions;

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
            FilledButton.icon(
              onPressed: onAddTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add transaction'),
            ),
            const SizedBox(width: 12),
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
        _RecentTransactionsCard(onViewTransactions: onViewTransactions),
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
  const _RecentTransactionsCard({required this.onViewTransactions});

  final VoidCallback onViewTransactions;

  static const _transactions = [
    _TransactionEntry(
      title: 'Shopping · Cash',
      subtitle: 'Aug 08, 2025',
      amount: r'-USD 50.0',
      icon: Icons.local_mall_outlined,
      accent: Color(0xFFFF6D8D),
    ),
    _TransactionEntry(
      title: 'Income · Cash',
      subtitle: 'Aug 08, 2025',
      amount: r'+USD 5000.0',
      icon: Icons.payments_outlined,
      accent: Color(0xFF4FF3B2),
    ),
    _TransactionEntry(
      title: 'Shopping · Vietcombank',
      subtitle: 'Aug 08, 2025',
      amount: r'-USD 1000.0',
      icon: Icons.directions_car_filled_outlined,
      accent: Color(0xFFFFC857),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                      'Updated Aug 08, 2025',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onViewTransactions,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('See all'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (final entry in _transactions) ...[
            _TransactionTile(entry: entry),
            if (entry != _transactions.last)
              const SizedBox(height: 12),
          ],
        ],
      ),
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
    final isPositive = entry.amount.startsWith('+');
    final amountColor = isPositive ? const Color(0xFF4FF3B2) : const Color(0xFFFF6D8D);

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
              color: amountColor,
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
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final Color accent;
}
