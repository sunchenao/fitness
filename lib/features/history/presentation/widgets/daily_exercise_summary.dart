import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/calorie_calculation_engine.dart';
import '../../../../core/models/exercise_record_model.dart';
import '../../../../shared/providers/exercise_provider.dart';
import '../pages/history_list_page.dart';
import 'exercise_record_card.dart';

class DailyExerciseSummary extends StatelessWidget {
  final List<ExerciseRecordModel> exerciseRecords;
  final DateTime selectedDate;

  const DailyExerciseSummary({
    super.key,
    required this.exerciseRecords,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();
    final user = exerciseProvider.currentUser;

    if (user == null) {
      return const Center(child: Text('用户信息不可用'));
    }

    // 计算汇总数据
    final summary = _calculateSummary(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日汇总卡片
        _buildSummaryCard(summary),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        // 运动记录列表
        _buildRecordsList(),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
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
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '当日汇总',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.paddingMedium),
          
          // 汇总数据
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.fitness_center,
                  label: '训练次数',
                  value: summary['totalSessions'].toString(),
                  color: AppConstants.primaryColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.numbers,
                  label: '总次数',
                  value: summary['totalReps'].toString(),
                  color: AppConstants.successColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.local_fire_department,
                  label: '卡路里',
                  value: summary['totalCalories'].toStringAsFixed(0),
                  color: AppConstants.warningColor,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.timer,
                  label: '时长',
                  value: _formatDuration(summary['totalDuration']),
                  color: AppConstants.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildRecordsList() {
    // 按时间排序（最新的在前）
    final sortedRecords = List<ExerciseRecordModel>.from(exerciseRecords)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 列表标题
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '训练记录',
              style: TextStyle(
                fontSize: AppConstants.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimaryColor,
              ),
            ),
            const Spacer(),
            Text(
              '${sortedRecords.length} 次',
              style: const TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: AppConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryListPage(
                      filterDate: selectedDate,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '查看详细',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeSmall,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.paddingSmall),
        
        // 记录列表
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedRecords.length,
          separatorBuilder: (context, index) => const SizedBox(
            height: AppConstants.paddingSmall,
          ),
          itemBuilder: (context, index) {
            return ExerciseRecordCard(
              record: sortedRecords[index],
              showDate: false, // 在日历页面不显示日期
            );
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateSummary(dynamic user) {
    int totalSessions = exerciseRecords.length;
    int totalReps = 0;
    int totalDuration = 0;
    double totalCalories = 0.0;

    final calculationEngine = ExerciseCalculationEngine.instance;

    for (final record in exerciseRecords) {
      totalReps += record.reps;
      
      final duration = record.endTime != null
          ? record.endTime!.difference(record.startTime)
          : Duration.zero;
      totalDuration += duration.inSeconds;

      // 使用记录中已计算的卡路里
      totalCalories += record.caloriesBurned;
    }

    return {
      'totalSessions': totalSessions,
      'totalReps': totalReps,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
    };
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