import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/core/services/exercise_recognition_service.dart';
import 'package:fitness/core/models/sensor_data_model.dart';

void main() {
  late ExerciseRecognitionService recognitionService;

  setUp(() {
    recognitionService = ExerciseRecognitionService();
  });

  group('ExerciseRecognitionService Tests', () {
    test('应该能够初始化运动识别服务', () {
      expect(recognitionService, isNotNull);
      expect(recognitionService.isRecognizing, isFalse);
    });

    test('应该能够开始俯卧撑识别', () async {
      await recognitionService.startRecognition('push_up');
      expect(recognitionService.isRecognizing, isTrue);
      expect(recognitionService.currentExerciseType, equals('push_up'));
    });

    test('应该能够停止运动识别', () async {
      await recognitionService.startRecognition('push_up');
      expect(recognitionService.isRecognizing, isTrue);

      await recognitionService.stopRecognition();
      expect(recognitionService.isRecognizing, isFalse);
      expect(recognitionService.currentExerciseType, isNull);
    });

    test('应该能够识别俯卧撑动作', () async {
      await recognitionService.startRecognition('push_up');
      
      int detectedCount = 0;
      recognitionService.onExerciseDetected = (type, count) {
        detectedCount = count;
      };

      // 模拟俯卧撑传感器数据序列
      final pushUpSequence = [
        // 下降阶段 - Z轴加速度增加
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 0.1,
          accelerometerY: 0.2,
          accelerometerZ: 12.0, // 高于静止阈值
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
        // 上升阶段 - Z轴加速度减少
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 500)),
          accelerometerX: 0.1,
          accelerometerY: 0.2,
          accelerometerZ: 8.0, // 低于静止阈值
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
        // 完成一次俯卧撑
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 1000)),
          accelerometerX: 0.1,
          accelerometerY: 0.2,
          accelerometerZ: 10.0, // 回到静止状态
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
      ];

      for (final data in pushUpSequence) {
        recognitionService.processSensorData(data);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await Future.delayed(const Duration(milliseconds: 500));
      expect(detectedCount, greaterThan(0));
    });

    test('应该能够识别引体向上动作', () async {
      await recognitionService.startRecognition('pull_up');
      
      int detectedCount = 0;
      recognitionService.onExerciseDetected = (type, count) {
        detectedCount = count;
      };

      // 模拟引体向上传感器数据序列
      final pullUpSequence = [
        // 上拉阶段 - Y轴加速度变化
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 0.1,
          accelerometerY: 8.0, // 低于重力阈值
          accelerometerZ: 0.2,
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
        // 下降阶段 - Y轴加速度增加
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 800)),
          accelerometerX: 0.1,
          accelerometerY: 12.0, // 高于重力阈值
          accelerometerZ: 0.2,
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
        // 完成一次引体向上
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 1500)),
          accelerometerX: 0.1,
          accelerometerY: 9.8, // 回到重力水平
          accelerometerZ: 0.2,
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
      ];

      for (final data in pullUpSequence) {
        recognitionService.processSensorData(data);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await Future.delayed(const Duration(milliseconds: 500));
      expect(detectedCount, greaterThan(0));
    });

    test('应该能够识别仰卧起坐动作', () async {
      await recognitionService.startRecognition('sit_up');
      
      int detectedCount = 0;
      recognitionService.onExerciseDetected = (type, count) {
        detectedCount = count;
      };

      // 模拟仰卧起坐传感器数据序列
      final sitUpSequence = [
        // 起身阶段 - X轴加速度变化
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 6.0, // 低于重力阈值
          accelerometerY: 0.2,
          accelerometerZ: 0.1,
          gyroscopeX: 2.0, // 较大的角速度变化
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
        // 躺下阶段 - X轴加速度恢复
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 600)),
          accelerometerX: 11.0, // 高于重力阈值
          accelerometerY: 0.2,
          accelerometerZ: 0.1,
          gyroscopeX: -1.5, // 反向角速度
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
        // 完成一次仰卧起坐
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 1200)),
          accelerometerX: 9.8, // 回到重力水平
          accelerometerY: 0.2,
          accelerometerZ: 0.1,
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
      ];

      for (final data in sitUpSequence) {
        recognitionService.processSensorData(data);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await Future.delayed(const Duration(milliseconds: 500));
      expect(detectedCount, greaterThan(0));
    });

    test('应该能够过滤噪声数据', () async {
      await recognitionService.startRecognition('push_up');
      
      int detectedCount = 0;
      recognitionService.onExerciseDetected = (type, count) {
        detectedCount = count;
      };

      // 模拟包含噪声的数据
      final noisyData = [
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 0.1,
          accelerometerY: 0.2,
          accelerometerZ: 9.8, // 正常重力值
          gyroscopeX: 0.1,
          gyroscopeY: 0.1,
          gyroscopeZ: 0.1,
        ),
        // 轻微的噪声变化 - 不应该触发动作识别
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
          accelerometerX: 0.2,
          accelerometerY: 0.3,
          accelerometerZ: 10.1, // 轻微变化
          gyroscopeX: 0.2,
          gyroscopeY: 0.2,
          gyroscopeZ: 0.2,
        ),
      ];

      for (final data in noisyData) {
        recognitionService.processSensorData(data);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      expect(detectedCount, equals(0)); // 噪声不应该触发动作计数
    });

    test('应该能够处理快速连续动作', () async {
      await recognitionService.startRecognition('push_up');
      
      int detectedCount = 0;
      recognitionService.onExerciseDetected = (type, count) {
        detectedCount = count;
      };

      // 模拟快速连续的俯卧撑动作
      for (int i = 0; i < 3; i++) {
        final baseTime = DateTime.now().add(Duration(milliseconds: i * 800));
        
        final sequence = [
          SensorDataModel(
            timestamp: baseTime,
            accelerometerX: 0.1,
            accelerometerY: 0.2,
            accelerometerZ: 12.0,
            gyroscopeX: 0.1,
            gyroscopeY: 0.1,
            gyroscopeZ: 0.1,
          ),
          SensorDataModel(
            timestamp: baseTime.add(const Duration(milliseconds: 400)),
            accelerometerX: 0.1,
            accelerometerY: 0.2,
            accelerometerZ: 8.0,
            gyroscopeX: 0.1,
            gyroscopeY: 0.1,
            gyroscopeZ: 0.1,
          ),
        ];

        for (final data in sequence) {
          recognitionService.processSensorData(data);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      expect(detectedCount, greaterThanOrEqualTo(2)); // 至少识别出2次动作
    });

    test('应该能够重置计数器', () async {
      await recognitionService.startRecognition('push_up');
      
      // 执行一些动作以增加计数
      final data = SensorDataModel(
        timestamp: DateTime.now(),
        accelerometerX: 0.1,
        accelerometerY: 0.2,
        accelerometerZ: 12.0,
        gyroscopeX: 0.1,
        gyroscopeY: 0.1,
        gyroscopeZ: 0.1,
      );
      
      recognitionService.processSensorData(data);
      await Future.delayed(const Duration(milliseconds: 100));

      // 重置计数器
      recognitionService.resetCounter();
      expect(recognitionService.currentCount, equals(0));
    });
  });
}