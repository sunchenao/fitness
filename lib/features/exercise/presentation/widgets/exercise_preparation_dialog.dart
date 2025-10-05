import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';

class ExercisePreparationDialog extends StatefulWidget {
  final String exerciseType;
  final int countdownDuration;

  const ExercisePreparationDialog({
    super.key,
    required this.exerciseType,
    required this.countdownDuration,
  });

  @override
  State<ExercisePreparationDialog> createState() => _ExercisePreparationDialogState();
}

class _ExercisePreparationDialogState extends State<ExercisePreparationDialog>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownDuration;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _countdownController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: AppConstants.primaryColor,
      end: AppConstants.successColor,
    ).animate(_countdownController);
  }

  void _startCountdown() {
    setState(() {
      _isStarted = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      // 脉冲动画
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });

      // 震动反馈
      HapticFeedback.mediumImpact();

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onCountdownComplete();
      }
    });
  }

  void _onCountdownComplete() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseName = AppConstants.exerciseNames[widget.exerciseType] ?? widget.exerciseType;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '准备开始',
              style: const TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimaryColor,
              ),
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            // 运动类型
            Text(
              exerciseName,
              style: TextStyle(
                fontSize: AppConstants.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // 倒计时显示
            if (_isStarted) ...[
              AnimatedBuilder(
                animation: Listenable.merge([_pulseController, _colorAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _remainingSeconds <= 3 
                            ? AppConstants.warningColor.withOpacity(0.1)
                            : AppConstants.primaryColor.withOpacity(0.1),
                        border: Border.all(
                          color: _remainingSeconds <= 3 
                              ? AppConstants.warningColor
                              : AppConstants.primaryColor,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _remainingSeconds.toString(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds <= 3 
                                ? AppConstants.warningColor
                                : AppConstants.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppConstants.paddingMedium),
              
              Text(
                _getCountdownText(),
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  color: AppConstants.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              // 准备提示
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getExerciseIcon(widget.exerciseType),
                      size: 48,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      '请确保：',
                      style: const TextStyle(
                        fontSize: AppConstants.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    ...(_getPreparationTips(widget.exerciseType).map((tip) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppConstants.successColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: AppConstants.fontSizeSmall,
                                  color: AppConstants.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppConstants.paddingLarge),

            // 按钮
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isStarted ? null : _startCountdown,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isStarted ? '倒计时中...' : '开始倒计时'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCountdownText() {
    if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
      return '准备就绪！';
    } else if (_remainingSeconds > 3) {
      return '请调整姿势';
    } else {
      return '开始运动！';
    }
  }

  IconData _getExerciseIcon(String exerciseType) {
    switch (exerciseType) {
      case 'pushup':
        return Icons.fitness_center;
      case 'pullup':
        return Icons.sports_gymnastics;
      case 'situp':
        return Icons.self_improvement;
      case 'squat':
        return Icons.sports_kabaddi;
      case 'plank':
        return Icons.timer;
      default:
        return Icons.fitness_center;
    }
  }

  List<String> _getPreparationTips(String exerciseType) {
    switch (exerciseType) {
      case 'pushup':
        return [
          '将手机放在胸部附近',
          '保持身体成一条直线',
          '双手撑地与肩同宽',
        ];
      case 'pullup':
        return [
          '将手机放在胸前口袋',
          '双手握住单杠',
          '身体自然悬垂',
        ];
      case 'situp':
        return [
          '将手机放在胸部位置',
          '平躺并屈膝',
          '双手交叉抱胸',
        ];
      case 'squat':
        return [
          '将手机放在胸前',
          '双脚与肩同宽站立',
          '保持背部挺直',
        ];
      case 'plank':
        return [
          '将手机放在背部',
          '用前臂和脚尖支撑',
          '保持身体平直',
        ];
      default:
        return [
          '将手机放在合适位置',
          '保持正确姿势',
          '准备开始运动',
        ];
    }
  }
}