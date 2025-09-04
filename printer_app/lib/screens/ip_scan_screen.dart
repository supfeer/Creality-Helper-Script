import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../services/network_scanner.dart';

class IpScanScreen extends StatefulWidget {
  const IpScanScreen({super.key});

  @override
  State<IpScanScreen> createState() => _IpScanScreenState();
}

class _IpScanScreenState extends State<IpScanScreen> {
  final TextEditingController _manualIpController = TextEditingController();
  bool _scanning = false;
  String? _error;

  @override
  void dispose() {
    _manualIpController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final NetworkScanner scanner = NetworkScanner();
      final List<String> ips = await scanner.scanSubnetForSsh();
      if (!mounted) return;
      context.read<AppState>().setDiscoveredIps(ips);
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final List<String> ips = appState.discoveredIps;

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор IP принтера')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualIpController,
                    decoration: const InputDecoration(labelText: 'IP вручную'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    final String ip = _manualIpController.text.trim();
                    if (ip.isEmpty) return;
                    await appState.setSelectedIp(ip);
                    if (!mounted) return;
                    Navigator.of(context).pushNamed('/payment');
                  },
                  child: const Text('Выбрать'),
                )
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: const Icon(Icons.search),
                  label: Text(_scanning ? 'Сканирование...' : 'Сканировать сеть'),
                ),
                const SizedBox(width: 12),
                Text('Найдено: ${ips.length}')
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: ips.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final String ip = ips[index];
                return ListTile(
                  title: Text(ip),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await appState.setSelectedIp(ip);
                    if (!mounted) return;
                    Navigator.of(context).pushNamed('/payment');
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

