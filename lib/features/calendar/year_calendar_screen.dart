import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../cycles/data/cycle_service.dart';

class YearCalendarScreen extends StatefulWidget {
  final int? initialYear;

  const YearCalendarScreen({super.key, this.initialYear});

  @override
  State<YearCalendarScreen> createState() => _YearCalendarScreenState();
}

class _YearCalendarScreenState extends State<YearCalendarScreen> {
  late int _selectedYear;
  final CycleService _cycleService = CycleService();
  bool _isLoading = true;
  YearCalendarData? _yearData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    _fetchYearData();
  }

  Future<void> _fetchYearData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _cycleService.getYearCalendar(_selectedYear);
      if (mounted) {
        setState(() {
          _yearData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load year calendar.';
        });
      }
    }
  }

  void _nextYear() {
    setState(() => _selectedYear++);
    _fetchYearData();
  }

  void _prevYear() {
    setState(() => _selectedYear--);
    _fetchYearData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: FemLyraColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevYear),
            Text(
              '$_selectedYear',
              style: const TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextYear),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildLegend(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthData = _yearData?.months.firstWhere((m) => m.month == month, 
                  orElse: () => YearMonthSummary(month: month, days: []));
              return _buildMonthCard(month, monthData!);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(int month, YearMonthSummary data) {
    final monthName = DateFormat('MMMM').format(DateTime(_selectedYear, month));
    
    return AppCard(
      onTap: () {
        // Return selection to CalendarScreen
        Navigator.pop(context, DateTime(_selectedYear, month, 1));
      },
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            monthName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: FemLyraColors.textPrimary),
          ),
          const SizedBox(height: 6),
          _buildWeekdayHeader(),
          const SizedBox(height: 4),
          Expanded(
            child: _buildMiniGrid(month, data),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: FemLyraColors.textMuted,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildMiniGrid(int month, YearMonthSummary data) {
    final firstDay = DateTime(_selectedYear, month, 1);
    final daysInMonth = DateTime(_selectedYear, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: 42, // 6 weeks
      itemBuilder: (context, index) {
        final day = index - startWeekday + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();

        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(_selectedYear, month, day));
        final dayData = data.days.firstWhere((d) => d.date == dateStr, orElse: () => YearDaySummary(date: dateStr, day: day, statuses: []));
        
        return _buildDayCell(day, dayData.statuses);
      },
    );
  }

  Widget _buildDayCell(int day, List<String> statuses) {
    bool isPeriod = statuses.contains('period');
    bool isPredicted = statuses.contains('predicted_period');
    bool isFertile = statuses.contains('fertile');
    bool isOvulation = statuses.contains('ovulation');
    bool hasLoggedData = statuses.contains('symptoms') || 
                         statuses.contains('flow_logged') || 
                         statuses.contains('mood') || 
                         statuses.contains('exercise') || 
                         statuses.contains('pill');

    Color? bgColor;
    Border? border;
    Color textColor = FemLyraColors.textPrimary;

    if (isPeriod) {
      bgColor = FemLyraColors.period;
      textColor = Colors.white;
    } else if (isPredicted) {
      border = Border.all(color: FemLyraColors.period.withValues(alpha: 0.6), width: 1.0);
      textColor = FemLyraColors.period;
    } else if (isOvulation) {
      bgColor = Colors.teal;
      textColor = Colors.white;
    } else if (isFertile) {
      bgColor = Colors.teal.withValues(alpha: 0.15);
      textColor = Colors.teal[700] ?? Colors.teal;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 8.5, 
                fontWeight: (isPeriod || isOvulation) ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
        ),
        if (hasLoggedData && !isPeriod && !isOvulation)
          Positioned(
            bottom: 1,
            child: Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(color: FemLyraColors.primary, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _legendItem('Period', FemLyraColors.period),
          _legendItem('Predicted', FemLyraColors.period.withValues(alpha: 0.5), isOutline: true),
          _legendItem('Fertile', Colors.teal.withValues(alpha: 0.2)),
          _legendItem('Ovulation', Colors.teal),
          _legendItem('Logged Data', FemLyraColors.primary, isDot: true),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, {bool isOutline = false, bool isDot = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOutline ? null : color,
            shape: BoxShape.circle,
            border: isOutline ? Border.all(color: color, width: 1) : null,
          ),
          child: isDot ? Center(child: Container(width: 2, height: 2, color: color)) : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: FemLyraColors.textSecondary)),
      ],
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: FemLyraColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchYearData, child: const Text('Retry')),
        ],
      ),
    );
  }
}
