import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';
import '../../../common/presentation/moneybase_shell.dart';

class WeeklySnapshotReportCard extends StatelessWidget {
  const WeeklySnapshotReportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
              'This week report',
              style: textTheme.titleMedium?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Great job keeping things balanced. Here’s how the last seven days are shaping up.',
              style: textTheme.bodyMedium?.copyWith(color: mutedOnSurface),
            ),
            const SizedBox(height: 24),
            _ReportInsightTile(
              icon: Icons.payments_outlined,
              title: '42% of weekly budget used',
              subtitle: 'You still have room to spend $180 across your active plans.',
              iconTint: colors.secondaryAccent,
              textColor: onSurface,
              subtitleColor: mutedOnSurface,
            ),
            const SizedBox(height: 12),
            _ReportInsightTile(
              icon: Icons.trending_down,
              title: 'Spending cooled since Monday',
              subtitle: 'Daily expenses dropped 18% compared to the start of the week.',
              iconTint: colors.primaryAccent,
              textColor: onSurface,
              subtitleColor: mutedOnSurface,
            ),
            const SizedBox(height: 12),
            _ReportInsightTile(
              icon: Icons.check_circle_outline,
              title: '3 goals hit in a row',
              subtitle: 'Groceries, transport, and wellness stayed under their targets.',
              iconTint: colors.tertiaryAccent,
              textColor: onSurface,
              subtitleColor: mutedOnSurface,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _WeeklyStatChip(
                  label: 'Avg. daily spend',
                  value: '$56.40',
                  icon: Icons.calendar_view_week,
                ),
                _WeeklyStatChip(
                  label: 'Largest purchase',
                  value: '$142 • Home',
                  icon: Icons.home_outlined,
                ),
                _WeeklyStatChip(
                  label: 'Upcoming bills',
                  value: '2 due this weekend',
                  icon: Icons.receipt_long_outlined,
                ),
              ],
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

class _WeeklyStatChip extends StatelessWidget {
  const _WeeklyStatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primaryAccent, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.titleSmall?.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
