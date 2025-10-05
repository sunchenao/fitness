import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/navigation_service.dart';
import '../../../shared/providers/exercise_provider.dart';
import '../../../shared/providers/settings_provider.dart';
import '../widgets/exercise_counter_widget.dart';
import '../widgets/exercise_progress_ring.dart';
import '../widgets/exercise_control_panel.dart';
import '../widgets/exercise_stats_panel.dart';

class ExerciseMonitoringPage extends StatefulWidget {
  final String exerciseType;

  const ExerciseMonitoringPage({
    super.key,
    required this.exerciseType,
  });

  @override
  State<ExerciseMonitoringPage> createState() => _ExerciseMonitoringPageState();
}

class _ExerciseMonitoringPageState extends State<ExerciseMonitoringPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  Timer? _uiUpdateTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeExercise();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _initializeExercise() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final exerciseProvider = context.read<ExerciseProvider>();
      
      try {
        await exerciseProvider.startExercise(widget.exerciseType);
        
        // 开始UI更新定时器
        _uiUpdateTimer = Timer.periodic(
          const Duration(milliseconds: 100),
          (_) => _updateProgress(),
        );
        
        setState(() {
          _isInitialized = true;
        });
      } catch (e) {
        _showErrorDialog('初始化运动失败: $e');
      }
    });
  }

  void _updateProgress() {
    if (mounted) {
      final exerciseProvider = context.read<ExerciseProvider>();
      final progress = exerciseProvider.countProgress;
      
      if (progress != _progressAnimation.value) {
        _progressController.animateTo(progress);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Consumer<ExerciseProvider>(
          builder: (context, exerciseProvider, child) {
            return Column(
              children: [
                _buildAppBar(exerciseProvider),
                Expanded(
                  child: _buildMainContent(exerciseProvider),
                ),
                _buildBottomControls(exerciseProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(ExerciseProvider exerciseProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleBackPressed,
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  AppConstants.exerciseNames[widget.exerciseType] ?? widget.exerciseType,
                  style: const TextStyle(
                    fontSize: AppConstants.fontSizeTitle,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
                ),
                Text(
                  _getExercisePhaseText(exerciseProvider.exerciseState),
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeMedium,
                    color: _getPhaseColor(exerciseProvider.exerciseState),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(
              Icons.settings,
              color: AppConstants.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ExerciseProvider exerciseProvider) {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
            SizedBox(height: AppConstants.paddingMedium),
            Text(
              '正在初始化运动检测...',
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                color: AppConstants.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          // 主要计数和进度显示区域
          Expanded(
            flex: 3,
            child: _buildCounterSection(exerciseProvider),
          ),
          
          const SizedBox(height: AppConstants.paddingLarge),
          
          // 统计数据面板
          Expanded(
            flex: 2,
            child: ExerciseStatsPanel(
              currentCount: exerciseProvider.currentCount,
              targetCount: exerciseProvider.targetCount,
              calories: exerciseProvider.currentCalories,
              duration: exerciseProvider.activeDuration,
              exerciseType: widget.exerciseType,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterSection(ExerciseProvider exerciseProvider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景进度环
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return ExerciseProgressRing(
              progress: _progressAnimation.value,
              size: 280,
              strokeWidth: 12,
              backgroundColor: AppConstants.cardColor,
              progressColor: AppConstants.primaryColor,
            );
          },
        ),
        
        // 中心计数器
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: exerciseProvider.exerciseState == ExerciseState.active 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: ExerciseCounterWidget(
                count: exerciseProvider.currentCount,
                targetCount: exerciseProvider.targetCount,
                isActive: exerciseProvider.exerciseState == ExerciseState.active,
                onTap: () => _handleCounterTap(exerciseProvider),
                onLongPress: () => _showManualAdjustDialog(exerciseProvider),
              ),
            );
          },
        ),
        
        // 进度指示器
        Positioned(
          bottom: 40,
          child: _buildProgressIndicator(exerciseProvider),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(ExerciseProvider exerciseProvider) {
    final progress = exerciseProvider.countProgress;
    final percentage = (progress * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$percentage% 完成',
        style: const TextStyle(
          fontSize: AppConstants.fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildBottomControls(ExerciseProvider exerciseProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ExerciseControlPanel(
        exerciseState: exerciseProvider.exerciseState,
        onPause: () => _handlePause(exerciseProvider),
        onResume: () => _handleResume(exerciseProvider),
        onStop: () => _handleStop(exerciseProvider),
        onReset: () => _handleReset(exerciseProvider),
      ),
    );
  }

  // 事件处理方法
  void _handleBackPressed() {
    final exerciseProvider = context.read<ExerciseProvider>();
    
    if (exerciseProvider.exerciseState == ExerciseState.active ||
        exerciseProvider.exerciseState == ExerciseState.paused) {
      _showExitConfirmDialog();
    } else {
      NavigationService.pop();
    }
  }

  void _handleCounterTap(ExerciseProvider exerciseProvider) {
    // 手动计数（用于测试或辅助）
    if (exerciseProvider.exerciseState == ExerciseState.active) {
      HapticFeedback.lightImpact();
      exerciseProvider.incrementCount();
    }
  }

  void _handlePause(ExerciseProvider exerciseProvider) {
    exerciseProvider.pauseExercise();
    HapticFeedback.mediumImpact();
  }

  void _handleResume(ExerciseProvider exerciseProvider) {
    exerciseProvider.resumeExercise();
    HapticFeedback.lightImpact();
  }

  void _handleStop(ExerciseProvider exerciseProvider) {
    _showStopConfirmDialog(exerciseProvider);
  }

  void _handleReset(ExerciseProvider exerciseProvider) {
    _showResetConfirmDialog(exerciseProvider);
  }

  // 辅助方法
  String _getExercisePhaseText(ExerciseState state) {
    switch (state) {
      case ExerciseState.idle:
        return '待机中';
      case ExerciseState.preparing:
        return '准备中...';
      case ExerciseState.active:
        return '运动中';
      case ExerciseState.paused:
        return '已暂停';
      case ExerciseState.completed:
        return '已完成';
    }
  }

  Color _getPhaseColor(ExerciseState state) {
    switch (state) {
      case ExerciseState.idle:
        return AppConstants.textSecondaryColor;
      case ExerciseState.preparing:
        return AppConstants.warningColor;
      case ExerciseState.active:
        return AppConstants.successColor;
      case ExerciseState.paused:
        return AppConstants.warningColor;
      case ExerciseState.completed:
        return AppConstants.primaryColor;
    }
  }

  // 对话框方法
  void _showExitConfirmDialog() {
    NavigationService.showConfirmDialog(
      title: '退出运动',
      content: '运动正在进行中，确定要退出吗？',
      confirmText: '退出',
      cancelText: '继续',
      confirmColor: AppConstants.errorColor,
    ).then((confirmed) {
      if (confirmed == true) {
        final exerciseProvider = context.read<ExerciseProvider>();
        exerciseProvider.stopExercise();
        NavigationService.pop();
      }
    });
  }

  void _showStopConfirmDialog(ExerciseProvider exerciseProvider) {
    NavigationService.showConfirmDialog(
      title: '结束运动',
      content: '确定要结束当前运动吗？',
      confirmText: '结束',
      cancelText: '取消',
    ).then((confirmed) {
      if (confirmed == true) {
        exerciseProvider.stopExercise();
        _showResultDialog(exerciseProvider);
      }
    });
  }

  void _showResetConfirmDialog(ExerciseProvider exerciseProvider) {
    NavigationService.showConfirmDialog(
      title: '重置运动',
      content: '确定要重置当前运动数据吗？',
      confirmText: '重置',
      cancelText: '取消',
      confirmColor: AppConstants.warningColor,
    ).then((confirmed) {
      if (confirmed == true) {
        exerciseProvider.resetExercise();
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _showManualAdjustDialog(ExerciseProvider exerciseProvider) {
    final TextEditingController controller = TextEditingController(
      text: exerciseProvider.currentCount.toString(),
    );

    NavigationService.showAppDialog(
      child: AlertDialog(
        title: const Text('手动调整计数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '运动次数',
            border: OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationService.pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final newCount = int.tryParse(controller.text) ?? 0;
              if (newCount >= 0) {
                exerciseProvider.setCount(newCount);
                NavigationService.pop();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(ExerciseProvider exerciseProvider) {
    NavigationService.showAppDialog(
      child: AlertDialog(
        title: const Text('运动完成！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('运动类型: ${AppConstants.exerciseNames[widget.exerciseType]}'),
            Text('完成次数: ${exerciseProvider.currentCount}'),
            Text('运动时长: ${_formatDuration(exerciseProvider.activeDuration)}'),
            Text('消耗卡路里: ${exerciseProvider.currentCalories.toStringAsFixed(1)} 大卡'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              NavigationService.pop();
              NavigationService.pop();
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final settingsProvider = context.read<SettingsProvider>();
    
    NavigationService.showAppBottomSheet(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '运动设置',
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            SwitchListTile(
              title: const Text('声音提示'),
              value: settingsProvider.soundEnabled,
              onChanged: settingsProvider.setSoundEnabled,
            ),
            SwitchListTile(
              title: const Text('震动反馈'),
              value: settingsProvider.vibrationEnabled,
              onChanged: settingsProvider.setVibrationEnabled,
            ),
            SwitchListTile(
              title: const Text('语音播报'),
              value: settingsProvider.voicePromptEnabled,
              onChanged: settingsProvider.setVoicePromptEnabled,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    NavigationService.showAppDialog(
      child: AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              NavigationService.pop();
              NavigationService.pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
}