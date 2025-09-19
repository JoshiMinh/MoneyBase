import 'package:flutter/material.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 64 : 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick capture',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This form mirrors the Compose add transaction flow. Replace the placeholders '
                      'with your controllers, validation, and Firestore integration.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    const _AmountAndTypeSection(),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: const [
                        _DropdownField(
                          label: 'Wallet',
                          items: ['Personal', 'Business', 'Savings'],
                        ),
                        _DropdownField(
                          label: 'Category',
                          items: ['Shopping', 'Food', 'Salary', 'Transfer'],
                        ),
                        _DropdownField(
                          label: 'Currency',
                          items: ['USD', 'EUR', 'GBP'],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _DateAndAttachmentSection(),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText:
                            'Add a memo, receipt reference, or tags just like the Android implementation.',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Clear form'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Transaction saved! (placeholder)',
                                  ),
                                ),
                              ),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save transaction'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AmountAndTypeSection extends StatefulWidget {
  const _AmountAndTypeSection();

  @override
  State<_AmountAndTypeSection> createState() => _AmountAndTypeSectionState();
}

class _AmountAndTypeSectionState extends State<_AmountAndTypeSection> {
  bool _isIncome = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount & type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: r'$',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ToggleButtons(
                  isSelected: [_isIncome, !_isIncome],
                  onPressed: (index) {
                    setState(() => _isIncome = index == 0);
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Income'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Expense'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.label, required this.items});

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in items)
            DropdownMenuItem<String>(value: item, child: Text(item)),
        ],
        onChanged: (_) {},
      ),
    );
  }
}

class _DateAndAttachmentSection extends StatelessWidget {
  const _DateAndAttachmentSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule & attachments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 200,
                    maxWidth: 260,
                  ),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    readOnly: true,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 200,
                    maxWidth: 260,
                  ),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      suffixIcon: Icon(Icons.schedule_outlined),
                    ),
                    readOnly: true,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Upload receipt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
