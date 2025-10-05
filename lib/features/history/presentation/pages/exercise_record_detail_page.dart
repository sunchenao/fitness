import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/exercise_record_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/calorie_calculation_engine.dart';
import '../../../../shared/widgets/loading_indicator.dart';

/// 运动记录详情页面
class ExerciseRecordDetailPage extends StatefulWidget {
  final ExerciseRecordModel record;

  const ExerciseRecordDetailPage({
    Key? key,
    required this.record,
  }) : super(key: key);

  @override
  State<ExerciseRecordDetailPage> createState() => _ExerciseRecordDetailPageState();
}

class _ExerciseRecordDetailPageState extends State<ExerciseRecordDetailPage> {
  late ExerciseRecordModel _record;
  bool _isEditing = false;
  final _notesController = TextEditingController();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _notesController.text = _record.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateNotes() async {
    if (_isEditing) {
      try {
        final databaseService = context.read<DatabaseService>();
        final updatedRecord = _record.copyWith(notes: _notesController.text.trim());
        
        await databaseService.updateExerciseRecord(updatedRecord);
        
        setState(() {
          _record = updatedRecord;
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('备注已更新')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('更新失败: $e')),
          );
        }
      }
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  Future<void> _deleteRecord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后将无法恢复，确定要删除这条运动记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final databaseService = context.read<DatabaseService>();
        await databaseService.deleteExerciseRecord(_record.id!);
        
        if (mounted) {
          Navigator.pop(context, true); // 返回 true 表示已删除
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('运动记录已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(_getExerciseTypeText()),
        backgroundColor: _getExerciseColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteRecord,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildStatsCard(),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildTimeCard(),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildNotesCard(),
            const SizedBox(height: AppConstants.paddingMedium),
            _buildCalorieDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getExerciseColor(),
              _getExerciseColor().withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Column(
          children: [
            Icon(
              _getExerciseIcon(),
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              _getExerciseTypeText(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatFullDateTime(_record.startTime),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final duration = _record.endTime != null
        ? _record.endTime!.difference(_record.startTime)
        : Duration.zero;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '运动数据',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.repeat,
                    label: '完成次数',
                    value: '${_record.reps}',
                    unit: '次',
                    color: AppConstants.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    label: '运动时长',
                    value: _formatDuration(duration),
                    unit: '',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_fire_department,
                    label: '消耗卡路里',
                    value: _record.caloriesBurned.toStringAsFixed(1),
                    unit: 'kcal',
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.speed,
                    label: '平均频率',
                    value: _calculateAverageFrequency(),
                    unit: '次/分',
                    color: Colors.green,
                  ),
                ),
              ],
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
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: color,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeCard() {
    final endTime = _record.endTime ?? _record.startTime;
    final duration = endTime.difference(_record.startTime);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '时间详情',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeRow(
              icon: Icons.play_arrow,
              label: '开始时间',
              time: _record.startTime,
            ),
            const SizedBox(height: 8),
            _buildTimeRow(
              icon: Icons.stop,
              label: '结束时间',
              time: endTime,
            ),
            const SizedBox(height: 8),
            _buildTimeRow(
              icon: Icons.hourglass_bottom,
              label: '持续时间',
              duration: duration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    DateTime? time,
    Duration? duration,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          time != null 
              ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}'
              : _formatDuration(duration!),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '运动备注',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _updateNotes,
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  label: Text(_isEditing ? '保存' : '编辑'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: '添加运动备注...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Text(
                  _record.notes?.isNotEmpty == true 
                      ? _record.notes!
                      : '暂无备注',
                  style: TextStyle(
                    color: _record.notes?.isNotEmpty == true 
                        ? Colors.black87
                        : Colors.grey[500],
                    fontStyle: _record.notes?.isNotEmpty == true 
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '卡路里详情',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '本次运动消耗了 ${_record.caloriesBurned.toStringAsFixed(1)} 千卡',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '计算基于：${_record.reps} 次 ${_getExerciseTypeText()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '平均每次消耗: ${(_record.caloriesBurned / _record.reps).toStringAsFixed(2)} 千卡',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExerciseTypeText() {
    switch (_record.exerciseType) {
      case 'push_up':
        return '俯卧撑';
      case 'pull_up':
        return '引体向上';
      case 'sit_up':
        return '仰卧起坐';
      default:
        return _record.exerciseType;
    }
  }

  IconData _getExerciseIcon() {
    switch (_record.exerciseType) {
      case 'push_up':
        return Icons.fitness_center;
      case 'pull_up':
        return Icons.accessibility_new;
      case 'sit_up':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getExerciseColor() {
    switch (_record.exerciseType) {
      case 'push_up':
        return AppConstants.pushUpColor;
      case 'pull_up':
        return AppConstants.pullUpColor;
      case 'sit_up':
        return AppConstants.sitUpColor;
      default:
        return AppConstants.primaryColor;
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
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

  String _calculateAverageFrequency() {
    final duration = _record.endTime != null
        ? _record.endTime!.difference(_record.startTime)
        : Duration.zero;
    
    if (duration.inSeconds == 0) {
      return '0';
    }
    
    final frequency = (_record.reps / duration.inMinutes);
    return frequency.toStringAsFixed(1);
  }
}