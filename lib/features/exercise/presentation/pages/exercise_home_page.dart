import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/exercise_provider.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../../../core/constants/app_constants.dart';

class ExerciseHomePage extends StatefulWidget {
  const ExerciseHomePage({super.key});

  @override
  State<ExerciseHomePage> createState() => _ExerciseHomePageState();
}

class _ExerciseHomePageState extends State<ExerciseHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ExerciseMainView(),
          HistoryView(),
          StatisticsView(),
          SettingsView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '运动',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '记录',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

// 运动主界面
class ExerciseMainView extends StatelessWidget {
  const ExerciseMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseProvider>(
      builder: (context, exerciseProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('健身记录'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              if (exerciseProvider.errorMessage != null)
                IconButton(
                  icon: const Icon(Icons.error, color: AppConstants.errorColor),
                  onPressed: () {
                    _showErrorDialog(context, exerciseProvider.errorMessage!);
                  },
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            children: [
              // 今日统计卡片
              _buildTodayStatsCard(exerciseProvider),
              const SizedBox(height: AppConstants.paddingLarge),
              
              // 运动选择网格
              _buildExerciseGrid(context, exerciseProvider),
              
              // 当前运动状态
              if (exerciseProvider.exerciseState != ExerciseState.idle)
                _buildCurrentExerciseCard(exerciseProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayStatsCard(ExerciseProvider exerciseProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日概览',
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            FutureBuilder<Map<String, dynamic>>(
              future: exerciseProvider.getTodayStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final stats = snapshot.data ?? {};
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('训练次数', '${stats['totalSessions'] ?? 0}', Icons.fitness_center),
                    _buildStatItem('总次数', '${stats['totalCount'] ?? 0}', Icons.numbers),
                    _buildStatItem('卡路里', '${(stats['totalCalories'] ?? 0.0).toInt()}', Icons.local_fire_department),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: AppConstants.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseGrid(BuildContext context, ExerciseProvider exerciseProvider) {
    return Expanded(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: AppConstants.paddingMedium,
          mainAxisSpacing: AppConstants.paddingMedium,
        ),
        itemCount: AppConstants.exerciseTypes.length,
        itemBuilder: (context, index) {
          final exerciseType = AppConstants.exerciseTypes[index];
          final exerciseName = AppConstants.exerciseNames[exerciseType] ?? exerciseType;
          
          return _buildExerciseCard(
            context,
            exerciseType,
            exerciseName,
            _getExerciseIcon(exerciseType),
            exerciseProvider,
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    String exerciseType,
    String exerciseName,
    IconData icon,
    ExerciseProvider exerciseProvider,
  ) {
    final isActive = exerciseProvider.currentExerciseType == exerciseType;
    final canStart = exerciseProvider.exerciseState == ExerciseState.idle || 
                    exerciseProvider.exerciseState == ExerciseState.completed;

    return Card(
      color: isActive ? AppConstants.primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: canStart ? () => exerciseProvider.startExercise(exerciseType) : null,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: isActive ? AppConstants.primaryColor : AppConstants.textSecondaryColor,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                exerciseName,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppConstants.primaryColor : AppConstants.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '进行中',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppConstants.fontSizeSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentExerciseCard(ExerciseProvider exerciseProvider) {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.paddingLarge),
      child: Card(
        color: AppConstants.primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              Text(
                '当前运动: ${exerciseProvider.currentExerciseName}',
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCurrentStatItem('次数', '${exerciseProvider.currentCount}'),
                  _buildCurrentStatItem('时长', _formatDuration(exerciseProvider.activeDuration)),
                  _buildCurrentStatItem('卡路里', '${exerciseProvider.currentCalories.toInt()}'),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (exerciseProvider.exerciseState == ExerciseState.active)
                    ElevatedButton.icon(
                      onPressed: exerciseProvider.pauseExercise,
                      icon: const Icon(Icons.pause),
                      label: const Text('暂停'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.warningColor,
                      ),
                    ),
                  if (exerciseProvider.exerciseState == ExerciseState.paused)
                    ElevatedButton.icon(
                      onPressed: exerciseProvider.resumeExercise,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('继续'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: exerciseProvider.stopExercise,
                    icon: const Icon(Icons.stop),
                    label: const Text('结束'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: AppConstants.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  IconData _getExerciseIcon(String exerciseType) {
    switch (exerciseType) {
      case 'pushup':
        return Icons.fitness_center;
      case 'pullup':
        return Icons.sports_gymnastics;
      case 'situp':
        return Icons.accessibility_new;
      case 'squat':
        return Icons.sports_kabaddi;
      case 'plank':
        return Icons.timer;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}分${remainingSeconds}秒';
    } else {
      return '${remainingSeconds}秒';
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ExerciseProvider>().clearError();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// 临时的其他页面占位符
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('历史记录页面\n（待实现）', textAlign: TextAlign.center),
      ),
    );
  }
}

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('统计分析页面\n（待实现）', textAlign: TextAlign.center),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('设置页面\n（待实现）', textAlign: TextAlign.center),
      ),
    );
  }
}