import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moneybase/app/theme/theme.dart';
import 'package:moneybase/core/models/shopping_item.dart';
import 'package:moneybase/core/models/shopping_list.dart';
import 'package:moneybase/core/repositories/shopping_list_repository.dart';
import 'package:moneybase/features/common/presentation/moneybase_shell.dart';

import 'utils/shopping_list_formatters.dart';
import 'widgets/lists_section.dart';
import 'widgets/shopping_list_dialogs.dart';
import 'widgets/shopping_list_items_view.dart';

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
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleItem,
    required this.onEditList,
    required this.onDeleteList,
  });

  final String userId;
  final ShoppingListRepository repository;
  final ShoppingList initialList;
  final ValueChanged<ShoppingList> onAddItem;
  final void Function(ShoppingList, ShoppingItem) onEditItem;
  final void Function(ShoppingList, ShoppingItem) onDeleteItem;
  final void Function(ShoppingList, ShoppingItem, bool) onToggleItem;
  final ValueChanged<ShoppingList> onEditList;
  final ValueChanged<ShoppingList> onDeleteList;
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
    final result = await showShoppingListDialog(
      context,
      initial: initial,
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
    final result = await showShoppingItemDialog(
      context,
      list: list,
      initial: initial,
    );

    if (result == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      if (initial == null) {
        await _repository.addItem(userId, list.id, result);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '"${result.title}" added to ${list.name.isEmpty ? 'your list' : list.name}.',
            ),
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
      builder: (context, _) {
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
                  child: ShoppingListsSection(
                    lists: lists,
                    selectedListId: _selectedListId,
                    onOpenList: (list) => _openListDetail(context, user.uid, list),
                    onCreateList: () => _openListDialog(context, user.uid),
                    onEditList: (list) =>
                        _openListDialog(context, user.uid, initial: list),
                    onDeleteList: (list) => _deleteList(context, user.uid, list),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final selected = lists.firstWhere(
                        (list) => list.id == _selectedListId,
                        orElse: () => lists.isNotEmpty ? lists.first : ShoppingList(),
                      );

                      if (selected.id.isEmpty) {
                        return Center(
                          child: Text(
                            'Create a list to start planning your next grocery run.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: mutedOnSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return MoneyBaseSurface(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        child: ShoppingListItemsView(
                          userId: user.uid,
                          list: selected,
                          repository: _repository,
                          onAddItem: (current) => _openItemDialog(
                            context,
                            user.uid,
                            current,
                          ),
                          onEditItem: (current, item) => _openItemDialog(
                            context,
                            user.uid,
                            current,
                            initial: item,
                          ),
                          onDeleteItem: (current, item) =>
                              _deleteItem(context, user.uid, current, item),
                          onToggleItem: (current, item, bought) => _toggleItem(
                            context,
                            user.uid,
                            current,
                            item,
                            bought,
                          ),
                        ),
                      );
                    },
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

class ShoppingListDetailScreen extends StatelessWidget {
  const ShoppingListDetailScreen({
    required this.userId,
    required this.repository,
    required this.initialList,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleItem,
    required this.onEditList,
    required this.onDeleteList,
    super.key,
  });

  final String userId;
  final ShoppingListRepository repository;
  final ShoppingList initialList;
  final ValueChanged<ShoppingList> onAddItem;
  final void Function(ShoppingList, ShoppingItem) onEditItem;
  final void Function(ShoppingList, ShoppingItem) onDeleteItem;
  final void Function(ShoppingList, ShoppingItem, bool) onToggleItem;
  final ValueChanged<ShoppingList> onEditList;
  final ValueChanged<ShoppingList> onDeleteList;

  Future<void> _importItemsFromJson(
    BuildContext context,
    ShoppingList list,
  ) async {
    final rawJson = await showShoppingItemsImportDialog(context);

    if (rawJson == null) {
      return;
    }

    try {
      final summary = await repository.importItemsFromJson(
        userId: userId,
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShoppingList?>(
      stream: repository.watchShoppingList(userId, initialList.id),
      initialData: initialList,
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
                final padding = EdgeInsets.symmetric(
                  horizontal: isWide ? 64 : 24,
                  vertical: isWide ? 40 : 24,
                );

                return SingleChildScrollView(
                  padding: padding.copyWith(bottom: padding.bottom + 96),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MoneyBaseSurface(
                            padding: const EdgeInsets.all(28),
                            backgroundColor: colors.surfaceBackground,
                            borderColor: colors.surfaceBorder,
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
                                  spacing: 12,
                                  runSpacing: 12,
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
                                      label:
                                          'Created ${formatShoppingDate(resolved.createdAt)}',
                                      color: colors.info,
                                    ),
                                  ],
                                ),
                                if (notes.isNotEmpty) ...[
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
                          const SizedBox(height: 24),
                          MoneyBaseSurface(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            child: ShoppingListItemsView(
                              userId: userId,
                              list: resolved,
                              repository: repository,
                              onAddItem: onAddItem,
                              onEditItem: onEditItem,
                              onDeleteItem: onDeleteItem,
                              onToggleItem: onToggleItem,
                            ),
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

        Widget body;
        if (error != null) {
          body = Center(
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
          );
        } else if (list == null) {
          body = Center(
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
          );
        } else {
          body = buildContent(list);
        }

        final titleList = list ?? initialList;

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
                        tooltip: 'Import JSON',
                        onPressed: () => _importItemsFromJson(context, list),
                        icon: const Icon(Icons.upload_file),
                      ),
                      IconButton(
                        tooltip: 'Add item',
                        onPressed: () => onAddItem(list),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Edit list',
                        onPressed: () => onEditList(list),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete list',
                        onPressed: () => onDeleteList(list),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
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
