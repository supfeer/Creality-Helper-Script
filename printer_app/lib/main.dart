import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _appState;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.init().then((_) {
      if (mounted) setState(() {});
    });
    _router = createRouter(_appState);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );

    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp.router(
        title: 'Printer Manager',
        theme: theme,
        routerConfig: _router,
      ),
    );
  }
}
