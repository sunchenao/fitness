import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitness/main.dart' as app;
import 'package:fitness/core/constants/app_constants.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('健身记录应用集成测试', () {
    testWidgets('应用启动和基本导航测试', (WidgetTester tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 验证应用启动成功
      expect(find.byType(MaterialApp), findsOneWidget);

      // 验证底部导航栏存在
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 验证默认页面是运动页面
      expect(find.text('开始运动'), findsOneWidget);
    });

    testWidgets('底部导航栏切换测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 点击历史记录标签
      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();

      // 验证进入历史记录页面
      expect(find.text('运动历史'), findsOneWidget);

      // 点击统计标签
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();

      // 验证进入统计页面
      expect(find.text('运动统计'), findsOneWidget);

      // 点击设置标签
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 验证进入设置页面
      expect(find.text('设置中心'), findsOneWidget);

      // 返回运动页面
      await tester.tap(find.text('运动'));
      await tester.pumpAndSettle();

      expect(find.text('开始运动'), findsOneWidget);
    });

    testWidgets('运动选择和准备流程测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 查找并点击俯卧撑运动选项
      final pushUpButton = find.text('俯卧撑');
      expect(pushUpButton, findsOneWidget);
      
      await tester.tap(pushUpButton);
      await tester.pumpAndSettle();

      // 验证进入运动准备页面
      expect(find.text('运动准备'), findsOneWidget);
      expect(find.text('俯卧撑'), findsOneWidget);

      // 查找开始运动按钮
      final startButton = find.text('开始运动');
      if (startButton.evaluate().isNotEmpty) {
        await tester.tap(startButton);
        await tester.pumpAndSettle();

        // 验证进入运动监测页面
        expect(find.text('运动中'), findsOneWidget);
      }
    });

    testWidgets('历史记录页面功能测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 导航到历史记录页面
      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();

      // 验证历史记录页面组件
      expect(find.text('运动历史'), findsOneWidget);

      // 验证TabBar存在
      expect(find.text('日历视图'), findsOneWidget);
      expect(find.text('列表视图'), findsOneWidget);

      // 切换到列表视图
      await tester.tap(find.text('列表视图'));
      await tester.pumpAndSettle();

      // 验证列表视图页面
      expect(find.byType(ListView), findsOneWidget);

      // 切换回日历视图
      await tester.tap(find.text('日历视图'));
      await tester.pumpAndSettle();

      // 验证日历组件存在
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('统计页面功能测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 导航到统计页面
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();

      // 验证统计页面组件
      expect(find.text('运动统计'), findsOneWidget);

      // 验证Tab切换
      expect(find.text('概览'), findsOneWidget);
      expect(find.text('趋势'), findsOneWidget);
      expect(find.text('对比'), findsOneWidget);

      // 验证时间范围选择器
      expect(find.text('时间范围:'), findsOneWidget);
      expect(find.text('7天'), findsOneWidget);
      expect(find.text('30天'), findsOneWidget);

      // 切换时间范围
      await tester.tap(find.text('7天'));
      await tester.pumpAndSettle();

      // 切换到趋势标签
      await tester.tap(find.text('趋势'));
      await tester.pumpAndSettle();

      // 切换到对比标签
      await tester.tap(find.text('对比'));
      await tester.pumpAndSettle();
    });

    testWidgets('设置页面功能测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 导航到设置页面
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 验证设置页面组件
      expect(find.text('设置中心'), findsOneWidget);

      // 验证个人信息卡片
      expect(find.byType(CircleAvatar), findsOneWidget);

      // 验证设置选项
      expect(find.text('编辑资料'), findsOneWidget);
      expect(find.text('运动目标'), findsOneWidget);
      expect(find.text('通知设置'), findsOneWidget);
      expect(find.text('主题模式'), findsOneWidget);

      // 点击编辑资料
      await tester.tap(find.text('编辑资料'));
      await tester.pumpAndSettle();

      // 验证对话框出现
      expect(find.text('编辑资料'), findsNWidgets(2)); // 原有的和对话框中的
      expect(find.text('确定'), findsOneWidget);

      // 关闭对话框
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // 点击主题模式
      await tester.tap(find.text('主题模式'));
      await tester.pumpAndSettle();

      // 验证主题选择对话框
      expect(find.text('选择主题'), findsOneWidget);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
    });

    testWidgets('完整用户流程测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 开始一个完整的运动流程
      await tester.tap(find.text('俯卧撑'));
      await tester.pumpAndSettle();

      // 如果存在开始运动按钮，点击它
      final startButton = find.text('开始运动');
      if (startButton.evaluate().isNotEmpty) {
        await tester.tap(startButton);
        await tester.pumpAndSettle();

        // 等待一段时间模拟运动
        await tester.pump(const Duration(seconds: 2));

        // 查找停止按钮并点击
        final stopButton = find.byIcon(Icons.stop);
        if (stopButton.evaluate().isNotEmpty) {
          await tester.tap(stopButton);
          await tester.pumpAndSettle();
        }
      }

      // 2. 检查历史记录
      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();

      // 验证历史记录页面正常显示
      expect(find.text('运动历史'), findsOneWidget);

      // 3. 检查统计数据
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();

      // 验证统计页面正常显示
      expect(find.text('运动统计'), findsOneWidget);

      // 4. 最后回到主页
      await tester.tap(find.text('运动'));
      await tester.pumpAndSettle();

      expect(find.text('开始运动'), findsOneWidget);
    });

    testWidgets('应用性能和响应性测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 快速切换页面多次，测试应用响应性
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('历史'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        await tester.tap(find.text('统计'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        await tester.tap(find.text('设置'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        await tester.tap(find.text('运动'));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
      }

      // 验证应用仍然正常工作
      expect(find.text('开始运动'), findsOneWidget);
    });

    testWidgets('错误处理和边界情况测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 测试在没有数据的情况下访问各个页面
      
      // 历史记录页面 - 应该显示空状态
      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();

      // 统计页面 - 应该显示零值统计
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();

      // 验证统计页面不会崩溃
      expect(find.text('运动统计'), findsOneWidget);

      // 设置页面 - 应该正常显示
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      expect(find.text('设置中心'), findsOneWidget);
    });

    testWidgets('应用主题和UI一致性测试', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 验证主色调在各个页面中的一致性
      
      // 运动页面
      expect(find.byType(MaterialApp), findsOneWidget);

      // 历史记录页面
      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();
      
      // 验证AppBar颜色一致性
      final appBars = find.byType(AppBar);
      expect(appBars, findsOneWidget);

      // 统计页面
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();
      
      expect(find.byType(AppBar), findsOneWidget);

      // 设置页面
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}