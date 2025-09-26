import 'package:flutter/material.dart';
import 'package:moneybase/app/theme/app_colors.dart';

class MoneyBaseColorPicker extends StatelessWidget {
  const MoneyBaseColorPicker({
    required this.onColorSelected,
    this.selectedColor,
    this.onClear,
    super.key,
  });

  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback? onClear;

  static const List<Color> _palette = [
    MoneyBaseColors.red,
    MoneyBaseColors.green,
    MoneyBaseColors.blue,
    MoneyBaseColors.pink,
    MoneyBaseColors.purple,
    MoneyBaseColors.grey,
    MoneyBaseColors.yellow,
    MoneyBaseColors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in _palette)
          _ColorChip(
            color: color,
            selected:
                selectedColor != null && color.value == selectedColor!.value,
            onTap: () => onColorSelected(color),
          ),
        if (onClear != null)
          ActionChip(
            onPressed: onClear,
            label: const Text('Clear color'),
            avatar: const Icon(Icons.backspace_outlined, size: 18),
          ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white.withOpacity(0.4);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: selected ? 3 : 2),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
