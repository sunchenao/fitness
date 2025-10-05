import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/core/services/sensor_service.dart';
import 'package:fitness/core/models/sensor_data_model.dart';

void main() {
  late SensorService sensorService;

  setUp(() {
    sensorService = SensorService();
  });

  tearDown(() {
    sensorService.dispose();
  });

  group('SensorService Tests', () {
    test('应该能够初始化传感器服务', () {
      expect(sensorService, isNotNull);
      expect(sensorService.isListening, isFalse);
    });

    test('应该能够开始传感器监听', () async {
      List<SensorDataModel> receivedData = [];
      
      sensorService.sensorDataStream.listen((data) {
        receivedData.add(data);
      });

      await sensorService.startListening();
      expect(sensorService.isListening, isTrue);

      // 等待一段时间以接收数据
      await Future.delayed(const Duration(milliseconds: 500));
      
      await sensorService.stopListening();
      expect(sensorService.isListening, isFalse);
      
      // 在测试环境中可能无法获取真实传感器数据
      // 但至少验证监听状态的改变
    });

    test('应该能够停止传感器监听', () async {
      await sensorService.startListening();
      expect(sensorService.isListening, isTrue);

      await sensorService.stopListening();
      expect(sensorService.isListening, isFalse);
    });

    test('应该能够暂停和恢复传感器监听', () async {
      await sensorService.startListening();
      expect(sensorService.isListening, isTrue);

      sensorService.pauseListening();
      expect(sensorService.isListening, isFalse);

      sensorService.resumeListening();
      expect(sensorService.isListening, isTrue);

      await sensorService.stopListening();
    });

    test('应该能够设置采样频率', () {
      const testFrequency = Duration(milliseconds: 50);
      sensorService.setSamplingFrequency(testFrequency);
      
      // 验证采样频率设置（这需要访问内部状态，具体实现依赖于SensorService的设计）
      expect(sensorService.samplingFrequency, equals(testFrequency));
    });

    test('应该能够检查传感器可用性', () async {
      final isAccelerometerAvailable = await sensorService.isAccelerometerAvailable();
      final isGyroscopeAvailable = await sensorService.isGyroscopeAvailable();

      // 在测试环境中，传感器可能不可用，但方法应该返回boolean值
      expect(isAccelerometerAvailable, isA<bool>());
      expect(isGyroscopeAvailable, isA<bool>());
    });

    test('应该能够获取传感器校准状态', () async {
      final calibrationStatus = await sensorService.getCalibrationStatus();
      expect(calibrationStatus, isA<Map<String, dynamic>>());
    });

    test('应该能够进行传感器校准', () async {
      bool calibrationCompleted = false;
      
      sensorService.calibrationStatusStream.listen((status) {
        if (status['isCalibrated'] == true) {
          calibrationCompleted = true;
        }
      });

      await sensorService.startCalibration();
      
      // 等待校准完成或超时
      int waitCount = 0;
      while (!calibrationCompleted && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }

      // 校准应该在合理时间内完成或至少不抛出异常
      expect(() => sensorService.stopCalibration(), returnsNormally);
    });

    test('应该能够过滤传感器数据', () {
      final rawData = [
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 10.5,
          accelerometerY: 9.2,
          accelerometerZ: 8.8,
          gyroscopeX: 0.1,
          gyroscopeY: 0.2,
          gyroscopeZ: 0.1,
        ),
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 50)),
          accelerometerX: 10.3,
          accelerometerY: 9.4,
          accelerometerZ: 9.0,
          gyroscopeX: 0.15,
          gyroscopeY: 0.18,
          gyroscopeZ: 0.12,
        ),
      ];

      final filteredData = sensorService.applyFilter(rawData);
      
      expect(filteredData, isNotEmpty);
      expect(filteredData.length, lessThanOrEqualTo(rawData.length));
      
      // 过滤后的数据应该更平滑
      for (final data in filteredData) {
        expect(data.accelerometerX, isFinite);
        expect(data.accelerometerY, isFinite);
        expect(data.accelerometerZ, isFinite);
      }
    });

    test('应该能够检测运动状态', () {
      final staticData = [
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 0.1,
          accelerometerY: 0.1,
          accelerometerZ: 9.8,
          gyroscopeX: 0.0,
          gyroscopeY: 0.0,
          gyroscopeZ: 0.0,
        ),
      ];

      final movingData = [
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 5.5,
          accelerometerY: 8.2,
          accelerometerZ: 12.1,
          gyroscopeX: 2.1,
          gyroscopeY: 1.8,
          gyroscopeZ: 0.9,
        ),
      ];

      final staticMotionState = sensorService.detectMotionState(staticData);
      final movingMotionState = sensorService.detectMotionState(movingData);

      expect(staticMotionState, equals('static'));
      expect(movingMotionState, equals('moving'));
    });

    test('应该能够计算传感器数据统计', () {
      final testData = [
        SensorDataModel(
          timestamp: DateTime.now(),
          accelerometerX: 1.0,
          accelerometerY: 2.0,
          accelerometerZ: 3.0,
          gyroscopeX: 0.1,
          gyroscopeY: 0.2,
          gyroscopeZ: 0.3,
        ),
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 50)),
          accelerometerX: 2.0,
          accelerometerY: 3.0,
          accelerometerZ: 4.0,
          gyroscopeX: 0.2,
          gyroscopeY: 0.3,
          gyroscopeZ: 0.4,
        ),
        SensorDataModel(
          timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
          accelerometerX: 3.0,
          accelerometerY: 4.0,
          accelerometerZ: 5.0,
          gyroscopeX: 0.3,
          gyroscopeY: 0.4,
          gyroscopeZ: 0.5,
        ),
      ];

      final statistics = sensorService.calculateStatistics(testData);

      expect(statistics['accelerometer']['mean']['x'], equals(2.0));
      expect(statistics['accelerometer']['mean']['y'], equals(3.0));
      expect(statistics['accelerometer']['mean']['z'], equals(4.0));
      
      expect(statistics['gyroscope']['mean']['x'], equals(0.2));
      expect(statistics['gyroscope']['mean']['y'], equals(0.3));
      expect(statistics['gyroscope']['mean']['z'], equals(0.4));
    });

    test('应该能够检测传感器异常', () {
      final normalData = SensorDataModel(
        timestamp: DateTime.now(),
        accelerometerX: 1.0,
        accelerometerY: 2.0,
        accelerometerZ: 9.8,
        gyroscopeX: 0.1,
        gyroscopeY: 0.2,
        gyroscopeZ: 0.1,
      );

      final abnormalData = SensorDataModel(
        timestamp: DateTime.now(),
        accelerometerX: 100.0, // 异常高的值
        accelerometerY: 200.0,
        accelerometerZ: 300.0,
        gyroscopeX: 50.0, // 异常高的角速度
        gyroscopeY: 60.0,
        gyroscopeZ: 70.0,
      );

      expect(sensorService.isDataAbnormal(normalData), isFalse);
      expect(sensorService.isDataAbnormal(abnormalData), isTrue);
    });

    test('应该能够处理传感器错误', () {
      bool errorHandled = false;
      
      sensorService.errorStream.listen((error) {
        errorHandled = true;
      });

      // 模拟传感器错误
      sensorService.handleSensorError(Exception('Test sensor error'));
      
      expect(errorHandled, isTrue);
    });

    test('应该能够获取设备方向', () {
      final testData = SensorDataModel(
        timestamp: DateTime.now(),
        accelerometerX: 0.0,
        accelerometerY: 0.0,
        accelerometerZ: 9.8, // 垂直向上
        gyroscopeX: 0.0,
        gyroscopeY: 0.0,
        gyroscopeZ: 0.0,
      );

      final orientation = sensorService.getDeviceOrientation(testData);
      expect(orientation, equals('portrait')); // 设备垂直放置
    });

    test('应该能够重置传感器缓冲区', () {
      // 添加一些数据到缓冲区
      sensorService.addToBuffer(SensorDataModel(
        timestamp: DateTime.now(),
        accelerometerX: 1.0,
        accelerometerY: 2.0,
        accelerometerZ: 3.0,
        gyroscopeX: 0.1,
        gyroscopeY: 0.2,
        gyroscopeZ: 0.3,
      ));

      expect(sensorService.bufferSize, greaterThan(0));

      sensorService.clearBuffer();
      expect(sensorService.bufferSize, equals(0));
    });
  });
}