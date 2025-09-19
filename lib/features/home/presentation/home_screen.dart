import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: onViewReports,
            tooltip: 'Reports',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: onViewTransactions,
            tooltip: 'Transactions',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return _HomeWideView(
              onAddTransaction: onAddTransaction,
              onViewReports: onViewReports,
              onViewTransactions: onViewTransactions,
            );
          }

          return _HomeCompactView(
            onAddTransaction: onAddTransaction,
            onViewReports: onViewReports,
            onViewTransactions: onViewTransactions,
          );
        },
      ),
    );
  }
}

class _HomeCompactView extends StatelessWidget {
  const _HomeCompactView({
    required this.onAddTransaction,
    required this.onViewReports,
    required this.onViewTransactions,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onViewReports;
  final VoidCallback onViewTransactions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Text(
          'Welcome back, Jamie! 👋',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Track your balance, review weekly spending, and jump straight into the flows '
          'you already have on Android.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _DashboardCard(
          title: 'Total balance',
          actions: [
            FilledButton.tonalIcon(
              onPressed: onAddTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add transaction'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                r'$12,480.00',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('Latest sync 5 minutes ago • Wallets: Personal, Business'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DashboardCard(
          title: 'At a glance',
          child: Column(
            children: const [
              _MetricRow(label: 'This month income', value: r'$5,420'),
              SizedBox(height: 12),
              _MetricRow(label: 'This month expense', value: r'$3,870'),
              SizedBox(height: 12),
              _MetricRow(label: 'Upcoming bills', value: r'$540 due soon'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _DashboardCard(
          title: 'Spending breakdown',
          actions: [
            TextButton.icon(
              onPressed: onViewReports,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open reports'),
            ),
          ],
          child: const _ChartPlaceholder(
            icon: Icons.pie_chart_outline,
            label:
                'Connect your Firestore categories to populate the pie chart.',
          ),
        ),
        const SizedBox(height: 24),
        _DashboardCard(
          title: 'Recent activity',
          actions: [
            TextButton(
              onPressed: onViewTransactions,
              child: const Text('View all transactions'),
            ),
          ],
          child: const _RecentTransactionsList(),
        ),
      ],
    );
  }
}

class _HomeWideView extends StatelessWidget {
  const _HomeWideView({
    required this.onAddTransaction,
    required this.onViewReports,
    required this.onViewTransactions,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onViewReports;
  final VoidCallback onViewTransactions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
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
                          'Good afternoon, Jamie',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Android dashboard is now available on the web. Plug in the Firestore '
                          'streams to replace these placeholders.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  FilledButton.icon(
                    onPressed: onAddTransaction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add transaction'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _DashboardCard(
                          title: 'Total balance',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r'$12,480.00',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                r'Cash • $4,280  |  Savings • $6,100  |  Investments • $2,100',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: const [
                                  _ChipStat(
                                    label: '30 day change',
                                    value: '+8.2%',
                                  ),
                                  _ChipStat(
                                    label: 'Budget health',
                                    value: 'On track',
                                  ),
                                  _ChipStat(
                                    label: 'Sync status',
                                    value: 'Live',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _DashboardCard(
                          title: 'Quick actions',
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: onAddTransaction,
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Record expense'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: onViewTransactions,
                                icon: const Icon(Icons.receipt_long_outlined),
                                label: const Text('View ledger'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: onViewReports,
                                icon: const Icon(Icons.auto_graph_outlined),
                                label: const Text('Open analytics'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _DashboardCard(
                          title: 'Spending breakdown',
                          actions: [
                            IconButton(
                              tooltip: 'Open reports',
                              onPressed: onViewReports,
                              icon: const Icon(Icons.open_in_new),
                            ),
                          ],
                          child: const _ChartPlaceholder(
                            icon: Icons.pie_chart_outline,
                            label:
                                'Chart and category insights from the Compose dashboard appear here.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _DashboardCard(
                          title: 'Income vs expense',
                          child: const _ChartPlaceholder(
                            icon: Icons.stacked_line_chart,
                            label:
                                'Use a Flutter charting library to rebuild the Compose bar comparison.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DashboardCard(
                title: 'Recent activity',
                actions: [
                  TextButton.icon(
                    onPressed: onViewTransactions,
                    icon: const Icon(Icons.view_list_outlined),
                    label: const Text('View all transactions'),
                  ),
                ],
                child: const _RecentTransactionsList(expanded: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(title, style: titleStyle)),
                if (actions != null)
                  Wrap(spacing: 12, runSpacing: 12, children: actions!),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceVariant = colorScheme.surfaceVariant;

    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: surfaceVariant.withOpacity(0.3),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  const _RecentTransactionsList({this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final items = List.generate(5, (index) {
      final incoming = index.isEven;
      return _TransactionPreview(
        title: incoming ? 'Freelance payment' : 'Coffee with client',
        subtitle: incoming
            ? 'Business wallet • Invoices'
            : 'Personal wallet • Dining',
        amount: incoming ? r'+$750.00' : r'-$18.50',
        positive: incoming,
      );
    });

    return SizedBox(
      height: expanded ? 320 : null,
      child: ListView.separated(
        shrinkWrap: !expanded,
        physics: expanded ? null : const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}

class _TransactionPreview extends StatelessWidget {
  const _TransactionPreview({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.teal : Theme.of(context).colorScheme.error;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(
          positive ? Icons.trending_up : Icons.trending_down,
          color: color,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
