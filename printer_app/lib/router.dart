import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'screens/model_selection_screen.dart';
import 'screens/credentials_screen.dart';
import 'screens/ip_scan_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/operations_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/guard.dart';

GoRouter createRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) => const ModelSelectionScreen(),
      ),
      GoRoute(
        path: '/credentials',
        builder: (BuildContext context, GoRouterState state) => const CredentialsScreen(),
      ),
      GoRoute(
        path: '/ip',
        builder: (BuildContext context, GoRouterState state) => const IpScanScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (BuildContext context, GoRouterState state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/ops',
        builder: (BuildContext context, GoRouterState state) => const TokenGuard(child: OperationsScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
      ),
    ],
  );
}

