import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/database_service.dart';
import '../models/exercise_record_model.dart';
import '../models/user_model.dart';

enum ExerciseState {
  idle,
  preparing,
  active,
  paused,
  completed,
}

class ExerciseProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  
  // 运动状态
  ExerciseState _exerciseState = ExerciseState.idle;
  String? _currentExerciseType;
  int _currentCount = 0;
  double _currentCalories = 0.0;
  DateTime? _exerciseStartTime;
  DateTime? _exercisePauseTime;
  int _totalDuration = 0; // 总时长（秒）
  int _pausedDuration = 0; // 暂停时长（秒）
  Timer? _exerciseTimer;
  UserModel? _currentUser;
  
  // 运动目标
  int _targetCount = 20;
  int _targetCalories = 100;
  
  // 错误处理
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  ExerciseState get exerciseState => _exerciseState;
  String? get currentExerciseType => _currentExerciseType;
  int get currentCount => _currentCount;
  double get currentCalories => _currentCalories;
  DateTime? get exerciseStartTime => _exerciseStartTime;
  int get totalDuration => _totalDuration;
  int get activeDuration => _totalDuration - _pausedDuration;
  int get targetCount => _targetCount;
  int get targetCalories => _targetCalories;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;

  // 计算进度百分比
  double get countProgress => _targetCount > 0 ? (_currentCount / _targetCount).clamp(0.0, 1.0) : 0.0;
  double get calorieProgress => _targetCalories > 0 ? (_currentCalories / _targetCalories).clamp(0.0, 1.0) : 0.0;

  // 获取运动名称
  String get currentExerciseName {
    if (_currentExerciseType == null) return '';
    return AppConstants.exerciseNames[_currentExerciseType] ?? _currentExerciseType!;
  }

  ExerciseProvider() {
    _loadCurrentUser();
  }

  // 加载当前用户
  Future<void> _loadCurrentUser() async {
    try {
      setLoading(true);
      // 这里暂时创建一个默认用户，实际应用中应该有用户登录逻辑
      // 后续可以从SharedPreferences或数据库中加载
      _currentUser = UserModel(
        username: '健身爱好者',
        age: 25,
        gender: '男',
        height: 175.0,
        weight: 70.0,
      );
      
      // 检查数据库中是否已存在该用户
      final existingUser = await _databaseService.getUser(_currentUser!.localUserId);
      if (existingUser == null) {
        await _databaseService.insertUser(_currentUser!);
      } else {
        _currentUser = existingUser;
      }
      
      notifyListeners();
    } catch (e) {
      setError('加载用户信息失败: $e');
    } finally {
      setLoading(false);
    }
  }

  // 开始运动
  Future<void> startExercise(String exerciseType) async {
    try {
      if (_exerciseState != ExerciseState.idle && _exerciseState != ExerciseState.completed) {
        throw Exception('当前有运动正在进行中');
      }

      _currentExerciseType = exerciseType;
      _exerciseState = ExerciseState.preparing;
      _currentCount = 0;
      _currentCalories = 0.0;
      _totalDuration = 0;
      _pausedDuration = 0;
      _exerciseStartTime = DateTime.now();
      _exercisePauseTime = null;
      
      clearError();
      notifyListeners();

      // 3秒准备时间
      await Future.delayed(const Duration(seconds: 3));
      
      if (_exerciseState == ExerciseState.preparing) {
        _exerciseState = ExerciseState.active;
        _startTimer();
        notifyListeners();
      }
    } catch (e) {
      setError('开始运动失败: $e');
      _exerciseState = ExerciseState.idle;
      notifyListeners();
    }
  }

  // 暂停运动
  void pauseExercise() {
    if (_exerciseState == ExerciseState.active) {
      _exerciseState = ExerciseState.paused;
      _exercisePauseTime = DateTime.now();
      _exerciseTimer?.cancel();
      notifyListeners();
    }
  }

  // 恢复运动
  void resumeExercise() {
    if (_exerciseState == ExerciseState.paused && _exercisePauseTime != null) {
      _pausedDuration += DateTime.now().difference(_exercisePauseTime!).inSeconds;
      _exerciseState = ExerciseState.active;
      _exercisePauseTime = null;
      _startTimer();
      notifyListeners();
    }
  }

  // 停止运动
  Future<void> stopExercise() async {
    try {
      if (_exerciseState == ExerciseState.idle || _exerciseState == ExerciseState.completed) {
        return;
      }

      _exerciseTimer?.cancel();
      
      if (_exerciseState == ExerciseState.paused && _exercisePauseTime != null) {
        _pausedDuration += DateTime.now().difference(_exercisePauseTime!).inSeconds;
      }
      
      _exerciseState = ExerciseState.completed;
      
      // 保存运动记录
      if (_currentExerciseType != null && _exerciseStartTime != null && _currentUser != null) {
        await _saveExerciseRecord();
      }
      
      notifyListeners();
    } catch (e) {
      setError('停止运动失败: $e');
    }
  }

  // 增加运动计数
  void incrementCount() {
    if (_exerciseState == ExerciseState.active) {
      _currentCount++;
      _updateCalories();
      notifyListeners();
    }
  }

  // 减少运动计数（错误识别时的纠正）
  void decrementCount() {
    if (_exerciseState == ExerciseState.active && _currentCount > 0) {
      _currentCount--;
      _updateCalories();
      notifyListeners();
    }
  }

  // 手动调整计数
  void setCount(int count) {
    if (count >= 0) {
      _currentCount = count;
      _updateCalories();
      notifyListeners();
    }
  }

  // 设置运动目标
  void setTargetCount(int target) {
    if (target > 0) {
      _targetCount = target;
      notifyListeners();
    }
  }

  void setTargetCalories(int target) {
    if (target > 0) {
      _targetCalories = target;
      notifyListeners();
    }
  }

  // 重置运动状态
  void resetExercise() {
    _exerciseTimer?.cancel();
    _exerciseState = ExerciseState.idle;
    _currentExerciseType = null;
    _currentCount = 0;
    _currentCalories = 0.0;
    _totalDuration = 0;
    _pausedDuration = 0;
    _exerciseStartTime = null;
    _exercisePauseTime = null;
    clearError();
    notifyListeners();
  }

  // 开始计时器
  void _startTimer() {
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_exerciseState == ExerciseState.active) {
        _totalDuration++;
        notifyListeners();
      }
    });
  }

  // 更新卡路里计算
  void _updateCalories() {
    if (_currentExerciseType != null && _currentUser != null) {
      final baseCalories = AppConstants.caloriesPerRep[_currentExerciseType] ?? 0.0;
      final personalMultiplier = _currentUser!.personalCalorieMultiplier;
      _currentCalories = _currentCount * baseCalories * personalMultiplier;
    }
  }

  // 保存运动记录
  Future<void> _saveExerciseRecord() async {
    if (_currentExerciseType == null || 
        _exerciseStartTime == null || 
        _currentUser == null) {
      return;
    }

    final record = ExerciseRecordModel(
      userId: _currentUser!.localUserId,
      exerciseType: _currentExerciseType!,
      count: _currentCount,
      duration: activeDuration,
      calories: _currentCalories,
      startTime: _exerciseStartTime!,
      endTime: DateTime.now(),
    );

    await _databaseService.insertExerciseRecord(record);
  }

  // 错误处理
  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  // 获取运动统计
  Future<Map<String, dynamic>> getTodayStatistics() async {
    if (_currentUser == null) return {};
    
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final records = await _databaseService.getExerciseRecords(
        userId: _currentUser!.localUserId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      int totalCount = 0;
      double totalCalories = 0.0;
      int totalDuration = 0;
      
      for (final record in records) {
        totalCount += record.count;
        totalCalories += record.calories;
        totalDuration += record.duration;
      }
      
      return {
        'totalSessions': records.length,
        'totalCount': totalCount,
        'totalCalories': totalCalories,
        'totalDuration': totalDuration,
        'records': records,
      };
    } catch (e) {
      setError('获取今日统计失败: $e');
      return {};
    }
  }

  @override
  void dispose() {
    _exerciseTimer?.cancel();
    super.dispose();
  }
}