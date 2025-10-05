import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../services/sensor_service.dart';
import '../services/advanced_feature_extractor.dart';

// 俯卧撑运动状态
enum PushupPhase {
  idle,
  down,
  up,
  completed,
}

// 俯卧撑检测结果
class PushupDetectionResult {
  final bool isValidPushup;
  final double confidence;
  final PushupPhase currentPhase;
  final int repetitionCount;
  final double peakValue;
  final double valleyValue;
  final Map<String, dynamic> debugInfo;
  final DateTime timestamp;

  PushupDetectionResult({
    required this.isValidPushup,
    required this.confidence,
    required this.currentPhase,
    required this.repetitionCount,
    required this.peakValue,
    required this.valleyValue,
    required this.debugInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'PushupDetectionResult(valid: $isValidPushup, confidence: $confidence, phase: $currentPhase, count: $repetitionCount)';
}

// 俯卧撑识别器
class PushupRecognizer {
  static final PushupRecognizer _instance = PushupRecognizer._internal();
  factory PushupRecognizer() => _instance;
  static PushupRecognizer get instance => _instance;
  PushupRecognizer._internal();

  final AdvancedFeatureExtractor _featureExtractor = AdvancedFeatureExtractor.instance;

  // 识别参数
  double _detectionThreshold = 2.0;
  double _confidenceThreshold = 0.7;
  int _windowSize = 20;
  int _minCycleDuration = 30; // 最小周期持续时间（采样点数）
  int _maxCycleDuration = 150; // 最大周期持续时间
  double _peakThreshold = 1.5; // 峰值阈值
  double _valleyThreshold = -1.0; // 谷值阈值

  // 状态变量
  PushupPhase _currentPhase = PushupPhase.idle;
  int _repetitionCount = 0;
  bool _isActive = false;
  
  // 数据缓冲区
  final Queue<SensorData> _dataBuffer = Queue<SensorData>();
  final Queue<double> _yAxisBuffer = Queue<double>();
  final Queue<double> _magnitudeBuffer = Queue<double>();
  
  // 周期检测
  DateTime? _lastPeakTime;
  DateTime? _lastValleyTime;
  double _lastPeakValue = 0.0;
  double _lastValleyValue = 0.0;
  bool _waitingForValley = false;
  bool _waitingForPeak = false;
  
  // 特征历史
  final Queue<Map<String, double>> _featureHistory = Queue<Map<String, double>>();

  // Getters
  PushupPhase get currentPhase => _currentPhase;
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
    double? peakThreshold,
    double? valleyThreshold,
  }) {
    _detectionThreshold = detectionThreshold ?? _detectionThreshold;
    _confidenceThreshold = confidenceThreshold ?? _confidenceThreshold;
    _windowSize = windowSize ?? _windowSize;
    _minCycleDuration = minCycleDuration ?? _minCycleDuration;
    _maxCycleDuration = maxCycleDuration ?? _maxCycleDuration;
    _peakThreshold = peakThreshold ?? _peakThreshold;
    _valleyThreshold = valleyThreshold ?? _valleyThreshold;
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
    _currentPhase = PushupPhase.idle;
    _repetitionCount = 0;
    _dataBuffer.clear();
    _yAxisBuffer.clear();
    _magnitudeBuffer.clear();
    _featureHistory.clear();
    _lastPeakTime = null;
    _lastValleyTime = null;
    _lastPeakValue = 0.0;
    _lastValleyValue = 0.0;
    _waitingForValley = false;
    _waitingForPeak = false;
  }

  // 处理传感器数据
  PushupDetectionResult? processSensorData(SensorData sensorData) {
    if (!_isActive) return null;

    // 添加数据到缓冲区
    _addDataToBuffer(sensorData);

    // 检查缓冲区是否有足够数据
    if (_yAxisBuffer.length < _windowSize) {
      return null;
    }

    // 提取特征
    final features = _extractPushupFeatures();
    _featureHistory.add(features);
    if (_featureHistory.length > 10) {
      _featureHistory.removeFirst();
    }

    // 执行俯卧撑检测
    return _detectPushup(sensorData, features);
  }

  // 添加数据到缓冲区
  void _addDataToBuffer(SensorData data) {
    _dataBuffer.add(data);
    _yAxisBuffer.add(data.y);
    _magnitudeBuffer.add(data.magnitude);

    // 维护缓冲区大小
    if (_dataBuffer.length > _windowSize) {
      _dataBuffer.removeFirst();
      _yAxisBuffer.removeFirst();
      _magnitudeBuffer.removeFirst();
    }
  }

  // 提取俯卧撑特定特征
  Map<String, double> _extractPushupFeatures() {
    final yValues = _yAxisBuffer.toList();
    final magnitudes = _magnitudeBuffer.toList();
    
    // 基础统计特征
    final yMean = yValues.fold(0.0, (sum, value) => sum + value) / yValues.length;
    final yStd = _calculateStandardDeviation(yValues);
    final yRange = yValues.reduce(max) - yValues.reduce(min);
    
    // Y轴变化率
    final yChangeRate = _calculateChangeRate(yValues);
    
    // 检测峰值和谷值
    final peaks = _detectPeaks(yValues, threshold: _peakThreshold);
    final valleys = _detectValleys(yValues, threshold: _valleyThreshold);
    
    // 周期性特征
    final cyclicityScore = _calculateCyclicityScore(yValues);
    
    // 倾斜角度变化
    final tiltVariation = _calculateTiltVariation();
    
    // 频域特征（简化）
    final dominantFreq = _estimateDominantFrequency(yValues);
    
    return {
      'y_mean': yMean,
      'y_std': yStd,
      'y_range': yRange,
      'y_change_rate': yChangeRate,
      'peak_count': peaks.length.toDouble(),
      'valley_count': valleys.length.toDouble(),
      'cyclicity_score': cyclicityScore,
      'tilt_variation': tiltVariation,
      'dominant_frequency': dominantFreq,
      'rhythm_regularity': _calculateRhythmRegularity(),
    };
  }

  // 俯卧撑检测主逻辑
  PushupDetectionResult? _detectPushup(SensorData currentData, Map<String, double> features) {
    final currentY = currentData.y;
    final currentTime = currentData.timestamp;
    
    // 状态机检测
    PushupPhase newPhase = _currentPhase;
    bool validPushup = false;
    double confidence = 0.0;
    
    // 检测运动周期
    final cycleDetection = _detectMovementCycle(currentY, currentTime);
    
    if (cycleDetection['completed'] == true) {
      // 验证是否为有效俯卧撑
      final validation = _validatePushupCycle(features, cycleDetection);
      
      if (validation['isValid'] == true) {
        _repetitionCount++;
        validPushup = true;
        confidence = validation['confidence'] as double;
        newPhase = PushupPhase.completed;
        
        if (kDebugMode) {
          print('检测到俯卧撑: #$_repetitionCount, 置信度: ${confidence.toStringAsFixed(2)}');
        }
      }
    } else {
      // 更新当前阶段
      newPhase = _updatePhaseFromCycle(cycleDetection);
    }
    
    _currentPhase = newPhase;
    
    // 计算整体置信度
    final overallConfidence = _calculateOverallConfidence(features, cycleDetection);
    
    return PushupDetectionResult(
      isValidPushup: validPushup,
      confidence: confidence > 0 ? confidence : overallConfidence,
      currentPhase: _currentPhase,
      repetitionCount: _repetitionCount,
      peakValue: _lastPeakValue,
      valleyValue: _lastValleyValue,
      debugInfo: {
        'features': features,
        'cycle_detection': cycleDetection,
        'y_value': currentY,
        'buffer_size': _yAxisBuffer.length,
      },
    );
  }

  // 检测运动周期
  Map<String, dynamic> _detectMovementCycle(double currentY, DateTime currentTime) {
    bool completed = false;
    String phase = 'idle';
    
    // 检测峰值（手机向上，身体向下）
    if (!_waitingForValley && currentY > _peakThreshold) {
      if (_lastPeakTime == null || 
          currentTime.difference(_lastPeakTime!).inMilliseconds > 500) {
        _lastPeakValue = currentY;
        _lastPeakTime = currentTime;
        _waitingForValley = true;
        _waitingForPeak = false;
        phase = 'down';
      }
    }
    
    // 检测谷值（手机向下，身体向上）
    if (_waitingForValley && currentY < _valleyThreshold) {
      if (_lastValleyTime == null || 
          currentTime.difference(_lastValleyTime!).inMilliseconds > 500) {
        _lastValleyValue = currentY;
        _lastValleyTime = currentTime;
        
        // 检查是否完成一个完整周期
        if (_lastPeakTime != null && _lastValleyTime != null) {
          final cycleDuration = _lastValleyTime!.difference(_lastPeakTime!).inMilliseconds;
          
          if (cycleDuration >= _minCycleDuration * 20 && cycleDuration <= _maxCycleDuration * 20) {
            completed = true;
            phase = 'up';
          }
        }
        
        _waitingForValley = false;
        _waitingForPeak = true;
      }
    }
    
    return {
      'completed': completed,
      'phase': phase,
      'peak_value': _lastPeakValue,
      'valley_value': _lastValleyValue,
      'cycle_duration': _lastPeakTime != null && _lastValleyTime != null 
          ? _lastValleyTime!.difference(_lastPeakTime!).inMilliseconds 
          : 0,
    };
  }

  // 验证俯卧撑周期
  Map<String, dynamic> _validatePushupCycle(Map<String, double> features, Map<String, dynamic> cycleInfo) {
    double confidence = 0.0;
    bool isValid = false;
    
    // 幅度检查
    final amplitude = _lastPeakValue - _lastValleyValue;
    if (amplitude > 2.0) {
      confidence += 0.3;
    }
    
    // 持续时间检查
    final duration = cycleInfo['cycle_duration'] as int;
    if (duration >= 800 && duration <= 4000) { // 0.8-4秒的合理范围
      confidence += 0.2;
    }
    
    // Y轴标准差检查（运动应该有明显变化）
    final yStd = features['y_std'] ?? 0.0;
    if (yStd > 1.0) {
      confidence += 0.2;
    }
    
    // 周期性检查
    final cyclicity = features['cyclicity_score'] ?? 0.0;
    if (cyclicity > 0.5) {
      confidence += 0.15;
    }
    
    // 频率检查（俯卧撑频率通常在0.25-1.5Hz之间）
    final freq = features['dominant_frequency'] ?? 0.0;
    if (freq >= 0.25 && freq <= 1.5) {
      confidence += 0.15;
    }
    
    isValid = confidence >= _confidenceThreshold;
    
    return {
      'isValid': isValid,
      'confidence': confidence,
      'amplitude': amplitude,
      'duration': duration,
    };
  }

  // 从周期信息更新阶段
  PushupPhase _updatePhaseFromCycle(Map<String, dynamic> cycleInfo) {
    final phase = cycleInfo['phase'] as String;
    
    switch (phase) {
      case 'down':
        return PushupPhase.down;
      case 'up':
        return PushupPhase.up;
      default:
        return PushupPhase.idle;
    }
  }

  // 计算整体置信度
  double _calculateOverallConfidence(Map<String, double> features, Map<String, dynamic> cycleInfo) {
    double confidence = 0.0;
    
    // 基于特征的置信度
    final yStd = features['y_std'] ?? 0.0;
    final cyclicity = features['cyclicity_score'] ?? 0.0;
    final rhythm = features['rhythm_regularity'] ?? 0.0;
    
    confidence += (yStd / 5.0).clamp(0.0, 0.3);
    confidence += cyclicity * 0.3;
    confidence += rhythm * 0.4;
    
    return confidence.clamp(0.0, 1.0);
  }

  // 计算标准差
  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.fold(0.0, (sum, value) => sum + value) / values.length;
    final variance = values.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  // 计算变化率
  double _calculateChangeRate(List<double> values) {
    if (values.length < 2) return 0.0;
    
    double totalChange = 0.0;
    for (int i = 1; i < values.length; i++) {
      totalChange += (values[i] - values[i - 1]).abs();
    }
    
    return totalChange / (values.length - 1);
  }

  // 检测峰值
  List<int> _detectPeaks(List<double> values, {required double threshold}) {
    final peaks = <int>[];
    
    for (int i = 1; i < values.length - 1; i++) {
      if (values[i] > threshold && 
          values[i] > values[i - 1] && 
          values[i] > values[i + 1]) {
        peaks.add(i);
      }
    }
    
    return peaks;
  }

  // 检测谷值
  List<int> _detectValleys(List<double> values, {required double threshold}) {
    final valleys = <int>[];
    
    for (int i = 1; i < values.length - 1; i++) {
      if (values[i] < threshold && 
          values[i] < values[i - 1] && 
          values[i] < values[i + 1]) {
        valleys.add(i);
      }
    }
    
    return valleys;
  }

  // 计算周期性得分
  double _calculateCyclicityScore(List<double> values) {
    if (values.length < 4) return 0.0;
    
    // 简化的自相关计算
    final halfLength = values.length ~/ 2;
    double maxCorrelation = 0.0;
    
    for (int lag = 5; lag < halfLength; lag++) {
      double correlation = 0.0;
      int count = 0;
      
      for (int i = 0; i < values.length - lag; i++) {
        correlation += values[i] * values[i + lag];
        count++;
      }
      
      if (count > 0) {
        correlation /= count;
        maxCorrelation = max(maxCorrelation, correlation.abs());
      }
    }
    
    return maxCorrelation / (values.map((v) => v * v).reduce((a, b) => a + b) / values.length);
  }

  // 计算倾斜变化
  double _calculateTiltVariation() {
    if (_dataBuffer.length < 3) return 0.0;
    
    final recent = _dataBuffer.toList().sublist(_dataBuffer.length - 3);
    double variation = 0.0;
    
    for (int i = 1; i < recent.length; i++) {
      final angle1 = atan2(recent[i - 1].y, recent[i - 1].z);
      final angle2 = atan2(recent[i].y, recent[i].z);
      variation += (angle2 - angle1).abs();
    }
    
    return variation * 180 / pi; // 转换为度
  }

  // 估算主导频率
  double _estimateDominantFrequency(List<double> values) {
    if (values.length < 4) return 0.0;
    
    // 简化的频率估算：基于零穿越
    int crossings = 0;
    final mean = values.fold(0.0, (sum, value) => sum + value) / values.length;
    
    for (int i = 1; i < values.length; i++) {
      if ((values[i] - mean) * (values[i - 1] - mean) < 0) {
        crossings++;
      }
    }
    
    // 假设采样率为50Hz
    return crossings / (2.0 * values.length / 50.0);
  }

  // 计算节奏规律性
  double _calculateRhythmRegularity() {
    if (_featureHistory.length < 3) return 0.0;
    
    final recentFreqs = _featureHistory
        .map((f) => f['dominant_frequency'] ?? 0.0)
        .toList();
    
    if (recentFreqs.every((f) => f == 0.0)) return 0.0;
    
    final mean = recentFreqs.fold(0.0, (sum, freq) => sum + freq) / recentFreqs.length;
    final variance = recentFreqs.map((freq) => pow(freq - mean, 2)).reduce((a, b) => a + b) / recentFreqs.length;
    
    // 变异系数越小，规律性越好
    return mean > 0 ? 1.0 / (1.0 + sqrt(variance) / mean) : 0.0;
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
      'last_peak_value': _lastPeakValue,
      'last_valley_value': _lastValleyValue,
      'waiting_for_valley': _waitingForValley,
      'waiting_for_peak': _waitingForPeak,
    };
  }
}