import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  // Persistent keys
  static const String _keySelectedModel = 'selected_model';
  static const String _keySelectedIp = 'selected_ip';
  static const String _keyPaymentEnabled = 'payment_enabled';

  static const String _keySshUsername = 'ssh_username';
  static const String _keySshPassword = 'ssh_password';
  static const String _keyPaymentToken = 'payment_token';

  // App data
  final List<String> printerModels = <String>[
    'Generic Printer',
    'Creality Ender',
    'Creality K1',
    'Voron',
    'Anycubic',
    'Prusa',
  ];

  String? _selectedModel;
  String _sshUsername = 'root';
  String _sshPassword = '';
  String? _selectedIp;
  List<String> _discoveredIps = <String>[];
  bool _paymentEnabled = true;
  String? _paymentToken;

  bool _initialized = false;

  // Getters
  String? get selectedModel => _selectedModel;
  String get sshUsername => _sshUsername;
  String get sshPassword => _sshPassword;
  String? get selectedIp => _selectedIp;
  List<String> get discoveredIps => List.unmodifiable(_discoveredIps);
  bool get paymentEnabled => _paymentEnabled;
  String? get paymentToken => _paymentToken;
  bool get initialized => _initialized;

  bool get hasValidToken => !_paymentEnabled || (_paymentToken != null && _paymentToken!.isNotEmpty);

  Future<void> init() async {
    if (_initialized) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _selectedModel = prefs.getString(_keySelectedModel);
    _selectedIp = prefs.getString(_keySelectedIp);
    _paymentEnabled = prefs.getBool(_keyPaymentEnabled) ?? true;

    _sshUsername = prefs.getString(_keySshUsername) ?? _sshUsername;
    _sshPassword = prefs.getString(_keySshPassword) ?? _sshPassword;
    _paymentToken = prefs.getString(_keyPaymentToken);

    _initialized = true;
    notifyListeners();
  }

  Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedModel, model);
    notifyListeners();
  }

  Future<void> setSshCredentials({required String username, required String password}) async {
    _sshUsername = username;
    _sshPassword = password;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySshUsername, username);
    await prefs.setString(_keySshPassword, password);
    notifyListeners();
  }

  Future<void> setSelectedIp(String ip) async {
    _selectedIp = ip;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedIp, ip);
    notifyListeners();
  }

  void setDiscoveredIps(List<String> ips) {
    _discoveredIps = ips;
    notifyListeners();
  }

  Future<void> setPaymentEnabled(bool enabled) async {
    _paymentEnabled = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPaymentEnabled, enabled);
    notifyListeners();
  }

  Future<void> setPaymentToken(String token) async {
    _paymentToken = token;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPaymentToken, token);
    notifyListeners();
  }

  Future<void> clearPaymentToken() async {
    _paymentToken = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPaymentToken);
    notifyListeners();
  }
}

