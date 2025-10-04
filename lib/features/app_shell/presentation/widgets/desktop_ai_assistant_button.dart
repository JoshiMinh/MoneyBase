part of 'app_shell.dart';

class _DesktopAiAssistantButton extends StatelessWidget {
  const _DesktopAiAssistantButton({
    required this.extendedRail,
    required this.onPressed,
  });

  final bool extendedRail;
  final VoidCallback onPressed;

  static const double _extendedWidth = 260;
  static const double _collapsedWidth = 88;

  @override
  Widget build(BuildContext context) {
    final railWidth = extendedRail ? _extendedWidth : _collapsedWidth;

    return Positioned(
      left: railWidth - 28,
      bottom: 32,
      child: FloatingActionButton(
        heroTag: 'aiChatDesktopFab',
        onPressed: onPressed,
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }
}
