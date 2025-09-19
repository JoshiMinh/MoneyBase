import 'dart:ui';

import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';

enum _TransactionType { expense, income }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  _TransactionType _type = _TransactionType.expense;
  DateTime _selectedDate = DateTime(2025, 8, 8);
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  int _selectedCategory = 0;
  int _selectedWallet = 0;

  static const _categories = <_CategoryChipData>[
    _CategoryChipData(
      label: 'Car Fix',
      icon: Icons.directions_car_filled_outlined,
    ),
    _CategoryChipData(
      label: 'Groceries',
      icon: Icons.local_grocery_store_outlined,
    ),
    _CategoryChipData(
      label: 'Dining',
      icon: Icons.restaurant_outlined,
    ),
    _CategoryChipData(
      label: 'Travel',
      icon: Icons.flight_takeoff_outlined,
    ),
  ];

  static const _wallets = <_WalletCardData>[
    _WalletCardData(
      name: 'Vietcombank',
      balance: 'USD 900.00',
      icon: Icons.account_balance,
      gradient: [Color(0xFF1FD97C), Color(0xFF41B899)],
    ),
    _WalletCardData(
      name: 'Cash',
      balance: 'USD 650.00',
      icon: Icons.account_balance_wallet_outlined,
      gradient: [Color(0xFF9E6BFF), Color(0xFF5B3CF6)],
    ),
    _WalletCardData(
      name: 'Credit Card',
      balance: 'USD 420.00',
      icon: Icons.credit_card,
      gradient: [Color(0xFFFF8A94), Color(0xFFFF5D7A)],
    ),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7B5BFF),
              surface: Color(0xFF1B1232),
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() => _selectedDate = result);
    }
  }

  String get _formattedDate {
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    return '$month/$day/$year';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MoneyBaseScaffold(
      maxContentWidth: 960,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add transaction',
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture new spending in the refreshed MoneyBase glass surface shared between Android and web.',
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            MoneyBaseFrostedPanel(
              padding: EdgeInsets.symmetric(
                horizontal: layout.isWide ? 36 : 28,
                vertical: layout.isWide ? 36 : 28,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 32,
                  offset: Offset(0, 24),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction type',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: _TransactionType.expense,
                        label: Text('Expense'),
                        icon: Icon(Icons.south_east),
                      ),
                      ButtonSegment(
                        value: _TransactionType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.north_east),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      setState(() => _type = selection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white.withOpacity(0.72),
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor:
                          const Color(0xFF7B5BFF).withOpacity(0.65),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      textStyle: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _GlassField(
                    label: 'Date',
                    onTap: () => _pickDate(context),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formattedDate,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlassField(
                    label: 'Note',
                    child: TextField(
                      controller: _noteController,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Enter a note',
                        hintStyle: textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlassField(
                    label: 'Amount',
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration.collapsed(
                              hintText: 'Enter amount',
                              hintStyle: textTheme.headlineSmall?.copyWith(
                                color: Colors.white.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Category',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < _categories.length; i++)
                        _CategoryChip(
                          data: _categories[i],
                          selected: _selectedCategory == i,
                          onTap: () => setState(() => _selectedCategory = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Wallet',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _wallets.length; i++) ...[
                          _WalletCard(
                            data: _wallets[i],
                            selected: _selectedWallet == i,
                            onTap: () => setState(() => _selectedWallet = i),
                          ),
                          const SizedBox(width: 16),
                        ],
                        _AddWalletCard(onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            backgroundColor: const Color(0xFF7B5BFF),
                            foregroundColor: Colors.white,
                            textStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Transaction saved to ${_wallets[_selectedWallet].name} (placeholder)',
                                ),
                              ),
                            );
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.label,
    required this.child,
    this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding=
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              color: Colors.white.withOpacity(0.06),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _CategoryChipData {
  const _CategoryChipData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _CategoryChipData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color=
                selected ? Colors.white : Colors.white.withOpacity(0.18),
          ),
          color: selected
              ? Colors.white.withOpacity(0.14)
              : Colors.white.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              data.icon,
              color: selected
                  ? Colors.white
                  : Colors.white.withOpacity(0.75),
            ),
            const SizedBox(width: 10),
            Text(
              data.label,
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCardData {
  const _WalletCardData({
    required this.name,
    required this.balance,
    required this.icon,
    required this.gradient,
  });

  final String name;
  final String balance;
  final IconData icon;
  final List<Color> gradient;
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _WalletCardData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.gradient,
          ),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                data.icon,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data.name,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.balance,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWalletCard extends StatelessWidget {
  const _AddWalletCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.24),
            width: 2,
          ),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: Colors.white.withOpacity(0.8),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Add wallet',
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
