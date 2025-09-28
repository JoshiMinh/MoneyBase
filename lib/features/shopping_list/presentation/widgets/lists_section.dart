import 'package:flutter/material.dart';
import 'package:moneybase/app/theme/theme.dart';
import 'package:moneybase/core/models/shopping_list.dart';

import '../utils/shopping_list_formatters.dart';

typedef ShoppingListCallback = void Function(ShoppingList list);

enum ShoppingListAction { edit, delete }

class ShoppingListsSection extends StatelessWidget {
  const ShoppingListsSection({
    required this.lists,
    required this.selectedListId,
    required this.onOpenList,
    required this.onEditList,
    required this.onDeleteList,
    required this.onCreateList,
    super.key,
  });

  final List<ShoppingList> lists;
  final String? selectedListId;
  final ShoppingListCallback onOpenList;
  final ShoppingListCallback onEditList;
  final ShoppingListCallback onDeleteList;
  final VoidCallback onCreateList;

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
                ShoppingListTile(
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

class ShoppingListTile extends StatelessWidget {
  const ShoppingListTile({
    required this.list,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
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
        ? colors.primaryAccent
            .withOpacity(theme.brightness == Brightness.dark ? 0.25 : 0.14)
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
                        : 'Created ${formatShoppingDate(list.createdAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.mutedText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<ShoppingListAction>(
              onSelected: (action) {
                switch (action) {
                  case ShoppingListAction.edit:
                    onEdit();
                    break;
                  case ShoppingListAction.delete:
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ShoppingListAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: ShoppingListAction.delete,
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
