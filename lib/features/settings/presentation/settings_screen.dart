import 'package:flutter/material.dart';

import '../../../app/theme/palettes.dart';
import '../../../app/theme/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerProvider.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 840 ? 48 : 24,
                  vertical: 32,
                ),
                children: [
                  _SettingsCard(
                    title: 'Appearance',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('Dark mode'),
                          subtitle: const Text(
                            'Match the Compose toggle so state stays in sync.',
                          ),
                          value: controller.darkMode,
                          onChanged: controller.setDarkMode,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Color palette',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (var i = 0; i < kMoneyBasePalettes.length; i++)
                              ChoiceChip(
                                label: Text(kMoneyBasePalettes[i].name),
                                selected:
                                    controller.palette == kMoneyBasePalettes[i],
                                onSelected: (_) => controller.selectPalette(i),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final color = await showDialog<Color?>(
                              context: context,
                              builder: (context) => _ThemeColorPicker(
                                initialColor:
                                    controller.customPrimary ??
                                    controller.palette.primary,
                              ),
                            );
                            if (color != null) {
                              controller.updateCustomPrimary(color);
                            }
                          },
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text('Pick custom primary color'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => controller.updateCustomPrimary(null),
                          child: const Text('Reset custom color'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsCard(
                    title: 'Account',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: const Icon(Icons.person_outline),
                          ),
                          title: const Text('Jamie Rivera'),
                          subtitle: const Text('jamie.rivera@example.com'),
                          trailing: TextButton(
                            onPressed: () {},
                            child: const Text('Edit profile'),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.cloud_upload_outlined),
                          title: const Text('Upload avatar'),
                          subtitle: const Text(
                            'Connect Cloudinary to mirror the Android flow.',
                          ),
                          onTap: () {},
                        ),
                        if (onLogout != null) ...[
                          const SizedBox(height: 24),
                          FilledButton.tonalIcon(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign out'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemeColorPicker extends StatefulWidget {
  const _ThemeColorPicker({required this.initialColor});

  final Color initialColor;

  @override
  State<_ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<_ThemeColorPicker> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _selectedColor.red.toDouble(),
              max: 255,
              label: 'Red: ${_selectedColor.red}',
              onChanged: (value) => setState(
                () => _selectedColor = _selectedColor.withRed(value.toInt()),
              ),
            ),
            Slider(
              value: _selectedColor.green.toDouble(),
              max: 255,
              label: 'Green: ${_selectedColor.green}',
              onChanged: (value) => setState(
                () => _selectedColor = _selectedColor.withGreen(value.toInt()),
              ),
            ),
            Slider(
              value: _selectedColor.blue.toDouble(),
              max: 255,
              label: 'Blue: ${_selectedColor.blue}',
              onChanged: (value) => setState(
                () => _selectedColor = _selectedColor.withBlue(value.toInt()),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedColor),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
