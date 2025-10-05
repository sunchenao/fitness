import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class ExerciseStatsPanel extends StatelessWidget {
  final int currentCount;
  final int targetCount;
  final double calories;
  final int duration;
  final String exerciseType;

  const ExerciseStatsPanel({
    super.key,
    required this.currentCount,
    required this.targetCount,
    required this.calories,
    required this.duration,
    required this.exerciseType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // 标题
            Text(
              '运动数据',
              style: const TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimaryColor,
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            // 统计数据网格
            Expanded(
              child: Row(
                children: [
                  // 左列
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatItem(
                          icon: Icons.fitness_center,
                          label: '次数',
                          value: '$currentCount',
                          subtitle: '目标: $targetCount',
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildStatItem(
                          icon: Icons.local_fire_department,
                          label: '卡路里',
                          value: calories.toStringAsFixed(1),
                          subtitle: '大卡',
                          color: AppConstants.warningColor,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.paddingMedium),
                  
                  // 右列
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatItem(
                          icon: Icons.timer,
                          label: '时长',
                          value: _formatDuration(duration),
                          subtitle: '已用时间',
                          color: AppConstants.successColor,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildStatItem(
                          icon: Icons.speed,
                          label: '配速',
                          value: _calculatePace(),
                          subtitle: '次/分钟',
                          color: AppConstants.secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            
            const SizedBox(height: 8),
            
            // 标签
            Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 主要数值
            Text(
              value,
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 2),
            
            // 副标题
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: AppConstants.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else if (minutes > 0) {
      return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${remainingSeconds}s';
    }
  }

  String _calculatePace() {
    if (duration == 0 || currentCount == 0) {
      return '0.0';
    }
    
    final pace = (currentCount / (duration / 60.0));
    return pace.toStringAsFixed(1);
  }
}