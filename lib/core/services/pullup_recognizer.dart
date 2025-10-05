import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../services/sensor_service.dart';
import '../services/advanced_feature_extractor.dart';

// 引体向上运动状态
enum PullupPhase {
  idle,
  pulling, // 向上拉
  holding,  // 顶端保持
  lowering, // 向下降
  completed,
}

// 引体向上检测结果
class PullupDetectionResult {
  final bool isValidPullup;
  final double confidence;
  final PullupPhase currentPhase;
  final int repetitionCount;
  final double pullupHeight;
  final double holdDuration;
  final Map<String, dynamic> debugInfo;
  final DateTime timestamp;

  PullupDetectionResult({
    required this.isValidPullup,
    required this.confidence,
    required this.currentPhase,
    required this.repetitionCount,
    required this.pullupHeight,
    required this.holdDuration,
    required this.debugInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'PullupDetectionResult(valid: $isValidPullup, confidence: $confidence, phase: $currentPhase, count: $repetitionCount)';
}

// 引体向上识别器
class PullupRecognizer {
  static final PullupRecognizer _instance = PullupRecognizer._internal();
  factory PullupRecognizer() => _instance;
  static PullupRecognizer get instance => _instance;
  PullupRecognizer._internal();

  final AdvancedFeatureExtractor _featureExtractor = AdvancedFeatureExtractor.instance;

  // 识别参数
  double _detectionThreshold = 1.8;
  double _confidenceThreshold = 0.75;
  int _windowSize = 25;
  int _minCycleDuration = 40; // 最小周期持续时间（采样点数）
  int _maxCycleDuration = 200; // 最大周期持续时间
  double _upwardThreshold = 2.5; // 向上运动阈值
  double _downwardThreshold = -2.0; // 向下运动阈值
  double _holdThreshold = 0.8; // 顶端保持阈值

  // 状态变量
  PullupPhase _currentPhase = PullupPhase.idle;
  int _repetitionCount = 0;
  bool _isActive = false;
  
  // 数据缓冲区
  final Queue<SensorData> _dataBuffer = Queue<SensorData>();
  final Queue<double> _zAxisBuffer = Queue<double>();
  final Queue<double> _magnitudeBuffer = Queue<double>();
  final Queue<double> _verticalVelocityBuffer = Queue<double>();
  
  // 引体向上特定检测
  DateTime? _pullStartTime;
  DateTime? _pullEndTime;
  DateTime? _holdStartTime;
  DateTime? _lowerStartTime;
  double _maxHeight = 0.0;
  double _startHeight = 0.0;
  double _currentVelocity = 0.0;
  bool _isInPullPhase = false;
  bool _isInHoldPhase = false;
  bool _isInLowerPhase = false;
  
  // 特征历史
  final Queue<Map<String, double>> _featureHistory = Queue<Map<String, double>>();

  // Getters
  PullupPhase get currentPhase => _currentPhase;
  int get repetitionCount => _repetitionCount;
  bool get isActive => _isActive;
  double get detectionThreshold => _detectionThreshold;

  // 配置参数
  void configure({
    double? detectionThreshold,
    double? confidenceThreshold,
    int? windowSize,
    int? minCycleDuration,
    int? maxCycleDuration,
    double? upwardThreshold,
    double? downwardThreshold,
    double? holdThreshold,
  }) {
    _detectionThreshold = detectionThreshold ?? _detectionThreshold;
    _confidenceThreshold = confidenceThreshold ?? _confidenceThreshold;
    _windowSize = windowSize ?? _windowSize;
    _minCycleDuration = minCycleDuration ?? _minCycleDuration;
    _maxCycleDuration = maxCycleDuration ?? _maxCycleDuration;
    _upwardThreshold = upwardThreshold ?? _upwardThreshold;
    _downwardThreshold = downwardThreshold ?? _downwardThreshold;
    _holdThreshold = holdThreshold ?? _holdThreshold;
  }

  // 开始识别
  void startRecognition() {
    _isActive = true;
    _reset();
  }

  // 停止识别
  void stopRecognition() {
    _isActive = false;
    _reset();
  }

  // 重置状态
  void _reset() {
    _currentPhase = PullupPhase.idle;
    _repetitionCount = 0;
    _dataBuffer.clear();
    _zAxisBuffer.clear();
    _magnitudeBuffer.clear();
    _verticalVelocityBuffer.clear();
    _featureHistory.clear();
    _pullStartTime = null;
    _pullEndTime = null;
    _holdStartTime = null;
    _lowerStartTime = null;
    _maxHeight = 0.0;
    _startHeight = 0.0;
    _currentVelocity = 0.0;
    _isInPullPhase = false;
    _isInHoldPhase = false;
    _isInLowerPhase = false;
  }

  // 处理传感器数据
  PullupDetectionResult? processSensorData(SensorData sensorData) {
    if (!_isActive) return null;

    // 添加数据到缓冲区
    _addDataToBuffer(sensorData);

    // 检查缓冲区是否有足够数据
    if (_zAxisBuffer.length < _windowSize) {
      return null;
    }

    // 计算垂直速度
    _updateVerticalVelocity();

    // 提取特征
    final features = _extractPullupFeatures();
    _featureHistory.add(features);
    if (_featureHistory.length > 10) {
      _featureHistory.removeFirst();
    }

    // 执行引体向上检测
    return _detectPullup(sensorData, features);
  }

  // 添加数据到缓冲区
  void _addDataToBuffer(SensorData data) {
    _dataBuffer.add(data);
    _zAxisBuffer.add(data.z);
    _magnitudeBuffer.add(data.magnitude);

    // 维护缓冲区大小
    if (_dataBuffer.length > _windowSize) {
      _dataBuffer.removeFirst();
      _zAxisBuffer.removeFirst();
      _magnitudeBuffer.removeFirst();
    }
  }

  // 更新垂直速度
  void _updateVerticalVelocity() {
    if (_zAxisBuffer.length >= 2) {
      final current = _zAxisBuffer.last;
      final previous = _zAxisBuffer.elementAt(_zAxisBuffer.length - 2);
      _currentVelocity = current - previous; // 简化的速度计算
      
      _verticalVelocityBuffer.add(_currentVelocity);
      if (_verticalVelocityBuffer.length > _windowSize) {
        _verticalVelocityBuffer.removeFirst();
      }
    }
  }

  // 提取引体向上特定特征
  Map<String, double> _extractPullupFeatures() {
    final zValues = _zAxisBuffer.toList();
    final velocities = _verticalVelocityBuffer.toList();
    final magnitudes = _magnitudeBuffer.toList();
    
    // Z轴统计特征
    final zMean = zValues.fold(0.0, (sum, value) => sum + value) / zValues.length;
    final zStd = _calculateStandardDeviation(zValues);
    final zRange = zValues.reduce(max) - zValues.reduce(min);
    
    // 垂直速度特征
    final velocityMean = velocities.isNotEmpty 
        ? velocities.fold(0.0, (sum, value) => sum + value) / velocities.length 
        : 0.0;
    final velocityStd = velocities.isNotEmpty 
        ? _calculateStandardDeviation(velocities) 
        : 0.0;
    
    // 检测垂直运动模式
    final upwardMotion = _detectUpwardMotion(zValues, velocities);
    final downwardMotion = _detectDownwardMotion(zValues, velocities);
    final holdPattern = _detectHoldPattern(zValues, velocities);
    
    // 运动幅度和持续时间
    final motionAmplitude = _calculateMotionAmplitude(zValues);
    final motionSmoothness = _calculateMotionSmoothness(velocities);
    
    // 引体向上特定节奏检测
    final pullupRhythm = _detectPullupRhythm(zValues);
    
    return {
      'z_mean': zMean,
      'z_std': zStd,
      'z_range': zRange,
      'velocity_mean': velocityMean,
      'velocity_std': velocityStd,
      'upward_motion_score': upwardMotion,
      'downward_motion_score': downwardMotion,
      'hold_pattern_score': holdPattern,
      'motion_amplitude': motionAmplitude,
      'motion_smoothness': motionSmoothness,
      'pullup_rhythm_score': pullupRhythm,
      'vertical_acceleration': _currentVelocity,
    };
  }

  // 引体向上检测主逻辑
  PullupDetectionResult? _detectPullup(SensorData currentData, Map<String, double> features) {
    final currentZ = currentData.z;
    final currentTime = currentData.timestamp;
    
    // 状态机检测
    PullupPhase newPhase = _updatePhaseStateMachine(currentZ, currentTime, features);
    
    bool validPullup = false;
    double confidence = 0.0;
    double holdDuration = 0.0;
    
    // 检测完整的引体向上周期
    if (newPhase == PullupPhase.completed) {
      final validation = _validatePullupCycle(features);
      
      if (validation['isValid'] == true) {
        _repetitionCount++;
        validPullup = true;
        confidence = validation['confidence'] as double;
        holdDuration = validation['hold_duration'] as double;
        
        if (kDebugMode) {
          print('检测到引体向上: #$_repetitionCount, 置信度: ${confidence.toStringAsFixed(2)}, 保持时间: ${holdDuration.toStringAsFixed(1)}ms');
        }
        
        // 重置周期状态
        _resetCycleState();
      }
    }
    
    _currentPhase = newPhase;
    
    // 计算整体置信度
    final overallConfidence = _calculateOverallConfidence(features);
    
    return PullupDetectionResult(
      isValidPullup: validPullup,
      confidence: confidence > 0 ? confidence : overallConfidence,
      currentPhase: _currentPhase,
      repetitionCount: _repetitionCount,
      pullupHeight: _maxHeight - _startHeight,
      holdDuration: holdDuration,
      debugInfo: {
        'features': features,
        'z_value': currentZ,
        'velocity': _currentVelocity,
        'max_height': _maxHeight,
        'current_phase': _currentPhase.toString(),
      },
    );
  }

  // 状态机更新
  PullupPhase _updatePhaseStateMachine(double currentZ, DateTime currentTime, Map<String, double> features) {
    final velocity = _currentVelocity;
    final upwardMotion = features['upward_motion_score'] ?? 0.0;
    final downwardMotion = features['downward_motion_score'] ?? 0.0;
    final holdPattern = features['hold_pattern_score'] ?? 0.0;
    
    switch (_currentPhase) {
      case PullupPhase.idle:
        // 检测开始向上拉
        if (velocity > _upwardThreshold && upwardMotion > 0.6) {
          _pullStartTime = currentTime;
          _startHeight = currentZ;
          _maxHeight = currentZ;
          _isInPullPhase = true;
          return PullupPhase.pulling;
        }
        break;
        
      case PullupPhase.pulling:
        // 更新最大高度
        if (currentZ > _maxHeight) {
          _maxHeight = currentZ;
        }
        
        // 检测到达顶端并开始保持
        if (velocity.abs() < _holdThreshold && holdPattern > 0.5) {
          _holdStartTime = currentTime;
          _isInHoldPhase = true;
          _isInPullPhase = false;
          return PullupPhase.holding;
        }
        
        // 检测直接开始下降（没有保持阶段）
        if (velocity < _downwardThreshold && downwardMotion > 0.5) {
          _lowerStartTime = currentTime;
          _isInLowerPhase = true;
          _isInPullPhase = false;
          return PullupPhase.lowering;
        }
        break;
        
      case PullupPhase.holding:
        // 检测开始下降
        if (velocity < _downwardThreshold && downwardMotion > 0.5) {
          _lowerStartTime = currentTime;
          _isInLowerPhase = true;
          _isInHoldPhase = false;
          return PullupPhase.lowering;
        }
        
        // 保持时间过长，可能不是有效的引体向上
        if (_holdStartTime != null && 
            currentTime.difference(_holdStartTime!).inMilliseconds > 3000) {
          return PullupPhase.idle;
        }
        break;
        
      case PullupPhase.lowering:
        // 检测回到起始位置
        if (currentZ <= _startHeight + 0.5 && velocity.abs() < 1.0) {
          _pullEndTime = currentTime;
          _isInLowerPhase = false;
          return PullupPhase.completed;
        }
        break;
        
      case PullupPhase.completed:
        return PullupPhase.idle;
    }
    
    return _currentPhase;
  }

  // 验证引体向上周期
  Map<String, dynamic> _validatePullupCycle(Map<String, double> features) {
    double confidence = 0.0;
    bool isValid = false;
    double holdDuration = 0.0;
    
    // 计算保持时间
    if (_holdStartTime != null && _lowerStartTime != null) {
      holdDuration = _lowerStartTime!.difference(_holdStartTime!).inMilliseconds.toDouble();
    }
    
    // 运动幅度检查
    final amplitude = _maxHeight - _startHeight;
    if (amplitude > 3.0) {
      confidence += 0.25;
    }
    
    // 总持续时间检查
    if (_pullStartTime != null && _pullEndTime != null) {
      final totalDuration = _pullEndTime!.difference(_pullStartTime!).inMilliseconds;
      if (totalDuration >= 1500 && totalDuration <= 8000) { // 1.5-8秒的合理范围
        confidence += 0.2;
      }
    }
    
    // 垂直运动特征检查
    final zStd = features['z_std'] ?? 0.0;
    if (zStd > 1.5) {
      confidence += 0.2;
    }
    
    // 运动平滑度检查
    final smoothness = features['motion_smoothness'] ?? 0.0;
    if (smoothness > 0.6) {
      confidence += 0.15;
    }
    
    // 节奏检查
    final rhythm = features['pullup_rhythm_score'] ?? 0.0;
    if (rhythm > 0.5) {
      confidence += 0.1;
    }
    
    // 保持阶段检查（可选）
    if (holdDuration > 100 && holdDuration < 2000) { // 0.1-2秒的保持时间
      confidence += 0.1;
    }
    
    isValid = confidence >= _confidenceThreshold;
    
    return {
      'isValid': isValid,
      'confidence': confidence,
      'amplitude': amplitude,
      'hold_duration': holdDuration,
      'total_duration': _pullStartTime != null && _pullEndTime != null 
          ? _pullEndTime!.difference(_pullStartTime!).inMilliseconds 
          : 0,
    };
  }

  // 重置周期状态
  void _resetCycleState() {
    _pullStartTime = null;
    _pullEndTime = null;
    _holdStartTime = null;
    _lowerStartTime = null;
    _maxHeight = 0.0;
    _startHeight = 0.0;
    _isInPullPhase = false;
    _isInHoldPhase = false;
    _isInLowerPhase = false;
  }

  // 检测向上运动
  double _detectUpwardMotion(List<double> zValues, List<double> velocities) {
    if (velocities.isEmpty) return 0.0;
    
    final positiveVelocities = velocities.where((v) => v > 0.5).length;
    return positiveVelocities / velocities.length;
  }

  // 检测向下运动
  double _detectDownwardMotion(List<double> zValues, List<double> velocities) {
    if (velocities.isEmpty) return 0.0;
    
    final negativeVelocities = velocities.where((v) => v < -0.5).length;
    return negativeVelocities / velocities.length;
  }

  // 检测保持模式
  double _detectHoldPattern(List<double> zValues, List<double> velocities) {
    if (velocities.isEmpty) return 0.0;
    
    final stableVelocities = velocities.where((v) => v.abs() < 0.3).length;
    return stableVelocities / velocities.length;
  }

  // 计算运动幅度
  double _calculateMotionAmplitude(List<double> zValues) {
    if (zValues.isEmpty) return 0.0;
    return zValues.reduce(max) - zValues.reduce(min);
  }

  // 计算运动平滑度
  double _calculateMotionSmoothness(List<double> velocities) {
    if (velocities.length < 2) return 0.0;
    
    double totalAcceleration = 0.0;
    for (int i = 1; i < velocities.length; i++) {
      totalAcceleration += (velocities[i] - velocities[i - 1]).abs();
    }
    
    final averageAcceleration = totalAcceleration / (velocities.length - 1);
    
    // 平滑度得分：加速度变化越小，越平滑
    return 1.0 / (1.0 + averageAcceleration);
  }

  // 检测引体向上节奏
  double _detectPullupRhythm(List<double> zValues) {
    if (zValues.length < 10) return 0.0;
    
    // 检测明显的上升-下降模式
    int transitions = 0;
    bool wasIncreasing = false;
    
    for (int i = 5; i < zValues.length - 5; i++) {
      final trend = zValues[i + 5] - zValues[i - 5];
      final isIncreasing = trend > 0.5;
      
      if (i > 5 && isIncreasing != wasIncreasing) {
        transitions++;
      }
      
      wasIncreasing = isIncreasing;
    }
    
    // 理想情况下应该有2-4个转换点（上-下或上-保持-下）
    return transitions >= 2 && transitions <= 6 ? 0.8 : 0.3;
  }

  // 计算整体置信度
  double _calculateOverallConfidence(Map<String, double> features) {
    double confidence = 0.0;
    
    // 基于特征的置信度
    final zStd = features['z_std'] ?? 0.0;
    final upwardMotion = features['upward_motion_score'] ?? 0.0;
    final downwardMotion = features['downward_motion_score'] ?? 0.0;
    final smoothness = features['motion_smoothness'] ?? 0.0;
    
    confidence += (zStd / 8.0).clamp(0.0, 0.25);
    confidence += upwardMotion * 0.25;
    confidence += downwardMotion * 0.25;
    confidence += smoothness * 0.25;
    
    return confidence.clamp(0.0, 1.0);
  }

  // 计算标准差
  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.fold(0.0, (sum, value) => sum + value) / values.length;
    final variance = values.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  // 获取识别统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'is_active': _isActive,
      'current_phase': _currentPhase.toString(),
      'repetition_count': _repetitionCount,
      'detection_threshold': _detectionThreshold,
      'confidence_threshold': _confidenceThreshold,
      'buffer_size': _dataBuffer.length,
      'max_height': _maxHeight,
      'start_height': _startHeight,
      'current_velocity': _currentVelocity,
      'is_in_pull_phase': _isInPullPhase,
      'is_in_hold_phase': _isInHoldPhase,
      'is_in_lower_phase': _isInLowerPhase,
    };
  }
}