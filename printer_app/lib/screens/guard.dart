import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class TokenGuard extends StatelessWidget {
  final Widget child;
  const TokenGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    if (!appState.hasValidToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/payment');
        }
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}

