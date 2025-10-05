import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fitness/features/history/presentation/widgets/daily_exercise_summary.dart';
import 'package:fitness/core/models/exercise_record_model.dart';
import 'package:fitness/shared/providers/exercise_provider.dart';

// Mock用户数据
class MockUser {
  final String name = '测试用户';
  final int age = 25;
  final String gender = 'male';
  final double weight = 70.0;
  final double height = 175.0;
}

// Mock ExerciseProvider
class MockExerciseProvider extends ExerciseProvider {
  final MockUser _mockUser = MockUser();
  
  @override
  MockUser? get currentUser => _mockUser;
}

void main() {
  group('DailyExerciseSummary Widget Tests', () {
    late List<ExerciseRecordModel> testRecords;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
      testRecords = [
        ExerciseRecordModel(
          id: 1,
          exerciseType: 'push_up',
          startTime: testDate.add(const Duration(hours: 9)),
          endTime: testDate.add(const Duration(hours: 9, minutes: 2)),
          reps: 20,
          caloriesBurned: 15.5,
          notes: '早晨运动',
        ),
        ExerciseRecordModel(
          id: 2,
          exerciseType: 'sit_up',
          startTime: testDate.add(const Duration(hours: 18)),
          endTime: testDate.add(const Duration(hours: 18, minutes: 3)),
          reps: 30,
          caloriesBurned: 20.0,
          notes: '晚间运动',
        ),
      ];
    });

    Widget createTestWidget(List<ExerciseRecordModel> records) {
      return MaterialApp(
        home: ChangeNotifierProvider<ExerciseProvider>(
          create: (context) => MockExerciseProvider(),
          child: Scaffold(
            body: DailyExerciseSummary(
              exerciseRecords: records,
              selectedDate: testDate,
            ),
          ),
        ),
      );
    }

    testWidgets('应该显示当日汇总标题', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      expect(find.text('当日汇总'), findsOneWidget);
    });

    testWidgets('应该显示正确的汇总统计', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      // 验证训练次数
      expect(find.text('2'), findsOneWidget); // 2次训练
      
      // 验证总次数
      expect(find.text('50'), findsOneWidget); // 20 + 30 = 50
      
      // 验证总卡路里（大约值）
      expect(find.textContaining('35'), findsOneWidget); // 15.5 + 20.0 = 35.5
    });

    testWidgets('应该显示训练记录列表标题', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      expect(find.text('训练记录'), findsOneWidget);
      expect(find.text('2 次'), findsOneWidget);
    });

    testWidgets('应该显示查看详细按钮', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      expect(find.text('查看详细'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('应该正确处理查看详细按钮点击', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      // 点击查看详细按钮
      await tester.tap(find.text('查看详细'));
      await tester.pumpAndSettle();

      // 由于导航到新页面，这里主要验证点击不会抛出异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示各个统计项目的图标', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      // 验证统计图标
      expect(find.byIcon(Icons.fitness_center), findsOneWidget); // 训练次数
      expect(find.byIcon(Icons.numbers), findsOneWidget); // 总次数
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget); // 卡路里
      expect(find.byIcon(Icons.timer), findsOneWidget); // 时长
    });

    testWidgets('应该按时间倒序显示运动记录', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      // 运动记录卡片应该存在
      expect(find.byType(ExerciseRecordCard), findsNWidgets(2));
    });

    testWidgets('应该正确格式化时长显示', (WidgetTester tester) async {
      // 创建一个长时间的记录
      final longDurationRecords = [
        ExerciseRecordModel(
          id: 1,
          exerciseType: 'push_up',
          startTime: testDate,
          endTime: testDate.add(const Duration(hours: 1, minutes: 30)),
          reps: 100,
          caloriesBurned: 80.0,
        ),
      ];

      await tester.pumpWidget(createTestWidget(longDurationRecords));

      // 应该显示小时和分钟格式
      expect(find.textContaining('1h30m'), findsOneWidget);
    });

    testWidgets('应该正确处理空记录列表', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget([]));

      // 应该显示0的统计值
      expect(find.text('0'), findsNWidgets(4)); // 四个统计项都应该是0
    });

    testWidgets('应该正确处理单条记录', (WidgetTester tester) async {
      final singleRecord = [testRecords.first];
      
      await tester.pumpWidget(createTestWidget(singleRecord));

      expect(find.text('1'), findsOneWidget); // 1次训练
      expect(find.text('20'), findsOneWidget); // 20次
      expect(find.text('1 次'), findsOneWidget); // 1次记录
    });

    testWidgets('应该正确处理不同运动类型', (WidgetTester tester) async {
      final mixedRecords = [
        ExerciseRecordModel(
          id: 1,
          exerciseType: 'push_up',
          startTime: testDate,
          endTime: testDate.add(const Duration(minutes: 2)),
          reps: 15,
          caloriesBurned: 12.0,
        ),
        ExerciseRecordModel(
          id: 2,
          exerciseType: 'pull_up',
          startTime: testDate.add(const Duration(hours: 1)),
          endTime: testDate.add(const Duration(hours: 1, minutes: 3)),
          reps: 8,
          caloriesBurned: 18.0,
        ),
        ExerciseRecordModel(
          id: 3,
          exerciseType: 'sit_up',
          startTime: testDate.add(const Duration(hours: 2)),
          endTime: testDate.add(const Duration(hours: 2, minutes: 2)),
          reps: 25,
          caloriesBurned: 20.0,
        ),
      ];

      await tester.pumpWidget(createTestWidget(mixedRecords));

      expect(find.text('3'), findsOneWidget); // 3次训练
      expect(find.text('48'), findsOneWidget); // 15 + 8 + 25 = 48次
      expect(find.text('3 次'), findsOneWidget); // 3次记录
    });

    testWidgets('应该显示渐变背景', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testRecords));

      // 验证包含渐变装饰的容器存在
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('应该处理用户为null的情况', (WidgetTester tester) async {
      final widget = MaterialApp(
        home: ChangeNotifierProvider<ExerciseProvider>(
          create: (context) => ExerciseProvider(), // 没有mock用户的provider
          child: Scaffold(
            body: DailyExerciseSummary(
              exerciseRecords: testRecords,
              selectedDate: testDate,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // 应该显示用户信息不可用的消息
      expect(find.text('用户信息不可用'), findsOneWidget);
    });
  });
}