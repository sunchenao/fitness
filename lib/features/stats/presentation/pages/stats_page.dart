import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/exercise_record_model.dart';
import '../../../../shared/providers/exercise_provider.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_message.dart';
import '../widgets/stats_card.dart';

/// 统计分析页面
class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30days'; // '7days', '30days', '90days', '1year'
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStats() {
    _statsFuture = _fetchStatsData();
  }

  Future<Map<String, dynamic>> _fetchStatsData() async {
    final exerciseProvider = context.read<ExerciseProvider>();
    final user = exerciseProvider.currentUser;
    
    if (user == null) {
      throw Exception('用户信息不可用');
    }

    final databaseService = context.read<DatabaseService>();
    
    // 计算时间范围
    final now = DateTime.now();
    late DateTime startDate;
    
    switch (_selectedPeriod) {
      case '7days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '30days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '90days':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '1year':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    // 获取指定时间范围内的记录
    final records = await databaseService.getExerciseRecords(
      startDate: startDate,
      endDate: now,
    );

    return {
      'records': records,
      'totalStats': _calculateTotalStats(records),
      'exerciseTypeStats': _calculateExerciseTypeStats(records),
      'period': _selectedPeriod,
    };
  }

  Map<String, dynamic> _calculateTotalStats(List<ExerciseRecordModel> records) {
    int totalSessions = records.length;
    int totalReps = records.fold(0, (sum, record) => sum + record.reps);
    double totalCalories = records.fold(0.0, (sum, record) => sum + record.caloriesBurned);
    
    int totalDurationSeconds = 0;
    for (final record in records) {
      if (record.endTime != null) {
        totalDurationSeconds += record.endTime!.difference(record.startTime).inSeconds;
      }
    }

    return {
      'totalSessions': totalSessions,
      'totalReps': totalReps,
      'totalCalories': totalCalories,
      'totalDurationSeconds': totalDurationSeconds,
    };
  }

  Map<String, Map<String, dynamic>> _calculateExerciseTypeStats(List<ExerciseRecordModel> records) {
    final Map<String, Map<String, dynamic>> typeStats = {};

    for (final record in records) {
      final type = record.exerciseType;
      
      if (!typeStats.containsKey(type)) {
        typeStats[type] = {
          'sessions': 0,
          'reps': 0,
          'calories': 0.0,
          'duration': 0,
        };
      }

      typeStats[type]!['sessions'] += 1;
      typeStats[type]!['reps'] += record.reps;
      typeStats[type]!['calories'] += record.caloriesBurned;
      
      if (record.endTime != null) {
        typeStats[type]!['duration'] += record.endTime!.difference(record.startTime).inSeconds;
      }
    }

    return typeStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: Column(
          children: [
            _buildPeriodSelector(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildTrendsTab(),
                  _buildComparisonTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '运动统计',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: '概览'),
          Tab(icon: Icon(Icons.trending_up), text: '趋势'),
          Tab(icon: Icon(Icons.compare), text: '对比'),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Row(
        children: [
          const Text(
            '时间范围:',
            style: TextStyle(
              fontSize: AppConstants.fontSizeMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodButton('7days', '7天'),
                  _buildPeriodButton('30days', '30天'),
                  _buildPeriodButton('90days', '90天'),
                  _buildPeriodButton('1year', '1年'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedPeriod = period;
              _loadStats();
            });
          }
        },
        selectedColor: AppConstants.primaryColor.withOpacity(0.2),
        checkmarkColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError) {
          return ErrorMessage(
            message: '加载统计数据失败',
            error: snapshot.error,
            onRetry: _loadStats,
          );
        }

        final data = snapshot.data!;
        final totalStats = data['totalStats'] as Map<String, dynamic>;
        final exerciseTypeStats = data['exerciseTypeStats'] as Map<String, Map<String, dynamic>>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(totalStats),
              const SizedBox(height: AppConstants.paddingLarge),
              _buildExerciseTypeSection(exerciseTypeStats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('趋势图表', style: TextStyle(fontSize: 18)),
          Text('（图表功能待实现）', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('对比分析', style: TextStyle(fontSize: 18)),
          Text('（对比功能待实现）', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppConstants.paddingMedium,
      mainAxisSpacing: AppConstants.paddingMedium,
      childAspectRatio: 1.2,
      children: [
        StatsCard(
          title: '总训练次数',
          value: stats['totalSessions'].toString(),
          icon: Icons.fitness_center,
          color: AppConstants.primaryColor,
        ),
        StatsCard(
          title: '总次数',
          value: stats['totalReps'].toString(),
          icon: Icons.numbers,
          color: AppConstants.successColor,
        ),
        StatsCard(
          title: '总卡路里',
          value: '${stats['totalCalories'].toStringAsFixed(0)}卡',
          icon: Icons.local_fire_department,
          color: AppConstants.warningColor,
        ),
        StatsCard(
          title: '总时长',
          value: _formatDuration(stats['totalDurationSeconds']),
          icon: Icons.timer,
          color: AppConstants.secondaryColor,
        ),
      ],
    );
  }

  Widget _buildExerciseTypeSection(Map<String, Map<String, dynamic>> exerciseTypeStats) {
    if (exerciseTypeStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '运动类型分布',
          style: TextStyle(
            fontSize: AppConstants.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        ...exerciseTypeStats.entries.map((entry) {
          final type = entry.key;
          final stats = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
            child: ListTile(
              leading: _buildExerciseIcon(type),
              title: Text(_getExerciseTypeText(type)),
              subtitle: Text(
                '${stats['sessions']}次训练 • ${stats['reps']}次 • ${stats['calories'].toStringAsFixed(0)}卡',
              ),
              trailing: Text(
                '${((stats['sessions'] / exerciseTypeStats.values.fold(0, (sum, s) => sum + s['sessions'] as int)) * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _getExerciseColor(type),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExerciseIcon(String exerciseType) {
    IconData iconData;
    Color iconColor;
    
    switch (exerciseType) {
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

  String _getExerciseTypeText(String exerciseType) {
    switch (exerciseType) {
      case 'push_up':
        return '俯卧撑';
      case 'pull_up':
        return '引体向上';
      case 'sit_up':
        return '仰卧起坐';
      default:
        return exerciseType;
    }
  }

  Color _getExerciseColor(String exerciseType) {
    switch (exerciseType) {
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

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}秒';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}分${remainingSeconds}秒';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}小时${minutes}分';
    }
  }
}