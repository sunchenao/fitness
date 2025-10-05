import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/exercise_provider.dart';

class ExerciseControlPanel extends StatelessWidget {
  final ExerciseState exerciseState;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onReset;

  const ExerciseControlPanel({
    super.key,
    required this.exerciseState,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 暂停/继续按钮
        _buildControlButton(
          onPressed: _getPauseResumeAction(),
          icon: _getPauseResumeIcon(),
          label: _getPauseResumeLabel(),
          color: _getPauseResumeColor(),
          enabled: _isPauseResumeEnabled(),
        ),
        
        // 停止按钮
        _buildControlButton(
          onPressed: onStop,
          icon: Icons.stop_rounded,
          label: '结束',
          color: AppConstants.errorColor,
          enabled: exerciseState == ExerciseState.active ||
              exerciseState == ExerciseState.paused,
        ),
        
        // 重置按钮
        _buildControlButton(
          onPressed: onReset,
          icon: Icons.refresh_rounded,
          label: '重置',
          color: AppConstants.warningColor,
          enabled: exerciseState != ExerciseState.idle,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool enabled = true,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: enabled ? () {
            HapticFeedback.mediumImpact();
            onPressed?.call();
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled ? color : Colors.grey[300],
            foregroundColor: enabled ? Colors.white : Colors.grey[600],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            ),
            elevation: enabled ? 4 : 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 暂停/继续按钮的动作
  VoidCallback? _getPauseResumeAction() {
    switch (exerciseState) {
      case ExerciseState.active:
        return onPause;
      case ExerciseState.paused:
        return onResume;
      default:
        return null;
    }
  }

  // 暂停/继续按钮的图标
  IconData _getPauseResumeIcon() {
    switch (exerciseState) {
      case ExerciseState.active:
        return Icons.pause_rounded;
      case ExerciseState.paused:
        return Icons.play_arrow_rounded;
      case ExerciseState.preparing:
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.play_arrow_rounded;
    }
  }

  // 暂停/继续按钮的标签
  String _getPauseResumeLabel() {
    switch (exerciseState) {
      case ExerciseState.active:
        return '暂停';
      case ExerciseState.paused:
        return '继续';
      case ExerciseState.preparing:
        return '准备中';
      case ExerciseState.completed:
        return '已完成';
      default:
        return '开始';
    }
  }

  // 暂停/继续按钮的颜色
  Color _getPauseResumeColor() {
    switch (exerciseState) {
      case ExerciseState.active:
        return AppConstants.warningColor;
      case ExerciseState.paused:
        return AppConstants.successColor;
      case ExerciseState.preparing:
        return AppConstants.primaryColor;
      case ExerciseState.completed:
        return AppConstants.primaryColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  // 暂停/继续按钮是否启用
  bool _isPauseResumeEnabled() {
    return exerciseState == ExerciseState.active ||
        exerciseState == ExerciseState.paused;
  }
}