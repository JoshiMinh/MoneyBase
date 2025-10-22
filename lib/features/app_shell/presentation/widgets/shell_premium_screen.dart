part of 'package:moneybase/features/app_shell/presentation/app_shell.dart';

void _openPremiumScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const _PremiumScreen(),
    ),
  );
}

class _PremiumScreen extends StatelessWidget {
  const _PremiumScreen();

  @override
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      builder: (context, layout) {
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        final themeColors = context.themeColors;
        final isDark = theme.brightness == Brightness.dark;
        final descriptionColor =
            themeColors.mutedText.withOpacity(isDark ? 0.9 : 0.85);
        final badgeSize = layout.isWide ? 56.0 : 48.0;
        final horizontalPadding = layout.isWide ? 28.0 : 20.0;
        final headerSpacing = layout.isWide ? 32.0 : 24.0;
        final bottomPadding = layout.isWide ? 28.0 : 20.0;
        final plans = _premiumPlans;

        void handleSelection(String label) {
          final messenger = ScaffoldMessenger.of(context);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('$label plan is coming soon.'),
              ),
            );
        }

        final content = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                      themeColors.primaryAccent,
                      themeColors.surfaceElevated,
                      isDark ? 0.7 : 0.85,
                    ) ??
                    themeColors.surfaceElevated,
                themeColors.surfaceBackground.withOpacity(
                  isDark ? 0.82 : 0.95,
                ),
              ],
            ),
            border: Border.all(
              color: themeColors.surfaceBorder.withOpacity(
                isDark ? 0.6 : 0.75,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: themeColors.surfaceShadow.withOpacity(
                  isDark ? 0.7 : 0.35,
                ),
                blurRadius: 36,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              layout.isWide ? 36.0 : 28.0,
              horizontalPadding,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            themeColors.primaryAccent,
                            themeColors.secondaryAccent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeColors.primaryAccent.withOpacity(0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: layout.isWide ? 30 : 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MoneyBase Premium',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: themeColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unlock advanced automations, collaborative tools, and an AI coach tailored to your finances.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: descriptionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _PremiumFeatureChip(
                      icon: Icons.auto_graph_rounded,
                      label: 'Predictive cashflow forecasts',
                    ),
                    _PremiumFeatureChip(
                      icon: Icons.bolt_rounded,
                      label: 'Smart automation recipes',
                    ),
                    _PremiumFeatureChip(
                      icon: Icons.group_work_outlined,
                      label: 'Shared workspaces & roles',
                    ),
                    _PremiumFeatureChip(
                      icon: Icons.download_done_rounded,
                      label: 'One-click exports & backups',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(
                  height: 1,
                  color: themeColors.surfaceBorder.withOpacity(
                    isDark ? 0.6 : 0.7,
                  ),
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < plans.length; i++) ...[
                  _PremiumPlanTile(
                    option: plans[i],
                    onTap: () => handleSelection(plans[i].title),
                  ),
                  if (i != plans.length - 1) const SizedBox(height: 16),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  icon: const Icon(Icons.star_rate_rounded),
                  label: const Text('Join the Premium waitlist'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => handleSelection('Lifetime'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Maybe later'),
                  ),
                ),
              ],
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: themeColors.primaryText,
                tooltip: 'Back',
              ),
            ),
            SizedBox(height: headerSpacing),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: content,
              ),
            ),
            SizedBox(height: layout.isWide ? 40 : 32),
            Text(
              'MoneyBase © 2025',
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: themeColors.mutedText.withOpacity(isDark ? 0.9 : 0.7),
                letterSpacing: 0.4,
              ),
            ),
          ],
        );
      },
    );
  }
}

const List<_PremiumPlanOption> _premiumPlans = [
  _PremiumPlanOption(
    title: 'Monthly',
    price: r'$2 / month',
    description: 'Flexible access with a low monthly rate.',
  ),
  _PremiumPlanOption(
    title: 'Annual',
    price: r'$20 / year',
    description: 'Stay on track all year and save more than 15%.',
  ),
  _PremiumPlanOption(
    title: 'Lifetime',
    price: r'$25 one-time',
    description: 'Pay once and enjoy MoneyBase Premium forever.',
    badge: 'Best value',
    highlight: true,
  ),
];

class _PremiumFeatureChip extends StatelessWidget {
  const _PremiumFeatureChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: themeColors.surfaceBackground.withOpacity(isDark ? 0.6 : 0.9),
        border: Border.all(
          color: themeColors.surfaceBorder.withOpacity(isDark ? 0.7 : 0.85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: themeColors.primaryAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: themeColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPlanOption {
  const _PremiumPlanOption({
    required this.title,
    required this.price,
    required this.description,
    this.badge,
    this.highlight = false,
  });

  final String title;
  final String price;
  final String description;
  final String? badge;
  final bool highlight;
}

class _PremiumPlanTile extends StatelessWidget {
  const _PremiumPlanTile({
    required this.option,
    required this.onTap,
  });

  final _PremiumPlanOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final isDark = theme.brightness == Brightness.dark;

    final highlightGradient = option.highlight
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColors.primaryAccent.withOpacity(isDark ? 0.32 : 0.18),
              themeColors.secondaryAccent.withOpacity(isDark ? 0.28 : 0.12),
            ],
          )
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: highlightGradient,
          color: highlightGradient == null
              ? themeColors.surfaceBackground.withOpacity(isDark ? 0.6 : 0.92)
              : null,
          border: Border.all(
            color: option.highlight
                ? themeColors.primaryAccent.withOpacity(0.65)
                : themeColors.surfaceBorder.withOpacity(isDark ? 0.7 : 0.85),
          ),
          boxShadow: option.highlight
              ? [
                  BoxShadow(
                    color: themeColors.primaryAccent.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColors.primaryAccent.withOpacity(isDark ? 0.35 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  option.badge!.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: themeColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              option.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: themeColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: themeColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              option.price,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: themeColors.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
