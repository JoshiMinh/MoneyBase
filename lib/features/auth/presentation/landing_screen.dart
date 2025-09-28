import 'package:flutter/material.dart';

import 'auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(showMarketingPanel: false);
  }
}
