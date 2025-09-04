import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final AppState appState = context.read<AppState>();
    _usernameController = TextEditingController(text: appState.sshUsername);
    _passwordController = TextEditingController(text: appState.sshPassword);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('SSH Данные')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Логин'),
                validator: (value) => (value == null || value.isEmpty) ? 'Укажите логин' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль'),
                obscureText: true,
                validator: (value) => (value == null || value.isEmpty) ? 'Укажите пароль' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final String nextUsername = _usernameController.text.trim();
                  final String nextPassword = _passwordController.text;
                  await appState.setSshCredentials(
                    username: nextUsername,
                    password: nextPassword,
                  );
                  if (!mounted) return;
                  Navigator.of(context).pushNamed('/ip');
                },
                child: const Text('Далее'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

