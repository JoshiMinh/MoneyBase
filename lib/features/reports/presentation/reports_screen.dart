import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final padding = EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 24,
            vertical: 32,
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visualize trends',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Bring over the Compose analytics experience with period selectors, charts, '
                'and drill-ins. These placeholders help you stage the layout before wiring data.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: const [
                  _ReportCard(
                    title: 'Income vs Expense',
                    subtitle: 'Translate the Compose bar chart into Flutter.',
                    icon: Icons.query_stats_outlined,
                    height: 260,
                  ),
                  _ReportCard(
                    title: 'Category spending',
                    subtitle:
                        'Use the same Firestore aggregation powering the Android pie chart.',
                    icon: Icons.donut_large_outlined,
                    height: 260,
                  ),
                  _ReportCard(
                    title: 'Cash flow over time',
                    subtitle:
                        'Map monthly totals into a line chart with filters.',
                    icon: Icons.show_chart_outlined,
                    height: 260,
                  ),
                  _ReportCard(
                    title: 'Top merchants',
                    subtitle:
                        'Populate with your existing grouped query results.',
                    icon: Icons.storefront_outlined,
                    height: 220,
                  ),
                ],
              ),
            ],
          );

          if (isWide) {
            return Center(
              child: SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: content,
                ),
              ),
            );
          }

          return SingleChildScrollView(padding: padding, child: content);
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.height,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 320,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(icon, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: height,
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surfaceVariant.withOpacity(0.35),
                  ),
                  child: Center(
                    child: Icon(icon, size: 64, color: colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
