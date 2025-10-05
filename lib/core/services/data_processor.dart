import 'dart:collection';
import 'dart:math';
import 'package:collection/collection.dart';

import 'sensor_service.dart';

// 数据处理器类
class DataProcessor {
  static final DataProcessor _instance = DataProcessor._internal();
  factory DataProcessor() => _instance;
  static DataProcessor get instance => _instance;
  DataProcessor._internal();

  // 滑动窗口大小
  int _windowSize = 5;
  
  // 数据缓冲区
  final Queue<SensorData> _accelerometerBuffer = Queue<SensorData>();
  final Queue<SensorData> _gyroscopeBuffer = Queue<SensorData>();
  final Queue<SensorData> _userAccelerometerBuffer = Queue<SensorData>();
  
  // 低通滤波器参数
  double _lowPassAlpha = 0.8;
  SensorData? _lastLowPassAccelerometer;
  SensorData? _lastLowPassGyroscope;
  
  // 高通滤波器参数
  double _highPassAlpha = 0.1;
  SensorData? _lastHighPassAccelerometer;
  SensorData? _lastRawAccelerometer;

  // 设置窗口大小
  void setWindowSize(int size) {
    if (size > 0 && size <= 20) {
      _windowSize = size;
    }
  }

  // 设置低通滤波器参数
  void setLowPassAlpha(double alpha) {
    if (alpha >= 0.0 && alpha <= 1.0) {
      _lowPassAlpha = alpha;
    }
  }

  // 设置高通滤波器参数
  void setHighPassAlpha(double alpha) {
    if (alpha >= 0.0 && alpha <= 1.0) {
      _highPassAlpha = alpha;
    }
  }

  // 添加加速度计数据到缓冲区
  void addAccelerometerData(SensorData data) {
    _accelerometerBuffer.add(data);
    if (_accelerometerBuffer.length > _windowSize) {
      _accelerometerBuffer.removeFirst();
    }
  }

  // 添加陀螺仪数据到缓冲区
  void addGyroscopeData(SensorData data) {
    _gyroscopeBuffer.add(data);
    if (_gyroscopeBuffer.length > _windowSize) {
      _gyroscopeBuffer.removeFirst();
    }
  }

  // 添加用户加速度计数据到缓冲区
  void addUserAccelerometerData(SensorData data) {
    _userAccelerometerBuffer.add(data);
    if (_userAccelerometerBuffer.length > _windowSize) {
      _userAccelerometerBuffer.removeFirst();
    }
  }

  // 低通滤波器 - 去除高频噪声
  SensorData applyLowPassFilter(SensorData newData, SensorData? lastFiltered, double alpha) {
    if (lastFiltered == null) {
      return newData;
    }
    
    return SensorData(
      x: alpha * lastFiltered.x + (1 - alpha) * newData.x,
      y: alpha * lastFiltered.y + (1 - alpha) * newData.y,
      z: alpha * lastFiltered.z + (1 - alpha) * newData.z,
      timestamp: newData.timestamp,
    );
  }

  // 高通滤波器 - 去除低频趋势
  SensorData applyHighPassFilter(SensorData newData, SensorData? lastFiltered, SensorData? lastRaw, double alpha) {
    if (lastFiltered == null || lastRaw == null) {
      return newData;
    }
    
    return SensorData(
      x: alpha * (lastFiltered.x + newData.x - lastRaw.x),
      y: alpha * (lastFiltered.y + newData.y - lastRaw.y),
      z: alpha * (lastFiltered.z + newData.z - lastRaw.z),
      timestamp: newData.timestamp,
    );
  }

  // 移动平均滤波
  SensorData applyMovingAverageFilter(Queue<SensorData> buffer) {
    if (buffer.isEmpty) {
      return SensorData(x: 0, y: 0, z: 0);
    }
    
    double sumX = 0, sumY = 0, sumZ = 0;
    for (final data in buffer) {
      sumX += data.x;
      sumY += data.y;
      sumZ += data.z;
    }
    
    final count = buffer.length;
    return SensorData(
      x: sumX / count,
      y: sumY / count,
      z: sumZ / count,
      timestamp: buffer.last.timestamp,
    );
  }

  // 中值滤波 - 去除突发噪声
  SensorData applyMedianFilter(Queue<SensorData> buffer) {
    if (buffer.isEmpty) {
      return SensorData(x: 0, y: 0, z: 0);
    }
    
    final xValues = buffer.map((d) => d.x).toList()..sort();
    final yValues = buffer.map((d) => d.y).toList()..sort();
    final zValues = buffer.map((d) => d.z).toList()..sort();
    
    final mid = xValues.length ~/ 2;
    
    return SensorData(
      x: xValues.length.isOdd ? xValues[mid] : (xValues[mid - 1] + xValues[mid]) / 2,
      y: yValues.length.isOdd ? yValues[mid] : (yValues[mid - 1] + yValues[mid]) / 2,
      z: zValues.length.isOdd ? zValues[mid] : (zValues[mid - 1] + zValues[mid]) / 2,
      timestamp: buffer.last.timestamp,
    );
  }

  // 处理加速度计数据
  SensorData processAccelerometerData(SensorData rawData) {
    // 添加到缓冲区
    addAccelerometerData(rawData);
    
    // 应用低通滤波器
    _lastLowPassAccelerometer = applyLowPassFilter(
      rawData, 
      _lastLowPassAccelerometer, 
      _lowPassAlpha,
    );
    
    // 应用高通滤波器
    _lastHighPassAccelerometer = applyHighPassFilter(
      rawData,
      _lastHighPassAccelerometer,
      _lastRawAccelerometer,
      _highPassAlpha,
    );
    _lastRawAccelerometer = rawData;
    
    // 应用移动平均滤波
    final smoothedData = applyMovingAverageFilter(_accelerometerBuffer);
    
    return smoothedData;
  }

  // 处理陀螺仪数据
  SensorData processGyroscopeData(SensorData rawData) {
    // 添加到缓冲区
    addGyroscopeData(rawData);
    
    // 应用低通滤波器
    _lastLowPassGyroscope = applyLowPassFilter(
      rawData, 
      _lastLowPassGyroscope, 
      _lowPassAlpha,
    );
    
    // 应用移动平均滤波
    final smoothedData = applyMovingAverageFilter(_gyroscopeBuffer);
    
    return smoothedData;
  }

  // 处理用户加速度计数据
  SensorData processUserAccelerometerData(SensorData rawData) {
    // 添加到缓冲区
    addUserAccelerometerData(rawData);
    
    // 应用移动平均滤波
    final smoothedData = applyMovingAverageFilter(_userAccelerometerBuffer);
    
    return smoothedData;
  }

  // 计算加速度变化率
  double calculateAccelerationChange(Queue<SensorData> buffer) {
    if (buffer.length < 2) return 0.0;
    
    final recent = buffer.last;
    final previous = buffer.elementAt(buffer.length - 2);
    
    return (recent.magnitude - previous.magnitude).abs();
  }

  // 检测峰值
  List<int> detectPeaks(List<double> data, {double threshold = 0.5, int minDistance = 10}) {
    final peaks = <int>[];
    
    for (int i = minDistance; i < data.length - minDistance; i++) {
      bool isPeak = true;
      
      // 检查是否大于阈值
      if (data[i] < threshold) continue;
      
      // 检查是否是局部最大值
      for (int j = i - minDistance; j <= i + minDistance; j++) {
        if (j != i && data[j] >= data[i]) {
          isPeak = false;
          break;
        }
      }
      
      // 检查与上一个峰值的距离
      if (isPeak && peaks.isNotEmpty && i - peaks.last < minDistance) {
        // 如果距离太近，保留较大的峰值
        if (data[i] > data[peaks.last]) {
          peaks.removeLast();
          peaks.add(i);
        }
      } else if (isPeak) {
        peaks.add(i);
      }
    }
    
    return peaks;
  }

  // 计算标准差
  double calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.average;
    final variance = values.map((x) => pow(x - mean, 2)).average;
    return sqrt(variance);
  }

  // 计算相关系数
  double calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    final meanX = x.average;
    final meanY = y.average;
    
    double numerator = 0.0;
    double denomX = 0.0;
    double denomY = 0.0;
    
    for (int i = 0; i < x.length; i++) {
      final diffX = x[i] - meanX;
      final diffY = y[i] - meanY;
      
      numerator += diffX * diffY;
      denomX += diffX * diffX;
      denomY += diffY * diffY;
    }
    
    if (denomX == 0.0 || denomY == 0.0) return 0.0;
    
    return numerator / sqrt(denomX * denomY);
  }

  // 频率域分析 - 简单的功率谱
  Map<String, double> analyzePowerSpectrum(List<double> data, double sampleRate) {
    if (data.length < 4) return {};
    
    // 计算不同频率段的功率
    final lowFreq = <double>[];
    final midFreq = <double>[];
    final highFreq = <double>[];
    
    // 简单的频率分析，基于数据变化率
    for (int i = 1; i < data.length; i++) {
      final change = (data[i] - data[i - 1]).abs();
      
      // 根据变化幅度分类到不同频率段
      if (change < 0.5) {
        lowFreq.add(change);
      } else if (change < 2.0) {
        midFreq.add(change);
      } else {
        highFreq.add(change);
      }
    }
    
    return {
      'lowFreqPower': lowFreq.isNotEmpty ? lowFreq.average : 0.0,
      'midFreqPower': midFreq.isNotEmpty ? midFreq.average : 0.0,
      'highFreqPower': highFreq.isNotEmpty ? highFreq.average : 0.0,
      'totalPower': data.map((x) => x * x).average,
    };
  }

  // 获取数据特征
  Map<String, dynamic> extractFeatures(Queue<SensorData> buffer) {
    if (buffer.isEmpty) return {};
    
    final magnitudes = buffer.map((d) => d.magnitude).toList();
    final xValues = buffer.map((d) => d.x).toList();
    final yValues = buffer.map((d) => d.y).toList();
    final zValues = buffer.map((d) => d.z).toList();
    
    return {
      'mean': magnitudes.average,
      'max': magnitudes.max,
      'min': magnitudes.min,
      'std': calculateStandardDeviation(magnitudes),
      'range': magnitudes.max - magnitudes.min,
      'peaks': detectPeaks(magnitudes).length,
      'energy': magnitudes.map((x) => x * x).sum,
      'rms': sqrt(magnitudes.map((x) => x * x).average),
      'correlation_xy': calculateCorrelation(xValues, yValues),
      'correlation_xz': calculateCorrelation(xValues, zValues),
      'correlation_yz': calculateCorrelation(yValues, zValues),
    };
  }

  // 重置处理器
  void reset() {
    _accelerometerBuffer.clear();
    _gyroscopeBuffer.clear();
    _userAccelerometerBuffer.clear();
    _lastLowPassAccelerometer = null;
    _lastLowPassGyroscope = null;
    _lastHighPassAccelerometer = null;
    _lastRawAccelerometer = null;
  }

  // 获取缓冲区状态
  Map<String, dynamic> getBufferStatus() {
    return {
      'accelerometerBufferSize': _accelerometerBuffer.length,
      'gyroscopeBufferSize': _gyroscopeBuffer.length,
      'userAccelerometerBufferSize': _userAccelerometerBuffer.length,
      'windowSize': _windowSize,
      'lowPassAlpha': _lowPassAlpha,
      'highPassAlpha': _highPassAlpha,
    };
  }
}