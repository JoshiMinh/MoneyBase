import 'package:flutter/material.dart';

import '../../../../app/theme/theme.dart';

class AppShellFloatingActions extends StatelessWidget {
  const AppShellFloatingActions({
    required this.onAddTransaction,
    required this.onOpenAssistant,
    this.showAssistantButton = true,
    super.key,
  });

  final VoidCallback onAddTransaction;
  final VoidCallback onOpenAssistant;
  final bool showAssistantButton;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width > 640 ? 32.0 : 20.0;
    final colors = context.moneyBaseColors;
    final surface = Color.alphaBlend(colors.glassOverlay, colors.surfaceElevated);
    final borderColor = colors.surfaceBorder;
    final shadowColor = colors.surfaceShadow.withOpacity(0.45);

    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                if (showAssistantButton) ...[
                  FloatingActionButton(
                    heroTag: 'aiChatFab',
                    onPressed: onOpenAssistant,
                    elevation: 0,
                    child: const Icon(Icons.smart_toy_outlined),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Align(
                    alignment:
                        showAssistantButton ? Alignment.centerRight : Alignment.center,
                    child: FloatingActionButton.extended(
                      heroTag: 'addTransactionFab',
                      onPressed: onAddTransaction,
                      icon: const Icon(Icons.add),
                      label: const Text('Add transaction'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
