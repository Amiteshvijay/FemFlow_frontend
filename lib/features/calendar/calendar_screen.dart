import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../cycles/data/cycle_service.dart';
import '../log_period/period_calendar_editor_screen.dart';
import '../log_period/period_daily_log_screen.dart';
import '../symptoms/symptoms_screen.dart';
import 'date_detail_screen.dart';
import 'year_calendar_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  final CycleService _cycleService = CycleService();
  bool _isLoading = true;
  Map<String, dynamic>? _calendarData;
  Map<String, dynamic>? _selectedDayData;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCalendarData();
  }

  Future<void> _fetchCalendarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final calendarData = await _cycleService.getCalendarMonth(_focusedDay.year, _focusedDay.month);
      final dashboardData = await _cycleService.getDashboard();
      if (mounted) {
        setState(() {
          _calendarData = calendarData;
          _dashboardData = dashboardData;
          _isLoading = false;
        });
        _updateSelectedDayData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load calendar data.';
        });
      }
    }
  }

  void _updateSelectedDayData() {
    if (_calendarData == null) return;
    final days = List<Map<String, dynamic>>.from(_calendarData!['days']);
    final dateStr = _selectedDay.toIso8601String().split('T')[0];
    
    try {
      final dayData = days.firstWhere((d) => d['date'] == dateStr);
      setState(() {
        _selectedDayData = dayData;
      });
    } catch (_) {
      setState(() {
        _selectedDayData = null;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, dynamic>? _getDayData(DateTime date) {
    if (_calendarData == null) return null;
    final dateStr = date.toIso8601String().split('T')[0];
    try {
      return List<Map<String, dynamic>>.from(_calendarData!['days'])
          .firstWhere((d) => d['date'] == dateStr);
    } catch (_) {
      return null;
    }
  }

  bool _isShowingCurrentMonth() {
    final now = DateTime.now();
    return _focusedDay.year == now.year && _focusedDay.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!, style: const TextStyle(color: FemFlowColors.period)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _fetchCalendarData, child: const Text('Retry')),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    if (_isShowingCurrentMonth()) ...[
                      const SizedBox(height: 16),
                      _buildHeroCard(),
                    ],
                    const SizedBox(height: 16),
                    _buildCalendar(),
                    const SizedBox(height: 16),
                    _buildLegend(),
                    const SizedBox(height: 24),
                    _buildSelectedDateDetail(),
                    if (_isShowingCurrentMonth()) ...[
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: '+ Log Data',
                        onPressed: () {
                          _showLogOptions(context);
                        },
                        backgroundColor: FemFlowColors.primary,
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
            });
            _fetchCalendarData();
          },
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedDay),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: FemFlowColors.textPrimary,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
            });
            _fetchCalendarData();
          },
        ),
        IconButton(
          icon: const Icon(Icons.calendar_view_month, color: FemFlowColors.textPrimary),
          onPressed: () {
            _showViewOptions(context);
          },
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    if (_dashboardData == null) return const SizedBox.shrink();

    final activePeriod = _dashboardData!['active_period'] ?? false;
    final lastPeriodEndDate = _dashboardData!['last_period_end_date'];
    final periodDay = _dashboardData!['current_period_day'];
    final cycleDay = _dashboardData!['current_cycle_day'];
    final daysUntilFertile = _dashboardData!['days_until_fertile_window'];
    final daysUntilOvulation = _dashboardData!['days_until_ovulation'];
    final nextPeriod = _dashboardData!['next_period'];

    String title = '';
    String subtitle = '';
    String cta = '';
    Color cardColor = Colors.white;
    Color textColor = FemFlowColors.textPrimary;
    Color btnColor = FemFlowColors.primary;

    // Only show "Log period end" if the period is active AND has no end date yet
    if (activePeriod && periodDay != null && lastPeriodEndDate == null) {
      title = _dashboardData?['display_title'] ?? '$periodDay${_getDaySuffix(periodDay)} day of period';
      subtitle = _dashboardData?['display_subtitle'] ?? 'Cycle Day $cycleDay';
      cta = 'Log period end';
      cardColor = FemFlowColors.period.withValues(alpha: 0.1);
      textColor = FemFlowColors.period;
      btnColor = FemFlowColors.period;
    } else if (daysUntilFertile != null && daysUntilFertile >= 0 && daysUntilFertile <= 7) {
      title = daysUntilFertile == 0 ? 'Fertile window starts today' : 'Fertile window starts in $daysUntilFertile days';
      subtitle = 'Cycle Day $cycleDay';
      cta = 'View details';
      cardColor = Colors.teal.withValues(alpha: 0.1);
      textColor = Colors.teal;
      btnColor = Colors.teal;
    } else if (daysUntilOvulation != null && daysUntilOvulation >= 0 && daysUntilOvulation <= 7) {
      title = daysUntilOvulation == 0 ? 'Ovulation estimated today' : 'Ovulation estimated in $daysUntilOvulation days';
      subtitle = 'Cycle Day $cycleDay';
      cta = 'View details';
      cardColor = Colors.teal.withValues(alpha: 0.1);
      textColor = Colors.teal;
      btnColor = Colors.teal;
    } else if (cycleDay != null) {
      title = _dashboardData?['display_title'] ?? '$cycleDay${_getDaySuffix(cycleDay)} day of cycle';
      cta = 'Log today';
      if (nextPeriod != null) {
        final date = DateTime.parse(nextPeriod);
        subtitle = _dashboardData?['display_subtitle'] ?? 'Next period expected on ${DateFormat('d MMM').format(date)}';
      }
      cardColor = FemFlowColors.blushMist;
    } else {
      title = 'Start tracking your cycle';
      subtitle = 'Log your first period to get started';
      cta = 'Log first period';
      cardColor = FemFlowColors.blushMist;
    }

    return AppCard(
      color: cardColor,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                bool? result;
                if (cta == 'Log period end') {
                  result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PeriodDailyLogScreen(date: DateTime.now())));
                } else if (cta == 'View details') {
                  result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DateDetailScreen(selectedDate: DateTime.now())),
                  );
                } else if (cta == "Log Today's Flow") {
                   result = await Navigator.push(context, MaterialPageRoute(builder: (context) => PeriodDailyLogScreen(date: DateTime.now())));
                } else {
                  _showLogOptions(context);
                }
                if (result == true) _fetchCalendarData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(cta, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      headerVisible: false,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) async {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _updateSelectedDayData();
        
        // Directly navigate to details on tap as per user expectation
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DateDetailScreen(selectedDate: selectedDay),
          ),
        );
        if (result == true) _fetchCalendarData();
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        _fetchCalendarData();
      },
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: true,
        defaultTextStyle: TextStyle(color: FemFlowColors.textPrimary),
        outsideTextStyle: TextStyle(color: FemFlowColors.textMuted),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) => _buildDayWidget(day),
        selectedBuilder: (context, day, focusedDay) => _buildDayWidget(day, isSelected: true),
        todayBuilder: (context, day, focusedDay) => _buildDayWidget(day, isToday: true),
        outsideBuilder: (context, day, focusedDay) => _buildDayWidget(day, isOutside: true),
      ),
    );
  }

  Widget _buildDayWidget(DateTime day, {bool isSelected = false, bool isToday = false, bool isOutside = false}) {
    final dayData = _getDayData(day);
    final status = List<String>.from(dayData?['status'] ?? []);
    
    final prevDayData = _getDayData(day.subtract(const Duration(days: 1)));
    final nextDayData = _getDayData(day.add(const Duration(days: 1)));
    
    final prevStatus = List<String>.from(prevDayData?['status'] ?? []);
    final nextStatus = List<String>.from(nextDayData?['status'] ?? []);

    Color? bgColor;
    Color textColor = isOutside ? FemFlowColors.textMuted : FemFlowColors.textPrimary;
    Border? border;
    EdgeInsets margin = const EdgeInsets.all(4);
    BorderRadius? borderRadius = BorderRadius.circular(20);

    bool isPeriod = status.contains('period');
    bool isPredicted = status.contains('predicted_period');
    bool isFertile = status.contains('fertile');
    bool isOvulation = status.contains('ovulation');
    bool isPMS = status.contains('pms');

    if (isOvulation) {
      // Connect with fertile window neighbors
      bool isStart = !prevStatus.contains('fertile') && !prevStatus.contains('ovulation');
      bool isEnd = !nextStatus.contains('fertile') && !nextStatus.contains('ovulation');
      
      bgColor = Colors.teal;
      textColor = Colors.white;
      
      margin = EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isStart ? 4 : 0,
        right: isEnd ? 4 : 0,
      );
      
      borderRadius = BorderRadius.only(
        topLeft: isStart ? const Radius.circular(20) : Radius.zero,
        bottomLeft: isStart ? const Radius.circular(20) : Radius.zero,
        topRight: isEnd ? const Radius.circular(20) : Radius.zero,
        bottomRight: isEnd ? const Radius.circular(20) : Radius.zero,
      );
    } else if (isPeriod) {
      bool isStart = !prevStatus.contains('period');
      bool isEnd = !nextStatus.contains('period');
      
      bgColor = isSelected ? FemFlowColors.period : FemFlowColors.period.withValues(alpha: 0.3);
      textColor = isSelected ? Colors.white : FemFlowColors.textPrimary;
      
      margin = EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isStart ? 4 : 0,
        right: isEnd ? 4 : 0,
      );
      
      borderRadius = BorderRadius.only(
        topLeft: isStart ? const Radius.circular(20) : Radius.zero,
        bottomLeft: isStart ? const Radius.circular(20) : Radius.zero,
        topRight: isEnd ? const Radius.circular(20) : Radius.zero,
        bottomRight: isEnd ? const Radius.circular(20) : Radius.zero,
      );
    } else if (isPredicted) {
      bool isStart = !prevStatus.contains('predicted_period');
      bool isEnd = !nextStatus.contains('predicted_period');
      
      bgColor = Colors.transparent;
      border = Border.all(color: FemFlowColors.period.withValues(alpha: 0.5), width: 1.5);
      
      margin = EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isStart ? 4 : 0,
        right: isEnd ? 4 : 0,
      );
      
      borderRadius = BorderRadius.only(
        topLeft: isStart ? const Radius.circular(20) : Radius.zero,
        bottomLeft: isStart ? const Radius.circular(20) : Radius.zero,
        topRight: isEnd ? const Radius.circular(20) : Radius.zero,
        bottomRight: isEnd ? const Radius.circular(20) : Radius.zero,
      );
    } else if (isFertile) {
      bool isStart = !prevStatus.contains('fertile');
      bool isEnd = !nextStatus.contains('fertile');
      
      bgColor = FemFlowColors.ovulation.withValues(alpha: 0.3); // Lavender/Mint
      
      margin = EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isStart ? 4 : 0,
        right: isEnd ? 4 : 0,
      );
      
      borderRadius = BorderRadius.only(
        topLeft: isStart ? const Radius.circular(20) : Radius.zero,
        bottomLeft: isStart ? const Radius.circular(20) : Radius.zero,
        topRight: isEnd ? const Radius.circular(20) : Radius.zero,
        bottomRight: isEnd ? const Radius.circular(20) : Radius.zero,
      );
    } else if (isPMS) {
      bool isStart = !prevStatus.contains('pms');
      bool isEnd = !nextStatus.contains('pms');
      
      bgColor = const Color(0xFFFFF3E0); // Warm amber tint
      textColor = const Color(0xFFE8A838);
      
      margin = EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isStart ? 4 : 0,
        right: isEnd ? 4 : 0,
      );
      
      borderRadius = BorderRadius.only(
        topLeft: isStart ? const Radius.circular(20) : Radius.zero,
        bottomLeft: isStart ? const Radius.circular(20) : Radius.zero,
        topRight: isEnd ? const Radius.circular(20) : Radius.zero,
        bottomRight: isEnd ? const Radius.circular(20) : Radius.zero,
      );
    } else if (isOvulation) {
      bgColor = Colors.teal;
      textColor = Colors.white;
    }

    if (isSelected && !isPeriod) {
      border = Border.all(color: FemFlowColors.primary, width: 2);
    }

    if (isToday && bgColor == null) {
      bgColor = FemFlowColors.blushMist;
    }

    return Container(
      margin: margin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(color: textColor, fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal),
          ),
          if (status.contains('symptom_logged'))
             Positioned(
               bottom: 4,
               child: Container(
                 width: 4,
                 height: 4,
                 decoration: const BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('Period', FemFlowColors.period),
        _buildLegendItem('Predicted', FemFlowColors.period.withValues(alpha: 0.5), isOutline: true),
        _buildLegendItem('PMS', const Color(0xFFE8A838)),
        _buildLegendItem('Fertile', FemFlowColors.ovulation.withValues(alpha: 0.3)),
        _buildLegendItem('Ovulation', Colors.teal),
        _buildLegendItem('Symptoms', FemFlowColors.primary, isDot: true),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isOutline = false, bool isDot = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
           Container(
             width: 6,
             height: 6,
             decoration: BoxDecoration(color: color, shape: BoxShape.circle),
           )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOutline ? null : color,
              shape: BoxShape.circle,
              border: isOutline ? Border.all(color: color, width: 1.5) : null,
            ),
          ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: FemFlowColors.textSecondary)),
      ],
    );
  }

  Widget _buildSelectedDateDetail() {
    if (_selectedDayData == null) return const SizedBox.shrink();

    final cycleDay = _selectedDayData!['cycle_day'];
    final status = List<String>.from(_selectedDayData!['status'] ?? []);
    
    String? statusText;
    Color statusColor = FemFlowColors.textSecondary;

    if (status.contains('ovulation')) {
      statusText = 'Ovulation Day';
      statusColor = Colors.teal;
    } else if (status.contains('period')) {
      statusText = 'Period';
      statusColor = FemFlowColors.period;
    } else if (status.contains('predicted_period')) {
      statusText = 'Predicted Period';
      statusColor = FemFlowColors.period.withValues(alpha: 0.7);
    } else if (status.contains('fertile')) {
      statusText = 'Fertile Window';
      statusColor = FemFlowColors.fertileWindow;
    } else if (status.contains('pms')) {
      statusText = 'PMS Phase';
      statusColor = const Color(0xFFE8A838);
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DateDetailScreen(selectedDate: _selectedDay)),
        );
        if (result == true) _fetchCalendarData();
      },
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDay),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (cycleDay != null)
                        Text(
                          'Day $cycleDay',
                          style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
                        ),
                      if (cycleDay != null && statusText != null)
                        const Text(' • ', style: TextStyle(color: FemFlowColors.textMuted)),
                      if (statusText != null)
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted),
          ],
        ),
      ),
    );
  }

  String _getDaySuffix(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return 'th';
    }

    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _showLogOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildOption(Icons.opacity, 'Period', FemFlowColors.period, () async {
               Navigator.pop(context);
               // Simple check: if today is in an active period, show daily flow. 
               // Otherwise show calendar editor.
               final activePeriod = _dashboardData?['active_period'] ?? false;
               if (activePeriod && _isSameDay(_selectedDay, DateTime.now())) {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => PeriodDailyLogScreen(date: _selectedDay)));
               } else {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => PeriodCalendarEditorScreen(initialStartDate: _selectedDay)));
               }
               _fetchCalendarData();
            }),
            _buildOption(Icons.sentiment_satisfied_alt, 'Symptoms & Mood', FemFlowColors.primary, () async {
               Navigator.pop(context);
               final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => SymptomsScreen(initialDate: _selectedDay)));
               if (result == true) _fetchCalendarData();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _showViewOptions(BuildContext context) {
     showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('View Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.calendar_view_month, color: FemFlowColors.primary),
              title: const Text('Month View'),
              trailing: const Icon(Icons.check, color: FemFlowColors.primary),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: FemFlowColors.textSecondary),
              title: const Text('Year View'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => YearCalendarScreen(initialYear: _focusedDay.year)),
                );
                if (result is DateTime) {
                  setState(() {
                    _focusedDay = result;
                    _selectedDay = result;
                  });
                  _fetchCalendarData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
