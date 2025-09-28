import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import '../../../common/presentation/moneybase_shell.dart';

class MonthlyInsightsReportCard extends StatelessWidget {
  const MonthlyInsightsReportCard({super.key, required this.onViewReports});

  final VoidCallback onViewReports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final mutedOnSurface = colors.mutedText;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 360),
      child: MoneyBaseSurface(
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
              subtitle: 'You spent $250 less compared to last month.',
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
