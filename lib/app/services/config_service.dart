import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
    try {
      final themeIndex = _prefs.getInt(_themeKey);
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }
    } catch (_) {}

    _savePath = _prefs.getString(_savePathKey) ?? '';

    try {
      final configJson = _prefs.getString(_configKey);
      if (configJson != null) {
        _downloadConfig = DownloadConfig.fromJson(jsonDecode(configJson));
      }
    } catch (_) {}

    try {
      final historyJson = _prefs.getString(_historyKey);
      if (historyJson != null) {
        final list = jsonDecode(historyJson);
        if (list is List) {
          _history = List<Map<String, dynamic>>.from(
            list.whereType<Map<String, dynamic>>(),
          );
        }
      }
    } catch (_) {
      _history = [];
    }
  }

  Future<String> getEffectiveSavePath() async {
    if (_savePath.isNotEmpty) {
      try {
        if (await Directory(_savePath).exists()) return _savePath;
      } catch (_) {}
    }

    if (Platform.isAndroid) {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (dirs != null && dirs.isNotEmpty) {
        final dlDir =
            Directory('${dirs.first.path}/TelegraphDownloader');
        await dlDir.create(recursive: true);
        return dlDir.path;
      }
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final dlDir =
            Directory('${extDir.path}/TelegraphDownloader');
        await dlDir.create(recursive: true);
        return dlDir.path;
      }
    }

    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final dlDir = Directory('${dir.path}/TelegraphDownloader');
      await dlDir.create(recursive: true);
      return dlDir.path;
    }

    final dir = await getDownloadsDirectory();
    if (dir != null) return dir.path;
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
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
    final urls = entry['urls'] as List<String>? ?? [];
    final truncatedUrls = urls.length > 10 ? urls.sublist(0, 10) : urls;

    final safeEntry = {
      'urls': truncatedUrls,
      'time': entry['time'],
      'success': entry['success'],
      'failed': entry['failed'],
      'images': entry['images'],
      'bytes': entry['bytes'],
      'elapsed': entry['elapsed'],
      'path': entry['path'],
    };
    _history.insert(0, safeEntry);
    if (_history.length > 30) {
      _history = _history.sublist(0, 30);
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
