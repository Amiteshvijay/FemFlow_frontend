import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/diet_service.dart';
import '../models/meal_plan.dart';
import '../../exercises/screens/exercise_detail_screen.dart';
import '../../activity/screens/calorie_burn_screen.dart';
import '../custom_plan/create_custom_plan_screen.dart';
import '../custom_plan/my_custom_plans_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import 'dart:developer' as dev;

class DietHomeScreen extends StatefulWidget {
  const DietHomeScreen({super.key});

  @override
  State<DietHomeScreen> createState() => _DietHomeScreenState();
}

class _DietHomeScreenState extends State<DietHomeScreen> {
  final DietService _dietService = DietService();
  MealPlan? _plan;
  bool _isLoading = true;
  bool _remindersEnabled = false;
  Map<String, TimeOfDay> _reminderTimes = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? false;
      _reminderTimes = {
        'breakfast': _parseTime(prefs.getString('reminder_breakfast_time') ?? '08:00'),
        'water1': _parseTime(prefs.getString('reminder_water1_time') ?? '10:30'),
        'lunch': _parseTime(prefs.getString('reminder_lunch_time') ?? '13:00'),
        'water2': _parseTime(prefs.getString('reminder_water2_time') ?? '15:30'),
        'snack': _parseTime(prefs.getString('reminder_snack_time') ?? '17:00'),
        'dinner': _parseTime(prefs.getString('reminder_dinner_time') ?? '20:00'),
        'water3': _parseTime(prefs.getString('reminder_water3_time') ?? '21:30'),
      };
    });
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $period';
  }

  Future<void> _toggleReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', value);
    setState(() {
      _remindersEnabled = value;
    });

    if (value) {
      await _scheduleAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily alerts scheduled!')),
        );
      }
    } else {
      await _cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily alerts disabled.')),
        );
      }
    }
  }

  Future<void> _scheduleAllNotifications() async {
    final notificationService = NotificationService();
    await notificationService.requestPermissions();
    await notificationService.requestExactAlarmPermission();

    await _scheduleSingleNotification('breakfast', 101, 'Time for Breakfast!', 'Fuel your body with a professional, nourishing meal.', _reminderTimes['breakfast'] ?? const TimeOfDay(hour: 8, minute: 0));
    await _scheduleSingleNotification('water1', 102, 'Hydration Check!', 'Drink a fresh glass of water to support metabolism.', _reminderTimes['water1'] ?? const TimeOfDay(hour: 10, minute: 30));
    await _scheduleSingleNotification('lunch', 103, 'Time for Lunch!', 'Enjoy your custom balanced meal to support your goal.', _reminderTimes['lunch'] ?? const TimeOfDay(hour: 13, minute: 0));
    await _scheduleSingleNotification('water2', 104, 'Hydration Check!', 'Keep going! Drink some water to stay energized.', _reminderTimes['water2'] ?? const TimeOfDay(hour: 15, minute: 30));
    await _scheduleSingleNotification('snack', 105, 'Snack Alert!', 'Time for a light healthy snack to keep energy steady.', _reminderTimes['snack'] ?? const TimeOfDay(hour: 17, minute: 0));
    await _scheduleSingleNotification('dinner', 106, 'Time for Dinner!', 'Wrap up your day with a light, protein-rich dinner.', _reminderTimes['dinner'] ?? const TimeOfDay(hour: 20, minute: 0));
    await _scheduleSingleNotification('water3', 107, 'Hydration Check!', 'A glass of water before bed to support muscle recovery.', _reminderTimes['water3'] ?? const TimeOfDay(hour: 21, minute: 30));
  }

  Future<void> _scheduleSingleNotification(String key, int id, String title, String body, TimeOfDay time) async {
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    final notificationService = NotificationService();
    await notificationService.cancelNotification(id);
    
    await notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      repeatDaily: true,
      payload: 'diet:$key',
    );
  }

  Future<void> _cancelAllNotifications() async {
    final notificationService = NotificationService();
    await notificationService.cancelNotification(101);
    await notificationService.cancelNotification(102);
    await notificationService.cancelNotification(103);
    await notificationService.cancelNotification(104);
    await notificationService.cancelNotification(105);
    await notificationService.cancelNotification(106);
    await notificationService.cancelNotification(107);
  }

  Future<void> _updateReminderTime(String key, int id, String title, String body, TimeOfDay newTime) async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
    await prefs.setString('reminder_${key}_time', timeStr);
    
    setState(() {
      _reminderTimes[key] = newTime;
    });

    if (_remindersEnabled) {
      await _scheduleSingleNotification(key, id, title, body, newTime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rescheduled alert for ${_formatTimeOfDay(newTime)}')),
        );
      }
    }
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final plan = await _dietService.getTodayDietPlan();
      setState(() {
        _plan = plan;
        _isLoading = false;
      });
    } catch (e, stack) {
      dev.log('Error fetching diet plan', error: e, stackTrace: stack);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Nutrition', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFocusHeader(),
                    const SizedBox(height: 24),
                    _buildGoalCard(),
                    const SizedBox(height: 16),
                    _buildCreateCustomPlanCard(),
                    const SizedBox(height: 24),
                    _buildCalorieBalanceCard(),
                    const SizedBox(height: 24),
                    _buildHydrationCard(),
                    const SizedBox(height: 24),
                    _buildRemindersCard(),
                    const SizedBox(height: 24),
                    _buildDietExerciseMatchCard(),
                    const SizedBox(height: 24),
                    _buildMealSection(),
                    const SizedBox(height: 24),
                    _buildDietScoreCard(),
                    const SizedBox(height: 24),
                    _buildFemAITipCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRemindersCard() {
    final List<Map<String, dynamic>> items = [
      {'key': 'breakfast', 'id': 101, 'label': 'Breakfast Alert', 'icon': Icons.wb_sunny_outlined, 'title': 'Time for Breakfast!', 'body': 'Fuel your body with a professional, nourishing meal.'},
      {'key': 'water1', 'id': 102, 'label': 'Water Alert 1', 'icon': Icons.opacity, 'title': 'Hydration Check!', 'body': 'Drink a fresh glass of water to support metabolism.'},
      {'key': 'lunch', 'id': 103, 'label': 'Lunch Alert', 'icon': Icons.light_mode, 'title': 'Time for Lunch!', 'body': 'Enjoy your custom balanced meal to support your goal.'},
      {'key': 'water2', 'id': 104, 'label': 'Water Alert 2', 'icon': Icons.opacity, 'title': 'Hydration Check!', 'body': 'Keep going! Drink some water to stay energized.'},
      {'key': 'snack', 'id': 105, 'label': 'Snack Alert', 'icon': Icons.apple, 'title': 'Snack Alert!', 'body': 'Time for a light healthy snack to keep energy steady.'},
      {'key': 'dinner', 'id': 106, 'label': 'Dinner Alert', 'icon': Icons.dark_mode_outlined, 'title': 'Time for Dinner!', 'body': 'Wrap up your day with a light, protein-rich dinner.'},
      {'key': 'water3', 'id': 107, 'label': 'Water Alert 3', 'icon': Icons.opacity, 'title': 'Hydration Check!', 'body': 'A glass of water before bed to support muscle recovery.'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: FemFlowColors.primary, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Daily Reminders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemFlowColors.textPrimary),
                  ),
                ],
              ),
              Switch(
                value: _remindersEnabled,
                onChanged: _toggleReminders,
                activeTrackColor: FemFlowColors.primary.withValues(alpha: 0.5),
                activeThumbColor: FemFlowColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your nutrition and water consistent with offline-resilient alerts.',
            style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary, height: 1.4),
          ),
          if (_remindersEnabled) ...[
            const Divider(height: 24),
            const Text(
              'Customize Timeline',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final key = item['key'] as String;
                final time = _reminderTimes[key] ?? const TimeOfDay(hour: 8, minute: 0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(item['icon'] as IconData, size: 16, color: FemFlowColors.primary.withValues(alpha: 0.6)),
                          const SizedBox(width: 8),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(fontSize: 13, color: FemFlowColors.textPrimary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () async {
                          final newTime = await showTimePicker(
                            context: context,
                            initialTime: time,
                          );
                          if (newTime != null) {
                            await _updateReminderTime(
                              key,
                              item['id'] as int,
                              item['title'] as String,
                              item['body'] as String,
                              newTime,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: FemFlowColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _formatTimeOfDay(time),
                                style: const TextStyle(color: FemFlowColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 12, color: FemFlowColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalorieBalanceCard() {
    // This requires current activity burn stats
    // We'll use a simplified integration card
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalorieBurnScreen())).then((_) => _fetchData()),
      color: Colors.orange.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.orange.withValues(alpha: 0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calorie Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.bolt, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'See how your activity today balances with your nutrition goals.',
            style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text('View Activity Burn >', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusHeader() {
    final phase = _plan?.cyclePhase.toUpperCase() ?? 'TRACKING';
    final focus = _plan?.nutritionFocus ?? 'Balanced Nutrition';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Nutrition Focus',
          style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$phase PHASE · $focus',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    return AppCard(
      color: FemFlowColors.primary.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.primary.withValues(alpha: 0.2)),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: FemFlowColors.primary,
            child: Icon(Icons.track_changes, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Goal', style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 12)),
                Text(
                  _plan?.goal.replaceAll('_', ' ').toUpperCase() ?? 'MAINTENANCE',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCustomPlanCard() {
    return AppCard(
      color: Colors.white,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateCustomPlanScreen()),
        ).then((_) => _fetchData());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu_rounded, color: FemFlowColors.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Create Custom Plan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemFlowColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FemFlowColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PERSONALIZED',
                  style: TextStyle(
                    color: FemFlowColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Build a plan based on your calorie needs, goals, and doctor advice.',
            style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateCustomPlanScreen()),
                  ).then((_) => _fetchData());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: FemFlowColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Create Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCustomPlansScreen()),
                  ).then((_) => _fetchData());
                },
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: const Text('My Plans'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FemFlowColors.primary,
                  side: const BorderSide(color: FemFlowColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard() {
    final stats = _plan?.hydration;
    final consumed = stats?.consumedMl ?? 0;
    final target = stats?.targetMl ?? 2000;
    final percent = consumed / target;

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hydration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$consumed / $target ml', style: const TextStyle(color: FemFlowColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            color: Colors.blue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _waterButton(250),
              _waterButton(500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waterButton(int ml) {
    return OutlinedButton.icon(
      onPressed: () async {
        if (_plan != null) {
          setState(() {
            _plan = MealPlan(
              id: _plan!.id,
              date: _plan!.date,
              goal: _plan!.goal,
              cyclePhase: _plan!.cyclePhase,
              nutritionFocus: _plan!.nutritionFocus,
              hydration: HydrationStats(
                targetMl: _plan!.hydration.targetMl,
                consumedMl: _plan!.hydration.consumedMl + ml,
              ),
              dietScore: _plan!.dietScore,
              exerciseMatch: _plan!.exerciseMatch,
              meals: _plan!.meals,
              femaiTip: _plan!.femaiTip,
            );
          });
        }
        await _dietService.logWater(ml);
        _fetchData(silent: true);
      },
      icon: const Icon(Icons.add, size: 16),
      label: Text('$ml ml'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDietExerciseMatchCard() {
    final match = _plan?.exerciseMatch;
    
    return AppCard(
      color: Colors.indigo.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.indigo.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              const Text('Diet + Movement Match', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 12),
          Text(match?.reason ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          if (match?.isCompleted ?? false)
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
               child: Row(
                 children: [
                   const Icon(Icons.check_circle, color: Colors.green, size: 18),
                   const SizedBox(width: 8),
                   Expanded(child: Text(match?.recoveryTip ?? 'Great job! Rehydrate for recovery.', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600))),
                 ],
               ),
             )
          else
            PrimaryButton(
              label: 'Start ${match?.title ?? "Movement"} (${match?.duration ?? "20 min"})',
              onPressed: () {
                if (match?.exerciseId != null) {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailScreen(
                     exerciseId: match!.exerciseId!,
                     source: 'diet_plan',
                   ))).then((_) => _fetchData());
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMealSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s Meal Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        if (_plan?.meals.isEmpty ?? true)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Your personalized meal suggestions will appear here.', style: TextStyle(color: FemFlowColors.textMuted)),
          )
        else
          ..._plan!.meals.map((meal) => _mealCard(meal)),
      ],
    );
  }

  Widget _mealCard(MealPlanItem meal) {
    String? formattedTime;
    if (meal.isEaten && meal.eatenAt != null) {
      final localTime = meal.eatenAt!.toLocal();
      final hour = localTime.hour;
      final minute = localTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      formattedTime = '$formattedHour:$minute $period';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: meal.isEaten 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : FemFlowColors.primary.withValues(alpha: 0.1), 
                shape: BoxShape.circle
              ),
              child: Icon(
                _getMealIcon(meal.mealType), 
                color: meal.isEaten ? Colors.green : FemFlowColors.primary, 
                size: 20
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        meal.mealType.toUpperCase(), 
                        style: TextStyle(
                          color: meal.isEaten ? Colors.green : FemFlowColors.textSecondary, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                      if (meal.isEaten && formattedTime != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Completed at $formattedTime',
                            style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    meal.name, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      decoration: meal.isEaten ? TextDecoration.lineThrough : null,
                      color: meal.isEaten ? FemFlowColors.textSecondary : FemFlowColors.textPrimary,
                    )
                  ),
                  Text('${meal.calories} kcal · ${meal.protein}g protein', style: const TextStyle(color: FemFlowColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                meal.isEaten ? Icons.check_circle : Icons.radio_button_unchecked,
                color: meal.isEaten ? Colors.green : FemFlowColors.textMuted,
                size: 24,
              ),
              onPressed: () async {
                final originalEaten = meal.isEaten;
                if (_plan != null) {
                  setState(() {
                    _plan = MealPlan(
                      id: _plan!.id,
                      date: _plan!.date,
                      goal: _plan!.goal,
                      cyclePhase: _plan!.cyclePhase,
                      nutritionFocus: _plan!.nutritionFocus,
                      hydration: _plan!.hydration,
                      dietScore: _plan!.dietScore,
                      exerciseMatch: _plan!.exerciseMatch,
                      meals: _plan!.meals.map((m) {
                        if (m.id == meal.id) {
                          return MealPlanItem(
                            id: m.id,
                            mealType: m.mealType,
                            name: m.name,
                            calories: m.calories,
                            protein: m.protein,
                            reason: m.reason,
                            isEaten: !originalEaten,
                            eatenAt: !originalEaten ? DateTime.now() : null,
                          );
                        }
                        return m;
                      }).toList(),
                      femaiTip: _plan!.femaiTip,
                    );
                  });
                }
                try {
                  await _dietService.logMealEaten(meal.id, !originalEaten);
                  await _fetchData(silent: true);
                } catch (e) {
                  // Revert optimistic update on error
                  if (_plan != null) {
                    setState(() {
                      _plan = MealPlan(
                        id: _plan!.id,
                        date: _plan!.date,
                        goal: _plan!.goal,
                        cyclePhase: _plan!.cyclePhase,
                        nutritionFocus: _plan!.nutritionFocus,
                        hydration: _plan!.hydration,
                        dietScore: _plan!.dietScore,
                        exerciseMatch: _plan!.exerciseMatch,
                        meals: _plan!.meals.map((m) {
                          if (m.id == meal.id) {
                            return MealPlanItem(
                              id: m.id,
                              mealType: m.mealType,
                              name: m.name,
                              calories: m.calories,
                              protein: m.protein,
                              reason: m.reason,
                              isEaten: originalEaten,
                              eatenAt: m.eatenAt,
                            );
                          }
                          return m;
                        }).toList(),
                        femaiTip: _plan!.femaiTip,
                      );
                    });
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating meal: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return Icons.wb_sunny_outlined;
      case 'lunch': return Icons.light_mode;
      case 'snack': return Icons.apple;
      case 'dinner': return Icons.dark_mode_outlined;
      default: return Icons.restaurant;
    }
  }

  Widget _buildDietScoreCard() {
    final score = _plan?.dietScore;
    return AppCard(
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: (score?.score ?? 0) / 100,
                  strokeWidth: 6,
                  color: Colors.green,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                ),
              ),
              Text('${score?.score ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Diet Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(score?.explanation ?? 'Log meals to see your score.', style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFemAITipCard() {
    return AppCard(
      color: FemFlowColors.aiWellness.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.aiWellness.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(width: 8),
              Text('FemAI Food Tip', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_plan?.femaiTip ?? 'Focus on balanced hydration and consistent protein today.', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
