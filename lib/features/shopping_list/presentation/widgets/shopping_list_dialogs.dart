import 'package:flutter/material.dart';
import 'package:moneybase/app/theme/theme.dart';
import 'package:moneybase/core/constants/currencies.dart';
import 'package:moneybase/core/models/shopping_item.dart';
import 'package:moneybase/core/models/shopping_list.dart';
import 'package:moneybase/features/common/presentation/currency_dropdown_field.dart';

import '../utils/shopping_list_formatters.dart';

Future<ShoppingList?> showShoppingListDialog(
  BuildContext context, {
  ShoppingList? initial,
}) {
  return showDialog<ShoppingList>(
    context: context,
    builder: (context) => ShoppingListDialog(initial: initial),
  );
}

Future<ShoppingItem?> showShoppingItemDialog(
  BuildContext context, {
  required ShoppingList list,
  ShoppingItem? initial,
}) {
  return showDialog<ShoppingItem>(
    context: context,
    builder: (context) => ShoppingItemDialog(list: list, initial: initial),
  );
}

Future<String?> showShoppingItemsImportDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const ShoppingItemsImportDialog(),
  );
}

class ShoppingListDialog extends StatefulWidget {
  const ShoppingListDialog({this.initial, super.key});

  final ShoppingList? initial;

  @override
  State<ShoppingListDialog> createState() => _ShoppingListDialogState();
}

class _ShoppingListDialogState extends State<ShoppingListDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late ShoppingListType _type;
  late String _currencyCode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _notesController = TextEditingController(text: widget.initial?.notes ?? '');
    _type = widget.initial?.type ?? ShoppingListType.grocery;
    _currencyCode = currencyOptionFor(widget.initial?.currency).code;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final notes = _notesController.text.trim();
    final base = widget.initial ?? ShoppingList();

    Navigator.of(context).pop(
      base.copyWith(
        name: name,
        notes: notes.isEmpty ? null : notes,
        type: _type,
        currency: _currencyCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null
          ? 'New shopping list'
          : 'Edit shopping list'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'List name'),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a list name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShoppingListType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'List type'),
                items: ShoppingListType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              if (_type == ShoppingListType.grocery) ...[
                const SizedBox(height: 12),
                CurrencyDropdownFormField(
                  value: _currencyCode,
                  labelText: 'Currency',
                  onChanged: (code) => setState(() => _currencyCode = code),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Share extra context with collaborators',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ShoppingItemsImportDialog extends StatefulWidget {
  const ShoppingItemsImportDialog({super.key});

  @override
  State<ShoppingItemsImportDialog> createState() =>
      _ShoppingItemsImportDialogState();
}

class _ShoppingItemsImportDialogState
    extends State<ShoppingItemsImportDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.moneyBaseColors;

    return AlertDialog(
      title: const Text('Import shopping items'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste the JSON export that follows the provided Notion sample format.',
                style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                minLines: 6,
                maxLines: 16,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Shopping items JSON',
                  alignLabelWithHint: true,
                  hintText: '{ "object": "list", "results": [ ... ] }',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Provide the JSON payload to import.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) {
              return;
            }
            Navigator.of(context).pop(_controller.text);
          },
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class ShoppingItemDialog extends StatefulWidget {
  const ShoppingItemDialog({
    required this.list,
    this.initial,
    super.key,
  });

  final ShoppingList list;
  final ShoppingItem? initial;

  @override
  State<ShoppingItemDialog> createState() => _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends State<ShoppingItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _emojiController;
  late final TextEditingController _iconUrlController;
  bool _bought = false;
  ShoppingItemPriority _priority = ShoppingItemPriority.medium;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  late String _currencyCode;

  bool get _isShoppingList => widget.list.type == ShoppingListType.shopping;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _priceController = TextEditingController(
      text: initial != null && initial.price > 0
          ? initial.price.toStringAsFixed(2)
          : '',
    );
    final defaultCurrency = widget.list.currency;
    _currencyCode =
        currencyOptionFor(initial?.currency ?? defaultCurrency).code;
    if (!_isShoppingList) {
      _currencyCode = currencyOptionFor(defaultCurrency).code;
    }
    _emojiController = TextEditingController(text: initial?.iconEmoji ?? '');
    _iconUrlController = TextEditingController(text: initial?.iconUrl ?? '');
    _priority = initial?.priority ?? ShoppingItemPriority.medium;
    _bought = initial?.bought ?? false;
    _purchaseDate = initial?.purchaseDate;
    _expiryDate = _isShoppingList ? initial?.expiryDate : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _emojiController.dispose();
    _iconUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isPurchase}) async {
    final now = DateTime.now();
    final initialDate =
        isPurchase ? (_purchaseDate ?? now) : (_expiryDate ?? now);

    final result = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (result != null) {
      setState(() {
        if (isPurchase) {
          _purchaseDate = result;
        } else {
          _expiryDate = result;
        }
      });
    }
  }

  void _clearDate(bool isPurchase) {
    setState(() {
      if (isPurchase) {
        _purchaseDate = null;
      } else {
        _expiryDate = null;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text.trim();
    final parsedPrice = double.tryParse(priceText);
    final price = parsedPrice != null && parsedPrice > 0 ? parsedPrice : 0.0;

    final currency = _isShoppingList ? _currencyCode : widget.list.currency;

    final emoji = _emojiController.text.trim();
    final iconUrl = _isShoppingList ? _iconUrlController.text.trim() : '';

    final base = widget.initial ?? ShoppingItem();

    Navigator.of(context).pop(
      base.copyWith(
        title: _titleController.text.trim(),
        price: price,
        currency: currency,
        priority: _priority,
        bought: _bought,
        iconEmoji: emoji.isEmpty ? null : emoji,
        iconUrl: iconUrl.isEmpty ? null : iconUrl,
        purchaseDate: _purchaseDate,
        expiryDate: _isShoppingList ? _expiryDate : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add item' : 'Edit item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Item title'),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShoppingItemPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ShoppingItemPriority.values
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority.labelTitleCase),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _priority = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              CurrencyDropdownFormField(
                value: _isShoppingList ? _currencyCode : widget.list.currency,
                labelText: 'Currency',
                helperText: _isShoppingList
                    ? null
                    : 'Currency is managed at the grocery list level.',
                enabled: _isShoppingList,
                onChanged: (code) => setState(() => _currencyCode = code),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emojiController,
                decoration: const InputDecoration(labelText: 'Emoji icon'),
                maxLength: 2,
              ),
              if (_isShoppingList) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _iconUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    helperText: 'Paste an image link to use as the icon.',
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _bought,
                onChanged: (value) => setState(() => _bought = value ?? false),
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as purchased'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DatePickerChip(
                    label: _purchaseDate != null
                        ? 'Needed ${formatShoppingDate(_purchaseDate!)}'
                        : 'Set need-by date',
                    onPressed: () => _pickDate(isPurchase: true),
                    onClear:
                        _purchaseDate != null ? () => _clearDate(true) : null,
                  ),
                  if (_isShoppingList)
                    _DatePickerChip(
                      label: _expiryDate != null
                          ? 'Expires ${formatShoppingDate(_expiryDate!)}'
                          : 'Set expiry date',
                      onPressed: () => _pickDate(isPurchase: false),
                      onClear: _expiryDate != null
                          ? () => _clearDate(false)
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DatePickerChip extends StatelessWidget {
  const _DatePickerChip({
    required this.label,
    required this.onPressed,
    this.onClear,
  });

  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.event_outlined),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.moneyBaseColors.primaryAccent,
      ),
    );

    if (onClear == null) {
      return button;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 6),
        IconButton(
          onPressed: onClear,
          tooltip: 'Clear date',
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
