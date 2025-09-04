import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/script_service.dart';
import '../services/ssh_service.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  final ScriptService _scriptService = ScriptService();
  final SshService _sshService = SshService();
  List<ScriptEntry> _scripts = <ScriptEntry>[];
  String? _log;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    try {
      final scripts = await _scriptService.listAvailableScripts();
      if (!mounted) return;
      setState(() {
        _scripts = scripts;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    }
  }

  Future<void> _runScript(ScriptEntry entry) async {
    final AppState appState = context.read<AppState>();
    if (!appState.hasValidToken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет токена. Пройдите оплату.')));
      }
      return;
    }

    final String? host = appState.selectedIp;
    if (host == null || host.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не выбран IP принтера')));
      }
      return;
    }

    setState(() {
      _running = true;
      _log = '';
      _error = null;
    });

    try {
      final String content = await _scriptService.loadScriptContent(entry.assetPath);
      final String result = await _sshService.uploadAndRunScriptFromAsset(
        host: host,
        username: appState.sshUsername,
        password: appState.sshPassword,
        scriptContent: content,
      );
      setState(() {
        _log = (_log ?? '') + result;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Операции'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text('Модель: ${appState.selectedModel ?? '-'}')),
                Expanded(child: Text('IP: ${appState.selectedIp ?? '-'}')),
                Expanded(child: Text('Платеж: ${appState.paymentEnabled ? (appState.hasValidToken ? 'ок' : 'нет') : 'выкл.'}')),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.8,
              ),
              itemCount: _scripts.length,
              itemBuilder: (context, index) {
                final ScriptEntry entry = _scripts[index];
                return FilledButton(
                  onPressed: _running ? null : () => _runScript(entry),
                  child: Text(entry.displayName),
                );
              },
            ),
          ),
          SizedBox(
            height: 160,
            child: Container(
              color: Colors.black,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _log ?? 'Лог будет здесь',
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

