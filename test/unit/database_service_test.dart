import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fitness/core/services/database_service.dart';
import 'package:fitness/core/models/exercise_record_model.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    // 初始化 sqflite_common_ffi 用于测试环境
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService.instance;
    await databaseService.initDatabase();
  });

  tearDown(() async {
    await databaseService.closeDatabase();
  });

  group('DatabaseService Tests', () {
    test('应该能够初始化数据库', () async {
      expect(databaseService.database, isNotNull);
    });

    test('应该能够插入运动记录', () async {
      final record = ExerciseRecordModel(
        exerciseType: 'push_up',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 2)),
        reps: 20,
        caloriesBurned: 15.5,
        notes: '测试记录',
      );

      final insertedId = await databaseService.insertExerciseRecord(record);
      expect(insertedId, isNotNull);
      expect(insertedId, greaterThan(0));
    });

    test('应该能够查询运动记录', () async {
      // 先插入一条记录
      final record = ExerciseRecordModel(
        exerciseType: 'sit_up',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 3)),
        reps: 30,
        caloriesBurned: 20.0,
      );

      await databaseService.insertExerciseRecord(record);

      // 查询记录
      final records = await databaseService.getExerciseRecords();
      expect(records, isNotEmpty);
      expect(records.first.exerciseType, equals('sit_up'));
      expect(records.first.reps, equals(30));
    });

    test('应该能够按日期范围查询记录', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      // 插入今天的记录
      final todayRecord = ExerciseRecordModel(
        exerciseType: 'push_up',
        startTime: now,
        endTime: now.add(const Duration(minutes: 2)),
        reps: 15,
        caloriesBurned: 12.0,
      );

      // 插入昨天的记录
      final yesterdayRecord = ExerciseRecordModel(
        exerciseType: 'pull_up',
        startTime: yesterday,
        endTime: yesterday.add(const Duration(minutes: 3)),
        reps: 10,
        caloriesBurned: 18.0,
      );

      await databaseService.insertExerciseRecord(todayRecord);
      await databaseService.insertExerciseRecord(yesterdayRecord);

      // 查询今天的记录
      final todayRecords = await databaseService.getExerciseRecords(
        startDate: DateTime(now.year, now.month, now.day),
        endDate: tomorrow,
      );

      expect(todayRecords.length, equals(1));
      expect(todayRecords.first.exerciseType, equals('push_up'));
    });

    test('应该能够按运动类型过滤记录', () async {
      // 插入不同类型的记录
      final pushUpRecord = ExerciseRecordModel(
        exerciseType: 'push_up',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 2)),
        reps: 20,
        caloriesBurned: 15.0,
      );

      final sitUpRecord = ExerciseRecordModel(
        exerciseType: 'sit_up',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 2)),
        reps: 25,
        caloriesBurned: 18.0,
      );

      await databaseService.insertExerciseRecord(pushUpRecord);
      await databaseService.insertExerciseRecord(sitUpRecord);

      // 只查询俯卧撑记录
      final pushUpRecords = await databaseService.getExerciseRecords(
        exerciseType: 'push_up',
      );

      expect(pushUpRecords.length, equals(1));
      expect(pushUpRecords.first.exerciseType, equals('push_up'));
      expect(pushUpRecords.first.reps, equals(20));
    });

    test('应该能够更新运动记录', () async {
      // 插入记录
      final record = ExerciseRecordModel(
        exerciseType: 'push_up',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 2)),
        reps: 20,
        caloriesBurned: 15.0,
        notes: '原始备注',
      );

      final insertedId = await databaseService.insertExerciseRecord(record);
      
      // 更新记录
      final updatedRecord = record.copyWith(
        id: insertedId,
        reps: 25,
        notes: '更新后的备注',
      );

      await databaseService.updateExerciseRecord(updatedRecord);

      // 验证更新
      final records = await databaseService.getExerciseRecords();
      final found = records.firstWhere((r) => r.id == insertedId);
      
      expect(found.reps, equals(25));
      expect(found.notes, equals('更新后的备注'));
    });

    test('应该能够删除运动记录', () async {
      // 插入记录
      final record = ExerciseRecordModel(
        exerciseType: 'push_up',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 2)),
        reps: 20,
        caloriesBurned: 15.0,
      );

      final insertedId = await databaseService.insertExerciseRecord(record);
      
      // 验证记录存在
      var records = await databaseService.getExerciseRecords();
      expect(records.any((r) => r.id == insertedId), isTrue);

      // 删除记录
      await databaseService.deleteExerciseRecord(insertedId);

      // 验证记录已删除
      records = await databaseService.getExerciseRecords();
      expect(records.any((r) => r.id == insertedId), isFalse);
    });

    test('应该能够获取运动统计', () async {
      final now = DateTime.now();
      
      // 插入多条记录
      final records = [
        ExerciseRecordModel(
          exerciseType: 'push_up',
          startTime: now,
          endTime: now.add(const Duration(minutes: 2)),
          reps: 20,
          caloriesBurned: 15.0,
        ),
        ExerciseRecordModel(
          exerciseType: 'push_up',
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 1, minutes: 3)),
          reps: 25,
          caloriesBurned: 18.0,
        ),
        ExerciseRecordModel(
          exerciseType: 'sit_up',
          startTime: now.add(const Duration(hours: 2)),
          endTime: now.add(const Duration(hours: 2, minutes: 2)),
          reps: 30,
          caloriesBurned: 20.0,
        ),
      ];

      for (final record in records) {
        await databaseService.insertExerciseRecord(record);
      }

      // 获取统计数据
      final allRecords = await databaseService.getExerciseRecords();
      expect(allRecords.length, equals(3));
      
      final totalReps = allRecords.fold<int>(0, (sum, record) => sum + record.reps);
      expect(totalReps, equals(75));
      
      final totalCalories = allRecords.fold<double>(0, (sum, record) => sum + record.caloriesBurned);
      expect(totalCalories, equals(53.0));
    });
  });
}