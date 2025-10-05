import 'dart:convert';
import 'package:uuid/uuid.dart';

class ExerciseRecordModel {
  final String recordId;
  final String userId;
  final String exerciseType;
  final int count;
  final int duration; // seconds
  final double calories;
  final DateTime startTime;
  final DateTime endTime;
  final String syncStatus; // local, synced, deleted
  final Map<String, dynamic>? sensorData;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExerciseRecordModel({
    String? recordId,
    required this.userId,
    required this.exerciseType,
    required this.count,
    required this.duration,
    required this.calories,
    required this.startTime,
    required this.endTime,
    this.syncStatus = 'local',
    this.sensorData,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : recordId = recordId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ExerciseRecordModel copyWith({
    String? recordId,
    String? userId,
    String? exerciseType,
    int? count,
    int? duration,
    double? calories,
    DateTime? startTime,
    DateTime? endTime,
    String? syncStatus,
    Map<String, dynamic>? sensorData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExerciseRecordModel(
      recordId: recordId ?? this.recordId,
      userId: userId ?? this.userId,
      exerciseType: exerciseType ?? this.exerciseType,
      count: count ?? this.count,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      syncStatus: syncStatus ?? this.syncStatus,
      sensorData: sensorData ?? this.sensorData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'user_id': userId,
      'exercise_type': exerciseType,
      'count': count,
      'duration': duration,
      'calories': calories,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'sync_status': syncStatus,
      'sensor_data': sensorData != null ? jsonEncode(sensorData) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExerciseRecordModel.fromMap(Map<String, dynamic> map) {
    return ExerciseRecordModel(
      recordId: map['record_id'] as String,
      userId: map['user_id'] as String,
      exerciseType: map['exercise_type'] as String,
      count: map['count'] as int,
      duration: map['duration'] as int,
      calories: (map['calories'] as num).toDouble(),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      syncStatus: map['sync_status'] as String? ?? 'local',
      sensorData: map['sensor_data'] != null
          ? jsonDecode(map['sensor_data'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ExerciseRecordModel.fromJson(Map<String, dynamic> json) => fromMap(json);

  @override
  String toString() {
    return 'ExerciseRecordModel(recordId: $recordId, userId: $userId, exerciseType: $exerciseType, count: $count, duration: $duration, calories: $calories, startTime: $startTime, endTime: $endTime, syncStatus: $syncStatus, sensorData: $sensorData, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseRecordModel &&
        other.recordId == recordId &&
        other.userId == userId &&
        other.exerciseType == exerciseType &&
        other.count == count &&
        other.duration == duration &&
        other.calories == calories &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.syncStatus == syncStatus &&
        other.sensorData == sensorData &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return recordId.hashCode ^
        userId.hashCode ^
        exerciseType.hashCode ^
        count.hashCode ^
        duration.hashCode ^
        calories.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        syncStatus.hashCode ^
        sensorData.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  // 获取运动强度
  double get intensity {
    if (duration == 0) return 0.0;
    return count / (duration / 60.0); // 每分钟次数
  }

  // 获取平均配速
  Duration get averagePace {
    if (count == 0) return Duration.zero;
    final secondsPerRep = duration / count;
    return Duration(seconds: secondsPerRep.round());
  }

  // 格式化持续时间
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}小时${minutes}分钟${seconds}秒';
    } else if (minutes > 0) {
      return '${minutes}分钟${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }

  // 格式化开始时间
  String get formattedStartTime {
    final now = DateTime.now();
    final difference = now.difference(startTime);

    if (difference.inDays == 0) {
      // 今天
      return '今天 ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天 ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // 本周
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekday = weekdays[startTime.weekday - 1];
      return '$weekday ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 更早
      return '${startTime.month}月${startTime.day}日';
    }
  }

  // 判断是否是今日记录
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  // 判断是否本周记录
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return startTime.isAfter(startOfWeek);
  }

  // 判断是否本月记录
  bool get isThisMonth {
    final now = DateTime.now();
    return startTime.year == now.year && startTime.month == now.month;
  }
}