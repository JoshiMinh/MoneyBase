import 'package:flutter/material.dart';

import '../../common/presentation/moneybase_shell.dart';
import 'widgets/auth_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MoneyBaseScaffold(
      maxContentWidth: 720,
      widePadding: const EdgeInsets.symmetric(horizontal: 64, vertical: 64),
      builder: (context, layout) {
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: layout.isWide ? 48 : 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AuthCard(
                onLoginSuccess: () => Navigator.of(context).maybePop(),
                isWide: layout.isWide,
              ),
            ),
          ),
        );
      },
    );
  }
}
