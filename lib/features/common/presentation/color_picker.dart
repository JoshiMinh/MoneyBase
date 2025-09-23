
import 'package:flutter/material.dart';

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
    Color(0xFF7B5BFF),
    Color(0xFFFF6D8D),
    Color(0xFFFFA658),
    Color(0xFF50D2C2),
    Color(0xFF5D9BFF),
    Color(0xFF9C6DFF),
    Color(0xFF2ECC71),
    Color(0xFFFFB6C1),
    Color(0xFFF9D423),
    Color(0xFF3AA6FF),
    Color(0xFFFA7A35),
    Color(0xFF5F6BFF),
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
            selected: selectedColor != null &&
                color.value == selectedColor!.value,
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
          border: Border.all(
            color: borderColor,
            width: selected ? 3 : 2,
          ),
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
