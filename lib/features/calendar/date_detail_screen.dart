import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../cycles/data/cycle_service.dart';
import '../symptoms/symptoms_screen.dart';
import '../log_period/period_calendar_editor_screen.dart';
import '../log_period/period_daily_log_screen.dart';
import '../journal/journal_screen.dart';
import '../wellness_score/wellness_score_dashboard_screen.dart';
import '../chat/femai_chat_screen.dart';
import '../exercises/models/exercise_models.dart' as ex_models;
import '../exercises/screens/exercise_library_screen.dart';
import '../exercises/widgets/exercise_card.dart';
import '../pill_reminder/pill_reminder_list_screen.dart';
import '../pill_reminder/data/pill_reminder_service.dart';
import '../insights/cycle_insights_detail_screen.dart';
import '../premium/premium_guard.dart';
import '../premium/premium_feature_preview_screen.dart';
import '../activity/data/activity_service.dart';
import '../activity/models/calorie_burn_models.dart';
import '../activity/screens/calorie_burn_screen.dart';
import '../activity/screens/add_activity_screen.dart';

class DateDetailScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DateDetailScreen({super.key, required this.selectedDate});

  @override
  State<DateDetailScreen> createState() => _DateDetailScreenState();
}

class _DateDetailScreenState extends State<DateDetailScreen> {
  late DateTime _currentDate;
  final CycleService _cycleService = CycleService();
  final PillReminderService _pillService = PillReminderService();
  final ActivityService _activityService = ActivityService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _dayData;
  DailyActivitySummary? _activitySummary;
  String? _errorMessage;

  late PageController _contentPageController;
  late PageController _stripPageController;
  final int _initialIndex = 5000;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _contentPageController = PageController(initialPage: _initialIndex);
    _stripPageController = PageController(initialPage: _initialIndex);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _cycleService.getDayDetails(_currentDate),
        _activityService.getDaySummary(DateFormat('yyyy-MM-dd').format(_currentDate)),
      ]);
      
      if (mounted) {
        setState(() {
          _dayData = results[0] as Map<String, dynamic>?;
          _activitySummary = results[1] as DailyActivitySummary?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load details.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: FemFlowColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          DateFormat('MMMM d').format(_currentDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _currentDate,
                firstDate: DateTime.utc(2020, 1, 1),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                final dayIndex = _initialIndex + date.difference(widget.selectedDate).inDays;
                _contentPageController.animateToPage(
                  dayIndex, 
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekStrip(),
          Expanded(
            child: PageView.builder(
              controller: _contentPageController,
              onPageChanged: (index) {
                final offset = index - _initialIndex;
                setState(() {
                  _currentDate = widget.selectedDate.add(Duration(days: offset));
                });
                _stripPageController.animateToPage(
                  index, 
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeInOut
                );
                _fetchDetails();
              },
              itemBuilder: (context, index) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator(color: FemFlowColors.primary));
                }
                if (_errorMessage != null) {
                  return _buildErrorState();
                }
                return _buildContent();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    return Container(
      color: Colors.white,
      height: 80,
      child: PageView.builder(
        controller: _stripPageController,
        onPageChanged: (index) {
          if (_contentPageController.page?.round() != index) {
            _contentPageController.jumpToPage(index);
          }
        },
        itemBuilder: (context, index) {
          final offset = index - _initialIndex;
          final middleDate = widget.selectedDate.add(Duration(days: offset));
          final startOfWeek = middleDate.subtract(const Duration(days: 3));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = startOfWeek.add(Duration(days: i));
              final isSelected = DateUtils.isSameDay(day, _currentDate);
              final isToday = DateUtils.isSameDay(day, DateTime.now());

              return GestureDetector(
                onTap: () {
                  final dayIndex = _initialIndex + day.difference(widget.selectedDate).inDays;
                  _contentPageController.animateToPage(
                    dayIndex, 
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(day).substring(0, 1),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? FemFlowColors.primary : FemFlowColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? FemFlowColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: FemFlowColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : FemFlowColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMyCycleCard(),
          const SizedBox(height: 20),
          _buildSymptomsSection(),
          const SizedBox(height: 20),
          _buildPainEnergySection(),
          const SizedBox(height: 20),
          _buildSexualActivitySection(),
          const SizedBox(height: 20),
          _buildContraceptionSection(),
          const SizedBox(height: 20),
          _buildActivityAndCaloriesSection(),
          const SizedBox(height: 20),
          _buildExerciseSection(),
          const SizedBox(height: 20),
          _buildAdvancedInsightsPreview(),
          const SizedBox(height: 20),
          _buildNotesSection(),
          const SizedBox(height: 20),
          _buildDocumentsSection(),
          const SizedBox(height: 20),
          _buildFemAIPriorityTips(),
          const SizedBox(height: 20),
          _buildClearLogsButton(),
          const SizedBox(height: 20),
          _buildSafetyNote(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildClearLogsButton() {
    final hasLogs = _dayData?['has_logs'] == true;
    if (!hasLogs) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, color: FemFlowColors.period),
          label: const Text('Clear Logs', style: TextStyle(color: FemFlowColors.period, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: FemFlowColors.period, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          onPressed: _showClearLogsConfirmation,
        ),
      ),
    );
  }

  void _showClearLogsConfirmation() {
    final isCycleStart = _dayData?['period']?['period_start_date'] != null &&
        _dayData!['period']['period_start_date'] == _currentDate.toIso8601String().split('T')[0];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Logs'),
        content: Text(
          isCycleStart
              ? 'Are you sure you want to erase this log?\nThis is the period start date — clearing it will recalculate your cycle predictions.'
              : 'Are you sure you want to erase this log?\nThis may recalculate your cycle predictions.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _executeClearLogs(); },
            child: const Text('Clear Logs', style: TextStyle(color: FemFlowColors.period)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeClearLogs() async {
    // Snapshot current data for undo
    final snapshot = Map<String, dynamic>.from(_dayData ?? {});

    setState(() => _isLoading = true);
    try {
      await _cycleService.clearDayLogs(_currentDate);
      await _fetchDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logs cleared'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _undoClearLogs(snapshot),
            ),
          ),
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

  Future<void> _undoClearLogs(Map<String, dynamic> snapshot) async {
    setState(() => _isLoading = true);
    try {
      // Restore period flow if existed
      if (snapshot['period'] != null && snapshot['period']['flow'] != null) {
        await _cycleService.startPeriod(
          periodStartDate: DateTime.parse(snapshot['period']['period_start_date']),
          flow: snapshot['period']['flow'],
          notes: snapshot['period']['notes'] ?? '',
        );
      }
      // Restore symptoms if existed
      if (snapshot['symptoms'] != null) {
        final s = snapshot['symptoms'];
        final ApiClient apiClient = ApiClient();
        await apiClient.post('/cycles/symptoms/', body: {
          'date': _currentDate.toIso8601String().split('T')[0],
          'symptoms': s['symptoms'] ?? [],
          'moods': s['moods'] ?? [],
          'primary_mood': s['primary_mood'],
          'pain_level': s['pain_level'] ?? 0,
          'energy_level': s['energy_level'] ?? 'Medium',
          'notes': s['notes'],
          'ovulation_test_result': s['ovulation_test_result'],
        });
      }
      // Restore sexual activities if existed
      if (snapshot['sexual_activity'] != null) {
        final sexList = snapshot['sexual_activity'] as List;
        for (final s in sexList) {
          await _cycleService.createSexualActivityLog(SexualActivityLog(
            date: _currentDate,
            activityType: s['activity_type'],
            notes: s['notes'],
          ));
        }
      }
      await _fetchDetails();
    } catch (e) {
      debugPrint('Undo failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMyCycleCard() {
    final period = _dayData?['period'];
    final prediction = _dayData?['prediction'];
    final ovulation = _dayData?['ovulation'];
    final fertility = _dayData?['fertility'];
    final cycleDay = _dayData?['cycle_day'];
    
    DateTime? nextPeriodStart;
    if (prediction != null && prediction['next_period_start'] != null) {
      nextPeriodStart = DateTime.parse(prediction['next_period_start']);
    }

    int? daysUntilNext;
    if (nextPeriodStart != null) {
      daysUntilNext = nextPeriodStart.difference(_currentDate).inDays;
    }

    String phase = "Follicular";
    if (period != null && period['period_day'] != null) {
      phase = "Period";
    } else if (_dayData?['is_ovulation'] == true) {
      phase = "Ovulation";
    } else if (_dayData?['is_fertile'] == true) {
      phase = "Fertile";
    } else if (cycleDay != null && cycleDay > 16) {
      phase = "Luteal";
    }

    final loggedOvulationResult = _dayData?['symptoms']?['ovulation_test_result'];
    String ovulationStatus = ovulation?['label'] ?? 'Estimated ovulation day';
    if (loggedOvulationResult == 'positive') {
      ovulationStatus = 'OPK Test: Positive ➕ (LH Surge)';
    } else if (loggedOvulationResult == 'negative') {
      ovulationStatus = 'OPK Test: Negative ➖';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Cycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildCycleRow(
            icon: Icons.water_drop,
            iconColor: FemFlowColors.period,
            title: 'Period',
            status: period != null && period['period_day'] != null 
                ? '${_formatOrdinal(period['period_day'])} day of period' 
                : 'Not logged',
            showLog: true,
            onLog: () async {
              final result = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => PeriodDailyLogScreen(date: _currentDate))
              );
              if (result == true) _fetchDetails();
            },
            showEdit: period != null,
            onEdit: () async {
              final periodStartDate = period['period_start_date'] != null 
                  ? DateTime.parse(period['period_start_date']) 
                  : _currentDate;
              final periodEndDate = period['period_end_date'] != null
                  ? DateTime.parse(period['period_end_date'])
                  : null;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PeriodCalendarEditorScreen(
                  initialStartDate: periodStartDate,
                  initialEndDate: periodEndDate,
                  periodLogId: period['cycle_log_id'],
                )),
              );
              if (result == true) _fetchDetails();
            },
            showEnd: period != null && period['can_end_period'] == true,
            onEnd: () async {
              setState(() => _isLoading = true);
              try {
                await _cycleService.endPeriod(periodEndDate: _currentDate);
                await _fetchDetails();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Period ended successfully'), behavior: SnackBarBehavior.floating),
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
            },
          ),
          const Divider(height: 32),
          _buildCycleRow(
            icon: Icons.wb_sunny,
            iconColor: FemFlowColors.ovulation,
            title: 'Ovulation',
            status: ovulationStatus,
            showLog: true,
            onLog: _showOvulationTestLogModal,
          ),
          const Divider(height: 32),
          _buildCycleRow(
            icon: Icons.favorite,
            iconColor: FemFlowColors.fertileWindow,
            title: 'Fertility',
            status: fertility?['label'] ?? 'Estimated fertile window',
          ),
          if (_dayData?['pms'] != null) ...[
            const Divider(height: 32),
            _buildCycleRow(
              icon: Icons.cloud,
              iconColor: const Color(0xFFE8A838),  // Soft orange
              title: 'PMS',
              status: _dayData!['pms']['label'] ?? 'Pre-menstrual phase',
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cycle Day ${cycleDay ?? '--'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Phase: $phase', style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13)),
                ],
              ),
              if (daysUntilNext != null && daysUntilNext > 0)
                Text('$daysUntilNext days to next period', style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  void _showOvulationTestLogModal() {
    final currentResult = _dayData?['symptoms']?['ovulation_test_result'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Log Ovulation OPK Test',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Record the Luteinizing Hormone (LH) surge test result for today.',
                style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: FemFlowColors.ovulation.withValues(alpha: 0.1),
                  child: const Icon(Icons.add, color: FemFlowColors.ovulation),
                ),
                title: const Text('Positive OPK ➕', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('LH surge detected (Highly fertile day)'),
                trailing: currentResult == 'positive' ? const Icon(Icons.check_circle, color: FemFlowColors.primary) : null,
                onTap: () => _saveOvulationTestResult('positive'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: FemFlowColors.textMuted.withValues(alpha: 0.1),
                  child: const Icon(Icons.remove, color: FemFlowColors.textSecondary),
                ),
                title: const Text('Negative OPK ➖', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('No LH surge detected'),
                trailing: currentResult == 'negative' ? const Icon(Icons.check_circle, color: FemFlowColors.primary) : null,
                onTap: () => _saveOvulationTestResult('negative'),
              ),
              if (currentResult != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: FemFlowColors.period.withValues(alpha: 0.1),
                    child: const Icon(Icons.delete_outline, color: FemFlowColors.period),
                  ),
                  title: const Text('Clear OPK Test Result', style: TextStyle(color: FemFlowColors.period)),
                  onTap: () => _saveOvulationTestResult(null),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveOvulationTestResult(String? result) async {
    Navigator.pop(context); // Close sheet
    setState(() => _isLoading = true);

    try {
      final symptomLog = _dayData?['symptoms'];
      final List<String> existingSymptoms = symptomLog != null && symptomLog['symptoms'] != null
          ? List<String>.from(symptomLog['symptoms'])
          : [];
      final List<String> existingMoods = symptomLog != null && symptomLog['moods'] != null
          ? List<String>.from(symptomLog['moods'])
          : [];
      final int existingPain = symptomLog != null && symptomLog['pain_level'] != null
          ? symptomLog['pain_level'] as int
          : 0;
      final String existingEnergy = symptomLog != null && symptomLog['energy_level'] != null
          ? symptomLog['energy_level'] as String
          : 'Medium';
      final String? existingNotes = symptomLog != null ? symptomLog['notes'] : null;
      final String? existingPrimaryMood = symptomLog != null ? symptomLog['primary_mood'] : null;

      final payload = {
        'date': _currentDate.toIso8601String().split('T')[0],
        'symptoms': existingSymptoms,
        'moods': existingMoods,
        'primary_mood': existingPrimaryMood,
        'pain_level': existingPain,
        'energy_level': existingEnergy,
        'notes': existingNotes,
        'ovulation_test_result': result,
      };

      final ApiClient apiClient = ApiClient();
      await apiClient.post('/cycles/symptoms/', body: payload);

      await _fetchDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ovulation test result logged'), behavior: SnackBarBehavior.floating),
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

  Widget _buildCycleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String status,
    bool showLog = false,
    VoidCallback? onLog,
    bool showEnd = false,
    VoidCallback? onEnd,
    bool showEdit = false,
    VoidCallback? onEdit,
  }) {
    final actions = [
      if (showLog) _buildActionButton('Log', onLog, FemFlowColors.primary),
      if (showEdit) _buildActionButton('Edit', onEdit, FemFlowColors.primary),
      if (showEnd) _buildActionButton('End Flow', onEnd, FemFlowColors.period),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 12)),
                    Text(status, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
              if (actions.length == 1) actions.first,
            ],
          ),
          if (actions.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: actions,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback? onTap, Color color) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSexualActivitySection() {
    final activities = _dayData?['sexual_activity'] as List? ?? [];
    final loggedTypes = activities.map((a) => a['activity_type']).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sexual Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _activityCircleItem(
                type: 'unprotected_sex', 
                label: 'Unprotected', 
                icon: Icons.favorite, 
                isActive: loggedTypes.contains('unprotected_sex')
              ),
              const SizedBox(width: 16),
              _activityCircleItem(
                type: 'protected_sex', 
                label: 'Protected', 
                icon: Icons.security, 
                isActive: loggedTypes.contains('protected_sex')
              ),
              const SizedBox(width: 16),
              _activityCircleItem(
                type: 'masturbation', 
                label: 'Masturbation', 
                icon: Icons.touch_app, 
                isActive: loggedTypes.contains('masturbation')
              ),
              const SizedBox(width: 16),
              _activityCircleItem(
                type: 'kissing', 
                label: 'Kissing', 
                icon: Icons.emoji_emotions, 
                isActive: loggedTypes.contains('kissing')
              ),
              const SizedBox(width: 16),
              _activityCircleItem(
                type: 'other', 
                label: 'Other', 
                icon: Icons.more_horiz, 
                isActive: loggedTypes.contains('other')
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityCircleItem({
    required String type,
    required String label,
    required IconData icon,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _toggleSexualActivity(type, isActive),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? FemFlowColors.primary : FemFlowColors.blushMist,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: isActive ? Colors.white : FemFlowColors.primary, 
              size: 24
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              fontSize: 10, 
              color: isActive ? FemFlowColors.textPrimary : FemFlowColors.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            )
          ),
        ],
      ),
    );
  }


  Widget _buildSymptomsSection() {
    final symptomLog = _dayData?['symptoms'];
    final symptoms = symptomLog?['symptoms'] as List? ?? [];
    final mood = symptomLog?['mood'];

    return AppCard(
      onTap: () async {
         final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => SymptomsScreen(initialDate: _currentDate)));
         if (result == true) _fetchDetails();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Symptoms & Mood', style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.edit_note, color: FemFlowColors.primary.withValues(alpha: 0.5), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          if (symptoms.isEmpty && mood == null)
            const Text('Not logged', style: TextStyle(color: FemFlowColors.textMuted, fontSize: 14))
          else ...[
            if (mood != null) 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Mood: ${mood[0].toUpperCase() + mood.substring(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            if (symptoms.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: symptoms.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: FemFlowColors.blushMist, borderRadius: BorderRadius.circular(20)),
                  child: Text(s.toString(), style: const TextStyle(fontSize: 12, color: FemFlowColors.deepRose)),
                )).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedInsightsPreview() {
    final isPremium = PremiumGuard.isPremium(context);
    
    return AppCard(
      onTap: isPremium ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CycleInsightsDetailScreen())) 
                       : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'cycle_insights'))),
      color: Colors.indigo.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.indigo.withValues(alpha: 0.1)),
      child: Row(
        children: [
          const Icon(Icons.insights, color: Colors.indigo),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cycle Pattern Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                Text('Compare current cycle with averages', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
              ],
            ),
          ),
          if (!isPremium)
            const Icon(Icons.lock, size: 16, color: FemFlowColors.textMuted)
          else
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildPainEnergySection() {
    final symptomLog = _dayData?['symptoms'];
    final pain = symptomLog?['pain_level'];
    final energy = symptomLog?['energy_level'];

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _buildSimpleMetric('Pain Level', pain?.toString() ?? 'N/A', Icons.healing),
          ),
          const VerticalDivider(),
          Expanded(
            child: _buildSimpleMetric('Energy Level', energy?.toString() ?? 'N/A', Icons.bolt),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: FemFlowColors.textMuted),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNotesSection() {
    final notes = _dayData?['journal_notes'] as List? ?? [];
    final isPremium = PremiumGuard.isPremium(context);

    return AppCard(
      onTap: isPremium ? null : () => PremiumGuard.openPremiumFeature(
        context: context, 
        featureKey: 'journal', 
        premiumScreen: const JournalScreen()
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notes & Journal', style: TextStyle(fontWeight: FontWeight.bold)),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                )
              else
                TextButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalScreen()));
                    _fetchDetails();
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          if (!isPremium)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Unlock a private health journal to record your physical and emotional journey.',
                style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            )
          else if (notes.isNotEmpty)
            ...notes.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(n['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
            ))
          else
            const Text('No notes for this date', style: TextStyle(color: FemFlowColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final docs = _dayData?['health_documents'] as List? ?? [];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Health Vault', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  // Navigate to vault or upload
                },
                child: const Text('Add'),
              ),
            ],
          ),
          if (docs.isNotEmpty)
            ...docs.map((d) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, color: Colors.blue),
              title: Text(d['title']),
              subtitle: Text(d['document_type_label']),
              dense: true,
            ))
          else
            const Text('No documents linked', style: TextStyle(color: FemFlowColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildExerciseSection() {
    final rec = _dayData?['recommended_exercise'];
    if (rec == null) return const SizedBox.shrink();

    final exercise = ex_models.Exercise.fromJson(rec['exercise']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recommended Exercise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen())),
              child: const Text('Library >', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ExerciseCard(
          exercise: exercise,
          recommendationReason: rec['reason'],
        ),
      ],
    );
  }

  Widget _buildContraceptionSection() {
    final contraception = _dayData?['contraception'] ?? {};
    final isConfigured = contraception['configured'] == true;
    final isPremium = PremiumGuard.isPremium(context);

    return AppCard(
      onTap: isPremium ? null : () => PremiumGuard.openPremiumFeature(
        context: context, 
        featureKey: 'pill_reminder', 
        premiumScreen: const PillReminderListScreen()
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Contraception', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (!isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                )
              else
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PillReminderListScreen()),
                  ).then((_) => _fetchDetails()),
                  child: Text(isConfigured ? 'Configure >' : 'Configure', style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isPremium)
            const Text(
              'Unlock smart medication reminders so you never miss a dose.',
              style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary, height: 1.4),
            )
          else if (!isConfigured)
            const Text('No contraception reminder configured', style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary))
          else ...[
            Row(
              children: [
                _buildPillStatusItem(
                  'Yesterday',
                  contraception['yesterday']?['status'] ?? 'not_logged',
                ),
                const SizedBox(width: 16),
                _buildPillStatusItem(
                  'Today',
                  contraception['today']?['status'] ?? 'pending',
                  reminderId: contraception['today']?['reminder_id'],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillStatusItem(String label, String status, {int? reminderId}) {
    Color statusColor;
    IconData icon = Icons.medication_outlined;
    String statusText = status.toUpperCase();

    switch (status) {
      case 'taken':
        statusColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'missed':
        statusColor = Colors.red;
        icon = Icons.error;
        break;
      case 'skipped':
        statusColor = Colors.orange;
        icon = Icons.block;
        break;
      case 'pending':
        statusColor = Colors.blue;
        icon = Icons.access_time;
        break;
      default:
        statusColor = FemFlowColors.textMuted;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: FemFlowColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
            if (status == 'pending' && reminderId != null && DateUtils.isSameDay(_currentDate, DateTime.now()))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () async {
                    await _pillService.markAsTaken(reminderId);
                    _fetchDetails();
                  },
                  child: const Text(
                    'Mark Taken',
                    style: TextStyle(fontSize: 12, color: FemFlowColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFemAIPriorityTips() {
    final isPremium = PremiumGuard.isPremium(context);
    if (!isPremium) {
       return AppCard(
         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'cycle_insights'))),
         color: const Color(0xFFF3F0FF),
         border: BorderSide.none,
         child: Column(
           children: [
             const Row(
               children: [
                 Text('FemAI Daily Tips', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
               ],
             ),
             const SizedBox(height: 12),
             const Text(
               'Get personalized daily guidance based on your cycle phase and symptoms.',
               style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 13),
             ),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
               decoration: BoxDecoration(color: FemFlowColors.primary, borderRadius: BorderRadius.circular(20)),
               child: const Text('Unlock with Premium', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
             ),
           ],
         ),
       );
    }

    final tips = _dayData?['femai_priority_tips'] as List? ?? [];
    final summary = _dayData?['femai_summary'] ?? 'Log your data to get personalized cycle insights.';

    return AppCard(
      color: const Color(0xFFF3F0FF), // Lavender soft card
      border: BorderSide.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FemAI Priority Tips',
                    style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Personalized for this day',
                    style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (tips.isEmpty)
             Text(
               summary,
               style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary),
             )
          else
            ...tips.map((tip) => _buildTipRow(tip)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => FemAIChatScreen(
                        dayContext: _dayData,
                        initialMessage: "I want to ask about my health for ${_dayData?['display_date'] ?? 'this day'}.",
                      ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Ask FemAI about this day',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(Map<String, dynamic> tip) {
    final color = _getTipColor(tip['color_type']);
    final icon = _getTipIcon(tip['icon']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tip['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (tip['priority'] == 'high') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIGH',
                          style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tip['message'],
                  style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary, height: 1.3),
                ),
                if (tip['action_type'] != null)
                   GestureDetector(
                     onTap: () => _handleTipAction(tip['action_type']),
                     child: Padding(
                       padding: const EdgeInsets.only(top: 6),
                       child: Text(
                         tip['action_label'] ?? 'Learn more',
                         style: TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.bold,
                           color: color,
                           decoration: TextDecoration.underline,
                         ),
                       ),
                     ),
                   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTipColor(String? colorType) {
    switch (colorType) {
      case 'red': return Colors.redAccent;
      case 'pink': return FemFlowColors.period;
      case 'orange': return Colors.orange;
      case 'teal': return Colors.teal;
      case 'mint': return FemFlowColors.fertileWindow;
      case 'lavender': return FemFlowColors.primary;
      default: return FemFlowColors.textMuted;
    }
  }

  IconData _getTipIcon(String? icon) {
    switch (icon) {
      case 'warning': return Icons.warning_amber_rounded;
      case 'period': return Icons.opacity;
      case 'healing': return Icons.healing_outlined;
      case 'ovulation': return Icons.wb_sunny_outlined;
      case 'fertility': return Icons.favorite_border;
      case 'mood': return Icons.sentiment_satisfied_outlined;
      case 'bolt': return Icons.bolt;
      case 'health_and_safety': return Icons.health_and_safety_outlined;
      case 'edit': return Icons.edit_note;
      case 'favorite': return Icons.favorite_outline;
      default: return Icons.lightbulb_outline;
    }
  }

  void _handleTipAction(String actionType) {
    switch (actionType) {
      case 'log_symptoms':
      case 'log_mood':
        Navigator.push(context, MaterialPageRoute(builder: (_) => SymptomsScreen(initialDate: _currentDate))).then((_) => _fetchDetails());
        break;
      case 'log_period':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PeriodCalendarEditorScreen(initialStartDate: _currentDate))).then((_) => _fetchDetails());
        break;
      case 'wellness_check':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessScoreDashboardScreen())).then((_) => _fetchDetails());
        break;
      case 'consult_doctor':
        // Placeholder or specific doctor screen
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to medical support...')));
        break;
      case 'view_cycle':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CycleInsightsDetailScreen())).then((_) => _fetchDetails());
        break;
      case 'add_note':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const JournalScreen())).then((_) => _fetchDetails());
        break;
      default:
        break;
    }
  }

  Widget _buildActivityAndCaloriesSection() {
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalorieBurnScreen())).then((_) => _fetchDetails()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activity & Calories', style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.bolt, color: Colors.orange.withValues(alpha: 0.5), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_activitySummary?.totalCaloriesBurned ?? 0} kcal',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const Text('Estimated Burn', style: TextStyle(fontSize: 11, color: FemFlowColors.textSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_activitySummary?.activeMinutes ?? 0} min',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                  ),
                  const Text('Active Time', style: TextStyle(fontSize: 11, color: FemFlowColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_activitySummary != null && _activitySummary!.totalCaloriesBurned == 0)
            PrimaryButton(
              label: 'Add Activity',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddActivityScreen())).then((_) => _fetchDetails()),
            ),
        ],
      ),
    );
  }

  Widget _buildSafetyNote() {
    return const Center(
      child: Text(
        'Cycle predictions are estimates and not medical advice.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: FemFlowColors.textMuted, fontStyle: FontStyle.italic),
      ),
    );
  }

  Future<void> _toggleSexualActivity(String type, bool currentlyLogged) async {
    try {
      if (currentlyLogged) {
        // Toggle off: delete the specific log
        final activities = _dayData?['sexual_activity'] as List? ?? [];
        final activity = activities.firstWhere(
          (e) => e['activity_type'] == type,
          orElse: () => null,
        );
        if (activity != null) {
          await _cycleService.deleteSexualActivityLog(activity['id']);
        }
      } else {
        // Toggle on: create new log
        await _cycleService.createSexualActivityLog(SexualActivityLog(
          date: _currentDate,
          activityType: type,
        ));
      }
      
      // Silent refresh instead of full-screen loader
      final data = await _cycleService.getDayDetails(_currentDate);
      if (mounted) {
        setState(() {
          _dayData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update activity.")));
      }
    }
  }


  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!, style: const TextStyle(color: FemFlowColors.period)),
          const SizedBox(height: 16),
          TextButton(onPressed: _fetchDetails, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _formatOrdinal(int? number) {
    if (number == null) return '';
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }
}
