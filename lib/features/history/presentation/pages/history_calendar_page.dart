import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/exercise_record_model.dart';
import '../../../../shared/providers/exercise_provider.dart';
import '../widgets/calendar_exercise_indicator.dart';
import '../widgets/daily_exercise_summary.dart';
import 'history_list_page.dart';

class HistoryCalendarPage extends StatefulWidget {
  const HistoryCalendarPage({super.key});

  @override
  State<HistoryCalendarPage> createState() => _HistoryCalendarPageState();
}

class _HistoryCalendarPageState extends State<HistoryCalendarPage>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  final DatabaseService _databaseService = DatabaseService.instance;
  Map<DateTime, List<ExerciseRecordModel>> _exerciseRecords = {};
  List<ExerciseRecordModel> _selectedDayRecords = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadExerciseRecords();
  }

  Future<void> _loadExerciseRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exerciseProvider = context.read<ExerciseProvider>();
      final user = exerciseProvider.currentUser;
      
      if (user != null) {
        // 加载当前月份的记录
        final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
        final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
        
        final records = await _databaseService.getExerciseRecords(
          userId: user.localUserId,
          startDate: startOfMonth,
          endDate: endOfMonth.add(const Duration(days: 1)),
        );

        // 按日期分组记录
        final Map<DateTime, List<ExerciseRecordModel>> recordsByDate = {};
        for (final record in records) {
          final date = DateTime(
            record.startTime.year,
            record.startTime.month,
            record.startTime.day,
          );
          
          if (recordsByDate[date] == null) {
            recordsByDate[date] = [];
          }
          recordsByDate[date]!.add(record);
        }

        setState(() {
          _exerciseRecords = recordsByDate;
          _selectedDayRecords = _exerciseRecords[_normalizeDate(_selectedDay)] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('加载运动记录失败: $e');
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadExerciseRecords,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: _buildCalendarSection(),
            ),
            _buildSelectedDaySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: AppConstants.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '运动日历',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          onPressed: _showCalendarOptions,
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
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
      child: TableCalendar<ExerciseRecordModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: AppConstants.errorColor),
          holidayTextStyle: const TextStyle(color: AppConstants.errorColor),
          selectedDecoration: BoxDecoration(
            color: AppConstants.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppConstants.successColor.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppConstants.warningColor,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          formatButtonTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadExerciseRecords();
        },

        // 自定义标记构建器
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return CalendarExerciseIndicator(
                exerciseRecords: events.cast<ExerciseRecordModel>(),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDaySection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppConstants.paddingMedium,
          0,
          AppConstants.paddingMedium,
          AppConstants.paddingMedium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选中日期标题
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatSelectedDate(),
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDayRecords.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.successColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedDayRecords.length} 次训练',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppConstants.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // 选中日期的运动记录
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingLarge),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedDayRecords.isEmpty)
              _buildEmptyState()
            else
              DailyExerciseSummary(
                exerciseRecords: _selectedDayRecords,
                selectedDate: _selectedDay,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final isPast = _selectedDay.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: AppConstants.cardColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isToday ? Icons.fitness_center : Icons.event_busy,
            size: 48,
            color: AppConstants.textHintColor,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            isToday 
                ? '今天还没有运动记录'
                : isPast 
                    ? '这天没有运动记录'
                    : '未来的日期',
            style: const TextStyle(
              fontSize: AppConstants.fontSizeMedium,
              color: AppConstants.textSecondaryColor,
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 4),
            const Text(
              '开始今天的第一次训练吧！',
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: AppConstants.textHintColor,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ElevatedButton.icon(
              onPressed: () {
                // 返回到运动选择页面
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始运动'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 事件处理方法
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedDayRecords = _exerciseRecords[_normalizeDate(selectedDay)] ?? [];
      });
    }
  }

  List<ExerciseRecordModel> _getEventsForDay(DateTime day) {
    return _exerciseRecords[_normalizeDate(day)] ?? [];
  }

  String _formatSelectedDate() {
    final now = DateTime.now();
    final selected = _selectedDay;
    
    if (isSameDay(selected, now)) {
      return '今天 (${selected.month}/${selected.day})';
    } else if (isSameDay(selected, now.subtract(const Duration(days: 1)))) {
      return '昨天 (${selected.month}/${selected.day})';
    } else if (isSameDay(selected, now.add(const Duration(days: 1)))) {
      return '明天 (${selected.month}/${selected.day})';
    } else {
      final weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return '${selected.month}月${selected.day}日 ${weekdays[selected.weekday]}';
    }
  }

  void _showCalendarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '日历选项',
              style: TextStyle(
                fontSize: AppConstants.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('回到今天'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedDay = DateTime.now();
                  _focusedDay = DateTime.now();
                });
                _loadExerciseRecords();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('刷新数据'),
              onTap: () {
                Navigator.pop(context);
                _loadExerciseRecords();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('列表视图'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryListPage(
                      filterDate: _selectedDay,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('查看统计'),
              onTap: () {
                Navigator.pop(context);
                // 跳转到统计页面
                DefaultTabController.of(context)?.animateTo(2);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        action: SnackBarAction(
          label: '重试',
          textColor: Colors.white,
          onPressed: _loadExerciseRecords,
        ),
      ),
    );
  }
}