import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/exercise_record_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 创建用户表
    await db.execute('''
      CREATE TABLE users (
        local_user_id TEXT PRIMARY KEY,
        username TEXT,
        age INTEGER,
        gender TEXT,
        height REAL,
        weight REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建运动记录表
    await db.execute('''
      CREATE TABLE exercise_records (
        record_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        exercise_type TEXT NOT NULL,
        count INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        calories REAL NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        sync_status TEXT DEFAULT 'local',
        sensor_data TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (local_user_id)
      )
    ''');

    // 创建运动配置表
    await db.execute('''
      CREATE TABLE exercise_configs (
        exercise_type TEXT PRIMARY KEY,
        calories_per_rep REAL NOT NULL,
        detection_threshold REAL NOT NULL,
        min_interval INTEGER NOT NULL,
        sensor_config TEXT NOT NULL
      )
    ''');

    // 插入默认运动配置
    await _insertDefaultExerciseConfigs(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
    if (oldVersion < 2) {
      // 版本2的升级逻辑
    }
  }

  Future<void> _insertDefaultExerciseConfigs(Database db) async {
    const configs = [
      {
        'exercise_type': 'pushup',
        'calories_per_rep': 0.32,
        'detection_threshold': 2.0,
        'min_interval': 500,
        'sensor_config': '{"axes": ["y"], "threshold": 2.0, "window": 5}',
      },
      {
        'exercise_type': 'pullup',
        'calories_per_rep': 0.68,
        'detection_threshold': 1.8,
        'min_interval': 800,
        'sensor_config': '{"axes": ["z"], "threshold": 1.8, "window": 5}',
      },
      {
        'exercise_type': 'situp',
        'calories_per_rep': 0.15,
        'detection_threshold': 1.5,
        'min_interval': 400,
        'sensor_config': '{"axes": ["x"], "threshold": 1.5, "window": 4}',
      },
      {
        'exercise_type': 'squat',
        'calories_per_rep': 0.40,
        'detection_threshold': 2.2,
        'min_interval': 600,
        'sensor_config': '{"axes": ["z"], "threshold": 2.2, "window": 5}',
      },
      {
        'exercise_type': 'plank',
        'calories_per_rep': 0.20,
        'detection_threshold': 0.5,
        'min_interval': 1000,
        'sensor_config': '{"axes": ["all"], "threshold": 0.5, "window": 10}',
      },
    ];

    for (final config in configs) {
      await db.insert('exercise_configs', config);
    }
  }

  // 用户相关操作
  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'local_user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'local_user_id = ?',
      whereArgs: [user.localUserId],
    );
  }

  // 运动记录相关操作
  Future<int> insertExerciseRecord(ExerciseRecordModel record) async {
    final db = await database;
    return await db.insert('exercise_records', record.toMap());
  }

  Future<List<ExerciseRecordModel>> getExerciseRecords({
    String? userId,
    String? exerciseType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (exerciseType != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'exercise_type = ?';
      whereArgs.add(exerciseType);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'start_time >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'end_time <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'exercise_records',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'start_time DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => ExerciseRecordModel.fromMap(map)).toList();
  }

  Future<int> updateExerciseRecord(ExerciseRecordModel record) async {
    final db = await database;
    return await db.update(
      'exercise_records',
      record.toMap(),
      where: 'record_id = ?',
      whereArgs: [record.recordId],
    );
  }

  Future<int> deleteExerciseRecord(String recordId) async {
    final db = await database;
    return await db.delete(
      'exercise_records',
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  // 统计查询
  Future<Map<String, dynamic>> getExerciseStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'start_time >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'end_time <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        exercise_type,
        COUNT(*) as session_count,
        SUM(count) as total_count,
        SUM(duration) as total_duration,
        SUM(calories) as total_calories,
        AVG(count) as avg_count,
        MAX(count) as max_count
      FROM exercise_records
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY exercise_type
    ''', whereArgs);

    return {
      'exercise_breakdown': result,
      'total_sessions': result.fold<int>(
        0,
        (sum, row) => sum + (row['session_count'] as int),
      ),
      'total_calories': result.fold<double>(
        0.0,
        (sum, row) => sum + (row['total_calories'] as double),
      ),
    };
  }

  // 数据库初始化
  Future<void> initialize() async {
    await database;
  }

  // 关闭数据库
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}