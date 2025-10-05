import 'package:flutter/material.dart';
import '../../../../core/models/exercise_record_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/calorie_calculation_engine.dart';

/// 运动记录卡片组件
class ExerciseRecordCard extends StatelessWidget {
  final ExerciseRecordModel record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDate;

  const ExerciseRecordCard({
    Key? key,
    required this.record,
    this.onTap,
    this.onDelete,
    this.showDate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: 8),
              _buildStats(context, theme),
              if (record.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildNotes(context, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        _buildExerciseIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getExerciseTypeText(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showDate) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(record.startTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onDelete != null)
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  Widget _buildExerciseIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (record.exerciseType) {
      case 'push_up':
        iconData = Icons.fitness_center;
        iconColor = AppConstants.pushUpColor;
        break;
      case 'pull_up':
        iconData = Icons.accessibility_new;
        iconColor = AppConstants.pullUpColor;
        break;
      case 'sit_up':
        iconData = Icons.self_improvement;
        iconColor = AppConstants.sitUpColor;
        break;
      default:
        iconData = Icons.fitness_center;
        iconColor = AppConstants.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildStats(BuildContext context, ThemeData theme) {
    final duration = record.endTime != null
        ? record.endTime!.difference(record.startTime)
        : Duration.zero;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.repeat,
            label: '次数',
            value: '${record.reps}',
            color: AppConstants.primaryColor,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.timer,
            label: '时长',
            value: _formatDuration(duration),
            color: Colors.orange,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.local_fire_department,
            label: '卡路里',
            value: '${record.caloriesBurned.toStringAsFixed(1)}',
            color: Colors.red,
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Text(
        record.notes!,
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getExerciseTypeText() {
    switch (record.exerciseType) {
      case 'push_up':
        return '俯卧撑';
      case 'pull_up':
        return '引体向上';
      case 'sit_up':
        return '仰卧起坐';
      default:
        return record.exerciseType;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String datePrefix;
    if (recordDate == today) {
      datePrefix = '今天';
    } else if (recordDate == yesterday) {
      datePrefix = '昨天';
    } else {
      datePrefix = '${dateTime.month}/${dateTime.day}';
    }

    final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:'
                      '${dateTime.minute.toString().padLeft(2, '0')}';

    return '$datePrefix $timeString';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }
}

/// 紧凑版运动记录卡片
class CompactExerciseRecordCard extends StatelessWidget {
  final ExerciseRecordModel record;
  final VoidCallback? onTap;

  const CompactExerciseRecordCard({
    Key? key,
    required this.record,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = record.endTime != null
        ? record.endTime!.difference(record.startTime)
        : Duration.zero;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildExerciseIcon(),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getExerciseTypeText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${record.reps}次 • ${_formatDuration(duration)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${record.caloriesBurned.toStringAsFixed(0)}卡',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseIcon() {
    IconData iconData;
    Color iconColor;
    
    switch (record.exerciseType) {
      case 'push_up':
        iconData = Icons.fitness_center;
        iconColor = AppConstants.pushUpColor;
        break;
      case 'pull_up':
        iconData = Icons.accessibility_new;
        iconColor = AppConstants.pullUpColor;
        break;
      case 'sit_up':
        iconData = Icons.self_improvement;
        iconColor = AppConstants.sitUpColor;
        break;
      default:
        iconData = Icons.fitness_center;
        iconColor = AppConstants.primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 16,
      ),
    );
  }

  String _getExerciseTypeText() {
    switch (record.exerciseType) {
      case 'push_up':
        return '俯卧撑';
      case 'pull_up':
        return '引体向上';
      case 'sit_up':
        return '仰卧起坐';
      default:
        return record.exerciseType;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }
}