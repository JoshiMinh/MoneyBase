part of 'app_shell.dart';

Future<void> _showPremiumDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _PremiumDialog(),
  );
}

class _PremiumDialog extends StatelessWidget {
  const _PremiumDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final mutedColor =
        colorScheme.onSurface.withOpacity(theme.brightness == Brightness.dark ? 0.7 : 0.6);

    void handleSelection(String label) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$label plan is coming soon.'),
        ),
      );
    }

    Widget buildOption({
      required String title,
      required String price,
      required String description,
    }) {
      return Card(
        margin: const EdgeInsets.only(top: 12),
        elevation: 0,
        color: colorScheme.surfaceVariant
            .withOpacity(theme.brightness == Brightness.dark ? 0.35 : 0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => handleSelection(title),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(color: mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  price,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'MoneyBase Premium',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlock deeper insights, advanced planning tools, and personalized coaching with Premium.',
            style: textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          buildOption(
            title: 'Monthly',
            price: r'$2 / month',
            description: 'Flexible access with a low monthly rate.',
          ),
          buildOption(
            title: 'Annual',
            price: r'$20 / year',
            description: 'Stay on track all year and save more than 15%.',
          ),
          buildOption(
            title: 'Lifetime',
            price: r'$25 one-time',
            description: 'Pay once and enjoy MoneyBase Premium forever.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
      ],
    );
  }
}
