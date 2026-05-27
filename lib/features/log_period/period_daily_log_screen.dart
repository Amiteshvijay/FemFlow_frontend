import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../cycles/data/cycle_service.dart';
import 'period_calendar_editor_screen.dart';

class PeriodDailyLogScreen extends StatefulWidget {
  final DateTime date;
  final String? initialFlow;
  final String? initialNotes;

  const PeriodDailyLogScreen({
    super.key,
    required this.date,
    this.initialFlow,
    this.initialNotes,
  });

  @override
  State<PeriodDailyLogScreen> createState() => _PeriodDailyLogScreenState();
}

class _PeriodDailyLogScreenState extends State<PeriodDailyLogScreen> {
  late String _selectedFlow;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  final CycleService _cycleService = CycleService();

  bool _hasActivePeriod = false;
  bool _endPeriodChecked = false;
  bool _initialEndPeriodChecked = false;
  int? _cycleLogId;

  final List<Map<String, dynamic>> _flowOptions = [
    {'key': 'spotting', 'label': 'Spotting', 'icon': Icons.water_drop_outlined},
    {'key': 'light', 'label': 'Light', 'icon': Icons.opacity},
    {'key': 'medium', 'label': 'Medium', 'icon': Icons.opacity},
    {'key': 'heavy', 'label': 'Heavy', 'icon': Icons.opacity},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFlow = widget.initialFlow ?? 'medium';
    _notesController.text = widget.initialNotes ?? '';
    _checkActivePeriod();
  }

  Future<void> _checkActivePeriod() async {
    try {
      final details = await _cycleService.getDayDetails(widget.date);
      if (details['period'] != null) {
        final period = details['period'];
        setState(() {
          _cycleLogId = period['cycle_log_id'];
          
          if (period['status'] == 'active') {
            _hasActivePeriod = true;
            _endPeriodChecked = false;
            _initialEndPeriodChecked = false;
          } else if (period['status'] == 'completed' && period['period_end_date'] != null) {
            final endDate = DateTime.parse(period['period_end_date']);
            if (DateUtils.isSameDay(endDate, widget.date)) {
              _hasActivePeriod = true;
              _endPeriodChecked = true;
              _initialEndPeriodChecked = true;
            }
          }

          if (widget.initialFlow == null && period['flow'] != null) {
            _selectedFlow = period['flow'];
          }
          if (widget.initialNotes == null && period['notes'] != null) {
            _notesController.text = period['notes'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking active period: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);
    try {
      // 1. Start period cycle if no cycle exists, otherwise log daily flow
      if (_cycleLogId == null) {
        try {
          final startRes = await _cycleService.startPeriod(
            periodStartDate: widget.date,
            flow: _selectedFlow,
            notes: _notesController.text,
          );
          if (startRes['cycle_log'] != null) {
            _cycleLogId = startRes['cycle_log']['id'];
          }
        } catch (e) {
          final errStr = e.toString();
          if (errStr.contains('409') || errStr.contains('already exists')) {
            if (mounted) {
              final shouldUpdate = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Active Period Exists'),
                  content: const Text(
                    'It looks like you already logged a period for this cycle.\n'
                    'Would you like to update the existing period instead?'
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Update Existing', style: TextStyle(color: FemFlowColors.primary)),
                    ),
                  ],
                ),
              );
              if (shouldUpdate == true) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PeriodCalendarEditorScreen(initialStartDate: widget.date),
                    ),
                  );
                }
                return;
              }
            }
            return; // User cancelled
          }
          rethrow;
        }
      } else {
        await _cycleService.logDailyPeriodFlow(
          date: widget.date,
          flow: _selectedFlow,
          notes: _notesController.text,
        );
      }

      // 2. End period if checked newly, or re-open if unchecked mistakenly
      if (_endPeriodChecked && !_initialEndPeriodChecked) {
        await _cycleService.endPeriod(
          periodEndDate: widget.date,
        );
      } else if (!_endPeriodChecked && _initialEndPeriodChecked && _cycleLogId != null) {
        await _cycleService.reopenPeriod(_cycleLogId!);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flow logged successfully'), behavior: SnackBarBehavior.floating),
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
        title: const Text('Log Flow', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE').format(widget.date),
                    style: const TextStyle(fontSize: 16, color: FemFlowColors.textSecondary),
                  ),
                  Text(
                    DateFormat('d MMMM').format(widget.date),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'How is your flow today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _flowOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final option = _flowOptions[index];
                final isSelected = _selectedFlow == option['key'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedFlow = option['key']),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    color: isSelected ? FemFlowColors.blushMist : Colors.white,
                    border: BorderSide(
                      color: isSelected ? FemFlowColors.primary : FemFlowColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(option['icon'], color: isSelected ? FemFlowColors.primary : FemFlowColors.textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          option['label'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? FemFlowColors.primary : FemFlowColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_hasActivePeriod) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _endPeriodChecked,
                    onChanged: (val) {
                      setState(() {
                        _endPeriodChecked = val ?? false;
                      });
                    },
                    activeColor: FemFlowColors.primary,
                  ),
                  const Text(
                    'End Period Today',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: FemFlowColors.textPrimary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'How are you feeling?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: FemFlowColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: FemFlowColors.border),
                ),
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Save Flow',
              onPressed: _onSave,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
