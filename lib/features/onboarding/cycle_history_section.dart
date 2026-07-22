import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../cycles/data/cycle_service.dart';

class CycleHistorySection extends StatefulWidget {
  final Function(List<CycleLog>) onHistoryChanged;

  const CycleHistorySection({
    super.key,
    required this.onHistoryChanged,
  });

  @override
  State<CycleHistorySection> createState() => _CycleHistorySectionState();
}

class _CycleHistorySectionState extends State<CycleHistorySection> {
  final List<CycleLog> _loggedCycles = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = selectedDay;
        _rangeEnd = null;
      } else if (selectedDay.isAfter(_rangeStart!)) {
        _rangeEnd = selectedDay;
      } else {
        _rangeStart = selectedDay;
        _rangeEnd = null;
      }
    });
  }

  void _addCycle() {
    if (_rangeStart != null && _rangeEnd != null) {
      setState(() {
        _loggedCycles.add(CycleLog(
          periodStartDate: _rangeStart!,
          periodEndDate: _rangeEnd,
          status: 'completed',
        ));
        _rangeStart = null;
        _rangeEnd = null;
      });
      widget.onHistoryChanged(_loggedCycles);
    }
  }

  void _removeCycle(int index) {
    setState(() {
      _loggedCycles.removeAt(index);
    });
    widget.onHistoryChanged(_loggedCycles);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add your recent periods to improve accuracy.',
          style: TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: RangeSelectionMode.enforced,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            calendarStyle: const CalendarStyle(
              rangeHighlightColor: FemFlowColors.blushMist,
              rangeStartDecoration: BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
              rangeEndDecoration: BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold),
            ),
            onDaySelected: _onDaySelected,
          ),
        ),
        const SizedBox(height: 20),
        if (_rangeStart != null && _rangeEnd != null)
          Center(
            child: TextButton.icon(
              onPressed: _addCycle,
              icon: const Icon(Icons.add_circle_outline, color: FemFlowColors.primary),
              label: const Text('Confirm Period Dates', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
            ),
          ),
        const SizedBox(height: 32),
        if (_loggedCycles.isNotEmpty) ...[
          const Text('Recent History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._loggedCycles.asMap().entries.map((entry) {
            final cycle = entry.value;
            final range = '${DateFormat('d MMM').format(cycle.periodStartDate)} – ${DateFormat('d MMM').format(cycle.periodEndDate!)}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: FemFlowColors.primary),
                    const SizedBox(width: 12),
                    Text(range, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                      onPressed: () => _removeCycle(entry.key),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
