import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _segments = [
    _ReportSegment(
      label: 'Income',
      amount: '\$5000.00 (76%)',
      ratio: 0.76,
      color: Color(0xFFFFC300),
    ),
    _ReportSegment(
      label: 'Shopping',
      amount: '\$1050.00 (16%)',
      ratio: 0.16,
      color: Color(0xFF7B61FF),
    ),
    _ReportSegment(
      label: 'Car Fix',
      amount: '\$500.00 (7%)',
      ratio: 0.07,
      color: Color(0xFFFF6D8D),
    ),
  ];

  _ReportPeriod _selectedPeriod = _ReportPeriod.month;

  @override
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      builder: (context, layout) {
        return _ReportsContent(
          segments: _segments,
          selectedPeriod: _selectedPeriod,
          onPeriodChanged: (period) {
            setState(() => _selectedPeriod = period);
          },
        );
      },
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({
    required this.segments,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final List<_ReportSegment> segments;
  final _ReportPeriod selectedPeriod;
  final ValueChanged<_ReportPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'August 2025 snapshot across your connected wallets.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            MoneyBaseGlassIconButton(
              icon: Icons.ios_share,
              tooltip: 'Share report',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 28),
        MoneyBaseSurface(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MoneyBaseGlassIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Previous month',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'August 2025',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compared to last month',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  MoneyBaseGlassIconButton(
                    icon: Icons.arrow_forward,
                    tooltip: 'Next month',
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isStacked = constraints.maxWidth < 720;

                  return Flex(
                    direction: isStacked ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: isStacked ? double.infinity : 280,
                        height: 280,
                        child: _DonutChart(
                          segments: segments,
                          totalLabel: '\$6,550',
                          subtitle: 'Total activity',
                        ),
                      ),
                      SizedBox(height: isStacked ? 32 : 0, width: isStacked ? 0 : 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final segment in segments) ...[
                              _LegendRow(segment: segment),
                              if (segment != segments.last)
                                const SizedBox(height: 18),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
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
                              ? const Color(0xFF1B1232)
                              : Colors.white,
                        ),
                      ),
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      selectedColor: const Color(0xFFFFC300),
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

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CustomPaint(
            painter: _DonutChartPainter(
              segments: segments,
              strokeWidth: 28,
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

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
  });

  final List<_ReportSegment> segments;
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
