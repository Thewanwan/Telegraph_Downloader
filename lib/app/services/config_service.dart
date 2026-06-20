import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_config.dart';

class ConfigService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _savePathKey = 'save_path';
  static const String _configKey = 'download_config';
  static const String _historyKey = 'download_history';

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.dark;
  String _savePath = '';
  DownloadConfig _downloadConfig = DownloadConfig();
  List<Map<String, dynamic>> _history = [];

  ThemeMode get themeMode => _themeMode;
  String get savePath => _savePath;
  DownloadConfig get downloadConfig => _downloadConfig;
  List<Map<String, dynamic>> get history => _history;

  ConfigService._();

  static Future<ConfigService> create() async {
    final service = ConfigService._();
    service._prefs = await SharedPreferences.getInstance();
    service._loadAll();
    return service;
  }

  void _loadAll() {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    _savePath = _prefs.getString(_savePathKey) ?? '';
    final configJson = _prefs.getString(_configKey);
    if (configJson != null) {
      _downloadConfig = DownloadConfig.fromJson(jsonDecode(configJson));
    }
    final historyJson = _prefs.getString(_historyKey);
    if (historyJson != null) {
      _history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setSavePath(String path) {
    _savePath = path;
    _prefs.setString(_savePathKey, path);
    notifyListeners();
  }

  void setDownloadConfig(DownloadConfig config) {
    _downloadConfig = config;
    _prefs.setString(_configKey, jsonEncode(config.toJson()));
    notifyListeners();
  }

  void addHistory(Map<String, dynamic> entry) {
    _history.insert(0, entry);
    if (_history.length > 100) {
      _history = _history.sublist(0, 100);
    }
    _prefs.setString(_historyKey, jsonEncode(_history));
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    _prefs.remove(_historyKey);
    notifyListeners();
  }
}
