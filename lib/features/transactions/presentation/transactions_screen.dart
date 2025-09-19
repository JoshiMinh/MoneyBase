import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = List.generate(10, (index) {
      final positive = index.isEven;
      return _TransactionRow(
        date: 'Apr ${12 + index}',
        description: positive ? 'Invoice payment' : 'Team lunch',
        category: positive ? 'Income' : 'Dining',
        wallet: positive ? 'Business' : 'Personal',
        amount: positive ? r'+$420.00' : r'-$84.50',
        positive: positive,
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final padding = EdgeInsets.symmetric(
            horizontal: isWide ? 48 : 24,
            vertical: 32,
          );

          if (isWide) {
            return Center(
              child: SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: DataTable(
                      headingRowColor:
                          MaterialStateProperty.resolveWith<Color?>(
                            (_) => Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.4),
                          ),
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Wallet')),
                        DataColumn(label: Text('Amount'), numeric: true),
                      ],
                      rows: [
                        for (final row in sample)
                          DataRow(
                            cells: [
                              DataCell(Text(row.date)),
                              DataCell(Text(row.description)),
                              DataCell(Text(row.category)),
                              DataCell(Text(row.wallet)),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    row.amount,
                                    style: TextStyle(
                                      color: row.positive
                                          ? Colors.teal
                                          : Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: padding,
            itemCount: sample.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = sample[index];
              final color = item.positive
                  ? Colors.teal
                  : Theme.of(context).colorScheme.error;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                    item.positive ? Icons.trending_up : Icons.trending_down,
                    color: color,
                  ),
                ),
                title: Text(item.description),
                subtitle: Text(
                  '${item.date} • ${item.wallet} • ${item.category}',
                ),
                trailing: Text(
                  item.amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TransactionRow {
  const _TransactionRow({
    required this.date,
    required this.description,
    required this.category,
    required this.wallet,
    required this.amount,
    required this.positive,
  });

  final String date;
  final String description;
  final String category;
  final String wallet;
  final String amount;
  final bool positive;
}
