import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../services/sensor_service.dart';
import '../services/advanced_feature_extractor.dart';

// 仰卧起坐运动状态
enum SitupPhase {
  idle,
  rising,   // 起身阶段
  peak,     // 顶点阶段
  lowering, // 下降阶段
  completed,
}

// 仰卧起坐检测结果
class SitupDetectionResult {
  final bool isValidSitup;
  final double confidence;
  final SitupPhase currentPhase;
  final int repetitionCount;
  final double angleRange;
  final double cadence; // 节奏（次/分钟）
  final Map<String, dynamic> debugInfo;
  final DateTime timestamp;

  SitupDetectionResult({
    required this.isValidSitup,
    required this.confidence,
    required this.currentPhase,
    required this.repetitionCount,
    required this.angleRange,
    required this.cadence,
    required this.debugInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'SitupDetectionResult(valid: $isValidSitup, confidence: $confidence, phase: $currentPhase, count: $repetitionCount)';
}

// 仰卧起坐识别器
class SitupRecognizer {
  static final SitupRecognizer _instance = SitupRecognizer._internal();
  factory SitupRecognizer() => _instance;
  static SitupRecognizer get instance => _instance;
  SitupRecognizer._internal();

  final AdvancedFeatureExtractor _featureExtractor = AdvancedFeatureExtractor.instance;

  // 识别参数
  double _detectionThreshold = 1.5;
  double _confidenceThreshold = 0.7;
  int _windowSize = 20;
  int _minCycleDuration = 25; // 最小周期持续时间（采样点数）
  int _maxCycleDuration = 120; // 最大周期持续时间
  double _risingThreshold = 1.2; // 起身检测阈值
  double _loweringThreshold = -1.0; // 下降检测阈值
  double _angleChangeThreshold = 30.0; // 角度变化阈值（度）

  // 状态变量
  SitupPhase _currentPhase = SitupPhase.idle;
  int _repetitionCount = 0;
  bool _isActive = false;
  
  // 数据缓冲区
  final Queue<SensorData> _dataBuffer = Queue<SensorData>();
  final Queue<double> _xAxisBuffer = Queue<double>();
  final Queue<double> _yAxisBuffer = Queue<double>();
  final Queue<double> _angleBuffer = Queue<double>(); // 躯干角度
  final Queue<double> _angularVelocityBuffer = Queue<double>();
  
  // 仰卧起坐特定检测
  DateTime? _riseStartTime;
  DateTime? _peakTime;
  DateTime? _lowerStartTime;
  DateTime? _cycleEndTime;
  double _baselineAngle = 0.0;
  double _peakAngle = 0.0;
  double _currentAngle = 0.0;
  double _lastAngle = 0.0;
  List<DateTime> _completionTimes = [];
  
  // 特征历史
  final Queue<Map<String, double>> _featureHistory = Queue<Map<String, double>>();

  // Getters
  SitupPhase get currentPhase => _currentPhase;
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
    double? risingThreshold,
    double? loweringThreshold,
    double? angleChangeThreshold,
  }) {
    _detectionThreshold = detectionThreshold ?? _detectionThreshold;
    _confidenceThreshold = confidenceThreshold ?? _confidenceThreshold;
    _windowSize = windowSize ?? _windowSize;
    _minCycleDuration = minCycleDuration ?? _minCycleDuration;
    _maxCycleDuration = maxCycleDuration ?? _maxCycleDuration;
    _risingThreshold = risingThreshold ?? _risingThreshold;
    _loweringThreshold = loweringThreshold ?? _loweringThreshold;
    _angleChangeThreshold = angleChangeThreshold ?? _angleChangeThreshold;
  }

  // 开始识别
  void startRecognition() {
    _isActive = true;
    _reset();
    _calibrateBaseline();
  }

  // 停止识别
  void stopRecognition() {
    _isActive = false;
    _reset();
  }

  // 重置状态
  void _reset() {
    _currentPhase = SitupPhase.idle;
    _repetitionCount = 0;
    _dataBuffer.clear();
    _xAxisBuffer.clear();
    _yAxisBuffer.clear();
    _angleBuffer.clear();
    _angularVelocityBuffer.clear();
    _featureHistory.clear();
    _riseStartTime = null;
    _peakTime = null;
    _lowerStartTime = null;
    _cycleEndTime = null;
    _baselineAngle = 0.0;
    _peakAngle = 0.0;
    _currentAngle = 0.0;
    _lastAngle = 0.0;
    _completionTimes.clear();
  }

  // 校准基线角度
  void _calibrateBaseline() {
    // 在开始时记录基线角度（仰卧位置）
    Future.delayed(const Duration(seconds: 2), () {
      if (_angleBuffer.isNotEmpty) {
        _baselineAngle = _angleBuffer.fold(0.0, (sum, angle) => sum + angle) / _angleBuffer.length;
        if (kDebugMode) {
          print('仰卧起坐基线角度校准完成: ${_baselineAngle.toStringAsFixed(1)}°');
        }
      }
    });
  }

  // 处理传感器数据
  SitupDetectionResult? processSensorData(SensorData sensorData) {
    if (!_isActive) return null;

    // 添加数据到缓冲区
    _addDataToBuffer(sensorData);

    // 计算躯干角度
    _updateTrunkAngle(sensorData);

    // 检查缓冲区是否有足够数据
    if (_angleBuffer.length < _windowSize) {
      return null;
    }

    // 提取特征
    final features = _extractSitupFeatures();
    _featureHistory.add(features);
    if (_featureHistory.length > 10) {
      _featureHistory.removeFirst();
    }

    // 执行仰卧起坐检测
    return _detectSitup(sensorData, features);
  }

  // 添加数据到缓冲区
  void _addDataToBuffer(SensorData data) {
    _dataBuffer.add(data);
    _xAxisBuffer.add(data.x);
    _yAxisBuffer.add(data.y);

    // 维护缓冲区大小
    if (_dataBuffer.length > _windowSize) {
      _dataBuffer.removeFirst();
      _xAxisBuffer.removeFirst();
      _yAxisBuffer.removeFirst();
    }
  }

  // 更新躯干角度
  void _updateTrunkAngle(SensorData data) {
    // 使用加速度计数据计算设备倾斜角度
    // 这里假设设备放置在胸部，X轴指向头部方向
    _lastAngle = _currentAngle;
    _currentAngle = atan2(data.x, sqrt(data.y * data.y + data.z * data.z)) * 180 / pi;
    
    _angleBuffer.add(_currentAngle);
    if (_angleBuffer.length > _windowSize) {
      _angleBuffer.removeFirst();
    }
    
    // 计算角速度
    if (_lastAngle != 0.0) {
      final angularVelocity = _currentAngle - _lastAngle;
      _angularVelocityBuffer.add(angularVelocity);
      if (_angularVelocityBuffer.length > _windowSize) {
        _angularVelocityBuffer.removeFirst();
      }
    }
  }

  // 提取仰卧起坐特定特征
  Map<String, double> _extractSitupFeatures() {
    final angles = _angleBuffer.toList();
    final angularVelocities = _angularVelocityBuffer.toList();
    final xValues = _xAxisBuffer.toList();
    
    // 角度统计特征
    final angleMean = angles.fold(0.0, (sum, angle) => sum + angle) / angles.length;
    final angleStd = _calculateStandardDeviation(angles);
    final angleRange = angles.reduce(max) - angles.reduce(min);
    
    // 相对于基线的角度变化
    final relativeAngleChange = (angleMean - _baselineAngle).abs();
    
    // 角速度特征
    final avgAngularVelocity = angularVelocities.isNotEmpty
        ? angularVelocities.fold(0.0, (sum, vel) => sum + vel) / angularVelocities.length
        : 0.0;
    final angularVelocityStd = angularVelocities.isNotEmpty 
        ? _calculateStandardDeviation(angularVelocities)
        : 0.0;
    
    // 运动方向检测
    final risingMotion = _detectRisingMotion(angles, angularVelocities);
    final loweringMotion = _detectLoweringMotion(angles, angularVelocities);
    final peakHolding = _detectPeakHolding(angles, angularVelocities);
    
    // 周期性和节奏检测
    final rhythmScore = _calculateRhythmScore(angles);
    final cycleCompleteness = _assessCycleCompleteness(angles);
    
    // X轴辅助特征（头部向前运动）
    final xAxisVariation = _calculateStandardDeviation(xValues);
    
    return {
      'angle_mean': angleMean,
      'angle_std': angleStd,
      'angle_range': angleRange,
      'relative_angle_change': relativeAngleChange,
      'angular_velocity_mean': avgAngularVelocity,
      'angular_velocity_std': angularVelocityStd,
      'rising_motion_score': risingMotion,
      'lowering_motion_score': loweringMotion,
      'peak_holding_score': peakHolding,
      'rhythm_score': rhythmScore,
      'cycle_completeness': cycleCompleteness,
      'x_axis_variation': xAxisVariation,
      'current_angle': _currentAngle,
      'baseline_angle': _baselineAngle,
    };
  }

  // 仰卧起坐检测主逻辑
  SitupDetectionResult? _detectSitup(SensorData currentData, Map<String, double> features) {
    final currentTime = currentData.timestamp;
    
    // 状态机检测
    SitupPhase newPhase = _updatePhaseStateMachine(currentTime, features);
    
    bool validSitup = false;
    double confidence = 0.0;
    double cadence = _calculateCadence();
    
    // 检测完整的仰卧起坐周期
    if (newPhase == SitupPhase.completed) {
      final validation = _validateSitupCycle(features);
      
      if (validation['isValid'] == true) {
        _repetitionCount++;
        validSitup = true;
        confidence = validation['confidence'] as double;
        _completionTimes.add(currentTime);
        
        // 保持最近10次的完成时间
        if (_completionTimes.length > 10) {
          _completionTimes.removeAt(0);
        }
        
        if (kDebugMode) {
          print('检测到仰卧起坐: #$_repetitionCount, 置信度: ${confidence.toStringAsFixed(2)}, 角度变化: ${features['angle_range']?.toStringAsFixed(1)}°');
        }
        
        // 重置周期状态
        _resetCycleState();
      }
    }
    
    _currentPhase = newPhase;
    
    // 计算整体置信度
    final overallConfidence = _calculateOverallConfidence(features);
    
    return SitupDetectionResult(
      isValidSitup: validSitup,
      confidence: confidence > 0 ? confidence : overallConfidence,
      currentPhase: _currentPhase,
      repetitionCount: _repetitionCount,
      angleRange: features['angle_range'] ?? 0.0,
      cadence: cadence,
      debugInfo: {
        'features': features,
        'current_angle': _currentAngle,
        'baseline_angle': _baselineAngle,
        'peak_angle': _peakAngle,
        'phase': _currentPhase.toString(),
      },
    );
  }

  // 状态机更新
  SitupPhase _updatePhaseStateMachine(DateTime currentTime, Map<String, double> features) {
    final risingMotion = features['rising_motion_score'] ?? 0.0;
    final loweringMotion = features['lowering_motion_score'] ?? 0.0;
    final peakHolding = features['peak_holding_score'] ?? 0.0;
    final relativeAngleChange = features['relative_angle_change'] ?? 0.0;
    
    switch (_currentPhase) {
      case SitupPhase.idle:
        // 检测开始起身
        if (risingMotion > 0.6 && relativeAngleChange > 15.0) {
          _riseStartTime = currentTime;
          _peakAngle = _currentAngle;
          return SitupPhase.rising;
        }
        break;
        
      case SitupPhase.rising:
        // 更新峰值角度
        if (_currentAngle > _peakAngle) {
          _peakAngle = _currentAngle;
        }
        
        // 检测到达峰值并保持
        if (peakHolding > 0.5 && relativeAngleChange > 30.0) {
          _peakTime = currentTime;
          return SitupPhase.peak;
        }
        
        // 检测直接开始下降
        if (loweringMotion > 0.6) {
          _lowerStartTime = currentTime;
          return SitupPhase.lowering;
        }
        
        // 检测起身时间过长
        if (_riseStartTime != null && 
            currentTime.difference(_riseStartTime!).inMilliseconds > 3000) {
          return SitupPhase.idle;
        }
        break;
        
      case SitupPhase.peak:
        // 检测开始下降
        if (loweringMotion > 0.6) {
          _lowerStartTime = currentTime;
          return SitupPhase.lowering;
        }
        
        // 峰值保持时间过长
        if (_peakTime != null && 
            currentTime.difference(_peakTime!).inMilliseconds > 2000) {
          return SitupPhase.idle;
        }
        break;
        
      case SitupPhase.lowering:
        // 检测回到起始位置
        if ((_currentAngle - _baselineAngle).abs() < 10.0) {
          _cycleEndTime = currentTime;
          return SitupPhase.completed;
        }
        
        // 下降时间过长
        if (_lowerStartTime != null && 
            currentTime.difference(_lowerStartTime!).inMilliseconds > 3000) {
          return SitupPhase.idle;
        }
        break;
        
      case SitupPhase.completed:
        return SitupPhase.idle;
    }
    
    return _currentPhase;
  }

  // 验证仰卧起坐周期
  Map<String, dynamic> _validateSitupCycle(Map<String, double> features) {
    double confidence = 0.0;
    bool isValid = false;
    
    // 角度变化幅度检查
    final angleRange = features['angle_range'] ?? 0.0;
    if (angleRange > 25.0) {
      confidence += 0.3;
    }
    
    // 相对角度变化检查
    final relativeChange = features['relative_angle_change'] ?? 0.0;
    if (relativeChange > 30.0) {
      confidence += 0.25;
    }
    
    // 总持续时间检查
    if (_riseStartTime != null && _cycleEndTime != null) {
      final totalDuration = _cycleEndTime!.difference(_riseStartTime!).inMilliseconds;
      if (totalDuration >= 800 && totalDuration <= 5000) { // 0.8-5秒的合理范围
        confidence += 0.2;
      }
    }
    
    // 运动平滑度检查
    final angularVelocityStd = features['angular_velocity_std'] ?? 0.0;
    if (angularVelocityStd > 2.0 && angularVelocityStd < 15.0) {
      confidence += 0.15;
    }
    
    // 周期完整性检查
    final completeness = features['cycle_completeness'] ?? 0.0;
    if (completeness > 0.7) {
      confidence += 0.1;
    }
    
    isValid = confidence >= _confidenceThreshold;
    
    return {
      'isValid': isValid,
      'confidence': confidence,
      'angle_range': angleRange,
      'relative_change': relativeChange,
      'total_duration': _riseStartTime != null && _cycleEndTime != null 
          ? _cycleEndTime!.difference(_riseStartTime!).inMilliseconds 
          : 0,
    };
  }

  // 重置周期状态
  void _resetCycleState() {
    _riseStartTime = null;
    _peakTime = null;
    _lowerStartTime = null;
    _cycleEndTime = null;
    _peakAngle = 0.0;
  }

  // 检测起身运动
  double _detectRisingMotion(List<double> angles, List<double> angularVelocities) {
    if (angularVelocities.isEmpty) return 0.0;
    
    // 检测正向角速度（起身时角度增大）
    final positiveVelocities = angularVelocities.where((v) => v > 1.0).length;
    return positiveVelocities / angularVelocities.length;
  }

  // 检测下降运动
  double _detectLoweringMotion(List<double> angles, List<double> angularVelocities) {
    if (angularVelocities.isEmpty) return 0.0;
    
    // 检测负向角速度（下降时角度减小）
    final negativeVelocities = angularVelocities.where((v) => v < -1.0).length;
    return negativeVelocities / angularVelocities.length;
  }

  // 检测峰值保持
  double _detectPeakHolding(List<double> angles, List<double> angularVelocities) {
    if (angularVelocities.isEmpty) return 0.0;
    
    // 检测低角速度（在峰值位置保持）
    final stableVelocities = angularVelocities.where((v) => v.abs() < 0.5).length;
    return stableVelocities / angularVelocities.length;
  }

  // 计算节奏得分
  double _calculateRhythmScore(List<double> angles) {
    if (angles.length < 10) return 0.0;
    
    // 检测明显的起伏模式
    int peaks = 0;
    int valleys = 0;
    
    for (int i = 2; i < angles.length - 2; i++) {
      if (angles[i] > angles[i-1] && angles[i] > angles[i+1] && 
          angles[i] > angles[i-2] && angles[i] > angles[i+2]) {
        peaks++;
      }
      if (angles[i] < angles[i-1] && angles[i] < angles[i+1] && 
          angles[i] < angles[i-2] && angles[i] < angles[i+2]) {
        valleys++;
      }
    }
    
    // 理想情况应该有相近数量的峰值和谷值
    final balance = 1.0 - (peaks - valleys).abs() / max(peaks + valleys, 1);
    return balance;
  }

  // 评估周期完整性
  double _assessCycleCompleteness(List<double> angles) {
    if (angles.length < 5) return 0.0;
    
    final startAngle = angles.first;
    final endAngle = angles.last;
    final maxAngle = angles.reduce(max);
    final minAngle = angles.reduce(min);
    
    // 检查是否形成完整的上升-下降周期
    final returnToStart = (endAngle - startAngle).abs() < 15.0;
    final hasSignificantRange = (maxAngle - minAngle) > 20.0;
    
    return (returnToStart && hasSignificantRange) ? 0.8 : 0.3;
  }

  // 计算节奏（次/分钟）
  double _calculateCadence() {
    if (_completionTimes.length < 2) return 0.0;
    
    final recentTimes = _completionTimes.length > 5 
        ? _completionTimes.sublist(_completionTimes.length - 5)
        : _completionTimes;
    
    if (recentTimes.length < 2) return 0.0;
    
    final totalTime = recentTimes.last.difference(recentTimes.first).inMilliseconds;
    final intervals = recentTimes.length - 1;
    
    if (totalTime > 0) {
      final avgInterval = totalTime / intervals;
      return 60000.0 / avgInterval; // 转换为次/分钟
    }
    
    return 0.0;
  }

  // 计算整体置信度
  double _calculateOverallConfidence(Map<String, double> features) {
    double confidence = 0.0;
    
    // 基于特征的置信度
    final angleStd = features['angle_std'] ?? 0.0;
    final relativeChange = features['relative_angle_change'] ?? 0.0;
    final risingMotion = features['rising_motion_score'] ?? 0.0;
    final loweringMotion = features['lowering_motion_score'] ?? 0.0;
    
    confidence += (angleStd / 20.0).clamp(0.0, 0.25);
    confidence += (relativeChange / 60.0).clamp(0.0, 0.25);
    confidence += risingMotion * 0.25;
    confidence += loweringMotion * 0.25;
    
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
      'current_angle': _currentAngle,
      'baseline_angle': _baselineAngle,
      'peak_angle': _peakAngle,
      'cadence': _calculateCadence(),
      'completion_times_count': _completionTimes.length,
    };
  }
}