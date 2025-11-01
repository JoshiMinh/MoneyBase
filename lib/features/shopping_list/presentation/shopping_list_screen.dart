import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/currencies.dart';
import '../../../core/models/shopping_item.dart';
import '../../../core/models/shopping_list.dart';
import '../../../core/repositories/shopping_list_repository.dart';
import '../../common/presentation/moneybase_shell.dart';
import '../../common/presentation/currency_dropdown_field.dart';
import '../../../app/theme/theme.dart';
import '../../../core/services/cloudinary_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class ShoppingListDetailRouteArgs {
  ShoppingListDetailRouteArgs({
    required this.userId,
    required this.repository,
    required this.initialList,
    this.onAddItem,
    this.onEditItem,
    this.onDeleteItem,
    this.onToggleItem,
    this.onEditList,
    this.onDeleteList,
  });

  final String userId;
  final ShoppingListRepository repository;
  final ShoppingList initialList;
  final ValueChanged<ShoppingList>? onAddItem;
  final void Function(ShoppingList, ShoppingItem)? onEditItem;
  final void Function(ShoppingList, ShoppingItem)? onDeleteItem;
  final void Function(ShoppingList, ShoppingItem, bool)? onToggleItem;
  final ValueChanged<ShoppingList>? onEditList;
  final ValueChanged<ShoppingList>? onDeleteList;
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
              backgroundColor: context.moneyBaseColors.negative,
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

  Future<void> _openListDetail(
    BuildContext context,
    String userId,
    ShoppingList list,
  ) async {
    if (list.id.isEmpty) {
      return;
    }

    setState(() => _selectedListId = list.id);

    await Navigator.of(context).pushNamed<void>(
      '/shopping/list',
      arguments: ShoppingListDetailRouteArgs(
        userId: userId,
        repository: _repository,
        initialList: list,
        onAddItem: (current) => _openItemDialog(context, userId, current),
        onEditItem: (current, item) =>
            _openItemDialog(context, userId, current, initial: item),
        onDeleteItem: (current, item) =>
            _deleteItem(context, userId, current, item),
        onToggleItem: (current, item, bought) =>
            _toggleItem(context, userId, current, item, bought),
        onEditList: (current) =>
            _openListDialog(context, userId, initial: current),
        onDeleteList: (current) => _deleteList(context, userId, current),
      ),
    );
  }

  Future<void> _openItemDialog(
    BuildContext context,
    String userId,
    ShoppingList list, {
    ShoppingItem? initial,
  }) async {
    final result = await showDialog<ShoppingItem>(
      context: context,
      builder: (context) => _ShoppingItemDialog(list: list, initial: initial),
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
              backgroundColor: context.moneyBaseColors.negative,
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
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        final colors = context.moneyBaseColors;
        final onSurface = colors.primaryText;
        final mutedOnSurface = colors.mutedText;

        if (user == null) {
          return Center(
            child: Text(
              'Sign in to create collaborative shopping lists.',
              style: textTheme.titleMedium?.copyWith(color: onSurface),
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
                  style: textTheme.bodyLarge?.copyWith(color: mutedOnSurface),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final lists = snapshot.data ?? const <ShoppingList>[];
            _syncSelection(lists);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shopping List',
                  style: textTheme.headlineMedium?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plan your next trip and keep essentials synced across devices.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: mutedOnSurface,
                  ),
                ),
                const SizedBox(height: 32),
                MoneyBaseSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  backgroundColor: colors.surfaceBackground,
                  borderColor: colors.surfaceBorder,
                  child: _ListsSection(
                    lists: lists,
                    selectedListId: _selectedListId,
                    onOpenList: (list) =>
                        _openListDetail(context, user.uid, list),
                    onCreateList: () => _openListDialog(context, user.uid),
                    onEditList: (list) => _openListDialog(context, user.uid, initial: list),
                    onDeleteList: (list) => _deleteList(context, user.uid, list),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a list to manage its items in a focused workspace.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: mutedOnSurface,
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
    required this.onOpenList,
    required this.onCreateList,
    required this.onEditList,
    required this.onDeleteList,
  });

  final List<ShoppingList> lists;
  final String? selectedListId;
  final ValueChanged<ShoppingList> onOpenList;
  final VoidCallback onCreateList;
  final ValueChanged<ShoppingList> onEditList;
  final ValueChanged<ShoppingList> onDeleteList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;

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
            style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
          )
        else
          Column(
            children: [
                for (final list in lists) ...[
                  _ListTile(
                    list: list,
                    selected: list.id == selectedListId,
                    onTap: () => onOpenList(list),
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
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final baseColor = colors.surfaceElevated;

    final background = selected
        ? colors.primaryAccent.withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.14)
        : baseColor;
    final borderColor = selected
        ? colors.primaryAccent.withOpacity(0.5)
        : colors.surfaceBorder;

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
                          color: colors.primaryAccent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          list.type.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primaryAccent,
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
                      color: colors.mutedText,
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

class ShoppingListDetailScreen extends StatefulWidget {
  const ShoppingListDetailScreen({
    required this.userId,
    required this.repository,
    required this.initialList,
    this.onAddItem,
    this.onEditItem,
    this.onDeleteItem,
    this.onToggleItem,
    this.onEditList,
    this.onDeleteList,
    super.key,
  });

  final String userId;
  final ShoppingListRepository repository;
  final ShoppingList initialList;
  final ValueChanged<ShoppingList>? onAddItem;
  final void Function(ShoppingList, ShoppingItem)? onEditItem;
  final void Function(ShoppingList, ShoppingItem)? onDeleteItem;
  final void Function(ShoppingList, ShoppingItem, bool)? onToggleItem;
  final ValueChanged<ShoppingList>? onEditList;
  final ValueChanged<ShoppingList>? onDeleteList;

  @override
  State<ShoppingListDetailScreen> createState() =>
      _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  ShoppingListRepository get _repository => widget.repository;

  Future<void> _handleExportList(ShoppingList list) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final items = await _repository.fetchItems(widget.userId, list.id);
      final metadataRows = <List<dynamic>>[
        ['List ID', list.id],
        ['List User ID', list.userId],
        ['List Name', list.name],
        ['List Type', list.type.name.toUpperCase()],
        ['List Currency', list.currency],
        ['List Notes', list.notes ?? ''],
        ['List Created At', list.createdAt.toIso8601String()],
        <dynamic>[],
      ];

      final rows = <List<dynamic>>[
        ...metadataRows,
        [
          'Item ID',
          'Title',
          'Status',
          'Priority',
          'Price',
          'Currency',
          'Icon Emoji',
          'Icon URL',
          'Parent Item ID',
          'Sub Item IDs',
          'Purchase Date',
          'Expiry Date',
          'Created At',
          'Updated At',
          'User ID',
          'List ID',
        ],
      ];

      for (final item in items) {
        final statusLabel = item.bought ? 'BOUGHT' : 'PENDING';
        final subItemIds = item.subItemRefs.map((ref) => ref.id).join(' | ');

        rows.add([
          item.id,
          item.title,
          statusLabel,
          item.priority.name.toUpperCase(),
          item.price,
          item.currency,
          item.iconEmoji ?? '',
          item.iconUrl ?? '',
          item.parentItemRef?.id ?? '',
          subItemIds,
          item.purchaseDate?.toIso8601String() ?? '',
          item.expiryDate?.toIso8601String() ?? '',
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
          item.userId,
          item.listId,
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      final baseName = list.name.trim().isEmpty ? 'shopping_list' : list.name.trim();
      final sanitized = baseName.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
      final fileName = sanitized.isEmpty ? 'shopping_list.csv' : '$sanitized.csv';

      final file = XFile.fromData(
        utf8.encode(csv),
        mimeType: 'text/csv',
        name: fileName,
      );

      await Share.shareXFiles([file]);

      if (!mounted) return;

      final count = items.length;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Exported $count item${count == 1 ? '' : 's'} to CSV.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to export list: $error')),
      );
    }
  }

  Future<void> _importItemsFromJson(
    BuildContext context,
    ShoppingList list,
  ) async {
    final rawJson = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ShoppingItemsImportDialog(),
    );

    if (rawJson == null) {
      return;
    }

    try {
      final summary = await _repository.importItemsFromJson(
        userId: widget.userId,
        list: list,
        rawJson: rawJson,
      );

      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final imported = summary.importedItems;
      final skipped = summary.totalItems - imported;
      final buffer = StringBuffer('Imported $imported item');
      if (imported != 1) {
        buffer.write('s');
      }
      if (skipped > 0) {
        buffer.write(' ($skipped skipped)');
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(buffer.toString()),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import items: $error')),
      );
    }
  }

  Future<ShoppingItem?> _showItemDialog({
    required ShoppingList list,
    ShoppingItem? initial,
  }) {
    return showDialog<ShoppingItem>(
      context: context,
      builder: (context) => _ShoppingItemDialog(list: list, initial: initial),
    );
  }

  Future<void> _handleAddItem(ShoppingList list) async {
    final callback = widget.onAddItem;
    if (callback != null) {
      callback(list);
      return;
    }

    final result = await _showItemDialog(list: list);
    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.addItem(widget.userId, list.id, result);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '"${result.title}" added to ${list.name.isEmpty ? 'your list' : list.name}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save item: $error')),
      );
    }
  }

  Future<void> _handleEditItem(ShoppingList list, ShoppingItem item) async {
    final callback = widget.onEditItem;
    if (callback != null) {
      callback(list, item);
      return;
    }

    final result = await _showItemDialog(list: list, initial: item);
    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.updateItem(widget.userId, list.id, result);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Shopping item updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save item: $error')),
      );
    }
  }

  Future<void> _handleDeleteItem(ShoppingList list, ShoppingItem item) async {
    final callback = widget.onDeleteItem;
    if (callback != null) {
      callback(list, item);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text(
          'Delete "${item.title}" from ${list.name.isEmpty ? 'this list' : list.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.moneyBaseColors.negative,
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
      await _repository.deleteItem(widget.userId, list.id, item.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('"${item.title}" removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to remove item: $error')),
      );
    }
  }

  Future<void> _handleToggleItem(
    ShoppingList list,
    ShoppingItem item,
    bool bought,
  ) async {
    final callback = widget.onToggleItem;
    if (callback != null) {
      callback(list, item, bought);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.setItemBought(widget.userId, list.id, item.id, bought);
      if (!mounted) return;
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
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update item: $error')),
      );
    }
  }

  Future<void> _handleEditList(ShoppingList list) async {
    final callback = widget.onEditList;
    if (callback != null) {
      callback(list);
      return;
    }

    final result = await showDialog<ShoppingList>(
      context: context,
      builder: (context) => _ShoppingListDialog(initial: list),
    );

    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.updateShoppingList(widget.userId, result);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Shopping list updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save shopping list: $error')),
      );
    }
  }

  Future<void> _handleDeleteList(ShoppingList list) async {
    final callback = widget.onDeleteList;
    if (callback != null) {
      callback(list);
      return;
    }

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
              backgroundColor: context.moneyBaseColors.negative,
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
      await _repository.deleteShoppingList(widget.userId, list.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Shopping list removed.')),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete shopping list: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShoppingList?>(
      stream: _repository.watchShoppingList(widget.userId, widget.initialList.id),
      initialData: widget.initialList,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colors = context.moneyBaseColors;
        final gradient = colors.backgroundGradient;
        final decoration = gradient.length >= 2
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            : BoxDecoration(color: theme.scaffoldBackgroundColor);

        final list = snapshot.data;
        final error = snapshot.error;

        Widget buildContent(ShoppingList resolved) {
          final textTheme = theme.textTheme;
          final notes = resolved.notes?.trim() ?? '';

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final horizontalPadding = isWide ? 48.0 : 16.0;
                final verticalPadding = isWide ? 32.0 : 16.0;

                return SelectionArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding + 72,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 36 : 20,
                                vertical: isWide ? 28 : 20,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceBackground,
                                border: Border.all(color: colors.surfaceBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resolved.name.isEmpty
                                        ? 'Shopping list'
                                        : resolved.name,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: colors.primaryText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ListMetadataChip(
                                        icon: Icons.category_outlined,
                                        label: resolved.type.label,
                                        color: colors.primaryAccent,
                                      ),
                                      if (resolved.currency.isNotEmpty)
                                        _ListMetadataChip(
                                          icon: Icons.attach_money,
                                          label: resolved.currency.toUpperCase(),
                                          color: colors.secondaryAccent,
                                        ),
                                      _ListMetadataChip(
                                        icon: Icons.calendar_today_outlined,
                                        label: 'Created ${_formatDate(resolved.createdAt)}',
                                        color: colors.info,
                                      ),
                                    ],
                                  ),
                                  if (notes.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Divider(
                                      color: colors.surfaceBorder,
                                      height: 1,
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      notes,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colors.mutedText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colors.surfaceBackground,
                                border: Border.all(color: colors.surfaceBorder),
                              ),
                              child: _ShoppingListItemsView(
                                userId: widget.userId,
                                list: resolved,
                                repository: _repository,
                                onAddItem: _handleAddItem,
                                onEditItem: _handleEditItem,
                                onDeleteItem: _handleDeleteItem,
                                onToggleItem: _handleToggleItem,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        Widget body;
        if (error != null) {
          body = SelectionArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load this list: $error',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else if (list == null) {
          body = SelectionArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'This shopping list is no longer available.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else {
          body = buildContent(list);
        }

        final titleList = list ?? widget.initialList;

        return Container(
          decoration: decoration,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                titleList.name.isEmpty ? 'Shopping list' : titleList.name,
              ),
              actions: list == null
                  ? null
                  : [
                      IconButton(
                        tooltip: 'Export CSV',
                        onPressed: () => _handleExportList(list),
                        icon: const Icon(Icons.download_outlined),
                      ),
                      IconButton(
                        tooltip: 'Import JSON',
                        onPressed: () => _importItemsFromJson(context, list),
                        icon: const Icon(Icons.upload_file),
                      ),
                      IconButton(
                        tooltip: 'Add item',
                        onPressed: () => _handleAddItem(list),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Edit list',
                        onPressed: () => _handleEditList(list),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete list',
                        onPressed: () => _handleDeleteList(list),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
            ),
            body: body,
          ),
        );
      },
    );
  }
}

class _ListMetadataChip extends StatelessWidget {
  const _ListMetadataChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.28)),
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

enum _ListAction { edit, delete }

class _ShoppingListItemsView extends StatefulWidget {
  const _ShoppingListItemsView({
    required this.userId,
    required this.list,
    required this.repository,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleItem,
  });

  final String userId;
  final ShoppingList list;
  final ShoppingListRepository repository;
  final ValueChanged<ShoppingList> onAddItem;
  final void Function(ShoppingList, ShoppingItem) onEditItem;
  final void Function(ShoppingList, ShoppingItem) onDeleteItem;
  final void Function(ShoppingList, ShoppingItem, bool) onToggleItem;

  @override
  State<_ShoppingListItemsView> createState() => _ShoppingListItemsViewState();
}

class _ShoppingListItemsViewState extends State<_ShoppingListItemsView> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }
  @override
  void didUpdateWidget(covariant _ShoppingListItemsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list.id != widget.list.id) {
      _searchController.clear();
      if (_searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  void _handleClearSearch() {
    if (_searchQuery.isEmpty) {
      return;
    }
    _searchController.clear();
    _handleSearchChanged('');
    _searchFocusNode.requestFocus();
  }

  bool _matchesQuery(ShoppingItem item, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;

    bool contains(String? value) {
      if (value == null || value.isEmpty) return false;
      return value.toLowerCase().contains(normalizedQuery);
    }

    final price = item.price;
    final searchFields = <String?>[
      item.title,
      item.currency,
      item.priority.label,
      item.priority.labelTitleCase,
      item.iconEmoji,
      item.iconUrl,
      item.id,
      if (price > 0) price.toStringAsFixed(2),
      if (price > 0) price.toString(),
      if (item.purchaseDate != null) _formatDate(item.purchaseDate!),
      if (item.expiryDate != null) _formatDate(item.expiryDate!),
      if (item.bought) 'purchased',
      if (!item.bought) 'pending',
    ];

    for (final field in searchFields) {
      if (contains(field)) {
        return true;
      }
    }

    return false;
  }

  List<ShoppingItem> _filterItems(
    List<ShoppingItem> items,
    ShoppingListType listType,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return items;

    if (listType == ShoppingListType.shopping) {
      final itemsById = {for (final item in items) item.id: item};
      final childrenByParent = <String, List<ShoppingItem>>{};

      for (final item in items) {
        final parentId = item.parentItemRef?.id;
        if (parentId == null) continue;
        childrenByParent.putIfAbsent(parentId, () => <ShoppingItem>[]).add(item);
      }

      final includedIds = <String>{};

      void includeWithFamily(ShoppingItem item) {
        if (!includedIds.add(item.id)) {
          return;
        }

        final parentId = item.parentItemRef?.id;
        if (parentId != null) {
          final parent = itemsById[parentId];
          if (parent != null) {
            includeWithFamily(parent);
          }
        }

        void includeDescendants(String itemId) {
          final children = childrenByParent[itemId];
          if (children == null) return;
          for (final child in children) {
            if (includedIds.add(child.id)) {
              includeDescendants(child.id);
            }
          }
        }

        includeDescendants(item.id);
      }

      for (final item in items) {
        if (_matchesQuery(item, normalizedQuery)) {
          includeWithFamily(item);
        }
      }

      return [
        for (final item in items)
          if (includedIds.contains(item.id)) item,
      ];
    }

    return [
      for (final item in items)
        if (_matchesQuery(item, normalizedQuery)) item,
    ];
  }

  List<Widget> _buildGroceryItems(
    List<ShoppingItem> items,
    ShoppingList list,
  ) {
    final widgets = <Widget>[];

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      widgets.add(
        _ItemTile(
          list: list,
          item: item,
          onEdit: () => widget.onEditItem(list, item),
          onDelete: () => widget.onDeleteItem(list, item),
          onToggle: (value) => widget.onToggleItem(list, item, value),
          showDividerBelow: index != items.length - 1,
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildShoppingItems(
    List<ShoppingItem> items,
    ShoppingList list,
  ) {
    if (items.isEmpty) return const [];

    final itemsById = {for (final item in items) item.id: item};
    final childrenMap = <String, List<ShoppingItem>>{};
    final roots = <ShoppingItem>[];

    for (final item in items) {
      final parentId = item.parentItemRef?.id;
      if (parentId != null && itemsById.containsKey(parentId)) {
        childrenMap.putIfAbsent(parentId, () => <ShoppingItem>[]).add(item);
      } else {
        roots.add(item);
      }
    }

    Widget buildNode(ShoppingItem item, int depth, bool isLastSibling) {
      final children = childrenMap[item.id] ?? const <ShoppingItem>[];
      final nested = <Widget>[];

      for (var index = 0; index < children.length; index++) {
        nested.add(buildNode(children[index], depth + 1, index == children.length - 1));
      }

      return _ItemTile(
        list: list,
        item: item,
        indent: depth * 24.0,
        onEdit: () => widget.onEditItem(list, item),
        onDelete: () => widget.onDeleteItem(list, item),
        onToggle: (value) => widget.onToggleItem(list, item, value),
        children: nested,
        showDividerBelow: !isLastSibling,
      );
    }

    if (roots.isEmpty) {
      roots.addAll(items);
    }

    final widgets = <Widget>[];

    for (var index = 0; index < roots.length; index++) {
      widgets.add(buildNode(roots[index], 0, index == roots.length - 1));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;

    return StreamBuilder<List<ShoppingItem>>(
      stream: widget.repository.watchItems(widget.userId, widget.list.id),
      builder: (context, snapshot) {
        final header = _ItemsHeader(
          onSurface: onSurface,
          textTheme: textTheme,
          onAddItem: () => widget.onAddItem(widget.list),
          searchController: _searchController,
          onQueryChanged: _handleSearchChanged,
          onClearSearch: _handleClearSearch,
          focusNode: _searchFocusNode,
        );

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 16),
                Text(
                  'Unable to load items: ${snapshot.error}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data ?? const <ShoppingItem>[];
        final listType = widget.list.type;
        final filteredItems = _filterItems(items, listType, _searchQuery);
        final hasQuery = _searchQuery.trim().isNotEmpty;

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: colors.surfaceBackground.withOpacity(0.6),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        listType == ShoppingListType.shopping
                            ? Icons.shopping_bag_outlined
                            : Icons.local_grocery_store_outlined,
                        size: 32,
                        color: colors.mutedText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No items yet',
                        style: textTheme.titleMedium?.copyWith(color: onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listType == ShoppingListType.shopping
                            ? 'Add products you want to keep an eye on.'
                            : 'Keep track of groceries you need to restock.',
                        style: textTheme.bodyMedium?.copyWith(color: colors.mutedText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SelectionContainer.disabled(
                        child: FilledButton.icon(
                          onPressed: () => widget.onAddItem(widget.list),
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: const Text('Start adding items'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredItems.isEmpty && hasQuery) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: colors.surfaceBackground.withOpacity(0.6),
                    border: Border.all(color: colors.surfaceBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 32,
                        color: colors.mutedText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No items match your search.',
                        style: textTheme.titleMedium?.copyWith(color: onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different keyword or clear the search to see all items.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SelectionContainer.disabled(
                        child: TextButton.icon(
                          onPressed: _handleClearSearch,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear search'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final itemWidgets = listType == ShoppingListType.shopping
            ? _buildShoppingItems(filteredItems, widget.list)
            : _buildGroceryItems(filteredItems, widget.list);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 16),
              Divider(
                color: colors.surfaceBorder,
                height: 1,
                thickness: 1,
              ),
              const SizedBox(height: 12),
              ...itemWidgets,
            ],
          ),
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
    required this.searchController,
    required this.onQueryChanged,
    required this.onClearSearch,
    required this.focusNode,
  });

  final Color onSurface;
  final TextTheme textTheme;
  final VoidCallback onAddItem;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearSearch;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final hasQuery = searchController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            SelectionContainer.disabled(
              child: FilledButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Add item'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SelectionContainer.disabled(
          child: TextField(
            controller: searchController,
            focusNode: focusNode,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search items',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),
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
    this.children = const <Widget>[],
    this.indent = 0,
    this.showDividerBelow = false,
  });

  final ShoppingList list;
  final ShoppingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;
  final double indent;
  final bool showDividerBelow;

  Color _priorityColor(BuildContext context) {
    final colors = context.moneyBaseColors;
    switch (item.priority) {
      case ShoppingItemPriority.low:
        return colors.info;
      case ShoppingItemPriority.medium:
        return colors.secondaryAccent;
      case ShoppingItemPriority.high:
        return colors.negative;
    }
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_outlined, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Unable to load image.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final subtitleColor = colors.mutedText;

    final emoji = item.iconEmoji;
    final hasEmoji = emoji != null && emoji.trim().isNotEmpty;
    final iconUrl = item.iconUrl;
    final hasIconUrl =
        list.type == ShoppingListType.shopping && iconUrl != null && iconUrl.trim().isNotEmpty;
    final createdLabel = _formatDate(item.createdAt);
    final updatedLabel = _formatDate(item.updatedAt);
    final metadataSummary = list.type == ShoppingListType.shopping
        ? 'Created $createdLabel · Updated $updatedLabel'
        : 'Updated $updatedLabel';

    Widget buildIcon() {
      if (hasIconUrl) {
        final radius = BorderRadius.circular(4);
        final sanitizedUrl = iconUrl!.trim();
        return SelectionContainer.disabled(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () => _showImagePreview(context, sanitizedUrl),
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceBackground,
                  borderRadius: radius,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Image.network(
                    sanitizedUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.primaryAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.primaryAccent.withOpacity(0.18),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: hasEmoji
            ? Text(
                emoji!,
                style: const TextStyle(fontSize: 24),
              )
            : Icon(Icons.shopping_bag_outlined, color: colors.primaryAccent),
      );
    }

    final priceLabel = item.price > 0
        ? '${item.currency.toUpperCase()} ${item.price.toStringAsFixed(2)}'
        : null;

    final content = Container(
      margin: EdgeInsets.only(left: indent),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: showDividerBelow
              ? BorderSide(color: colors.surfaceBorder)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectionContainer.disabled(
                child: Checkbox(
                  value: item.bought,
                  onChanged: (value) => onToggle(value ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              buildIcon(),
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
                              decoration: item.bought
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (priceLabel != null)
                              Text(
                                priceLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            SelectionContainer.disabled(
                              child: PopupMenuButton<_ItemAction>(
                                padding: EdgeInsets.zero,
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
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetadataChip(
                          icon: Icons.flag_outlined,
                          label: '${item.priority.label} priority',
                          color: _priorityColor(context),
                        ),
                        if (item.purchaseDate != null)
                          _MetadataChip(
                            icon: Icons.schedule_outlined,
                            label: 'Needed ${_formatDate(item.purchaseDate!)}',
                            color: colors.secondaryAccent,
                          ),
                        if (item.expiryDate != null &&
                            list.type == ShoppingListType.shopping)
                          _MetadataChip(
                            icon: Icons.hourglass_bottom,
                            label: 'Expires ${_formatDate(item.expiryDate!)}',
                            color: colors.info,
                          ),
                        if (item.bought)
                          _MetadataChip(
                            icon: Icons.check_circle_outline,
                            label: 'Purchased',
                            color: colors.positive,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      metadataSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );

    return content;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.28)),
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

class _ShoppingItemsImportDialog extends StatefulWidget {
  const _ShoppingItemsImportDialog();

  @override
  State<_ShoppingItemsImportDialog> createState() => _ShoppingItemsImportDialogState();
}

class _ShoppingItemsImportDialogState extends State<_ShoppingItemsImportDialog> {
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

class _ShoppingItemDialog extends StatefulWidget {
  const _ShoppingItemDialog({required this.list, this.initial});

  final ShoppingList list;
  final ShoppingItem? initial;

  @override
  State<_ShoppingItemDialog> createState() => _ShoppingItemDialogState();
}

class _ShoppingItemDialogState extends State<_ShoppingItemDialog> {
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
  bool _cloudinaryReady = cloudinaryService.isConfigured;
  bool _uploadingImage = false;
  String? _imageUploadError;
  String? _imageUploadSuccess;

  bool get _isShoppingList => widget.list.type == ShoppingListType.shopping;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _priceController = TextEditingController(
      text: initial != null && initial.price > 0 ? initial.price.toStringAsFixed(2) : '',
    );
    final defaultCurrency = widget.list.currency;
    _currencyCode = currencyOptionFor(initial?.currency ?? defaultCurrency).code;
    if (!_isShoppingList) {
      _currencyCode = currencyOptionFor(defaultCurrency).code;
    }
    _emojiController = TextEditingController(text: initial?.iconEmoji ?? '');
    _iconUrlController = TextEditingController(text: initial?.iconUrl ?? '');
    _priority = initial?.priority ?? ShoppingItemPriority.medium;
    _bought = initial?.bought ?? false;
    _purchaseDate = initial?.purchaseDate;
    _expiryDate = _isShoppingList ? initial?.expiryDate : null;
    _initializeCloudinary();
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

  Future<void> _initializeCloudinary() async {
    final ready = await cloudinaryService.ensureInitialized();
    if (!mounted) return;
    setState(() => _cloudinaryReady = ready);
  }

  Future<void> _uploadIconImage() async {
    if (!_cloudinaryReady) {
      setState(() {
        _imageUploadError = 'Cloudinary is not configured for this build.';
        _imageUploadSuccess = null;
      });
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _imageUploadError = 'Selected file does not contain any image data.';
        _imageUploadSuccess = null;
      });
      return;
    }

    setState(() {
      _uploadingImage = true;
      _imageUploadError = null;
      _imageUploadSuccess = null;
    });

    try {
      final uploadResult = await cloudinaryService.uploadBytes(
        bytes,
        fileName: file.name,
        folder: 'moneybase/shopping_items',
      );
      if (!mounted) return;
      setState(() {
        _iconUrlController.text = uploadResult.secureUrl;
        _imageUploadSuccess = 'Image uploaded. URL added above.';
      });
    } on CloudinaryException catch (error) {
      if (!mounted) return;
      setState(() {
        _imageUploadError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _imageUploadError = 'Unexpected upload error: $error';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
      });
    }
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
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
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
                const SizedBox(height: 8),
                if (_cloudinaryReady)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _uploadingImage ? null : _uploadIconImage,
                        icon: _uploadingImage
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _uploadingImage ? 'Uploading…' : 'Upload image',
                        ),
                      ),
                      if (_imageUploadSuccess != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _imageUploadSuccess!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (_imageUploadError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _imageUploadError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    'Add Cloudinary credentials to enable image uploads.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
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
                        ? 'Needed ${_formatDate(_purchaseDate!)}'
                        : 'Set need-by date',
                    onPressed: () => _pickDate(isPurchase: true),
                    onClear: _purchaseDate != null
                        ? () => _clearDate(true)
                        : null,
                  ),
                  if (_isShoppingList)
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
