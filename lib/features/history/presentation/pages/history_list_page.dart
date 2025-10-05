import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/exercise_record_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_message.dart';
import '../widgets/exercise_record_card.dart';
import 'exercise_record_detail_page.dart';

/// 运动历史记录列表页面
class HistoryListPage extends StatefulWidget {
  /// 可选的日期过滤器
  final DateTime? filterDate;
  
  /// 可选的运动类型过滤器
  final String? exerciseType;

  const HistoryListPage({
    Key? key,
    this.filterDate,
    this.exerciseType,
  }) : super(key: key);

  @override
  State<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends State<HistoryListPage> {
  late Future<List<ExerciseRecordModel>> _recordsFuture;
  String _sortBy = 'date'; // 'date', 'type', 'duration', 'calories'
  bool _ascending = false;
  String? _filterType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _filterType = widget.exerciseType;
    if (widget.filterDate != null) {
      _startDate = DateTime(
        widget.filterDate!.year,
        widget.filterDate!.month,
        widget.filterDate!.day,
      );
      _endDate = _startDate!.add(const Duration(days: 1));
    }
    _loadRecords();
  }

  void _loadRecords() {
    final databaseService = context.read<DatabaseService>();
    _recordsFuture = databaseService.getExerciseRecords(
      startDate: _startDate,
      endDate: _endDate,
      exerciseType: _filterType,
    ).then((records) {
      // 排序记录
      records.sort((a, b) {
        switch (_sortBy) {
          case 'date':
            return _ascending 
                ? a.startTime.compareTo(b.startTime)
                : b.startTime.compareTo(a.startTime);
          case 'type':
            final typeComparison = a.exerciseType.compareTo(b.exerciseType);
            return _ascending ? typeComparison : -typeComparison;
          case 'duration':
            final durationA = a.endTime?.difference(a.startTime).inMinutes ?? 0;
            final durationB = b.endTime?.difference(b.startTime).inMinutes ?? 0;
            return _ascending 
                ? durationA.compareTo(durationB)
                : durationB.compareTo(durationA);
          case 'calories':
            return _ascending 
                ? a.caloriesBurned.compareTo(b.caloriesBurned)
                : b.caloriesBurned.compareTo(a.caloriesBurned);
          default:
            return b.startTime.compareTo(a.startTime);
        }
      });
      return records;
    });
  }

  void _applySort(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _ascending = !_ascending;
      } else {
        _sortBy = sortBy;
        _ascending = false;
      }
      _loadRecords();
    });
  }

  void _applyFilter({String? exerciseType, DateTime? startDate, DateTime? endDate}) {
    setState(() {
      _filterType = exerciseType;
      _startDate = startDate;
      _endDate = endDate;
      _loadRecords();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        currentType: _filterType,
        currentStartDate: _startDate,
        currentEndDate: _endDate,
        onApply: _applyFilter,
      ),
    );
  }

  void _navigateToDetail(ExerciseRecordModel record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseRecordDetailPage(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.filterDate != null 
              ? '${widget.filterDate!.month}/${widget.filterDate!.day} 运动记录'
              : '运动历史',
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _applySort,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'date' 
                          ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.access_time,
                    ),
                    const SizedBox(width: 8),
                    const Text('按时间'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'type',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'type' 
                          ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.fitness_center,
                    ),
                    const SizedBox(width: 8),
                    const Text('按类型'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'duration',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'duration' 
                          ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.timer,
                    ),
                    const SizedBox(width: 8),
                    const Text('按时长'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'calories',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'calories' 
                          ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                          : Icons.local_fire_department,
                    ),
                    const SizedBox(width: 8),
                    const Text('按卡路里'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<ExerciseRecordModel>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return ErrorMessage(
              message: '加载运动记录失败',
              error: snapshot.error,
              onRetry: () {
                setState(() {
                  _loadRecords();
                });
              },
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return _buildEmptyState();
          }

          return _buildRecordsList(records);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _filterType != null || _startDate != null 
                ? '没有符合条件的运动记录'
                : '还没有运动记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filterType != null || _startDate != null 
                ? '尝试调整筛选条件'
                : '开始您的第一次运动吧！',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<ExerciseRecordModel> records) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          child: ExerciseRecordCard(
            record: record,
            onTap: () => _navigateToDetail(record),
          ),
        );
      },
    );
  }
}

/// 筛选对话框
class _FilterDialog extends StatefulWidget {
  final String? currentType;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;
  final Function({String? exerciseType, DateTime? startDate, DateTime? endDate}) onApply;

  const _FilterDialog({
    Key? key,
    this.currentType,
    this.currentStartDate,
    this.currentEndDate,
    required this.onApply,
  }) : super(key: key);

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
    _startDate = widget.currentStartDate;
    _endDate = widget.currentEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('筛选条件'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('运动类型'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _selectedType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('全部')),
              DropdownMenuItem(value: 'push_up', child: Text('俯卧撑')),
              DropdownMenuItem(value: 'pull_up', child: Text('引体向上')),
              DropdownMenuItem(value: 'sit_up', child: Text('仰卧起坐')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('时间范围'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                      });
                    }
                  },
                  child: Text(
                    _startDate != null 
                        ? '${_startDate!.month}/${_startDate!.day}'
                        : '开始日期',
                  ),
                ),
              ),
              const Text(' - '),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _endDate = date;
                      });
                    }
                  },
                  child: Text(
                    _endDate != null 
                        ? '${_endDate!.month}/${_endDate!.day}'
                        : '结束日期',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedType = null;
              _startDate = null;
              _endDate = null;
            });
          },
          child: const Text('清除'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(
              exerciseType: _selectedType,
              startDate: _startDate,
              endDate: _endDate,
            );
            Navigator.pop(context);
          },
          child: const Text('应用'),
        ),
      ],
    );
  }
}