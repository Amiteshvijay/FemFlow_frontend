import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
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
  late DateTime _focusedDay;
  Map<String, dynamic>? _calendarData;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _periodLogId = widget.periodLogId;
    _focusedDay = widget.initialStartDate;
    _calculatePrediction();
    _fetchExistingPeriod();
    _fetchCalendarMonthData(_focusedDay.year, _focusedDay.month);
  }

  Future<void> _fetchCalendarMonthData(int year, int month) async {
    try {
      final calendarData = await _cycleService.getCalendarMonth(year, month);
      if (mounted) {
        setState(() {
          _calendarData = calendarData;
        });
      }
    } catch (e) {
      debugPrint('Error fetching calendar data in editor: $e');
    }
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
          _focusedDay = _startDate;
          _calculatePrediction();
        });
        _fetchCalendarMonthData(_startDate.year, _startDate.month);
      }
    } catch (e) {
      debugPrint('Error fetching existing period: $e');
    }
  }

  void _calculatePrediction() {
    // Basic prediction logic for UI guidance
    // Defaulting to 5 days if end_date is null
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
          SnackBar(content: Text('Error: $e'), backgroundColor: FemFlowColors.period),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
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
                  const SizedBox(height: 16),
                  _buildLegend(),
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
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(color: FemFlowColors.blushMist, shape: BoxShape.circle),
          todayTextStyle: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold),
          outsideDaysVisible: true,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildDayWidget(day),
          outsideBuilder: (context, day, focusedDay) => _buildDayWidget(day, isOutside: true),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            if (_endDate == null && selectedDay.isAfter(_startDate)) {
              _endDate = selectedDay;
            } else {
              _startDate = selectedDay;
              _endDate = null;
            }
            _focusedDay = focusedDay;
            _calculatePrediction();
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          _fetchCalendarMonthData(focusedDay.year, focusedDay.month);
        },
      ),
    );
  }

  Widget _buildDayWidget(DateTime day, {bool isOutside = false}) {
    bool isStart = _isSameDay(day, _startDate);
    bool isEnd = _endDate != null && _isSameDay(day, _endDate!);
    bool inRange = _endDate != null && day.isAfter(_startDate) && day.isBefore(_endDate!);

    final dayData = _getDayData(day);
    final status = List<String>.from(dayData?['status'] ?? []);
    bool isFertile = status.contains('fertile');
    bool isOvulation = status.contains('ovulation');
    bool isPredictedPeriod = status.contains('predicted_period');

    Color? bgColor;
    Color textColor = isOutside ? FemFlowColors.textMuted : FemFlowColors.textPrimary;
    BoxShape shape = BoxShape.circle;
    Border? border;

    if (isStart || isEnd) {
      bgColor = FemFlowColors.primary;
      textColor = Colors.white;
    } else if (inRange) {
      bgColor = FemFlowColors.primary.withValues(alpha: 0.2);
      textColor = FemFlowColors.textPrimary;
    } else if (isOvulation) {
      bgColor = Colors.teal;
      textColor = Colors.white;
    } else if (isFertile) {
      bgColor = FemFlowColors.ovulation.withValues(alpha: 0.3);
      textColor = FemFlowColors.textPrimary;
    } else if (isPredictedPeriod) {
      border = Border.all(color: FemFlowColors.period.withValues(alpha: 0.5), width: 1.5);
      textColor = isOutside ? FemFlowColors.textMuted : FemFlowColors.textPrimary;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: shape,
        border: border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(color: textColor, fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal),
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
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOutline ? Colors.transparent : color,
              borderRadius: BorderRadius.circular(3),
              border: isOutline ? Border.all(color: color, width: 1.5) : null,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
        ),
      ],
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
              const Text('Selected Range', style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 14)),
              Text(rangeText, style: const TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
            ],
          ),
          const Divider(height: 24),
          if (_endDate == null && _predictedEndDate != null)
             Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: Row(
                 children: [
                   const Icon(Icons.info_outline, size: 16, color: FemFlowColors.textMuted),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Based on your history, your period may last until ${DateFormat('d MMM').format(_predictedEndDate!)}.',
                       style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
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
                    const Text('Period Length', style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 12)),
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
