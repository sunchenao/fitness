import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/exercise_provider.dart';
import '../../../../shared/providers/settings_provider.dart';

class ExerciseCardWidget extends StatefulWidget {
  final String exerciseType;
  final String exerciseName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExerciseCardWidget({
    super.key,
    required this.exerciseType,
    required this.exerciseName,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ExerciseCardWidget> createState() => _ExerciseCardWidgetState();
}

class _ExerciseCardWidgetState extends State<ExerciseCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final target = settingsProvider.getExerciseTarget(widget.exerciseType);

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            elevation: _elevationAnimation.value,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              onTapDown: (_) => _hoverController.forward(),
              onTapUp: (_) => _hoverController.reverse(),
              onTapCancel: () => _hoverController.reverse(),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      AppConstants.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 运动图标和名称
                      Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                            ),
                            child: Icon(
                              _getExerciseIcon(widget.exerciseType),
                              size: 32,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          Text(
                            widget.exerciseName,
                            style: const TextStyle(
                              fontSize: AppConstants.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      // 目标和最近记录
                      Column(
                        children: [
                          _buildInfoChip(
                            icon: Icons.flag,
                            text: '目标: $target',
                            color: AppConstants.successColor,
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String>(
                            future: _getLastRecord(),
                            builder: (context, snapshot) {
                              return _buildInfoChip(
                                icon: Icons.history,
                                text: snapshot.data ?? '暂无记录',
                                color: AppConstants.textSecondaryColor,
                              );
                            },
                          ),
                        ],
                      ),

                      // 开始按钮
                      Container(
                        width: double.infinity,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                        child: const Center(
                          child: Text(
                            '开始训练',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: AppConstants.fontSizeMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

  Future<String> _getLastRecord() async {
    try {
      final exerciseProvider = context.read<ExerciseProvider>();
      final stats = await exerciseProvider.getTodayStatistics();
      final records = stats['records'] as List? ?? [];
      
      final typeRecords = records.where((r) => r.exerciseType == widget.exerciseType).toList();
      
      if (typeRecords.isNotEmpty) {
        final lastRecord = typeRecords.first;
        return '上次: ${lastRecord.count}次';
      } else {
        return '今日未练';
      }
    } catch (e) {
      return '暂无记录';
    }
  }
}