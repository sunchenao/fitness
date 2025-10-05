import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/exercise_record_model.dart';

class CalendarExerciseIndicator extends StatelessWidget {
  final List<ExerciseRecordModel> exerciseRecords;

  const CalendarExerciseIndicator({
    super.key,
    required this.exerciseRecords,
  });

  @override
  Widget build(BuildContext context) {
    if (exerciseRecords.isEmpty) return const SizedBox.shrink();

    // 按运动类型分组
    final Map<String, int> exerciseCount = {};
    for (final record in exerciseRecords) {
      exerciseCount[record.exerciseType] = (exerciseCount[record.exerciseType] ?? 0) + 1;
    }

    // 获取主要运动类型（最多的那个）
    final sortedExercises = exerciseCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Positioned(
      bottom: 4,
      right: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主要运动类型指示器
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getExerciseColor(sortedExercises.first.key),
              shape: BoxShape.circle,
            ),
          ),
          
          // 如果有多种运动类型，显示数量
          if (exerciseCount.length > 1) ...[
            const SizedBox(width: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppConstants.textSecondaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
          
          // 如果有3种或更多运动类型，显示第三个点
          if (exerciseCount.length > 2) ...[
            const SizedBox(width: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppConstants.textHintColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getExerciseColor(String exerciseType) {
    switch (exerciseType.toLowerCase()) {
      case 'pushup':
        return AppConstants.primaryColor;
      case 'pullup':
        return AppConstants.successColor;
      case 'situp':
        return AppConstants.warningColor;
      case 'squat':
        return AppConstants.secondaryColor;
      case 'plank':
        return const Color(0xFF9C27B0);
      default:
        return AppConstants.textSecondaryColor;
    }
  }
}