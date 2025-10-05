import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../shared/providers/exercise_provider.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../widgets/exercise_card_widget.dart';
import '../widgets/exercise_preparation_dialog.dart';
import '../widgets/today_summary_card.dart';

class ExerciseSelectionPage extends StatefulWidget {
  const ExerciseSelectionPage({super.key});

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTodayData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(
      AppConstants.exerciseTypes.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          0.6 + (index * 0.1),
          curve: Curves.easeOutBack,
        ),
      )),
    );

    _animationController.forward();
  }

  void _loadTodayData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exerciseProvider = context.read<ExerciseProvider>();
      exerciseProvider.getTodayStatistics();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTodaySummary(),
                  const SizedBox(height: AppConstants.paddingLarge),
                  _buildSectionTitle('选择运动类型'),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildExerciseGrid(),
                  const SizedBox(height: AppConstants.paddingLarge),
                  _buildQuickActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '开始运动',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppConstants.primaryColor,
                AppConstants.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.fitness_center,
              size: 48,
              color: Colors.white54,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _showQuickSettings,
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTodaySummary() {
    return Consumer<ExerciseProvider>(
      builder: (context, exerciseProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: exerciseProvider.getTodayStatistics(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {};
            return TodaySummaryCard(
              totalSessions: stats['totalSessions'] ?? 0,
              totalCount: stats['totalCount'] ?? 0,
              totalCalories: stats['totalCalories']?.toDouble() ?? 0.0,
              totalDuration: stats['totalDuration'] ?? 0,
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppConstants.paddingSmall),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppConstants.paddingMedium,
        mainAxisSpacing: AppConstants.paddingMedium,
      ),
      itemCount: AppConstants.exerciseTypes.length,
      itemBuilder: (context, index) {
        final exerciseType = AppConstants.exerciseTypes[index];
        final exerciseName = AppConstants.exerciseNames[exerciseType] ?? exerciseType;

        return AnimatedBuilder(
          animation: _cardAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _cardAnimations[index].value,
              child: ExerciseCardWidget(
                exerciseType: exerciseType,
                exerciseName: exerciseName,
                onTap: () => _onExerciseSelected(exerciseType),
                onLongPress: () => _showExerciseInfo(exerciseType),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('快速操作'),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.history,
                title: '历史记录',
                subtitle: '查看过往训练',
                onTap: () => NavigationService.push('/history'),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.analytics,
                title: '数据统计',
                subtitle: '分析训练效果',
                onTap: () => NavigationService.push('/statistics'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 事件处理方法
  void _onExerciseSelected(String exerciseType) async {
    final settingsProvider = context.read<SettingsProvider>();
    final countdownDuration = settingsProvider.countdownDuration;

    if (countdownDuration > 0) {
      // 显示准备对话框
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExercisePreparationDialog(
          exerciseType: exerciseType,
          countdownDuration: countdownDuration,
        ),
      );

      if (confirmed == true) {
        _startExercise(exerciseType);
      }
    } else {
      _startExercise(exerciseType);
    }
  }

  void _startExercise(String exerciseType) {
    NavigationService.push(
      '/exercise-monitoring',
      arguments: exerciseType,
    );
  }

  void _showExerciseInfo(String exerciseType) {
    final exerciseName = AppConstants.exerciseNames[exerciseType] ?? exerciseType;
    final caloriesPerRep = AppConstants.caloriesPerRep[exerciseType] ?? 0.0;

    NavigationService.showAppBottomSheet(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName,
              style: const TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildInfoRow('运动类型', exerciseName),
            _buildInfoRow('每次消耗', '${caloriesPerRep.toStringAsFixed(2)} 大卡'),
            _buildInfoRow('建议目标', _getRecommendedTarget(exerciseType)),
            _buildInfoRow('主要肌群', _getTargetMuscles(exerciseType)),
            const SizedBox(height: AppConstants.paddingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  NavigationService.pop();
                  _onExerciseSelected(exerciseType);
                },
                child: const Text('开始运动'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppConstants.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickSettings() {
    final settingsProvider = context.read<SettingsProvider>();

    NavigationService.showAppBottomSheet(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '快速设置',
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            SwitchListTile(
              title: const Text('声音提示'),
              subtitle: const Text('运动时播放提示音'),
              value: settingsProvider.soundEnabled,
              onChanged: settingsProvider.setSoundEnabled,
            ),
            SwitchListTile(
              title: const Text('震动反馈'),
              subtitle: const Text('动作识别时震动提醒'),
              value: settingsProvider.vibrationEnabled,
              onChanged: settingsProvider.setVibrationEnabled,
            ),
            ListTile(
              title: const Text('倒计时时长'),
              subtitle: Text('${settingsProvider.countdownDuration} 秒'),
              trailing: DropdownButton<int>(
                value: settingsProvider.countdownDuration,
                items: [0, 3, 5, 10].map((duration) {
                  return DropdownMenuItem(
                    value: duration,
                    child: Text(duration == 0 ? '无' : '$duration 秒'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    settingsProvider.setCountdownDuration(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendedTarget(String exerciseType) {
    switch (exerciseType) {
      case 'pushup':
        return '20-30 次';
      case 'pullup':
        return '5-15 次';
      case 'situp':
        return '25-40 次';
      case 'squat':
        return '20-35 次';
      case 'plank':
        return '30-60 秒';
      default:
        return '根据个人能力';
    }
  }

  String _getTargetMuscles(String exerciseType) {
    switch (exerciseType) {
      case 'pushup':
        return '胸肌、三头肌、核心';
      case 'pullup':
        return '背阔肌、二头肌';
      case 'situp':
        return '腹直肌、髂腰肌';
      case 'squat':
        return '股四头肌、臀大肌';
      case 'plank':
        return '核心肌群、肩部';
      default:
        return '全身肌群';
    }
  }
}