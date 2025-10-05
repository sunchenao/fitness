import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../errors/app_exceptions.dart';
import '../constants/app_constants.dart';

// 传感器数据模型
class SensorData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  SensorData({
    required this.x,
    required this.y,
    required this.z,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // 计算向量的模长
  double get magnitude => sqrt(x * x + y * y + z * z);

  // 归一化向量
  SensorData get normalized {
    final mag = magnitude;
    if (mag == 0) return SensorData(x: 0, y: 0, z: 0, timestamp: timestamp);
    return SensorData(
      x: x / mag,
      y: y / mag,
      z: z / mag,
      timestamp: timestamp,
    );
  }

  @override
  String toString() => 'SensorData(x: $x, y: $y, z: $z, magnitude: $magnitude)';

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'z': z,
        'magnitude': magnitude,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory SensorData.fromAccelerometerEvent(AccelerometerEvent event) =>
      SensorData(x: event.x, y: event.y, z: event.z);

  factory SensorData.fromGyroscopeEvent(GyroscopeEvent event) =>
      SensorData(x: event.x, y: event.y, z: event.z);

  factory SensorData.fromUserAccelerometerEvent(UserAccelerometerEvent event) =>
      SensorData(x: event.x, y: event.y, z: event.z);
}

// 传感器状态枚举
enum SensorStatus {
  uninitialized,
  initializing,
  active,
  paused,
  error,
  unavailable,
}

// 传感器类型枚举
enum SensorType {
  accelerometer,
  gyroscope,
  userAccelerometer,
}

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  static SensorService get instance => _instance;
  SensorService._internal();

  // 传感器数据流
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<UserAccelerometerEvent>? _userAccelerometerSubscription;

  // 数据流控制器
  final StreamController<SensorData> _accelerometerController =
      StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _gyroscopeController =
      StreamController<SensorData>.broadcast();
  final StreamController<SensorData> _userAccelerometerController =
      StreamController<SensorData>.broadcast();

  // 传感器状态
  SensorStatus _status = SensorStatus.uninitialized;
  String? _errorMessage;

  // 配置参数
  Duration _sampleInterval = const Duration(milliseconds: 20); // 50Hz
  bool _isCalibrated = false;
  SensorData? _calibrationOffset;

  // Getters
  SensorStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isActive => _status == SensorStatus.active;
  bool get isCalibrated => _isCalibrated;
  Duration get sampleInterval => _sampleInterval;

  // 数据流
  Stream<SensorData> get accelerometerStream => _accelerometerController.stream;
  Stream<SensorData> get gyroscopeStream => _gyroscopeController.stream;
  Stream<SensorData> get userAccelerometerStream => _userAccelerometerController.stream;

  // 初始化传感器服务
  Future<void> initialize() async {
    try {
      _setStatus(SensorStatus.initializing);
      
      // 检查传感器可用性
      await _checkSensorAvailability();
      
      _setStatus(SensorStatus.active);
      _clearError();
    } catch (e) {
      _setError('传感器初始化失败: $e');
      throw SensorException('传感器初始化失败', originalError: e);
    }
  }

  // 检查传感器可用性
  Future<void> _checkSensorAvailability() async {
    try {
      // 尝试读取一次传感器数据来验证可用性
      final completer = Completer<void>();
      StreamSubscription? testSubscription;
      
      testSubscription = accelerometerEventStream().listen(
        (event) {
          testSubscription?.cancel();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onError: (error) {
          testSubscription?.cancel();
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );
      
      // 等待5秒，如果没有数据则认为传感器不可用
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw SensorException('传感器响应超时，设备可能不支持所需传感器');
        },
      );
    } catch (e) {
      _setStatus(SensorStatus.unavailable);
      throw SensorException('传感器不可用', originalError: e);
    }
  }

  // 开始数据采集
  Future<void> startDataCollection() async {
    try {
      if (_status != SensorStatus.active && _status != SensorStatus.paused) {
        await initialize();
      }

      _setStatus(SensorStatus.active);

      // 启动加速度计数据采集
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: _sampleInterval,
      ).listen(
        (AccelerometerEvent event) {
          final data = SensorData.fromAccelerometerEvent(event);
          final processedData = _applyCalibration(data);
          _accelerometerController.add(processedData);
        },
        onError: (error) {
          _setError('加速度计数据采集错误: $error');
        },
      );

      // 启动陀螺仪数据采集
      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: _sampleInterval,
      ).listen(
        (GyroscopeEvent event) {
          final data = SensorData.fromGyroscopeEvent(event);
          _gyroscopeController.add(data);
        },
        onError: (error) {
          _setError('陀螺仪数据采集错误: $error');
        },
      );

      // 启动用户加速度计数据采集（去除重力影响）
      _userAccelerometerSubscription = userAccelerometerEventStream(
        samplingPeriod: _sampleInterval,
      ).listen(
        (UserAccelerometerEvent event) {
          final data = SensorData.fromUserAccelerometerEvent(event);
          _userAccelerometerController.add(data);
        },
        onError: (error) {
          _setError('用户加速度计数据采集错误: $error');
        },
      );

      _clearError();
    } catch (e) {
      _setError('开始数据采集失败: $e');
      throw SensorException('开始数据采集失败', originalError: e);
    }
  }

  // 停止数据采集
  Future<void> stopDataCollection() async {
    try {
      await _accelerometerSubscription?.cancel();
      await _gyroscopeSubscription?.cancel();
      await _userAccelerometerSubscription?.cancel();

      _accelerometerSubscription = null;
      _gyroscopeSubscription = null;
      _userAccelerometerSubscription = null;

      _setStatus(SensorStatus.paused);
    } catch (e) {
      _setError('停止数据采集失败: $e');
    }
  }

  // 暂停数据采集
  Future<void> pauseDataCollection() async {
    if (_status == SensorStatus.active) {
      await stopDataCollection();
    }
  }

  // 恢复数据采集
  Future<void> resumeDataCollection() async {
    if (_status == SensorStatus.paused) {
      await startDataCollection();
    }
  }

  // 设置采样间隔
  void setSampleInterval(Duration interval) {
    _sampleInterval = interval;
    // 如果正在采集数据，重启采集以应用新的间隔
    if (_status == SensorStatus.active) {
      stopDataCollection().then((_) => startDataCollection());
    }
  }

  // 设置采样频率（Hz）
  void setSampleRate(int frequencyHz) {
    if (frequencyHz > 0 && frequencyHz <= 100) {
      setSampleInterval(Duration(milliseconds: 1000 ~/ frequencyHz));
    }
  }

  // 校准传感器
  Future<void> calibrate({Duration calibrationDuration = const Duration(seconds: 3)}) async {
    try {
      _isCalibrated = false;
      
      final calibrationData = <SensorData>[];
      late StreamSubscription subscription;
      
      final completer = Completer<void>();
      
      subscription = accelerometerStream.listen((data) {
        calibrationData.add(data);
      });
      
      // 收集校准数据
      Timer(calibrationDuration, () async {
        await subscription.cancel();
        
        if (calibrationData.isNotEmpty) {
          // 计算平均偏移量
          double avgX = calibrationData.map((d) => d.x).reduce((a, b) => a + b) / calibrationData.length;
          double avgY = calibrationData.map((d) => d.y).reduce((a, b) => a + b) / calibrationData.length;
          double avgZ = calibrationData.map((d) => d.z).reduce((a, b) => a + b) / calibrationData.length;
          
          _calibrationOffset = SensorData(x: avgX, y: avgY, z: avgZ - 9.8); // 减去重力加速度
          _isCalibrated = true;
        }
        
        completer.complete();
      });
      
      await completer.future;
    } catch (e) {
      throw SensorException('传感器校准失败', originalError: e);
    }
  }

  // 应用校准偏移
  SensorData _applyCalibration(SensorData data) {
    if (!_isCalibrated || _calibrationOffset == null) {
      return data;
    }
    
    return SensorData(
      x: data.x - _calibrationOffset!.x,
      y: data.y - _calibrationOffset!.y,
      z: data.z - _calibrationOffset!.z,
      timestamp: data.timestamp,
    );
  }

  // 重置校准
  void resetCalibration() {
    _isCalibrated = false;
    _calibrationOffset = null;
  }

  // 获取传感器信息
  Map<String, dynamic> getSensorInfo() {
    return {
      'status': _status.toString(),
      'isActive': isActive,
      'isCalibrated': _isCalibrated,
      'sampleInterval': _sampleInterval.inMilliseconds,
      'sampleRate': 1000 / _sampleInterval.inMilliseconds,
      'errorMessage': _errorMessage,
      'hasCalibrationOffset': _calibrationOffset != null,
    };
  }

  // 设置状态
  void _setStatus(SensorStatus status) {
    _status = status;
    if (kDebugMode) {
      print('传感器状态变更: $status');
    }
  }

  // 设置错误
  void _setError(String error) {
    _errorMessage = error;
    _setStatus(SensorStatus.error);
    if (kDebugMode) {
      print('传感器错误: $error');
    }
  }

  // 清除错误
  void _clearError() {
    _errorMessage = null;
  }

  // 获取实时传感器数据快照
  Future<Map<String, SensorData?>> getDataSnapshot() async {
    final snapshot = <String, SensorData?>{
      'accelerometer': null,
      'gyroscope': null,
      'userAccelerometer': null,
    };

    if (_status != SensorStatus.active) {
      return snapshot;
    }

    try {
      // 获取最新的传感器数据
      final futures = [
        accelerometerStream.first.timeout(const Duration(milliseconds: 100)),
        gyroscopeStream.first.timeout(const Duration(milliseconds: 100)),
        userAccelerometerStream.first.timeout(const Duration(milliseconds: 100)),
      ];

      final results = await Future.wait(futures, eagerError: false);
      
      if (results.isNotEmpty) {
        snapshot['accelerometer'] = results[0];
        snapshot['gyroscope'] = results[1];
        snapshot['userAccelerometer'] = results[2];
      }
    } catch (e) {
      // 超时或错误时返回空快照
    }

    return snapshot;
  }

  // 清理资源
  Future<void> dispose() async {
    await stopDataCollection();
    await _accelerometerController.close();
    await _gyroscopeController.close();
    await _userAccelerometerController.close();
  }
}