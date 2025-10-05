import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class AppStateProvider with ChangeNotifier {
  bool _isFirstLaunch = true;
  bool _isLoading = false;
  String? _errorMessage;
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('zh', 'CN');

  // Getters
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  AppStateProvider() {
    _loadAppState();
  }

  // 加载应用状态
  Future<void> _loadAppState() async {
    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 检查是否首次启动
      _isFirstLaunch = prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
      
      // 加载主题模式
      final themeModeString = prefs.getString(AppConstants.keyThemeMode);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
      
      // 加载语言设置
      final languageCode = prefs.getString(AppConstants.keyLanguage);
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }
      
      notifyListeners();
    } catch (e) {
      setError('加载应用设置失败: $e');
    } finally {
      setLoading(false);
    }
  }

  // 设置首次启动状态
  Future<void> setFirstLaunchCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyFirstLaunch, false);
      _isFirstLaunch = false;
      notifyListeners();
    } catch (e) {
      setError('保存首次启动状态失败: $e');
    }
  }

  // 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyThemeMode, mode.toString());
      _themeMode = mode;
      notifyListeners();
    } catch (e) {
      setError('保存主题设置失败: $e');
    }
  }

  // 设置语言
  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLanguage, locale.languageCode);
      _locale = locale;
      notifyListeners();
    } catch (e) {
      setError('保存语言设置失败: $e');
    }
  }

  // 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null; // 开始加载时清除错误信息
    }
    notifyListeners();
  }

  // 设置错误信息
  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 重置应用状态
  Future<void> resetAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _isFirstLaunch = true;
      _themeMode = ThemeMode.system;
      _locale = const Locale('zh', 'CN');
      _errorMessage = null;
      _isLoading = false;
      
      notifyListeners();
    } catch (e) {
      setError('重置应用状态失败: $e');
    }
  }

  // 检查网络连接状态（为第二版本预留）
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void setConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  // 应用版本信息
  String get appVersion => AppConstants.appVersion;
  String get appName => AppConstants.appName;
}