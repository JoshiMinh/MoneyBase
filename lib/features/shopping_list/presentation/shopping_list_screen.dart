import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/shopping_item.dart';
import '../../../core/models/shopping_list.dart';
import '../../../core/repositories/shopping_list_repository.dart';
import '../../common/presentation/moneybase_shell.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late final ShoppingListRepository _repository;
  String? _selectedListId;

  @override
  void initState() {
    super.initState();
    _repository = ShoppingListRepository();
  }

  void _syncSelection(List<ShoppingList> lists) {
    if (lists.isEmpty) {
      if (_selectedListId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedListId = null);
        });
      }
      return;
    }

    final containsSelection =
        lists.any((list) => list.id == _selectedListId && _selectedListId != null);

    if (!containsSelection) {
      final firstId = lists.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedListId = firstId);
      });
    }
  }

  Future<void> _openListDialog(
    BuildContext context,
    String userId, {
    ShoppingList? initial,
  }) async {
    final result = await showDialog<ShoppingList>(
      context: context,
      builder: (context) => _ShoppingListDialog(initial: initial),
    );

    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (initial == null) {
        await _repository.addShoppingList(userId, result);
        messenger.showSnackBar(
          const SnackBar(content: Text('Shopping list created.')),
        );
      } else {
        await _repository.updateShoppingList(userId, result);
        messenger.showSnackBar(
          const SnackBar(content: Text('Shopping list updated.')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save shopping list: $error')),
      );
    }
  }

  Future<void> _deleteList(
    BuildContext context,
    String userId,
    ShoppingList list,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete shopping list?'),
        content: Text(
          'This will remove "${list.name.isEmpty ? 'Untitled list' : list.name}" and all of its items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE54C4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.deleteShoppingList(userId, list.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Shopping list removed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete shopping list: $error')),
      );
    }
  }

  Future<void> _openItemDialog(
    BuildContext context,
    String userId,
    ShoppingList list, {
    ShoppingItem? initial,
  }) async {
    final result = await showDialog<ShoppingItem>(
      context: context,
      builder: (context) => _ShoppingItemDialog(initial: initial),
    );

    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (initial == null) {
        await _repository.addItem(userId, list.id, result);
        messenger.showSnackBar(
          SnackBar(
            content: Text('"${result.title}" added to ${list.name.isEmpty ? 'your list' : list.name}.'),
          ),
        );
      } else {
        await _repository.updateItem(userId, list.id, result);
        messenger.showSnackBar(
          const SnackBar(content: Text('Shopping item updated.')),
        );
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save item: $error')),
      );
    }
  }

  Future<void> _deleteItem(
    BuildContext context,
    String userId,
    ShoppingList list,
    ShoppingItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Delete "${item.title}" from ${list.name.isEmpty ? 'this list' : list.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE54C4C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.deleteItem(userId, list.id, item.id);
      messenger.showSnackBar(
        SnackBar(content: Text('"${item.title}" removed.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to remove item: $error')),
      );
    }
  }

  Future<void> _toggleItem(
    BuildContext context,
    String userId,
    ShoppingList list,
    ShoppingItem item,
    bool bought,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.setItemBought(userId, list.id, item.id, bought);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            bought
                ? 'Marked "${item.title}" as purchased.'
                : 'Marked "${item.title}" as pending.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update item: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MoneyBaseScaffold(
      builder: (context, layout) {
        final textTheme = Theme.of(context).textTheme;

        if (user == null) {
          return Center(
            child: Text(
              'Sign in to create collaborative shopping lists.',
              style: textTheme.titleMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        }

        return StreamBuilder<List<ShoppingList>>(
          stream: _repository.watchShoppingLists(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load shopping lists: ${snapshot.error}',
                  style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final lists = snapshot.data ?? const <ShoppingList>[];
            _syncSelection(lists);

            final selectedList =
                lists.firstWhere((list) => list.id == _selectedListId, orElse: () => ShoppingList());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shopping List',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plan your next trip and keep essentials synced across devices.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 32),
                MoneyBaseSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: _ListsSection(
                    lists: lists,
                    selectedListId: _selectedListId,
                    onSelectList: (id) => setState(() => _selectedListId = id),
                    onCreateList: () => _openListDialog(context, user.uid),
                    onEditList: (list) => _openListDialog(context, user.uid, initial: list),
                    onDeleteList: (list) => _deleteList(context, user.uid, list),
                  ),
                ),
                const SizedBox(height: 24),
                MoneyBaseSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: _ItemsSection(
                    userId: user.uid,
                    list: selectedList.id.isEmpty ? null : selectedList,
                    repository: _repository,
                    onAddItem: (list) => _openItemDialog(context, user.uid, list),
                    onEditItem: (list, item) =>
                        _openItemDialog(context, user.uid, list, initial: item),
                    onDeleteItem: (list, item) =>
                        _deleteItem(context, user.uid, list, item),
                    onToggleItem: (list, item, bought) =>
                        _toggleItem(context, user.uid, list, item, bought),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ListsSection extends StatelessWidget {
  const _ListsSection({
    required this.lists,
    required this.selectedListId,
    required this.onSelectList,
    required this.onCreateList,
    required this.onEditList,
    required this.onDeleteList,
  });

  final List<ShoppingList> lists;
  final String? selectedListId;
  final ValueChanged<String> onSelectList;
  final VoidCallback onCreateList;
  final ValueChanged<ShoppingList> onEditList;
  final ValueChanged<ShoppingList> onDeleteList;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Your lists',
                style: textTheme.titleMedium?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onCreateList,
              icon: const Icon(Icons.add),
              label: const Text('New list'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (lists.isEmpty)
          Text(
            'Start by creating a list for groceries or a weekend project.',
            style: textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.7)),
          )
        else
          Column(
            children: [
              for (final list in lists) ...[
                _ListTile(
                  list: list,
                  selected: list.id == selectedListId,
                  onTap: () => onSelectList(list.id),
                  onEdit: () => onEditList(list),
                  onDelete: () => onDeleteList(list),
                ),
                if (list != lists.last) const SizedBox(height: 16),
              ],
            ],
          ),
      ],
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.list,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingList list;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final baseColor = theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surface;

    final background =
        selected ? baseColor.withOpacity(0.5) : baseColor.withOpacity(0.2);
    final borderColor = selected
        ? colorScheme.primary.withOpacity(0.6)
        : colorScheme.outlineVariant.withOpacity(theme.brightness == Brightness.dark ? 0.5 : 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          list.name.isEmpty ? 'Untitled list' : list.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          list.type.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    list.notes?.isNotEmpty == true
                        ? list.notes!
                        : 'Created ${_formatDate(list.createdAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onSurface.withOpacity(0.68),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<_ListAction>(
              onSelected: (action) {
                switch (action) {
                  case _ListAction.edit:
                    onEdit();
                    break;
                  case _ListAction.delete:
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _ListAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: _ListAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ListAction { edit, delete }

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.userId,
    required this.list,
    required this.repository,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleItem,
  });

  final String userId;
  final ShoppingList? list;
  final ShoppingListRepository repository;
  final ValueChanged<ShoppingList> onAddItem;
  final void Function(ShoppingList, ShoppingItem) onEditItem;
  final void Function(ShoppingList, ShoppingItem) onDeleteItem;
  final void Function(ShoppingList, ShoppingItem, bool) onToggleItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final onSurface = theme.colorScheme.onSurface;

    if (list == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items',
            style: textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose a list to start adding items.',
            style: textTheme.bodyMedium?.copyWith(
              color: onSurface.withOpacity(0.7),
            ),
          ),
        ],
      );
    }

    return StreamBuilder<List<ShoppingItem>>(
      stream: repository.watchItems(userId, list!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ItemsHeader(onSurface: onSurface, textTheme: textTheme, onAddItem: () => onAddItem(list!)),
              const SizedBox(height: 16),
              Text(
                'Unable to load items: ${snapshot.error}',
                style: textTheme.bodyMedium?.copyWith(
                  color: onSurface.withOpacity(0.7),
                ),
              ),
            ],
          );
        }

        final items = snapshot.data ?? const <ShoppingItem>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ItemsHeader(
              onSurface: onSurface,
              textTheme: textTheme,
              onAddItem: () => onAddItem(list!),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(
                'Add essentials, plan meals, and track quantities in one place.',
                style: textTheme.bodyMedium?.copyWith(
                  color: onSurface.withOpacity(0.7),
                ),
              )
            else
              Column(
                children: [
                  for (final item in items) ...[
                    _ItemTile(
                      list: list!,
                      item: item,
                      onEdit: () => onEditItem(list!, item),
                      onDelete: () => onDeleteItem(list!, item),
                      onToggle: (value) => onToggleItem(list!, item, value),
                    ),
                    if (item != items.last) const Divider(height: 28),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader({
    required this.onSurface,
    required this.textTheme,
    required this.onAddItem,
  });

  final Color onSurface;
  final TextTheme textTheme;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Items',
            style: textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onAddItem,
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Add item'),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.list,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final ShoppingList list;
  final ShoppingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  Color _priorityColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (item.priority) {
      case ShoppingItemPriority.low:
        return scheme.tertiary;
      case ShoppingItemPriority.medium:
        return scheme.secondary;
      case ShoppingItemPriority.high:
        return scheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subtitleColor = onSurface.withOpacity(0.68);

    final emoji = item.iconEmoji;
    final hasEmoji = emoji != null && emoji.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: item.bought,
            onChanged: (value) => onToggle(value ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: hasEmoji
              ? Text(
                  emoji!,
                  style: const TextStyle(fontSize: 24),
                )
              : Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                        decoration:
                            item.bought ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                  ),
                  PopupMenuButton<_ItemAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _ItemAction.edit:
                          onEdit();
                          break;
                        case _ItemAction.delete:
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ItemAction.edit,
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: _ItemAction.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetadataChip(
                    icon: Icons.flag_outlined,
                    label: '${item.priority.label} priority',
                    color: _priorityColor(context),
                  ),
                  if (item.price > 0)
                    _MetadataChip(
                      icon: Icons.attach_money,
                      label:
                          '${item.currency.toUpperCase()} ${item.price.toStringAsFixed(2)}',
                      color: theme.colorScheme.primary,
                    ),
                  if (item.purchaseDate != null)
                    _MetadataChip(
                      icon: Icons.schedule_outlined,
                      label: 'Needed ${_formatDate(item.purchaseDate!)}',
                      color: theme.colorScheme.secondary,
                    ),
                  if (item.expiryDate != null)
                    _MetadataChip(
                      icon: Icons.hourglass_bottom,
                      label: 'Expires ${_formatDate(item.expiryDate!)}',
                      color: theme.colorScheme.tertiary,
                    ),
                  if (item.bought)
                    _MetadataChip(
                      icon: Icons.check_circle_outline,
                      label: 'Purchased',
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Updated ${_formatDate(item.updatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ItemAction { edit, delete }

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingListDialog extends StatefulWidget {
  const _ShoppingListDialog({this.initial});

  final ShoppingList? initial;

  @override
  State<_ShoppingListDialog> createState() => _ShoppingListDialogState();
}

class _ShoppingListDialogState extends State<_ShoppingListDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late ShoppingListType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _notesController = TextEditingController(text: widget.initial?.notes ?? '');
    _type = widget.initial?.type ?? ShoppingListType.grocery;
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'New shopping list' : 'Edit shopping list'),
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
                  if (value != null) setState(() => _type = value);
                },
              ),
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

class _ShoppingItemDialog extends StatefulWidget {
  const _ShoppingItemDialog({this.initial});

  final ShoppingItem? initial;

  @override
  State<_ShoppingItemDialog> createState() => _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends State<_ShoppingItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _emojiController;
  bool _bought = false;
  ShoppingItemPriority _priority = ShoppingItemPriority.medium;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _priceController = TextEditingController(
      text: initial != null && initial.price > 0 ? initial.price.toStringAsFixed(2) : '',
    );
    _currencyController = TextEditingController(text: initial?.currency ?? 'USD');
    _emojiController = TextEditingController(text: initial?.iconEmoji ?? '');
    _priority = initial?.priority ?? ShoppingItemPriority.medium;
    _bought = initial?.bought ?? false;
    _purchaseDate = initial?.purchaseDate;
    _expiryDate = initial?.expiryDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isPurchase}) async {
    final now = DateTime.now();
    final initialDate = isPurchase ? (_purchaseDate ?? now) : (_expiryDate ?? now);

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

    var currency = _currencyController.text.trim().toUpperCase();
    if (currency.isEmpty) {
      currency = 'USD';
    }

    final emoji = _emojiController.text.trim();

    final base = widget.initial ?? ShoppingItem();

    Navigator.of(context).pop(
      base.copyWith(
        title: _titleController.text.trim(),
        price: price,
        currency: currency,
        priority: _priority,
        bought: _bought,
        iconEmoji: emoji.isEmpty ? null : emoji,
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(labelText: 'Currency (e.g. USD)'),
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emojiController,
                decoration: const InputDecoration(labelText: 'Emoji icon'),
                maxLength: 2,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _bought,
                onChanged: (value) => setState(() => _bought = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Mark as purchased'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DatePickerChip(
                    label: _purchaseDate != null
                        ? 'Needed ${_formatDate(_purchaseDate!)}'
                        : 'Set need-by date',
                    onPressed: () => _pickDate(isPurchase: true),
                    onClear: _purchaseDate != null
                        ? () => _clearDate(true)
                        : null,
                  ),
                  _DatePickerChip(
                    label: _expiryDate != null
                        ? 'Expires ${_formatDate(_expiryDate!)}'
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
    final theme = Theme.of(context);
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.event_outlined),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
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

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  final day = date.day.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$month $day, $year';
}

extension on ShoppingListType {
  String get label {
    switch (this) {
      case ShoppingListType.grocery:
        return 'Grocery';
      case ShoppingListType.shopping:
        return 'Shopping';
    }
  }
}

extension on ShoppingItemPriority {
  String get label => name.toLowerCase();

  String get labelTitleCase =>
      '${name[0].toUpperCase()}${name.substring(1).toLowerCase()}';
}
