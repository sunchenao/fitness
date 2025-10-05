import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class SettingsProvider with ChangeNotifier {
  // 用户设置
  UserModel? _userProfile;
  
  // 应用设置
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('zh', 'CN');
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // 运动设置
  Map<String, double> _exerciseSensitivity = {
    'pushup': 2.0,
    'pullup': 1.8,
    'situp': 1.5,
    'squat': 2.2,
    'plank': 0.5,
  };
  
  Map<String, int> _exerciseTargets = {
    'pushup': 20,
    'pullup': 10,
    'situp': 30,
    'squat': 25,
    'plank': 60, // 秒
  };
  
  bool _voicePromptEnabled = true;
  bool _autoCountEnabled = true;
  int _countdownDuration = 3; // 秒
  
  // 错误处理
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  UserModel? get userProfile => _userProfile;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  Map<String, double> get exerciseSensitivity => Map.unmodifiable(_exerciseSensitivity);
  Map<String, int> get exerciseTargets => Map.unmodifiable(_exerciseTargets);
  bool get voicePromptEnabled => _voicePromptEnabled;
  bool get autoCountEnabled => _autoCountEnabled;
  int get countdownDuration => _countdownDuration;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载用户档案
      final userProfileJson = prefs.getString(AppConstants.keyUserProfile);
      if (userProfileJson != null) {
        _userProfile = UserModel.fromJson(jsonDecode(userProfileJson));
      }
      
      // 加载应用设置
      final themeModeString = prefs.getString(AppConstants.keyThemeMode);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
      
      final languageCode = prefs.getString(AppConstants.keyLanguage);
      if (languageCode != null) {
        _locale = Locale(languageCode);
      }
      
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      
      // 加载运动设置
      final exerciseSettingsJson = prefs.getString(AppConstants.keyExerciseSettings);
      if (exerciseSettingsJson != null) {
        final exerciseSettings = jsonDecode(exerciseSettingsJson) as Map<String, dynamic>;
        
        if (exerciseSettings['sensitivity'] != null) {
          _exerciseSensitivity = Map<String, double>.from(exerciseSettings['sensitivity']);
        }
        
        if (exerciseSettings['targets'] != null) {
          _exerciseTargets = Map<String, int>.from(exerciseSettings['targets']);
        }
        
        _voicePromptEnabled = exerciseSettings['voice_prompt'] ?? true;
        _autoCountEnabled = exerciseSettings['auto_count'] ?? true;
        _countdownDuration = exerciseSettings['countdown_duration'] ?? 3;
      }
      
      notifyListeners();
    } catch (e) {
      setError('加载设置失败: $e');
    } finally {
      setLoading(false);
    }
  }

  // 保存用户档案
  Future<void> updateUserProfile(UserModel userProfile) async {
    try {
      setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.keyUserProfile,
        jsonEncode(userProfile.toJson()),
      );
      _userProfile = userProfile;
      clearError();
      notifyListeners();
    } catch (e) {
      setError('保存用户档案失败: $e');
    } finally {
      setLoading(false);
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

  // 设置通知开关
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
      _notificationsEnabled = enabled;
      notifyListeners();
    } catch (e) {
      setError('保存通知设置失败: $e');
    }
  }

  // 设置声音开关
  Future<void> setSoundEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', enabled);
      _soundEnabled = enabled;
      notifyListeners();
    } catch (e) {
      setError('保存声音设置失败: $e');
    }
  }

  // 设置震动开关
  Future<void> setVibrationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vibration_enabled', enabled);
      _vibrationEnabled = enabled;
      notifyListeners();
    } catch (e) {
      setError('保存震动设置失败: $e');
    }
  }

  // 设置运动灵敏度
  Future<void> setExerciseSensitivity(String exerciseType, double sensitivity) async {
    try {
      _exerciseSensitivity[exerciseType] = sensitivity;
      await _saveExerciseSettings();
      notifyListeners();
    } catch (e) {
      setError('保存运动灵敏度失败: $e');
    }
  }

  // 设置运动目标
  Future<void> setExerciseTarget(String exerciseType, int target) async {
    try {
      _exerciseTargets[exerciseType] = target;
      await _saveExerciseSettings();
      notifyListeners();
    } catch (e) {
      setError('保存运动目标失败: $e');
    }
  }

  // 设置语音提示
  Future<void> setVoicePromptEnabled(bool enabled) async {
    try {
      _voicePromptEnabled = enabled;
      await _saveExerciseSettings();
      notifyListeners();
    } catch (e) {
      setError('保存语音设置失败: $e');
    }
  }

  // 设置自动计数
  Future<void> setAutoCountEnabled(bool enabled) async {
    try {
      _autoCountEnabled = enabled;
      await _saveExerciseSettings();
      notifyListeners();
    } catch (e) {
      setError('保存自动计数设置失败: $e');
    }
  }

  // 设置倒计时时长
  Future<void> setCountdownDuration(int duration) async {
    try {
      if (duration >= 0 && duration <= 10) {
        _countdownDuration = duration;
        await _saveExerciseSettings();
        notifyListeners();
      }
    } catch (e) {
      setError('保存倒计时设置失败: $e');
    }
  }

  // 保存运动设置
  Future<void> _saveExerciseSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final exerciseSettings = {
      'sensitivity': _exerciseSensitivity,
      'targets': _exerciseTargets,
      'voice_prompt': _voicePromptEnabled,
      'auto_count': _autoCountEnabled,
      'countdown_duration': _countdownDuration,
    };
    await prefs.setString(
      AppConstants.keyExerciseSettings,
      jsonEncode(exerciseSettings),
    );
  }

  // 重置所有设置
  Future<void> resetAllSettings() async {
    try {
      setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // 重置为默认值
      _userProfile = null;
      _themeMode = ThemeMode.system;
      _locale = const Locale('zh', 'CN');
      _notificationsEnabled = true;
      _soundEnabled = true;
      _vibrationEnabled = true;
      _exerciseSensitivity = {
        'pushup': 2.0,
        'pullup': 1.8,
        'situp': 1.5,
        'squat': 2.2,
        'plank': 0.5,
      };
      _exerciseTargets = {
        'pushup': 20,
        'pullup': 10,
        'situp': 30,
        'squat': 25,
        'plank': 60,
      };
      _voicePromptEnabled = true;
      _autoCountEnabled = true;
      _countdownDuration = 3;
      
      clearError();
      notifyListeners();
    } catch (e) {
      setError('重置设置失败: $e');
    } finally {
      setLoading(false);
    }
  }

  // 获取特定运动的灵敏度
  double getExerciseSensitivity(String exerciseType) {
    return _exerciseSensitivity[exerciseType] ?? AppConstants.defaultSensitivity;
  }

  // 获取特定运动的目标
  int getExerciseTarget(String exerciseType) {
    return _exerciseTargets[exerciseType] ?? 20;
  }

  // 错误处理
  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }
}