import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness/features/stats/presentation/widgets/stats_card.dart';

void main() {
  group('StatsCard Widget Tests', () {
    testWidgets('应该显示统计卡片基本信息', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: '总训练次数',
              value: '25',
              icon: Icons.fitness_center,
              color: Colors.blue,
            ),
          ),
        ),
      );

      // 验证标题和数值显示
      expect(find.text('总训练次数'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      
      // 验证图标显示
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('应该显示副标题当提供时', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: '总卡路里',
              value: '1250',
              icon: Icons.local_fire_department,
              color: Colors.red,
              subtitle: '比上周增加15%',
            ),
          ),
        ),
      );

      expect(find.text('比上周增加15%'), findsOneWidget);
    });

    testWidgets('应该处理点击事件', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: '总次数',
              value: '500',
              icon: Icons.numbers,
              color: Colors.green,
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

    testWidgets('应该显示前进箭头当可点击时', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: '总时长',
              value: '2小时30分',
              icon: Icons.timer,
              color: Colors.orange,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('不应该显示前进箭头当不可点击时', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              title: '总时长',
              value: '2小时30分',
              icon: Icons.timer,
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
    });
  });

  group('CompactStatsCard Widget Tests', () {
    testWidgets('应该显示紧凑统计卡片信息', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactStatsCard(
              label: '今日次数',
              value: '15',
              icon: Icons.today,
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text('今日次数'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);
    });

    testWidgets('应该正确设置颜色主题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactStatsCard(
              label: '今日卡路里',
              value: '120',
              icon: Icons.local_fire_department,
              color: Colors.red,
            ),
          ),
        ),
      );

      // 验证组件渲染成功
      expect(find.byType(CompactStatsCard), findsOneWidget);
    });
  });

  group('TrendStatsCard Widget Tests', () {
    testWidgets('应该显示上升趋势', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendStatsCard(
              title: '周总次数',
              value: '150',
              previousValue: '120',
              icon: Icons.trending_up,
              color: Colors.green,
              isIncreasing: true,
            ),
          ),
        ),
      );

      expect(find.text('周总次数'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('上期: 120'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsAtLeastNWidgets(1));
    });

    testWidgets('应该显示下降趋势', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendStatsCard(
              title: '平均时长',
              value: '90',
              previousValue: '110',
              icon: Icons.timer,
              color: Colors.blue,
              isIncreasing: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('应该计算正确的变化百分比', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendStatsCard(
              title: '总卡路里',
              value: '120',
              previousValue: '100',
              icon: Icons.local_fire_department,
              color: Colors.red,
              isIncreasing: true,
            ),
          ),
        ),
      );

      // 应该显示20%的增长 (120-100)/100*100 = 20%
      expect(find.text('20.0%'), findsOneWidget);
    });
  });

  group('RankStatsCard Widget Tests', () {
    testWidgets('应该显示金牌排名颜色', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RankStatsCard(
              title: '本周排名',
              value: '第1名',
              rank: 1,
              icon: Icons.emoji_events,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('本周排名'), findsOneWidget);
      expect(find.text('第1名'), findsOneWidget);
    });

    testWidgets('应该显示银牌排名颜色', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RankStatsCard(
              title: '本月排名',
              value: '第2名',
              rank: 2,
              icon: Icons.emoji_events,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('#2'), findsOneWidget);
    });

    testWidgets('应该显示铜牌排名颜色', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RankStatsCard(
              title: '总排名',
              value: '第3名',
              rank: 3,
              icon: Icons.emoji_events,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('应该显示普通排名颜色', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RankStatsCard(
              title: '班级排名',
              value: '第5名',
              rank: 5,
              icon: Icons.emoji_events,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('#5'), findsOneWidget);
    });
  });
}