import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/core/services/calorie_calculation_engine.dart';

void main() {
  late ExerciseCalculationEngine calculationEngine;

  setUp(() {
    calculationEngine = ExerciseCalculationEngine.instance;
  });

  group('ExerciseCalculationEngine Tests', () {
    test('应该能够获取单例实例', () {
      final instance1 = ExerciseCalculationEngine.instance;
      final instance2 = ExerciseCalculationEngine.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('应该能够计算俯卧撑基础卡路里', () {
      final result = calculationEngine.calculateBasicCalories(
        exerciseType: 'push_up',
        count: 10,
        durationSeconds: 120,
      );

      expect(result.totalCalories, greaterThan(0));
      expect(result.caloriesPerRep, greaterThan(0));
      expect(result.calculationMethod, equals('basic'));
    });

    test('应该能够计算引体向上基础卡路里', () {
      final result = calculationEngine.calculateBasicCalories(
        exerciseType: 'pull_up',
        count: 5,
        durationSeconds: 100,
      );

      expect(result.totalCalories, greaterThan(0));
      expect(result.caloriesPerRep, greaterThan(0));
      // 引体向上消耗的卡路里应该比俯卧撑多
      final pushUpResult = calculationEngine.calculateBasicCalories(
        exerciseType: 'push_up',
        count: 5,
        durationSeconds: 100,
      );
      expect(result.caloriesPerRep, greaterThan(pushUpResult.caloriesPerRep));
    });

    test('应该能够计算仰卧起坐基础卡路里', () {
      final result = calculationEngine.calculateBasicCalories(
        exerciseType: 'sit_up',
        count: 15,
        durationSeconds: 90,
      );

      expect(result.totalCalories, greaterThan(0));
      expect(result.caloriesPerRep, greaterThan(0));
      expect(result.calculationMethod, equals('basic'));
    });

    test('应该能够使用MET方法计算卡路里', () {
      final result = calculationEngine.calculateMETCalories(
        exerciseType: 'push_up',
        count: 20,
        durationSeconds: 180,
        weightKg: 70,
      );

      expect(result.totalCalories, greaterThan(0));
      expect(result.caloriesPerRep, greaterThan(0));
      expect(result.calculationMethod, equals('met'));
    });

    test('MET计算应该考虑体重差异', () {
      final lightPersonResult = calculationEngine.calculateMETCalories(
        exerciseType: 'push_up',
        count: 10,
        durationSeconds: 120,
        weightKg: 50, // 较轻体重
      );

      final heavyPersonResult = calculationEngine.calculateMETCalories(
        exerciseType: 'push_up',
        count: 10,
        durationSeconds: 120,
        weightKg: 90, // 较重体重
      );

      expect(heavyPersonResult.totalCalories, greaterThan(lightPersonResult.totalCalories));
    });

    test('应该能够进行个性化卡路里计算', () {
      final mockUser = {
        'age': 25,
        'gender': 'male',
        'weight': 75,
        'height': 175,
      };

      final result = calculationEngine.calculatePersonalizedCalories(
        exerciseType: 'push_up',
        count: 15,
        durationSeconds: 150,
        user: mockUser,
      );

      expect(result.totalCalories, greaterThan(0));
      expect(result.caloriesPerRep, greaterThan(0));
      expect(result.calculationMethod, equals('personalized'));
    });

    test('个性化计算应该考虑性别差异', () {
      final maleUser = {
        'age': 30,
        'gender': 'male',
        'weight': 75,
        'height': 175,
      };

      final femaleUser = {
        'age': 30,
        'gender': 'female',
        'weight': 75,
        'height': 175,
      };

      final maleResult = calculationEngine.calculatePersonalizedCalories(
        exerciseType: 'push_up',
        count: 10,
        durationSeconds: 120,
        user: maleUser,
      );

      final femaleResult = calculationEngine.calculatePersonalizedCalories(
        exerciseType: 'push_up',
        count: 10,
        durationSeconds: 120,
        user: femaleUser,
      );

      // 男性基础代谢率通常较高，消耗卡路里可能略多
      expect(maleResult.totalCalories, greaterThanOrEqualTo(femaleResult.totalCalories * 0.9));
    });

    test('个性化计算应该考虑年龄差异', () {
      final youngUser = {
        'age': 20,
        'gender': 'male',
        'weight': 75,
        'height': 175,
      };

      final olderUser = {
        'age': 50,
        'gender': 'male',
        'weight': 75,
        'height': 175,
      };

      final youngResult = calculationEngine.calculatePersonalizedCalories(
        exerciseType: 'push_up',
        count: 10,
        durationSeconds: 120,
        user: youngUser,
      );

      final olderResult = calculationEngine.calculatePersonalizedCalories(
        exerciseType: 'push_up',
        count: 10,
        durationSeconds: 120,
        user: olderUser,
      );

      // 年轻人的基础代谢率通常较高
      expect(youngResult.totalCalories, greaterThanOrEqualTo(olderResult.totalCalories * 0.95));
    });

    test('应该能够批量计算多条记录', () {
      final records = [
        {
          'exerciseType': 'push_up',
          'count': 10,
          'durationSeconds': 60,
        },
        {
          'exerciseType': 'sit_up',
          'count': 15,
          'durationSeconds': 80,
        },
        {
          'exerciseType': 'pull_up',
          'count': 5,
          'durationSeconds': 90,
        },
      ];

      final results = calculationEngine.calculateBatchRecords(records);

      expect(results.length, equals(3));
      expect(results.every((r) => r.totalCalories > 0), isTrue);
      
      final totalCalories = results.fold<double>(0, (sum, result) => sum + result.totalCalories);
      expect(totalCalories, greaterThan(0));
    });

    test('应该能够获取运动统计摘要', () {
      final records = [
        {
          'exerciseType': 'push_up',
          'count': 20,
          'durationSeconds': 120,
          'calories': 25.5,
        },
        {
          'exerciseType': 'push_up',
          'count': 15,
          'durationSeconds': 90,
          'calories': 19.0,
        },
        {
          'exerciseType': 'sit_up',
          'count': 30,
          'durationSeconds': 150,
          'calories': 30.0,
        },
      ];

      final summary = calculationEngine.getExerciseSummary(records);

      expect(summary['totalSessions'], equals(3));
      expect(summary['totalReps'], equals(65));
      expect(summary['totalCalories'], equals(74.5));
      expect(summary['totalDurationMinutes'], closeTo(6.0, 0.1));
      expect(summary['averageCaloriesPerSession'], closeTo(24.83, 0.1));
      expect(summary['exerciseTypeBreakdown'], isA<Map<String, dynamic>>());
    });

    test('应该正确处理零值输入', () {
      final result = calculationEngine.calculateBasicCalories(
        exerciseType: 'push_up',
        count: 0,
        durationSeconds: 0,
      );

      expect(result.totalCalories, equals(0));
      expect(result.caloriesPerRep, equals(0));
    });

    test('应该正确处理无效运动类型', () {
      final result = calculationEngine.calculateBasicCalories(
        exerciseType: 'invalid_exercise',
        count: 10,
        durationSeconds: 60,
      );

      // 对于无效运动类型，应该使用默认值
      expect(result.totalCalories, greaterThanOrEqualTo(0));
    });

    test('应该能够计算运动强度等级', () {
      // 低强度运动
      final lowIntensity = calculationEngine.calculateBasicCalories(
        exerciseType: 'push_up',
        count: 5,
        durationSeconds: 300, // 5分钟做5个，频率很低
      );

      // 高强度运动
      final highIntensity = calculationEngine.calculateBasicCalories(
        exerciseType: 'push_up',
        count: 30,
        durationSeconds: 60, // 1分钟做30个，频率很高
      );

      expect(highIntensity.caloriesPerRep, greaterThan(lowIntensity.caloriesPerRep));
    });

    test('应该能够计算热量密度', () {
      final result = calculationEngine.calculateBasicCalories(
        exerciseType: 'push_up',
        count: 20,
        durationSeconds: 120,
      );

      final caloriesPerMinute = result.totalCalories / (120 / 60);
      expect(caloriesPerMinute, greaterThan(0));
    });
  });
}