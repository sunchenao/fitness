import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/features/history/presentation/widgets/exercise_record_card.dart';
import 'package:fitness/core/models/exercise_record_model.dart';

void main() {
  group('ExerciseRecordCard Widget Tests', () {
    late ExerciseRecordModel testRecord;

    setUp(() {
      testRecord = ExerciseRecordModel(
        id: 1,
        exerciseType: 'push_up',
        startTime: DateTime(2024, 1, 15, 10, 30),
        endTime: DateTime(2024, 1, 15, 10, 32),
        reps: 20,
        caloriesBurned: 15.5,
        notes: '测试运动记录',
      );
    });

    testWidgets('应该显示运动记录基本信息', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(record: testRecord),
          ),
        ),
      );

      // 验证运动类型显示
      expect(find.text('俯卧撑'), findsOneWidget);
      
      // 验证次数显示
      expect(find.text('20'), findsOneWidget);
      
      // 验证卡路里显示
      expect(find.text('15.5'), findsOneWidget);
      
      // 验证备注显示
      expect(find.text('测试运动记录'), findsOneWidget);
    });

    testWidgets('应该显示正确的运动图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(record: testRecord),
          ),
        ),
      );

      // 验证俯卧撑图标存在
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('应该正确处理点击事件', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(
              record: testRecord,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // 点击卡片
      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('应该显示删除按钮当提供删除回调时', (WidgetTester tester) async {
      bool deleted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(
              record: testRecord,
              onDelete: () {
                deleted = true;
              },
            ),
          ),
        ),
      );

      // 验证删除按钮存在
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // 点击删除按钮
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(deleted, isTrue);
    });

    testWidgets('应该根据showDate参数显示或隐藏日期', (WidgetTester tester) async {
      // 测试显示日期
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(
              record: testRecord,
              showDate: true,
            ),
          ),
        ),
      );

      // 应该找到日期相关文本
      expect(find.textContaining('10:30'), findsOneWidget);

      // 测试隐藏日期
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(
              record: testRecord,
              showDate: false,
            ),
          ),
        ),
      );

      // 不应该找到日期相关文本
      expect(find.textContaining('10:30'), findsNothing);
    });

    testWidgets('应该正确显示不同运动类型', (WidgetTester tester) async {
      final pullUpRecord = testRecord.copyWith(exerciseType: 'pull_up');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(record: pullUpRecord),
          ),
        ),
      );

      expect(find.text('引体向上'), findsOneWidget);
      expect(find.byIcon(Icons.accessibility_new), findsOneWidget);
    });

    testWidgets('应该正确格式化时长显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(record: testRecord),
          ),
        ),
      );

      // 验证时长显示（2分钟）
      expect(find.text('2分0秒'), findsOneWidget);
    });

    testWidgets('应该处理没有备注的情况', (WidgetTester tester) async {
      final recordWithoutNotes = testRecord.copyWith(notes: null);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseRecordCard(record: recordWithoutNotes),
          ),
        ),
      );

      // 不应该找到备注容器
      expect(find.text('测试运动记录'), findsNothing);
    });
  });

  group('CompactExerciseRecordCard Widget Tests', () {
    late ExerciseRecordModel testRecord;

    setUp(() {
      testRecord = ExerciseRecordModel(
        id: 1,
        exerciseType: 'sit_up',
        startTime: DateTime(2024, 1, 15, 10, 30),
        endTime: DateTime(2024, 1, 15, 10, 32, 30),
        reps: 25,
        caloriesBurned: 18.0,
      );
    });

    testWidgets('应该显示紧凑版运动记录信息', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExerciseRecordCard(record: testRecord),
          ),
        ),
      );

      // 验证运动类型显示
      expect(find.text('仰卧起坐'), findsOneWidget);
      
      // 验证次数和时长显示
      expect(find.textContaining('25次'), findsOneWidget);
      expect(find.textContaining('2分30秒'), findsOneWidget);
      
      // 验证卡路里显示
      expect(find.text('18卡'), findsOneWidget);
    });

    testWidgets('应该正确处理点击事件', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExerciseRecordCard(
              record: testRecord,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('应该显示正确的图标和颜色', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExerciseRecordCard(record: testRecord),
          ),
        ),
      );

      // 验证仰卧起坐图标
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    });

    testWidgets('应该正确格式化短时长', (WidgetTester tester) async {
      final shortRecord = testRecord.copyWith(
        endTime: testRecord.startTime.add(const Duration(seconds: 45)),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactExerciseRecordCard(record: shortRecord),
          ),
        ),
      );

      expect(find.textContaining('45秒'), findsOneWidget);
    });
  });
}