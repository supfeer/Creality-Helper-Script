import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  Future<void> _openPaymentUrl() async {
    // Placeholder SBP URL. Replace with real SBP deeplink/URL logic.
    final Uri url = Uri.parse('https://example.com/sbp-pay');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();

    if (!appState.paymentEnabled) {
      // Skip payment if disabled
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/ops');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Оплата СБП')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Оплатите в банковском приложении через СБП.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _openPaymentUrl,
              child: const Text('Открыть оплату'),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Токен после оплаты',
                hintText: 'Вставьте токен',
              ),
              onSubmitted: (value) async {
                if (value.isEmpty) return;
                await appState.setPaymentToken(value.trim());
                if (!context.mounted) return;
                Navigator.of(context).pushReplacementNamed('/ops');
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: appState.paymentEnabled,
                  onChanged: (v) async {
                    await appState.setPaymentEnabled(v);
                  },
                ),
                const SizedBox(width: 8),
                const Text('Экран оплаты включен'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

