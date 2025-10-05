import 'dart:math';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/exercise_record_model.dart';

// 卡路里计算方法枚举
enum CalorieCalculationMethod {
  basic,        // 基础方法（固定系数）
  met,          // MET方法（代谢当量）
  heartRate,    // 心率方法（暂未实现）
  personalized, // 个性化方法（结合用户数据）
}

// 运动强度等级
enum ExerciseIntensity {
  light,    // 轻度
  moderate, // 中度
  vigorous, // 剧烈
  extreme,  // 极限
}

// 卡路里计算结果
class CalorieCalculationResult {
  final double totalCalories;
  final double caloriesPerRep;
  final double caloriesPerMinute;
  final double metValue;
  final ExerciseIntensity intensity;
  final Map<String, dynamic> breakdown;
  final DateTime timestamp;

  CalorieCalculationResult({
    required this.totalCalories,
    required this.caloriesPerRep,
    required this.caloriesPerMinute,
    required this.metValue,
    required this.intensity,
    required this.breakdown,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'CalorieCalculationResult(total: ${totalCalories.toStringAsFixed(1)} cal, per rep: ${caloriesPerRep.toStringAsFixed(2)} cal)';
}

// 运动计数和卡路里计算引擎
class ExerciseCalculationEngine {
  static final ExerciseCalculationEngine _instance = ExerciseCalculationEngine._internal();
  factory ExerciseCalculationEngine() => _instance;
  static ExerciseCalculationEngine get instance => _instance;
  ExerciseCalculationEngine._internal();

  // MET值表（代谢当量，每公斤体重每小时消耗的大卡数）
  static const Map<String, double> _metValues = {
    'pushup': 3.8,      // 俯卧撑
    'pullup': 8.0,      // 引体向上
    'situp': 3.5,       // 仰卧起坐
    'squat': 5.0,       // 深蹲
    'plank': 2.8,       // 平板支撑
  };

  // 运动强度系数
  static const Map<String, Map<ExerciseIntensity, double>> _intensityMultipliers = {
    'pushup': {
      ExerciseIntensity.light: 0.8,
      ExerciseIntensity.moderate: 1.0,
      ExerciseIntensity.vigorous: 1.3,
      ExerciseIntensity.extreme: 1.6,
    },
    'pullup': {
      ExerciseIntensity.light: 0.9,
      ExerciseIntensity.moderate: 1.0,
      ExerciseIntensity.vigorous: 1.2,
      ExerciseIntensity.extreme: 1.5,
    },
    'situp': {
      ExerciseIntensity.light: 0.8,
      ExerciseIntensity.moderate: 1.0,
      ExerciseIntensity.vigorous: 1.4,
      ExerciseIntensity.extreme: 1.7,
    },
    'squat': {
      ExerciseIntensity.light: 0.8,
      ExerciseIntensity.moderate: 1.0,
      ExerciseIntensity.vigorous: 1.3,
      ExerciseIntensity.extreme: 1.6,
    },
    'plank': {
      ExerciseIntensity.light: 0.8,
      ExerciseIntensity.moderate: 1.0,
      ExerciseIntensity.vigorous: 1.2,
      ExerciseIntensity.extreme: 1.4,
    },
  };

  // 基础卡路里计算（简单方法）
  CalorieCalculationResult calculateBasicCalories({
    required String exerciseType,
    required int count,
    required int durationSeconds,
    UserModel? user,
  }) {
    final baseCaloriesPerRep = AppConstants.caloriesPerRep[exerciseType] ?? 0.3;
    final personalMultiplier = user?.personalCalorieMultiplier ?? 1.0;
    
    final caloriesPerRep = baseCaloriesPerRep * personalMultiplier;
    final totalCalories = count * caloriesPerRep;
    final caloriesPerMinute = durationSeconds > 0 ? totalCalories / (durationSeconds / 60.0) : 0.0;
    
    final intensity = _determineIntensityFromCount(exerciseType, count, durationSeconds);
    
    return CalorieCalculationResult(
      totalCalories: totalCalories,
      caloriesPerRep: caloriesPerRep,
      caloriesPerMinute: caloriesPerMinute,
      metValue: _metValues[exerciseType] ?? 3.0,
      intensity: intensity,
      breakdown: {
        'method': 'basic',
        'base_calories_per_rep': baseCaloriesPerRep,
        'personal_multiplier': personalMultiplier,
        'count': count,
        'duration_minutes': durationSeconds / 60.0,
      },
    );
  }

  // MET方法卡路里计算
  CalorieCalculationResult calculateMETCalories({
    required String exerciseType,
    required int count,
    required int durationSeconds,
    required UserModel user,
    ExerciseIntensity? customIntensity,
  }) {
    final weight = user.weight ?? 70.0; // 默认70kg
    final baseMET = _metValues[exerciseType] ?? 3.0;
    final durationHours = durationSeconds / 3600.0;
    
    // 确定运动强度
    final intensity = customIntensity ?? _determineIntensityFromCount(exerciseType, count, durationSeconds);
    final intensityMultiplier = _intensityMultipliers[exerciseType]?[intensity] ?? 1.0;
    
    // 调整MET值
    final adjustedMET = baseMET * intensityMultiplier;
    
    // MET公式：卡路里 = MET × 体重(kg) × 时间(小时)
    final totalCalories = adjustedMET * weight * durationHours;
    final caloriesPerRep = count > 0 ? totalCalories / count : 0.0;
    final caloriesPerMinute = durationSeconds > 0 ? totalCalories / (durationSeconds / 60.0) : 0.0;
    
    return CalorieCalculationResult(
      totalCalories: totalCalories,
      caloriesPerRep: caloriesPerRep,
      caloriesPerMinute: caloriesPerMinute,
      metValue: adjustedMET,
      intensity: intensity,
      breakdown: {
        'method': 'met',
        'base_met': baseMET,
        'intensity_multiplier': intensityMultiplier,
        'adjusted_met': adjustedMET,
        'weight': weight,
        'duration_hours': durationHours,
        'count': count,
      },
    );
  }

  // 个性化卡路里计算
  CalorieCalculationResult calculatePersonalizedCalories({
    required String exerciseType,
    required int count,
    required int durationSeconds,
    required UserModel user,
    double? avgHeartRate,
    double? peakIntensity,
    Map<String, dynamic>? additionalFactors,
  }) {
    // 基础MET计算
    final metResult = calculateMETCalories(
      exerciseType: exerciseType,
      count: count,
      durationSeconds: durationSeconds,
      user: user,
    );
    
    double personalizedCalories = metResult.totalCalories;
    final breakdown = Map<String, dynamic>.from(metResult.breakdown);
    breakdown['method'] = 'personalized';
    
    // 年龄调整
    if (user.age != null) {
      final ageMultiplier = _calculateAgeMultiplier(user.age!);
      personalizedCalories *= ageMultiplier;
      breakdown['age_multiplier'] = ageMultiplier;
    }
    
    // 性别调整
    if (user.gender != null) {
      final genderMultiplier = _calculateGenderMultiplier(user.gender!);
      personalizedCalories *= genderMultiplier;
      breakdown['gender_multiplier'] = genderMultiplier;
    }
    
    // BMI调整
    if (user.bmi != null) {
      final bmiMultiplier = _calculateBMIMultiplier(user.bmi!);
      personalizedCalories *= bmiMultiplier;
      breakdown['bmi_multiplier'] = bmiMultiplier;
    }
    
    // 运动强度调整
    if (peakIntensity != null) {
      final intensityMultiplier = _calculateIntensityMultiplier(peakIntensity);
      personalizedCalories *= intensityMultiplier;
      breakdown['peak_intensity_multiplier'] = intensityMultiplier;
    }
    
    // 心率调整（如果可用）
    if (avgHeartRate != null && user.age != null) {
      final hrMultiplier = _calculateHeartRateMultiplier(avgHeartRate, user.age!);
      personalizedCalories *= hrMultiplier;
      breakdown['heart_rate_multiplier'] = hrMultiplier;
    }
    
    // 其他因素调整
    if (additionalFactors != null) {
      // 环境温度
      if (additionalFactors['temperature'] != null) {
        final tempMultiplier = _calculateTemperatureMultiplier(additionalFactors['temperature']);
        personalizedCalories *= tempMultiplier;
        breakdown['temperature_multiplier'] = tempMultiplier;
      }
      
      // 海拔高度
      if (additionalFactors['altitude'] != null) {
        final altitudeMultiplier = _calculateAltitudeMultiplier(additionalFactors['altitude']);
        personalizedCalories *= altitudeMultiplier;
        breakdown['altitude_multiplier'] = altitudeMultiplier;
      }
    }
    
    final caloriesPerRep = count > 0 ? personalizedCalories / count : 0.0;
    final caloriesPerMinute = durationSeconds > 0 ? personalizedCalories / (durationSeconds / 60.0) : 0.0;
    
    return CalorieCalculationResult(
      totalCalories: personalizedCalories,
      caloriesPerRep: caloriesPerRep,
      caloriesPerMinute: caloriesPerMinute,
      metValue: metResult.metValue,
      intensity: metResult.intensity,
      breakdown: breakdown,
    );
  }

  // 批量计算多次运动记录的卡路里
  List<CalorieCalculationResult> calculateBatchCalories({
    required List<ExerciseRecordModel> records,
    required UserModel user,
    CalorieCalculationMethod method = CalorieCalculationMethod.personalized,
  }) {
    final results = <CalorieCalculationResult>[];
    
    for (final record in records) {
      CalorieCalculationResult result;
      
      switch (method) {
        case CalorieCalculationMethod.basic:
          result = calculateBasicCalories(
            exerciseType: record.exerciseType,
            count: record.count,
            durationSeconds: record.duration,
            user: user,
          );
          break;
        case CalorieCalculationMethod.met:
          result = calculateMETCalories(
            exerciseType: record.exerciseType,
            count: record.count,
            durationSeconds: record.duration,
            user: user,
          );
          break;
        case CalorieCalculationMethod.personalized:
        default:
          result = calculatePersonalizedCalories(
            exerciseType: record.exerciseType,
            count: record.count,
            durationSeconds: record.duration,
            user: user,
          );
          break;
      }
      
      results.add(result);
    }
    
    return results;
  }

  // 根据计数和时间确定运动强度
  ExerciseIntensity _determineIntensityFromCount(String exerciseType, int count, int durationSeconds) {
    if (durationSeconds == 0) return ExerciseIntensity.moderate;
    
    final repsPerMinute = count / (durationSeconds / 60.0);
    
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
        if (repsPerMinute < 15) return ExerciseIntensity.light;
        if (repsPerMinute < 25) return ExerciseIntensity.moderate;
        if (repsPerMinute < 35) return ExerciseIntensity.vigorous;
        return ExerciseIntensity.extreme;
        
      case 'pullup':
        if (repsPerMinute < 5) return ExerciseIntensity.light;
        if (repsPerMinute < 10) return ExerciseIntensity.moderate;
        if (repsPerMinute < 15) return ExerciseIntensity.vigorous;
        return ExerciseIntensity.extreme;
        
      case 'situp':
        if (repsPerMinute < 20) return ExerciseIntensity.light;
        if (repsPerMinute < 30) return ExerciseIntensity.moderate;
        if (repsPerMinute < 45) return ExerciseIntensity.vigorous;
        return ExerciseIntensity.extreme;
        
      case 'squat':
        if (repsPerMinute < 15) return ExerciseIntensity.light;
        if (repsPerMinute < 25) return ExerciseIntensity.moderate;
        if (repsPerMinute < 35) return ExerciseIntensity.vigorous;
        return ExerciseIntensity.extreme;
        
      default:
        return ExerciseIntensity.moderate;
    }
  }

  // 年龄调整系数
  double _calculateAgeMultiplier(int age) {
    if (age < 20) return 1.1;
    if (age < 30) return 1.05;
    if (age < 45) return 1.0;
    if (age < 60) return 0.95;
    return 0.9;
  }

  // 性别调整系数
  double _calculateGenderMultiplier(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case '男':
        return 1.0;
      case 'female':
      case '女':
        return 0.85;
      default:
        return 0.92;
    }
  }

  // BMI调整系数
  double _calculateBMIMultiplier(double bmi) {
    if (bmi < 18.5) return 0.9;   // 体重过轻
    if (bmi < 24) return 1.0;     // 正常体重
    if (bmi < 28) return 1.1;     // 超重
    return 1.2;                   // 肥胖
  }

  // 运动强度调整系数
  double _calculateIntensityMultiplier(double peakIntensity) {
    // peakIntensity 范围 0.0 - 10.0
    return 0.8 + (peakIntensity / 10.0) * 0.4; // 0.8 - 1.2 范围
  }

  // 心率调整系数
  double _calculateHeartRateMultiplier(double avgHeartRate, int age) {
    final maxHeartRate = 220 - age;
    final heartRateReserve = maxHeartRate - 60; // 假设静息心率60
    final intensity = (avgHeartRate - 60) / heartRateReserve;
    
    return 0.8 + intensity.clamp(0.0, 1.0) * 0.6; // 0.8 - 1.4 范围
  }

  // 温度调整系数
  double _calculateTemperatureMultiplier(double temperature) {
    // 温度越高，消耗越大
    if (temperature < 15) return 0.95;  // 低温
    if (temperature < 25) return 1.0;   // 舒适温度
    if (temperature < 35) return 1.1;   // 高温
    return 1.2;                         // 极高温
  }

  // 海拔调整系数
  double _calculateAltitudeMultiplier(double altitude) {
    // 海拔越高，消耗越大（氧气稀薄）
    if (altitude < 1000) return 1.0;
    if (altitude < 2000) return 1.05;
    if (altitude < 3000) return 1.1;
    return 1.15;
  }

  // 计算总体统计信息
  Map<String, dynamic> calculateSummaryStatistics(List<ExerciseRecordModel> records, UserModel user) {
    if (records.isEmpty) {
      return {
        'total_calories': 0.0,
        'total_count': 0,
        'total_duration': 0,
        'average_calories_per_session': 0.0,
        'average_calories_per_minute': 0.0,
        'exercise_breakdown': <String, dynamic>{},
      };
    }

    final calorieResults = calculateBatchCalories(records: records, user: user);
    
    double totalCalories = 0.0;
    int totalCount = 0;
    int totalDuration = 0;
    Map<String, dynamic> exerciseBreakdown = {};
    
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      final result = calorieResults[i];
      
      totalCalories += result.totalCalories;
      totalCount += record.count;
      totalDuration += record.duration;
      
      // 按运动类型分组统计
      final exerciseType = record.exerciseType;
      if (!exerciseBreakdown.containsKey(exerciseType)) {
        exerciseBreakdown[exerciseType] = {
          'count': 0,
          'sessions': 0,
          'total_reps': 0,
          'total_duration': 0,
          'total_calories': 0.0,
        };
      }
      
      exerciseBreakdown[exerciseType]['sessions'] += 1;
      exerciseBreakdown[exerciseType]['total_reps'] += record.count;
      exerciseBreakdown[exerciseType]['total_duration'] += record.duration;
      exerciseBreakdown[exerciseType]['total_calories'] += result.totalCalories;
    }
    
    return {
      'total_calories': totalCalories,
      'total_count': totalCount,
      'total_sessions': records.length,
      'total_duration': totalDuration,
      'average_calories_per_session': totalCalories / records.length,
      'average_calories_per_minute': totalDuration > 0 ? totalCalories / (totalDuration / 60.0) : 0.0,
      'average_reps_per_session': totalCount / records.length,
      'exercise_breakdown': exerciseBreakdown,
    };
  }

  // 获取推荐卡路里目标
  Map<String, double> getRecommendedCalorieTargets(UserModel user) {
    final weight = user.weight ?? 70.0;
    final age = user.age ?? 30;
    final gender = user.gender ?? 'male';
    
    // 基于BMR计算日常运动建议
    final bmr = user.bmr ?? _calculateEstimatedBMR(weight, 175.0, age, gender);
    
    return {
      'daily_exercise_calories': bmr * 0.1,  // 建议日常运动消耗BMR的10%
      'weekly_exercise_calories': bmr * 0.7, // 周目标
      'per_session_light': bmr * 0.02,       // 轻度运动
      'per_session_moderate': bmr * 0.04,    // 中度运动  
      'per_session_vigorous': bmr * 0.06,    // 剧烈运动
    };
  }

  // 估算BMR（如果用户数据不完整）
  double _calculateEstimatedBMR(double weight, double height, int age, String gender) {
    // Mifflin-St Jeor方程
    double baseBmr = (10 * weight) + (6.25 * height) - (5 * age);
    
    if (gender.toLowerCase() == 'male' || gender.toLowerCase() == '男') {
      return baseBmr + 5;
    } else {
      return baseBmr - 161;
    }
  }

  // 调试信息
  void printCalculationDebug(CalorieCalculationResult result) {
    if (kDebugMode) {
      print('=== 卡路里计算详情 ===');
      print('总卡路里: ${result.totalCalories.toStringAsFixed(2)} cal');
      print('每次卡路里: ${result.caloriesPerRep.toStringAsFixed(3)} cal');
      print('每分钟卡路里: ${result.caloriesPerMinute.toStringAsFixed(2)} cal/min');
      print('MET值: ${result.metValue}');
      print('运动强度: ${result.intensity}');
      print('计算详情: ${result.breakdown}');
      print('=====================');
    }
  }
}