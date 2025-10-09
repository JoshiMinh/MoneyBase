part of 'package:moneybase/features/app_shell/presentation/app_shell.dart';

class _DesktopAiAssistantButton extends StatelessWidget {
  const _DesktopAiAssistantButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  static const double _railWidth = 260;
  static const double _gapFromRail = 16;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _railWidth + _gapFromRail,
      bottom: 32,
      child: FloatingActionButton(
        heroTag: 'aiChatDesktopFab',
        onPressed: onPressed,
        child: const Icon(Icons.smart_toy_outlined),
      ),
    );
  }
}
