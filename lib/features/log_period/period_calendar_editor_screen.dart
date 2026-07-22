import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../cycles/data/cycle_service.dart';

class PeriodCalendarEditorScreen extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime? initialEndDate;
  final int? periodLogId;

  const PeriodCalendarEditorScreen({
    super.key,
    required this.initialStartDate,
    this.initialEndDate,
    this.periodLogId,
  });

  @override
  State<PeriodCalendarEditorScreen> createState() => _PeriodCalendarEditorScreenState();
}

class _PeriodCalendarEditorScreenState extends State<PeriodCalendarEditorScreen> {
  late DateTime _startDate;
  DateTime? _endDate;
  DateTime? _predictedEndDate;
  bool _isLoading = false;
  final CycleService _cycleService = CycleService();
  int? _periodLogId;
  Map<String, dynamic>? _calendarData;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _periodLogId = widget.periodLogId;
    _calculatePrediction();
    _fetchExistingPeriod();
    _fetchCalendarData(_startDate);
  }

  Future<void> _fetchExistingPeriod() async {
    try {
      final details = await _cycleService.getDayDetails(widget.initialStartDate);
      if (details['period'] != null) {
        final period = details['period'];
        setState(() {
          _periodLogId = period['cycle_log_id'];
          _startDate = DateTime.parse(period['period_start_date']);
          if (period['period_end_date'] != null) {
            _endDate = DateTime.parse(period['period_end_date']);
          }
          _calculatePrediction();
        });
        _fetchCalendarData(_startDate);
      }
    } catch (e) {
      debugPrint('Error fetching existing period: $e');
    }
  }

  Future<void> _fetchCalendarData(DateTime date) async {
    try {
      final calendarData = await _cycleService.getCalendarMonth(date.year, date.month);
      if (mounted) {
        setState(() {
          _calendarData = calendarData;
        });
      }
    } catch (e) {
      debugPrint('Error fetching calendar data in editor: $e');
    }
  }

  void _calculatePrediction() {
    // Basic prediction logic for UI guidance
    if (_endDate == null) {
      _predictedEndDate = _startDate.add(const Duration(days: 4));
    } else {
      _predictedEndDate = null;
    }
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    final activeId = _periodLogId ?? widget.periodLogId;
    try {
      if (activeId != null) {
        // Update existing range
        final log = CycleLog(
          id: activeId,
          periodStartDate: _startDate,
          periodEndDate: _endDate,
          status: _endDate != null ? 'completed' : 'active',
          flow: 'medium', // Default/Keep previous
        );
        await _cycleService.updateCycleLog(activeId, log);
      } else {
        // Start new period
        await _cycleService.startPeriod(
          periodStartDate: _startDate,
          flow: 'medium',
        );
        
        if (_endDate != null) {
          // If user also selected end date, close it immediately
          await _cycleService.endPeriod(periodEndDate: _endDate!);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period dates updated'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FemLyraColors.period),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.periodLogId != null ? 'Edit Period' : 'Log Period',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 24),
                  _buildStatusCard(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _startDate,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: FemLyraColors.blushMist, shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildDayWidget(day),
              outsideBuilder: (context, day, focusedDay) => _buildDayWidget(day, isOutside: true),
            ),
            onPageChanged: (focusedDay) {
              _fetchCalendarData(focusedDay);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                if (_endDate == null && selectedDay.isAfter(_startDate)) {
                  _endDate = selectedDay;
                } else {
                  _startDate = selectedDay;
                  _endDate = null;
                }
                _calculatePrediction();
              });
            },
          ),
          const SizedBox(height: 16),
          _buildLegend(),
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
        _buildLegendItem('Period', FemLyraColors.period),
        _buildLegendItem('Predicted', FemLyraColors.period.withValues(alpha: 0.5), isOutline: true),
        _buildLegendItem('PMS', const Color(0xFFE8A838)),
        _buildLegendItem('Fertile', FemLyraColors.ovulation.withValues(alpha: 0.3)),
        _buildLegendItem('Ovulation', Colors.teal),
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
        Text(label, style: const TextStyle(fontSize: 10, color: FemLyraColors.textSecondary)),
      ],
    );
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

  Widget _buildDayWidget(DateTime day, {bool isOutside = false}) {
    bool isStart = _isSameDay(day, _startDate);
    bool isEnd = _endDate != null && _isSameDay(day, _endDate!);
    bool inRange = _endDate != null && day.isAfter(_startDate) && day.isBefore(_endDate!);
    bool isPredictedEnd = _predictedEndDate != null && _isSameDay(day, _predictedEndDate!);
    bool inPredictedRange = _predictedEndDate != null && day.isAfter(_startDate) && day.isBefore(_predictedEndDate!);

    // Fetch predictions status from calendar data
    final dayData = _getDayData(day);
    final status = List<String>.from(dayData?['status'] ?? []);
    
    bool isPeriod = status.contains('period');
    bool isPredicted = status.contains('predicted_period');
    bool isFertile = status.contains('fertile');
    bool isOvulation = status.contains('ovulation');
    bool isPMS = status.contains('pms');

    Color? bgColor;
    Color textColor = isOutside ? FemLyraColors.textMuted : FemLyraColors.textPrimary;
    BoxShape shape = BoxShape.circle;
    Border? border;

    if (isStart || isEnd) {
      bgColor = FemLyraColors.primary;
      textColor = Colors.white;
    } else if (inRange) {
      bgColor = FemLyraColors.primary.withValues(alpha: 0.2);
    } else {
      // Apply server predictions
      if (isOvulation) {
        bgColor = Colors.teal;
        textColor = Colors.white;
      } else if (isPredicted) {
        border = Border.all(color: FemLyraColors.period.withValues(alpha: 0.5), width: 1.5);
        textColor = FemLyraColors.textPrimary;
      } else if (isFertile) {
        bgColor = FemLyraColors.ovulation.withValues(alpha: 0.3);
        textColor = FemLyraColors.textPrimary;
      } else if (isPMS) {
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE8A838);
      } else if (isPeriod) {
        bgColor = FemLyraColors.period.withValues(alpha: 0.3);
        textColor = FemLyraColors.textPrimary;
      } else if (isPredictedEnd) {
        border = Border.all(color: FemLyraColors.primary, width: 1.5, style: BorderStyle.solid);
        textColor = FemLyraColors.primary;
      } else if (inPredictedRange) {
        bgColor = FemLyraColors.primary.withValues(alpha: 0.05);
      }
    }

    bool isToday = _isSameDay(day, DateTime.now());
    if (isToday && bgColor == null && border == null) {
      bgColor = FemLyraColors.blushMist;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: shape,
        border: border,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: (isStart || isEnd || isToday) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildStatusCard() {
    String rangeText = DateFormat('d MMM').format(_startDate);
    if (_endDate != null) {
      rangeText += ' – ${DateFormat('d MMM').format(_endDate!)}';
    } else {
      rangeText += ' – Active';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selected Range', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 14)),
              Text(rangeText, style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
            ],
          ),
          const Divider(height: 24),
          if (_endDate == null && _predictedEndDate != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: Row(
                 children: [
                   const Icon(Icons.info_outline, size: 16, color: FemLyraColors.textMuted),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Based on your history, your period may last until ${DateFormat('d MMM').format(_predictedEndDate!)}.',
                       style: const TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
                     ),
                   ),
                 ],
               ),
             ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Period Length', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 12)),
                    Text(
                      _endDate != null 
                        ? '${_endDate!.difference(_startDate).inDays + 1} days' 
                        : 'Currently logging...',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (_endDate != null)
                TextButton(
                  onPressed: () => setState(() => _endDate = null),
                  child: const Text('Clear End Date', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: PrimaryButton(
        label: widget.periodLogId != null ? 'Save Changes' : (_endDate != null ? 'Save Period' : 'Start Period'),
        onPressed: _onSave,
        isLoading: _isLoading,
      ),
    );
  }
}
