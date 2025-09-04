import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

class NetworkScanner {
  Future<String?> _getLocalIPv4() async {
    try {
      final NetworkInfo info = NetworkInfo();
      final String? ip = await info.getWifiIP();
      return ip;
    } catch (_) {
      return null;
    }
  }

  String? _inferSubnetFromIp(String? ip) {
    if (ip == null) return null;
    final List<String> parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}.'; // /24
  }

  Future<bool> _isPortOpen(String host, int port, {Duration timeout = const Duration(milliseconds: 500)}) async {
    try {
      final Socket socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> scanSubnetForSsh({int port = 22, Duration timeoutPerHost = const Duration(milliseconds: 500)}) async {
    final String? localIp = await _getLocalIPv4();
    final String? subnet = _inferSubnetFromIp(localIp);
    if (subnet == null) return <String>[];

    final List<Future<void>> tasks = <Future<void>>[];
    final List<String> found = <String>[];

    for (int i = 1; i < 255; i++) {
      final String host = '$subnet$i';
      tasks.add(() async {
        final bool open = await _isPortOpen(host, port, timeout: timeoutPerHost);
        if (open) {
          found.add(host);
        }
      }());
    }

    await Future.wait(tasks);
    found.sort();
    return found;
  }
}

