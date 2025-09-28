import 'package:flutter/material.dart';
import 'package:moneybase/app/theme/theme.dart';
import 'package:moneybase/core/models/shopping_item.dart';
import 'package:moneybase/core/models/shopping_list.dart';
import 'package:moneybase/core/repositories/shopping_list_repository.dart';

import '../utils/shopping_list_formatters.dart';

typedef ShoppingItemCallback = void Function(ShoppingList list);
typedef ShoppingItemMutation = void Function(ShoppingList list, ShoppingItem item);
typedef ShoppingItemToggle = void Function(
  ShoppingList list,
  ShoppingItem item,
  bool bought,
);

enum _ShoppingItemsLayout { list, grid }

class ShoppingListItemsView extends StatefulWidget {
  const ShoppingListItemsView({
    required this.userId,
    required this.list,
    required this.repository,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleItem,
    super.key,
  });

  final String userId;
  final ShoppingList list;
  final ShoppingListRepository repository;
  final ShoppingItemCallback onAddItem;
  final ShoppingItemMutation onEditItem;
  final ShoppingItemMutation onDeleteItem;
  final ShoppingItemToggle onToggleItem;

  @override
  State<ShoppingListItemsView> createState() => _ShoppingListItemsViewState();
}

class _ShoppingListItemsViewState extends State<ShoppingListItemsView> {
  _ShoppingItemsLayout _layout = _ShoppingItemsLayout.list;

  List<Widget> _buildGroceryItems(List<ShoppingItem> items, ShoppingList list) {
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
        ),
      );

      if (index != items.length - 1) {
        widgets.add(const Divider(height: 28));
      }
    }

    return widgets;
  }

  List<Widget> _buildShoppingItems(List<ShoppingItem> items, ShoppingList list) {
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

    Widget buildNode(ShoppingItem item, int depth) {
      final children = childrenMap[item.id] ?? const <ShoppingItem>[];
      final nested = <Widget>[];

      for (var index = 0; index < children.length; index++) {
        nested.add(buildNode(children[index], depth + 1));
        if (index != children.length - 1) {
          nested.add(const SizedBox(height: 12));
        }
      }

      return _ItemTile(
        list: list,
        item: item,
        indent: depth * 28.0,
        onEdit: () => widget.onEditItem(list, item),
        onDelete: () => widget.onDeleteItem(list, item),
        onToggle: (value) => widget.onToggleItem(list, item, value),
        children: nested,
      );
    }

    if (roots.isEmpty) {
      // Avoid an empty root set when all items reference missing parents.
      roots.addAll(items);
    }

    final widgets = <Widget>[];

    for (var index = 0; index < roots.length; index++) {
      widgets.add(buildNode(roots[index], 0));
      if (index != roots.length - 1) {
        widgets.add(const Divider(height: 28));
      }
    }

    return widgets;
  }

  List<_ItemEntry> _flattenEntries(
    List<ShoppingItem> items,
    ShoppingListType listType,
  ) {
    if (listType == ShoppingListType.grocery) {
      return [
        for (final item in items) _ItemEntry(item: item, depth: 0),
      ];
    }

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

    if (roots.isEmpty) {
      roots.addAll(items);
    }

    final entries = <_ItemEntry>[];

    void visit(ShoppingItem item, int depth) {
      entries.add(_ItemEntry(item: item, depth: depth));
      final children = childrenMap[item.id] ?? const <ShoppingItem>[];
      for (final child in children) {
        visit(child, depth + 1);
      }
    }

    for (final root in roots) {
      visit(root, 0);
    }

    return entries;
  }

  Widget _buildGridView(
    BuildContext context,
    List<_ItemEntry> entries,
    ShoppingList list,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var crossAxisCount = 2;
        if (width >= 1100) {
          crossAxisCount = 4;
        } else if (width >= 800) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _ItemGridTile(
              list: list,
              item: entry.item,
              depth: entry.depth,
              onEdit: () => widget.onEditItem(list, entry.item),
              onDelete: () => widget.onDeleteItem(list, entry.item),
              onToggle: (value) => widget.onToggleItem(list, entry.item, value),
            );
          },
        );
      },
    );
  }

  void _setLayout(_ShoppingItemsLayout layout) {
    setState(() {
      _layout = layout;
    });
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
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ItemsHeader(
                onSurface: onSurface,
                textTheme: textTheme,
                onAddItem: () => widget.onAddItem(widget.list),
                layout: _layout,
                showLayoutToggle: false,
                onLayoutChanged: null,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load items right now. Please try again later.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.negative,
                ),
              ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ItemsHeader(
                onSurface: onSurface,
                textTheme: textTheme,
                onAddItem: () => widget.onAddItem(widget.list),
                layout: _layout,
                showLayoutToggle: false,
                onLayoutChanged: null,
              ),
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        }

        final items = snapshot.data ?? const <ShoppingItem>[];
        final currentList = widget.list;
        final listType = currentList.type;
        final hasItems = items.isNotEmpty;

        final listChildren = listType == ShoppingListType.shopping
            ? _buildShoppingItems(items, currentList)
            : _buildGroceryItems(items, currentList);

        final gridEntries = _flattenEntries(items, listType);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ItemsHeader(
              onSurface: onSurface,
              textTheme: textTheme,
              onAddItem: () => widget.onAddItem(currentList),
              layout: _layout,
              showLayoutToggle: hasItems,
              onLayoutChanged: hasItems ? _setLayout : null,
            ),
            const SizedBox(height: 16),
            if (!hasItems)
              Text(
                'Add essentials, plan meals, and track quantities in one place.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.mutedText,
                ),
              )
            else if (_layout == _ShoppingItemsLayout.list)
              Column(children: listChildren)
            else
              _buildGridView(context, gridEntries, currentList),
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
    required this.layout,
    required this.showLayoutToggle,
    required this.onLayoutChanged,
  });

  final Color onSurface;
  final TextTheme textTheme;
  final VoidCallback onAddItem;
  final _ShoppingItemsLayout layout;
  final bool showLayoutToggle;
  final ValueChanged<_ShoppingItemsLayout>? onLayoutChanged;

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
        if (showLayoutToggle) ...[
          SegmentedButton<_ShoppingItemsLayout>(
            segments: const [
              ButtonSegment<_ShoppingItemsLayout>(
                value: _ShoppingItemsLayout.list,
                icon: Icon(Icons.view_list_outlined),
                label: Text('List'),
              ),
              ButtonSegment<_ShoppingItemsLayout>(
                value: _ShoppingItemsLayout.grid,
                icon: Icon(Icons.grid_view_outlined),
                label: Text('Grid'),
              ),
            ],
            selected: <_ShoppingItemsLayout>{layout},
            onSelectionChanged: onLayoutChanged == null
                ? null
                : (selection) => onLayoutChanged!(selection.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        FilledButton.icon(
          onPressed: onAddItem,
          icon: const Icon(Icons.add_shopping_cart_outlined),
          label: const Text('Add item'),
        ),
      ],
    );
  }
}

class _ItemEntry {
  const _ItemEntry({required this.item, required this.depth});

  final ShoppingItem item;
  final int depth;
}

enum _ItemAction { edit, delete }

class _ItemGridTile extends StatelessWidget {
  const _ItemGridTile({
    required this.list,
    required this.item,
    required this.depth,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final ShoppingList list;
  final ShoppingItem item;
  final int depth;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final subtitleColor = colors.mutedText;

    final metadataChips = _buildItemMetadataChips(context, list, item);
    if (depth > 0) {
      metadataChips.insert(
        1,
        _MetadataChip(
          icon: Icons.subdirectory_arrow_right,
          label: 'Sub item',
          color: colors.mutedText,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: colors.surfaceShadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemArtwork(
            list: list,
            item: item,
            onPreview: _showItemImagePreview,
            width: double.infinity,
            height: 140,
            radius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Transform.scale(
                scale: 1.12,
                child: Checkbox(
                  value: item.bought,
                  onChanged: (value) => onToggle(value ?? false),
                ),
              ),
              const Spacer(),
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
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
              decoration: item.bought
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (metadataChips.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metadataChips,
            ),
          const SizedBox(height: 8),
          Text(
            _buildItemTimelineSummary(list, item),
            style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
          ),
        ],
      ),
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
  });

  final ShoppingList list;
  final ShoppingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  final List<Widget> children;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.moneyBaseColors;
    final onSurface = colors.primaryText;
    final subtitleColor = colors.mutedText;
    final metadataChips = _buildItemMetadataChips(context, list, item);

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              _ItemArtwork(
                list: list,
                item: item,
                onPreview: _showItemImagePreview,
                width: 96,
                height: 76,
                radius: BorderRadius.circular(18),
              ),
              const SizedBox(width: 18),
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
                    if (metadataChips.isNotEmpty)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: metadataChips,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _buildItemTimelineSummary(list, item),
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
            const SizedBox(height: 16),
            ...children,
          ],
        ],
      ),
    );
  }
}

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

class _ItemArtwork extends StatelessWidget {
  const _ItemArtwork({
    required this.list,
    required this.item,
    required this.onPreview,
    this.width,
    required this.height,
    this.radius = const BorderRadius.all(Radius.circular(18)),
  });

  final ShoppingList list;
  final ShoppingItem item;
  final void Function(BuildContext context, String url) onPreview;
  final double? width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.moneyBaseColors;
    final emoji = item.iconEmoji;
    final hasEmoji = emoji != null && emoji.trim().isNotEmpty;
    final iconUrl = item.iconUrl;
    final hasIconUrl = list.type == ShoppingListType.shopping &&
        iconUrl != null &&
        iconUrl.trim().isNotEmpty;

    if (hasIconUrl) {
      final sanitizedUrl = iconUrl!.trim();
      return SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: () => onPreview(context, sanitizedUrl),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: colors.surfaceBackground,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Image.network(
                  sanitizedUrl,
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

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryAccent.withOpacity(0.18),
          borderRadius: radius,
        ),
        child: Center(
          child: hasEmoji
              ? Text(
                  emoji!,
                  style: TextStyle(fontSize: height * 0.5),
                )
              : Icon(
                  Icons.shopping_bag_outlined,
                  color: colors.primaryAccent,
                  size: height * 0.6,
                ),
        ),
      ),
    );
  }
}

List<Widget> _buildItemMetadataChips(
  BuildContext context,
  ShoppingList list,
  ShoppingItem item,
) {
  final colors = context.moneyBaseColors;
  final chips = <Widget>[
    _MetadataChip(
      icon: Icons.flag_outlined,
      label: '${item.priority.label} priority',
      color: _resolvePriorityColor(context, item.priority),
    ),
  ];

  if (item.price > 0) {
    chips.add(
      _MetadataChip(
        icon: Icons.attach_money,
        label: '${item.currency.toUpperCase()} ${item.price.toStringAsFixed(2)}',
        color: colors.primaryAccent,
      ),
    );
  }

  if (item.purchaseDate != null) {
    chips.add(
      _MetadataChip(
        icon: Icons.schedule_outlined,
        label: 'Needed ${formatShoppingDate(item.purchaseDate!)}',
        color: colors.secondaryAccent,
      ),
    );
  }

  if (item.expiryDate != null && list.type == ShoppingListType.shopping) {
    chips.add(
      _MetadataChip(
        icon: Icons.hourglass_bottom,
        label: 'Expires ${formatShoppingDate(item.expiryDate!)}',
        color: colors.info,
      ),
    );
  }

  if (item.bought) {
    chips.add(
      _MetadataChip(
        icon: Icons.check_circle_outline,
        label: 'Purchased',
        color: colors.positive,
      ),
    );
  }

  return chips;
}

Color _resolvePriorityColor(
  BuildContext context,
  ShoppingItemPriority priority,
) {
  final colors = context.moneyBaseColors;
  switch (priority) {
    case ShoppingItemPriority.low:
      return colors.info;
    case ShoppingItemPriority.medium:
      return colors.secondaryAccent;
    case ShoppingItemPriority.high:
      return colors.negative;
  }
}

String _buildItemTimelineSummary(ShoppingList list, ShoppingItem item) {
  final createdLabel = formatShoppingDate(item.createdAt);
  final updatedLabel = formatShoppingDate(item.updatedAt);
  if (list.type == ShoppingListType.shopping) {
    return 'Created $createdLabel · Updated $updatedLabel';
  }
  return 'Updated $updatedLabel';
}

void _showItemImagePreview(BuildContext context, String url) {
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
