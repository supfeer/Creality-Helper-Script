import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ScriptEntry {
  final String assetPath;
  final String displayName;
  final String? description;

  const ScriptEntry({required this.assetPath, required this.displayName, this.description});
}

class ScriptService {
  static const String _assetsPrefix = 'assets/scripts/';

  Future<List<ScriptEntry>> listAvailableScripts() async {
    // Attempt to read AssetManifest.json to list assets
    final String manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestJson) as Map<String, dynamic>;

    final List<ScriptEntry> entries = <ScriptEntry>[];
    for (final String key in manifest.keys) {
      if (key.startsWith(_assetsPrefix) && key.endsWith('.sh')) {
        final String name = key.substring(_assetsPrefix.length);
        entries.add(ScriptEntry(
          assetPath: key,
          displayName: name,
        ));
      }
    }

    entries.sort((a, b) => a.displayName.compareTo(b.displayName));
    return entries;
  }

  Future<String> loadScriptContent(String assetPath) async {
    return rootBundle.loadString(assetPath);
  }
}

