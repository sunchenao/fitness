import 'package:flutter/material.dart';

import '../../features/exercise/presentation/pages/exercise_home_page.dart';
import '../../features/exercise/presentation/pages/exercise_detail_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/user_profile_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String exerciseDetail = '/exercise-detail';
  static const String history = '/history';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String userProfile = '/user-profile';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const ExerciseHomePage(),
        exerciseDetail: (context) => const ExerciseDetailPage(),
        history: (context) => const HistoryPage(),
        statistics: (context) => const StatisticsPage(),
        settings: (context) => const SettingsPage(),
        userProfile: (context) => const UserProfilePage(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    final arguments = settings.arguments;

    switch (routeName) {
      case exerciseDetail:
        if (arguments is String) {
          return MaterialPageRoute(
            builder: (context) => ExerciseDetailPage(exerciseType: arguments),
            settings: settings,
          );
        }
        break;
      default:
        break;
    }

    // 如果没有匹配的路由，返回404页面
    return MaterialPageRoute(
      builder: (context) => const NotFoundPage(),
      settings: settings,
    );
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => const NotFoundPage(),
      settings: settings,
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('页面不存在'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '抱歉，您访问的页面不存在',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}