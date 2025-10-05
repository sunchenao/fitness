import 'dart:math';
import 'dart:collection';
import 'package:collection/collection.dart';

import 'sensor_service.dart';

// 高级特征提取器
class AdvancedFeatureExtractor {
  static final AdvancedFeatureExtractor _instance = AdvancedFeatureExtractor._internal();
  factory AdvancedFeatureExtractor() => _instance;
  static AdvancedFeatureExtractor get instance => _instance;
  AdvancedFeatureExtractor._internal();

  // 时域特征提取
  Map<String, double> extractTimeDomainFeatures(List<double> signal) {
    if (signal.isEmpty) return {};

    final mean = signal.average;
    final variance = signal.map((x) => pow(x - mean, 2)).average;
    final std = sqrt(variance);
    final rms = sqrt(signal.map((x) => x * x).average);
    final skewness = _calculateSkewness(signal, mean, std);
    final kurtosis = _calculateKurtosis(signal, mean, std);
    final energy = signal.map((x) => x * x).sum;
    
    return {
      'mean': mean,
      'std': std,
      'variance': variance,
      'rms': rms,
      'min': signal.min,
      'max': signal.max,
      'range': signal.max - signal.min,
      'skewness': skewness,
      'kurtosis': kurtosis,
      'energy': energy,
      'peak_to_peak': signal.max - signal.min,
      'mean_absolute_deviation': signal.map((x) => (x - mean).abs()).average,
      'zero_crossing_rate': _calculateZeroCrossingRate(signal),
    };
  }

  // 频域特征提取（简化版FFT）
  Map<String, double> extractFrequencyDomainFeatures(List<double> signal, double sampleRate) {
    if (signal.length < 4) return {};

    // 简化的频域分析
    final spectrum = _simpleSpectralAnalysis(signal);
    final dominantFreq = _findDominantFrequency(spectrum, sampleRate);
    final spectralCentroid = _calculateSpectralCentroid(spectrum, sampleRate);
    final spectralRolloff = _calculateSpectralRolloff(spectrum, 0.85);
    final spectralBandwidth = _calculateSpectralBandwidth(spectrum, spectralCentroid, sampleRate);
    
    return {
      'dominant_frequency': dominantFreq,
      'spectral_centroid': spectralCentroid,
      'spectral_rolloff': spectralRolloff,
      'spectral_bandwidth': spectralBandwidth,
      'spectral_energy': spectrum.map((x) => x * x).sum,
      'spectral_entropy': _calculateSpectralEntropy(spectrum),
    };
  }

  // 统计特征提取
  Map<String, double> extractStatisticalFeatures(List<double> signal) {
    if (signal.isEmpty) return {};

    final sorted = List<double>.from(signal)..sort();
    final n = sorted.length;
    
    return {
      'median': n.isOdd ? sorted[n ~/ 2] : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2,
      'q1': _calculatePercentile(sorted, 0.25),
      'q3': _calculatePercentile(sorted, 0.75),
      'iqr': _calculatePercentile(sorted, 0.75) - _calculatePercentile(sorted, 0.25),
      'mad': _calculateMedianAbsoluteDeviation(signal),
      'coefficient_of_variation': signal.average != 0 ? sqrt(signal.map((x) => pow(x - signal.average, 2)).average) / signal.average : 0,
    };
  }

  // 形态学特征提取
  Map<String, dynamic> extractMorphologicalFeatures(List<double> signal, {double minPeakHeight = 0.5, int minPeakDistance = 5}) {
    if (signal.isEmpty) return {};

    final peaks = _detectPeaks(signal, minPeakHeight: minPeakHeight, minPeakDistance: minPeakDistance);
    final valleys = _detectValleys(signal, minValleyDepth: minPeakHeight, minValleyDistance: minPeakDistance);
    
    final peakHeights = peaks.map((i) => signal[i]).toList();
    final valleyDepths = valleys.map((i) => signal[i]).toList();
    
    return {
      'peak_count': peaks.length,
      'valley_count': valleys.length,
      'peak_indices': peaks,
      'valley_indices': valleys,
      'average_peak_height': peakHeights.isNotEmpty ? peakHeights.average : 0.0,
      'average_valley_depth': valleyDepths.isNotEmpty ? valleyDepths.average : 0.0,
      'peak_to_valley_ratio': valleys.isNotEmpty ? peaks.length / valleys.length : 0.0,
      'regularity_score': _calculateRegularityScore(peaks),
    };
  }

  // 运动特定特征提取
  Map<String, double> extractMotionSpecificFeatures(Queue<SensorData> accelerometerData, Queue<SensorData> gyroscopeData) {
    if (accelerometerData.isEmpty) return {};

    final accMagnitudes = accelerometerData.map((d) => d.magnitude).toList();
    final accX = accelerometerData.map((d) => d.x).toList();
    final accY = accelerometerData.map((d) => d.y).toList();
    final accZ = accelerometerData.map((d) => d.z).toList();
    
    Map<String, double> features = {};
    
    // 加速度特征
    features.addAll({
      'acc_magnitude_mean': accMagnitudes.average,
      'acc_magnitude_std': _calculateStandardDeviation(accMagnitudes),
      'acc_x_std': _calculateStandardDeviation(accX),
      'acc_y_std': _calculateStandardDeviation(accY),
      'acc_z_std': _calculateStandardDeviation(accZ),
    });
    
    // 轴间相关性
    features.addAll({
      'acc_xy_correlation': _calculateCorrelation(accX, accY),
      'acc_xz_correlation': _calculateCorrelation(accX, accZ),
      'acc_yz_correlation': _calculateCorrelation(accY, accZ),
    });
    
    // 姿态角度估算
    final tiltAngles = _calculateTiltAngles(accelerometerData);
    features.addAll(tiltAngles);
    
    // 陀螺仪特征（如果可用）
    if (gyroscopeData.isNotEmpty) {
      final gyroMagnitudes = gyroscopeData.map((d) => d.magnitude).toList();
      features.addAll({
        'gyro_magnitude_mean': gyroMagnitudes.average,
        'gyro_magnitude_std': _calculateStandardDeviation(gyroMagnitudes),
        'angular_velocity': gyroMagnitudes.average,
      });
    }
    
    return features;
  }

  // 运动周期检测
  Map<String, dynamic> detectMotionCycles(List<double> signal, {double threshold = 0.5}) {
    final peaks = _detectPeaks(signal, minPeakHeight: threshold);
    final valleys = _detectValleys(signal, minValleyDepth: threshold);
    
    List<Map<String, int>> cycles = [];
    
    // 检测完整的运动周期（峰值到峰值）
    for (int i = 0; i < peaks.length - 1; i++) {
      final startPeak = peaks[i];
      final endPeak = peaks[i + 1];
      
      // 查找中间的谷值
      final middleValleys = valleys.where((v) => v > startPeak && v < endPeak).toList();
      
      if (middleValleys.isNotEmpty) {
        cycles.add({
          'start': startPeak,
          'valley': middleValleys.first,
          'end': endPeak,
          'duration': endPeak - startPeak,
        });
      }
    }
    
    final cycleDurations = cycles.map((c) => c['duration']! as int).toList();
    
    return {
      'cycle_count': cycles.length,
      'cycles': cycles,
      'average_cycle_duration': cycleDurations.isNotEmpty ? cycleDurations.average : 0.0,
      'cycle_regularity': _calculateCycleRegularity(cycleDurations),
    };
  }

  // 计算偏度
  double _calculateSkewness(List<double> data, double mean, double std) {
    if (std == 0) return 0.0;
    final n = data.length;
    final skew = data.map((x) => pow((x - mean) / std, 3)).sum / n;
    return skew;
  }

  // 计算峰度
  double _calculateKurtosis(List<double> data, double mean, double std) {
    if (std == 0) return 0.0;
    final n = data.length;
    final kurt = data.map((x) => pow((x - mean) / std, 4)).sum / n - 3;
    return kurt;
  }

  // 计算零穿越率
  double _calculateZeroCrossingRate(List<double> signal) {
    if (signal.length < 2) return 0.0;
    
    int crossings = 0;
    for (int i = 1; i < signal.length; i++) {
      if ((signal[i] >= 0 && signal[i - 1] < 0) || (signal[i] < 0 && signal[i - 1] >= 0)) {
        crossings++;
      }
    }
    
    return crossings / (signal.length - 1);
  }

  // 简化的频谱分析
  List<double> _simpleSpectralAnalysis(List<double> signal) {
    // 简化版本：基于自相关函数的频谱估计
    final n = signal.length;
    final spectrum = List<double>.filled(n ~/ 2, 0.0);
    
    for (int k = 0; k < spectrum.length; k++) {
      double real = 0.0, imag = 0.0;
      
      for (int i = 0; i < n; i++) {
        final angle = -2 * pi * k * i / n;
        real += signal[i] * cos(angle);
        imag += signal[i] * sin(angle);
      }
      
      spectrum[k] = sqrt(real * real + imag * imag);
    }
    
    return spectrum;
  }

  // 寻找主导频率
  double _findDominantFrequency(List<double> spectrum, double sampleRate) {
    if (spectrum.isEmpty) return 0.0;
    
    final maxIndex = spectrum.indexOf(spectrum.max);
    return maxIndex * sampleRate / (2 * spectrum.length);
  }

  // 计算频谱质心
  double _calculateSpectralCentroid(List<double> spectrum, double sampleRate) {
    if (spectrum.isEmpty) return 0.0;
    
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    
    for (int i = 0; i < spectrum.length; i++) {
      final frequency = i * sampleRate / (2 * spectrum.length);
      weightedSum += frequency * spectrum[i];
      totalWeight += spectrum[i];
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  // 计算频谱滚降点
  double _calculateSpectralRolloff(List<double> spectrum, double threshold) {
    final totalEnergy = spectrum.map((x) => x * x).sum;
    final targetEnergy = totalEnergy * threshold;
    
    double cumulativeEnergy = 0.0;
    for (int i = 0; i < spectrum.length; i++) {
      cumulativeEnergy += spectrum[i] * spectrum[i];
      if (cumulativeEnergy >= targetEnergy) {
        return i.toDouble();
      }
    }
    
    return spectrum.length.toDouble();
  }

  // 计算频谱带宽
  double _calculateSpectralBandwidth(List<double> spectrum, double centroid, double sampleRate) {
    if (spectrum.isEmpty) return 0.0;
    
    double weightedVariance = 0.0;
    double totalWeight = 0.0;
    
    for (int i = 0; i < spectrum.length; i++) {
      final frequency = i * sampleRate / (2 * spectrum.length);
      final deviation = frequency - centroid;
      weightedVariance += deviation * deviation * spectrum[i];
      totalWeight += spectrum[i];
    }
    
    return totalWeight > 0 ? sqrt(weightedVariance / totalWeight) : 0.0;
  }

  // 计算频谱熵
  double _calculateSpectralEntropy(List<double> spectrum) {
    final totalEnergy = spectrum.map((x) => x * x).sum;
    if (totalEnergy == 0) return 0.0;
    
    double entropy = 0.0;
    for (final value in spectrum) {
      if (value > 0) {
        final probability = (value * value) / totalEnergy;
        entropy -= probability * log(probability) / ln2;
      }
    }
    
    return entropy;
  }

  // 计算百分位数
  double _calculatePercentile(List<double> sortedData, double percentile) {
    if (sortedData.isEmpty) return 0.0;
    
    final index = percentile * (sortedData.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    
    if (lower == upper) {
      return sortedData[lower];
    } else {
      final weight = index - lower;
      return sortedData[lower] * (1 - weight) + sortedData[upper] * weight;
    }
  }

  // 计算中位绝对偏差
  double _calculateMedianAbsoluteDeviation(List<double> data) {
    if (data.isEmpty) return 0.0;
    
    final median = _calculatePercentile(List<double>.from(data)..sort(), 0.5);
    final deviations = data.map((x) => (x - median).abs()).toList()..sort();
    
    return _calculatePercentile(deviations, 0.5);
  }

  // 检测峰值
  List<int> _detectPeaks(List<double> signal, {double minPeakHeight = 0.5, int minPeakDistance = 5}) {
    final peaks = <int>[];
    
    for (int i = minPeakDistance; i < signal.length - minPeakDistance; i++) {
      if (signal[i] < minPeakHeight) continue;
      
      bool isPeak = true;
      for (int j = i - minPeakDistance; j <= i + minPeakDistance; j++) {
        if (j != i && signal[j] >= signal[i]) {
          isPeak = false;
          break;
        }
      }
      
      if (isPeak && (peaks.isEmpty || i - peaks.last >= minPeakDistance)) {
        peaks.add(i);
      }
    }
    
    return peaks;
  }

  // 检测谷值
  List<int> _detectValleys(List<double> signal, {double minValleyDepth = 0.5, int minValleyDistance = 5}) {
    final valleys = <int>[];
    
    for (int i = minValleyDistance; i < signal.length - minValleyDistance; i++) {
      if (signal[i] > -minValleyDepth) continue;
      
      bool isValley = true;
      for (int j = i - minValleyDistance; j <= i + minValleyDistance; j++) {
        if (j != i && signal[j] <= signal[i]) {
          isValley = false;
          break;
        }
      }
      
      if (isValley && (valleys.isEmpty || i - valleys.last >= minValleyDistance)) {
        valleys.add(i);
      }
    }
    
    return valleys;
  }

  // 计算标准差
  double _calculateStandardDeviation(List<double> data) {
    if (data.isEmpty) return 0.0;
    final mean = data.average;
    final variance = data.map((x) => pow(x - mean, 2)).average;
    return sqrt(variance);
  }

  // 计算相关系数
  double _calculateCorrelation(List<double> x, List<double> y) {
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
    
    return (denomX > 0 && denomY > 0) ? numerator / sqrt(denomX * denomY) : 0.0;
  }

  // 计算倾斜角度
  Map<String, double> _calculateTiltAngles(Queue<SensorData> accelerometerData) {
    if (accelerometerData.isEmpty) return {};
    
    final latest = accelerometerData.last;
    
    // 计算设备相对于重力的倾斜角度
    final roll = atan2(latest.y, latest.z) * 180 / pi;
    final pitch = atan2(-latest.x, sqrt(latest.y * latest.y + latest.z * latest.z)) * 180 / pi;
    
    return {
      'roll_angle': roll,
      'pitch_angle': pitch,
      'tilt_magnitude': sqrt(roll * roll + pitch * pitch),
    };
  }

  // 计算规律性得分
  double _calculateRegularityScore(List<int> peaks) {
    if (peaks.length < 3) return 0.0;
    
    final intervals = <int>[];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add(peaks[i] - peaks[i - 1]);
    }
    
    final meanInterval = intervals.average;
    final variance = intervals.map((x) => pow(x - meanInterval, 2)).average;
    final cv = sqrt(variance) / meanInterval;
    
    // 规律性得分：变异系数越小，规律性越高
    return 1.0 / (1.0 + cv);
  }

  // 计算周期规律性
  double _calculateCycleRegularity(List<int> cycleDurations) {
    if (cycleDurations.length < 2) return 0.0;
    
    final mean = cycleDurations.average;
    final std = _calculateStandardDeviation(cycleDurations.map((x) => x.toDouble()).toList());
    
    return mean > 0 ? 1.0 - (std / mean) : 0.0;
  }
}