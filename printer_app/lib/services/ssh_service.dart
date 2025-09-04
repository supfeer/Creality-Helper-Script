import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';

class SshService {
  Future<String> executeCommand({
    required String host,
    required String username,
    required String password,
    required String command,
    int port = 22,
  }) async {
    // Connect
    final socket = await SSHSocket.connect(host, port);
    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: () => password,
    );

    try {
      final bytes = await client.run(command);
      final String result = utf8.decode(bytes);
      return result;
    } finally {
      client.close();
    }
  }

  Future<String> uploadAndRunScriptFromAsset({
    required String host,
    required String username,
    required String password,
    required String scriptContent,
    String remotePath = '/tmp/app_script.sh',
    int port = 22,
  }) async {
    // Encode the script to base64 and recreate it on remote, then execute
    final String base64Script = base64Encode(utf8.encode(scriptContent));
    final String command = [
      'set -e',
      "TMP_SCRIPT='$remotePath'",
      "echo '$base64Script' | base64 -d > \"\$TMP_SCRIPT\"",
      'chmod +x "\$TMP_SCRIPT"',
      'bash "\$TMP_SCRIPT"',
      'rm -f "\$TMP_SCRIPT" || true',
    ].join(' && ');

    return executeCommand(
      host: host,
      username: username,
      password: password,
      port: port,
      command: command,
    );
  }
}

