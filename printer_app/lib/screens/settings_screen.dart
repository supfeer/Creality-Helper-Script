import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final TextEditingController tokenController = TextEditingController(text: appState.paymentToken ?? '');
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Включить экран оплаты'),
            value: appState.paymentEnabled,
            onChanged: (v) async => appState.setPaymentEnabled(v),
          ),
          ListTile(
            title: const Text('Токен оплаты'),
            subtitle: TextField(
              controller: tokenController,
              decoration: const InputDecoration(hintText: 'Вставьте токен'),
              onSubmitted: (value) async => appState.setPaymentToken(value.trim()),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () async => appState.clearPaymentToken(),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Переуказать IP принтера'),
            subtitle: Text(appState.selectedIp ?? '-'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/ip'),
          ),
          ListTile(
            title: const Text('Изменить SSH данные'),
            subtitle: Text('${appState.sshUsername}:${appState.sshPassword.isNotEmpty ? '******' : ''}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/credentials'),
          ),
        ],
      ),
    );
  }
}

