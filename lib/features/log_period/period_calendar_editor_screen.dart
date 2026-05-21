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

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _calculatePrediction();
  }

  void _calculatePrediction() {
    // Basic prediction logic for UI guidance
    // In real app, this would come from average_period_length in backend or local calculation
    // Defaulting to 5 days if end_date is null
    if (_endDate == null) {
      _predictedEndDate = _startDate.add(const Duration(days: 4));
    } else {
      _predictedEndDate = null;
    }
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    try {
      if (widget.periodLogId != null) {
        // Update existing range
        final log = CycleLog(
          id: widget.periodLogId,
          periodStartDate: _startDate,
          periodEndDate: _endDate,
          status: _endDate != null ? 'completed' : 'active',
          flow: 'medium', // Default/Keep previous
        );
        await _cycleService.updateCycleLog(widget.periodLogId!, log);
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
        focusedDay: _startDate,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(color: FemFlowColors.blushMist, shape: BoxShape.circle),
          todayTextStyle: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildDayWidget(day),
          outsideBuilder: (context, day, focusedDay) => _buildDayWidget(day, isOutside: true),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
             // Simple range selection logic
             if (selectedDay.isBefore(_startDate)) {
               _startDate = selectedDay;
               _endDate = null;
             } else if (_isSameDay(selectedDay, _startDate)) {
               // Deselect end date if tapping start date?
               _endDate = null;
             } else {
               _endDate = selectedDay;
             }
             _calculatePrediction();
          });
        },
      ),
    );
  }

  Widget _buildDayWidget(DateTime day, {bool isOutside = false}) {
    bool isStart = _isSameDay(day, _startDate);
    bool isEnd = _endDate != null && _isSameDay(day, _endDate!);
    bool inRange = _endDate != null && day.isAfter(_startDate) && day.isBefore(_endDate!);
    bool isPredictedEnd = _predictedEndDate != null && _isSameDay(day, _predictedEndDate!);
    bool inPredictedRange = _predictedEndDate != null && day.isAfter(_startDate) && day.isBefore(_predictedEndDate!);

    Color? bgColor;
    Color textColor = isOutside ? FemFlowColors.textMuted : FemFlowColors.textPrimary;
    BoxShape shape = BoxShape.circle;
    Border? border;

    if (isStart || isEnd) {
      bgColor = FemFlowColors.primary;
      textColor = Colors.white;
    } else if (inRange) {
      bgColor = FemFlowColors.primary.withValues(alpha: 0.2);
    } else if (isPredictedEnd) {
      border = Border.all(color: FemFlowColors.primary, width: 1.5, style: BorderStyle.solid);
      textColor = FemFlowColors.primary;
    } else if (inPredictedRange) {
       bgColor = FemFlowColors.primary.withValues(alpha: 0.05);
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
        style: TextStyle(color: textColor, fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal),
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
