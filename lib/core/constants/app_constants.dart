import 'package:flutter/material.dart';

class AppConstants {
  // 应用信息
  static const String appName = '健身记录';
  static const String appVersion = '1.0.0';
  static const String appDescription = '免费的智能健身记录应用';

  // 颜色主题
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF5722);
  
  // 背景颜色
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  
  // 文字颜色
  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textHintColor = Color(0xFF999999);

  // 尺寸常量
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusExtraLarge = 16.0;
  
  // 字体大小
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeNormal = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeading = 24.0;

  // 动画时长
  static const Duration animationDurationShort = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // 传感器配置
  static const int sensorSampleRate = 50; // Hz
  static const double defaultSensitivity = 2.0;
  static const int filterWindowSize = 5;
  static const int confirmationDelay = 500; // ms

  // 运动类型
  static const List<String> exerciseTypes = [
    'pushup',
    'pullup', 
    'situp',
    'squat',
    'plank',
  ];

  static const Map<String, String> exerciseNames = {
    'pushup': '俯卧撑',
    'pullup': '引体向上',
    'situp': '仰卧起坐', 
    'squat': '深蹲',
    'plank': '平板支撑',
  };

  // 卡路里计算常量
  static const Map<String, double> caloriesPerRep = {
    'pushup': 0.32,
    'pullup': 0.68,
    'situp': 0.15,
    'squat': 0.40,
    'plank': 0.20, // 每秒
  };

  // 支持的语言
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  // 数据库配置
  static const String databaseName = 'fitness_tracker.db';
  static const int databaseVersion = 1;

  // 共享偏好键
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyUserProfile = 'user_profile';
  static const String keyExerciseSettings = 'exercise_settings';
  static const String keyFirstLaunch = 'first_launch';

  // 权限配置
  static const List<String> requiredPermissions = [
    'sensors',
    'storage',
  ];

  // 网络配置（第二版本使用）
  static const String baseUrl = 'https://api.fitness-tracker.com';
  static const int connectTimeout = 30000; // ms
  static const int receiveTimeout = 30000; // ms
}