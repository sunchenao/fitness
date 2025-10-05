import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'sensor_service.dart';
import 'data_processor.dart';
import '../errors/app_exceptions.dart';

// 处理后的传感器数据
class ProcessedSensorData {
  final SensorData raw;
  final SensorData filtered;
  final Map<String, dynamic> features;
  final DateTime timestamp;

  ProcessedSensorData({
    required this.raw,
    required this.filtered,
    required this.features,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'ProcessedSensorData(raw: $raw, filtered: $filtered, features: $features)';
}

// 运动数据分析结果
class MotionAnalysisResult {
  final String exerciseType;
  final bool isValidMotion;
  final double confidence;
  final int? detectedCount;
  final Map<String, dynamic> analysisData;
  final DateTime timestamp;

  MotionAnalysisResult({
    required this.exerciseType,
    required this.isValidMotion,
    required this.confidence,
    this.detectedCount,
    required this.analysisData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'MotionAnalysisResult(exercise: $exerciseType, valid: $isValidMotion, confidence: $confidence, count: $detectedCount)';
}

class MotionDataManager {
  static final MotionDataManager _instance = MotionDataManager._internal();
  factory MotionDataManager() => _instance;
  static MotionDataManager get instance => _instance;
  MotionDataManager._internal();

  final SensorService _sensorService = SensorService.instance;
  final DataProcessor _dataProcessor = DataProcessor.instance;

  // 数据流订阅
  StreamSubscription<SensorData>? _accelerometerSubscription;
  StreamSubscription<SensorData>? _gyroscopeSubscription;
  StreamSubscription<SensorData>? _userAccelerometerSubscription;

  // 处理后的数据流控制器
  final StreamController<ProcessedSensorData> _processedDataController =
      StreamController<ProcessedSensorData>.broadcast();
  final StreamController<MotionAnalysisResult> _motionAnalysisController =
      StreamController<MotionAnalysisResult>.broadcast();

  // 运动检测状态
  bool _isAnalyzing = false;
  String? _currentExerciseType;
  double _detectionThreshold = 2.0;
  
  // 数据缓存
  final Queue<ProcessedSensorData> _dataHistory = Queue<ProcessedSensorData>();
  final int _maxHistorySize = 100;

  // 错误处理
  String? _errorMessage;

  // Getters
  bool get isAnalyzing => _isAnalyzing;
  String? get currentExerciseType => _currentExerciseType;
  double get detectionThreshold => _detectionThreshold;
  String? get errorMessage => _errorMessage;
  
  // 数据流
  Stream<ProcessedSensorData> get processedDataStream => _processedDataController.stream;
  Stream<MotionAnalysisResult> get motionAnalysisStream => _motionAnalysisController.stream;

  // 初始化运动数据管理器
  Future<void> initialize() async {
    try {
      // 初始化传感器服务
      await _sensorService.initialize();
      
      // 重置数据处理器
      _dataProcessor.reset();
      
      _clearError();
    } catch (e) {
      _setError('运动数据管理器初始化失败: $e');
      throw ExerciseException('运动数据管理器初始化失败', originalError: e);
    }
  }

  // 开始运动数据分析
  Future<void> startAnalysis(String exerciseType) async {
    try {
      if (_isAnalyzing) {
        await stopAnalysis();
      }

      _currentExerciseType = exerciseType;
      _isAnalyzing = true;
      
      // 设置运动特定的检测阈值
      _setExerciseSpecificSettings(exerciseType);
      
      // 开始传感器数据采集
      await _sensorService.startDataCollection();
      
      // 订阅传感器数据流
      _subscribeToSensorStreams();
      
      _clearError();
    } catch (e) {
      _setError('开始运动分析失败: $e');
      _isAnalyzing = false;
      throw ExerciseException('开始运动分析失败', originalError: e);
    }
  }

  // 停止运动数据分析
  Future<void> stopAnalysis() async {
    try {
      _isAnalyzing = false;
      _currentExerciseType = null;
      
      // 取消数据流订阅
      await _accelerometerSubscription?.cancel();
      await _gyroscopeSubscription?.cancel();
      await _userAccelerometerSubscription?.cancel();
      
      _accelerometerSubscription = null;
      _gyroscopeSubscription = null;
      _userAccelerometerSubscription = null;
      
      // 停止传感器数据采集
      await _sensorService.stopDataCollection();
      
      // 重置数据处理器
      _dataProcessor.reset();
      
      _clearError();
    } catch (e) {
      _setError('停止运动分析失败: $e');
    }
  }

  // 暂停分析
  Future<void> pauseAnalysis() async {
    if (_isAnalyzing) {
      await _sensorService.pauseDataCollection();
    }
  }

  // 恢复分析
  Future<void> resumeAnalysis() async {
    if (_isAnalyzing) {
      await _sensorService.resumeDataCollection();
    }
  }

  // 设置检测阈值
  void setDetectionThreshold(double threshold) {
    if (threshold > 0.0 && threshold <= 10.0) {
      _detectionThreshold = threshold;
    }
  }

  // 设置运动特定的参数
  void _setExerciseSpecificSettings(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
        _detectionThreshold = 2.0;
        _dataProcessor.setWindowSize(5);
        _dataProcessor.setLowPassAlpha(0.8);
        break;
      case 'pullup':
        _detectionThreshold = 1.8;
        _dataProcessor.setWindowSize(6);
        _dataProcessor.setLowPassAlpha(0.7);
        break;
      case 'situp':
        _detectionThreshold = 1.5;
        _dataProcessor.setWindowSize(4);
        _dataProcessor.setLowPassAlpha(0.9);
        break;
      case 'squat':
        _detectionThreshold = 2.2;
        _dataProcessor.setWindowSize(5);
        _dataProcessor.setLowPassAlpha(0.8);
        break;
      case 'plank':
        _detectionThreshold = 0.5;
        _dataProcessor.setWindowSize(10);
        _dataProcessor.setLowPassAlpha(0.95);
        break;
      default:
        _detectionThreshold = 2.0;
        _dataProcessor.setWindowSize(5);
        _dataProcessor.setLowPassAlpha(0.8);
    }
  }

  // 订阅传感器数据流
  void _subscribeToSensorStreams() {
    // 订阅加速度计数据
    _accelerometerSubscription = _sensorService.accelerometerStream.listen(
      (sensorData) {
        _processAccelerometerData(sensorData);
      },
      onError: (error) {
        _setError('加速度计数据处理错误: $error');
      },
    );

    // 订阅陀螺仪数据
    _gyroscopeSubscription = _sensorService.gyroscopeStream.listen(
      (sensorData) {
        _processGyroscopeData(sensorData);
      },
      onError: (error) {
        _setError('陀螺仪数据处理错误: $error');
      },
    );

    // 订阅用户加速度计数据
    _userAccelerometerSubscription = _sensorService.userAccelerometerStream.listen(
      (sensorData) {
        _processUserAccelerometerData(sensorData);
      },
      onError: (error) {
        _setError('用户加速度计数据处理错误: $error');
      },
    );
  }

  // 处理加速度计数据
  void _processAccelerometerData(SensorData rawData) {
    try {
      // 数据预处理
      final filteredData = _dataProcessor.processAccelerometerData(rawData);
      
      // 提取特征
      final features = _dataProcessor.extractFeatures(_dataProcessor._accelerometerBuffer);
      
      // 创建处理后的数据
      final processedData = ProcessedSensorData(
        raw: rawData,
        filtered: filteredData,
        features: features,
      );
      
      // 添加到历史记录
      _addToHistory(processedData);
      
      // 发送处理后的数据
      _processedDataController.add(processedData);
      
      // 运动分析
      if (_currentExerciseType != null) {
        final analysisResult = _analyzeMotion(processedData, _currentExerciseType!);
        if (analysisResult != null) {
          _motionAnalysisController.add(analysisResult);
        }
      }
    } catch (e) {
      _setError('加速度计数据处理失败: $e');
    }
  }

  // 处理陀螺仪数据
  void _processGyroscopeData(SensorData rawData) {
    try {
      final filteredData = _dataProcessor.processGyroscopeData(rawData);
      
      // 陀螺仪数据主要用于辅助分析
      final features = _dataProcessor.extractFeatures(_dataProcessor._gyroscopeBuffer);
      
      // 可以在这里添加基于陀螺仪的运动分析
    } catch (e) {
      _setError('陀螺仪数据处理失败: $e');
    }
  }

  // 处理用户加速度计数据
  void _processUserAccelerometerData(SensorData rawData) {
    try {
      final filteredData = _dataProcessor.processUserAccelerometerData(rawData);
      
      // 用户加速度计数据（去除重力）更适合检测运动
      final features = _dataProcessor.extractFeatures(_dataProcessor._userAccelerometerBuffer);
      
      // 可以在这里添加基于用户加速度计的运动分析
    } catch (e) {
      _setError('用户加速度计数据处理失败: $e');
    }
  }

  // 运动分析
  MotionAnalysisResult? _analyzeMotion(ProcessedSensorData data, String exerciseType) {
    try {
      // 基础运动检测逻辑
      final magnitude = data.filtered.magnitude;
      final features = data.features;
      
      bool isValidMotion = false;
      double confidence = 0.0;
      int? detectedCount;
      
      // 根据运动类型进行不同的分析
      switch (exerciseType.toLowerCase()) {
        case 'pushup':
          isValidMotion = _detectPushup(magnitude, features);
          confidence = _calculatePushupConfidence(magnitude, features);
          break;
        case 'pullup':
          isValidMotion = _detectPullup(magnitude, features);
          confidence = _calculatePullupConfidence(magnitude, features);
          break;
        case 'situp':
          isValidMotion = _detectSitup(magnitude, features);
          confidence = _calculateSitupConfidence(magnitude, features);
          break;
        case 'squat':
          isValidMotion = _detectSquat(magnitude, features);
          confidence = _calculateSquatConfidence(magnitude, features);
          break;
        case 'plank':
          isValidMotion = _detectPlank(magnitude, features);
          confidence = _calculatePlankConfidence(magnitude, features);
          break;
      }
      
      if (isValidMotion && confidence > 0.7) {
        return MotionAnalysisResult(
          exerciseType: exerciseType,
          isValidMotion: isValidMotion,
          confidence: confidence,
          detectedCount: detectedCount,
          analysisData: {
            'magnitude': magnitude,
            'features': features,
            'threshold': _detectionThreshold,
          },
        );
      }
      
      return null;
    } catch (e) {
      _setError('运动分析失败: $e');
      return null;
    }
  }

  // 俯卧撑检测逻辑
  bool _detectPushup(double magnitude, Map<String, dynamic> features) {
    // 简单的俯卧撑检测：检测Y轴的周期性变化
    final peaks = features['peaks'] as int? ?? 0;
    final range = features['range'] as double? ?? 0.0;
    
    return magnitude > _detectionThreshold && peaks > 0 && range > 1.0;
  }

  double _calculatePushupConfidence(double magnitude, Map<String, dynamic> features) {
    final range = features['range'] as double? ?? 0.0;
    final std = features['std'] as double? ?? 0.0;
    
    double confidence = 0.0;
    
    // 基于幅度的置信度
    if (magnitude > _detectionThreshold) {
      confidence += 0.4;
    }
    
    // 基于变化范围的置信度
    if (range > 1.0 && range < 8.0) {
      confidence += 0.3;
    }
    
    // 基于稳定性的置信度
    if (std > 0.5 && std < 3.0) {
      confidence += 0.3;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  // 引体向上检测逻辑
  bool _detectPullup(double magnitude, Map<String, dynamic> features) {
    final peaks = features['peaks'] as int? ?? 0;
    final range = features['range'] as double? ?? 0.0;
    
    return magnitude > _detectionThreshold && peaks > 0 && range > 1.5;
  }

  double _calculatePullupConfidence(double magnitude, Map<String, dynamic> features) {
    return _calculatePushupConfidence(magnitude, features); // 暂时使用相同逻辑
  }

  // 仰卧起坐检测逻辑
  bool _detectSitup(double magnitude, Map<String, dynamic> features) {
    final peaks = features['peaks'] as int? ?? 0;
    final range = features['range'] as double? ?? 0.0;
    
    return magnitude > _detectionThreshold && peaks > 0 && range > 0.8;
  }

  double _calculateSitupConfidence(double magnitude, Map<String, dynamic> features) {
    return _calculatePushupConfidence(magnitude, features); // 暂时使用相同逻辑
  }

  // 深蹲检测逻辑
  bool _detectSquat(double magnitude, Map<String, dynamic> features) {
    final peaks = features['peaks'] as int? ?? 0;
    final range = features['range'] as double? ?? 0.0;
    
    return magnitude > _detectionThreshold && peaks > 0 && range > 1.2;
  }

  double _calculateSquatConfidence(double magnitude, Map<String, dynamic> features) {
    return _calculatePushupConfidence(magnitude, features); // 暂时使用相同逻辑
  }

  // 平板支撑检测逻辑
  bool _detectPlank(double magnitude, Map<String, dynamic> features) {
    final std = features['std'] as double? ?? 0.0;
    
    // 平板支撑应该保持相对稳定
    return std < _detectionThreshold && magnitude > 8.0 && magnitude < 12.0;
  }

  double _calculatePlankConfidence(double magnitude, Map<String, dynamic> features) {
    final std = features['std'] as double? ?? 0.0;
    
    double confidence = 0.0;
    
    // 基于稳定性的置信度
    if (std < 0.5) {
      confidence += 0.6;
    }
    
    // 基于重力感应的置信度
    if (magnitude > 8.0 && magnitude < 12.0) {
      confidence += 0.4;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  // 添加到历史记录
  void _addToHistory(ProcessedSensorData data) {
    _dataHistory.add(data);
    if (_dataHistory.length > _maxHistorySize) {
      _dataHistory.removeFirst();
    }
  }

  // 获取历史数据
  List<ProcessedSensorData> getHistoryData({int? limit}) {
    final historyList = _dataHistory.toList();
    if (limit != null && limit > 0 && limit < historyList.length) {
      return historyList.sublist(historyList.length - limit);
    }
    return historyList;
  }

  // 获取分析统计信息
  Map<String, dynamic> getAnalysisStats() {
    return {
      'isAnalyzing': _isAnalyzing,
      'currentExercise': _currentExerciseType,
      'detectionThreshold': _detectionThreshold,
      'historySize': _dataHistory.length,
      'sensorStatus': _sensorService.status.toString(),
      'processorStatus': _dataProcessor.getBufferStatus(),
      'errorMessage': _errorMessage,
    };
  }

  // 错误处理
  void _setError(String error) {
    _errorMessage = error;
    if (kDebugMode) {
      print('MotionDataManager错误: $error');
    }
  }

  void _clearError() {
    _errorMessage = null;
  }

  // 清理资源
  Future<void> dispose() async {
    await stopAnalysis();
    await _processedDataController.close();
    await _motionAnalysisController.close();
  }
}