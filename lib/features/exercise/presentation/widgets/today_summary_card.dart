import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class TodaySummaryCard extends StatelessWidget {
  final int totalSessions;
  final int totalCount;
  final double totalCalories;
  final int totalDuration;

  const TodaySummaryCard({
    super.key,
    required this.totalSessions,
    required this.totalCount,
    required this.totalCalories,
    required this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.successColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和日期
          Row(
            children: [
              Icon(
                Icons.today,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '今日概览',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Text(
                _getTodayDateString(),
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // 统计数据
          if (totalSessions == 0)
            _buildEmptyState()
          else
            _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: AppConstants.textHintColor,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          const Text(
            '今天还没有开始运动',
            style: TextStyle(
              fontSize: AppConstants.fontSizeMedium,
              color: AppConstants.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '选择一项运动开始健身吧！',
            style: TextStyle(
              fontSize: AppConstants.fontSizeSmall,
              color: AppConstants.textHintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.fitness_center,
            label: '训练次数',
            value: totalSessions.toString(),
            color: AppConstants.primaryColor,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.numbers,
            label: '总次数',
            value: totalCount.toString(),
            color: AppConstants.successColor,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.local_fire_department,
            label: '卡路里',
            value: totalCalories.toStringAsFixed(0),
            color: AppConstants.warningColor,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.timer,
            label: '时长',
            value: _formatDuration(totalDuration),
            color: AppConstants.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: AppConstants.fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: AppConstants.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.month}月${now.day}日 $weekday';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h${minutes}m';
    }
  }
}