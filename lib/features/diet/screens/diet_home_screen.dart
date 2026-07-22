import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/diet_service.dart';
import '../models/meal_plan.dart';
import '../../exercises/screens/exercise_detail_screen.dart';
import '../../activity/screens/calorie_burn_screen.dart';
import '../custom_plan/create_custom_plan_screen.dart';
import '../custom_plan/my_custom_plans_screen.dart';
import 'dart:developer' as dev;
import '../data/nutrition_reminder_helper.dart';
import 'nutrition_reminder_screen.dart';

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
  int _activeRemindersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final enabled = await NutritionReminderHelper.areRemindersEnabled();
    final list = await NutritionReminderHelper.loadReminders();
    setState(() {
      _remindersEnabled = enabled;
      _activeRemindersCount = list.length;
    });
  }

  Future<void> _toggleReminders(bool value) async {
    await NutritionReminderHelper.setRemindersEnabled(value);
    setState(() {
      _remindersEnabled = value;
    });

    final list = await NutritionReminderHelper.loadReminders();
    if (value) {
      await NutritionReminderHelper.scheduleAll(list);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily alerts scheduled!')),
        );
      }
    } else {
      await NutritionReminderHelper.cancelAll(list);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily alerts disabled.')),
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
      backgroundColor: FemLyraColors.warmWhite,
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
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NutritionReminderScreen()),
        ).then((_) => _loadReminders());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: FemLyraColors.primary, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Daily Reminders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemLyraColors.textPrimary),
                  ),
                ],
              ),
              Switch(
                value: _remindersEnabled,
                onChanged: _toggleReminders,
                activeTrackColor: FemLyraColors.primary.withValues(alpha: 0.5),
                activeThumbColor: FemLyraColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _remindersEnabled
                ? 'Active: $_activeRemindersCount alert${_activeRemindersCount == 1 ? "" : "s"} scheduled. Tap to customize.'
                : 'Keep your nutrition consistent with offline-resilient alerts. Tap to configure.',
            style: const TextStyle(fontSize: 13, color: FemLyraColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Text(
                'Configure Alerts >',
                style: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
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
            style: TextStyle(fontSize: 13, color: FemLyraColors.textSecondary),
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
          style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '$phase PHASE · $focus',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    return AppCard(
      color: FemLyraColors.primary.withValues(alpha: 0.05),
      border: BorderSide(color: FemLyraColors.primary.withValues(alpha: 0.2)),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: FemLyraColors.primary,
            child: Icon(Icons.track_changes, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Goal', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 12)),
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
                    const Icon(Icons.restaurant_menu_rounded, color: FemLyraColors.primary, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Create Custom Plan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemLyraColors.textPrimary),
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
                  color: FemLyraColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PERSONALIZED',
                  style: TextStyle(
                    color: FemLyraColors.primary,
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
            style: TextStyle(fontSize: 13, color: FemLyraColors.textSecondary, height: 1.4),
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
                    color: FemLyraColors.primary,
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
                  foregroundColor: FemLyraColors.primary,
                  side: const BorderSide(color: FemLyraColors.primary),
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

  Future<void> _showHydrationCalculator() async {
    double selectedWeight = 60.0;
    int selectedAge = 28;
    bool isPregnant = false;
    double pregnancyWeek = 12;
    bool summerHeat = false;
    bool vomiting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double baseline = selectedWeight * 35;
            if (baseline < 2000) baseline = 2000;
            if (baseline > 2700) baseline = 2700;

            double calculated = baseline;
            if (isPregnant) {
              calculated += 300;
              if (pregnancyWeek > 28) {
                calculated += 200;
              }
            }
            if (summerHeat) {
              calculated += 800;
            }
            if (vomiting) {
              calculated += 500;
            }
            if (selectedAge > 55) {
              calculated -= 200;
            }

            if (calculated > 4000) calculated = 4000;
            if (calculated < 2000) calculated = 2000;

            final targetMl = calculated.round();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Hydration Calculator',
                style: TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculate your daily fluid intake targets based on personal health metrics.',
                      style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Weight: ${selectedWeight.round()} kg', style: const TextStyle(fontWeight: FontWeight.w500)),
                        SizedBox(
                          width: 150,
                          child: Slider(
                            value: selectedWeight,
                            min: 35.0,
                            max: 120.0,
                            activeColor: FemLyraColors.primary,
                            onChanged: (val) {
                              setDialogState(() => selectedWeight = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Age: $selectedAge years', style: const TextStyle(fontWeight: FontWeight.w500)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: FemLyraColors.primary),
                              onPressed: () {
                                if (selectedAge > 10) {
                                  setDialogState(() => selectedAge--);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: FemLyraColors.primary),
                              onPressed: () {
                                if (selectedAge < 100) {
                                  setDialogState(() => selectedAge++);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Are you pregnant?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: isPregnant,
                      activeThumbColor: FemLyraColors.primary,
                      activeTrackColor: FemLyraColors.primary.withValues(alpha: 0.5),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => isPregnant = val);
                      },
                    ),
                    if (isPregnant) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Week of pregnancy: ${pregnancyWeek.round()}', style: const TextStyle(fontSize: 13, color: FemLyraColors.textSecondary)),
                            SizedBox(
                              width: 120,
                              child: Slider(
                                value: pregnancyWeek,
                                min: 1.0,
                                max: 42.0,
                                activeColor: FemLyraColors.primary,
                                onChanged: (val) {
                                  setDialogState(() => pregnancyWeek = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SwitchListTile(
                      title: const Text('Summer heat / heavy exercise?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: summerHeat,
                      activeThumbColor: FemLyraColors.primary,
                      activeTrackColor: FemLyraColors.primary.withValues(alpha: 0.5),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => summerHeat = val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Experiencing vomiting/morning sickness?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: vomiting,
                      activeThumbColor: FemLyraColors.primary,
                      activeTrackColor: FemLyraColors.primary.withValues(alpha: 0.5),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() => vomiting = val);
                      },
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FemLyraColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECOMMENDED DAILY TARGET',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FemLyraColors.primary, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$targetMl ml (${(targetMl / 1000).toStringAsFixed(1)} Liters)',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 14, color: FemLyraColors.textSecondary),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Safe drinking rate: Kidneys process about 0.8–1.0L per hour safely.',
                                  style: TextStyle(fontSize: 11, color: FemLyraColors.textSecondary, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: FemLyraColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    try {
                      await _dietService.updateHydrationTarget(targetMl);
                      await _fetchData();
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to update target: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Apply Target', style: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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
              Row(
                children: [
                  const Text('Hydration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showHydrationCalculator,
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: FemLyraColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Text('$consumed / $target ml', style: const TextStyle(color: FemLyraColors.textSecondary)),
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
            child: Text('Your personalized meal suggestions will appear here.', style: TextStyle(color: FemLyraColors.textMuted)),
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
                    : FemLyraColors.primary.withValues(alpha: 0.1), 
                shape: BoxShape.circle
              ),
              child: Icon(
                _getMealIcon(meal.mealType), 
                color: meal.isEaten ? Colors.green : FemLyraColors.primary, 
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
                          color: meal.isEaten ? Colors.green : FemLyraColors.textSecondary, 
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
                      color: meal.isEaten ? FemLyraColors.textSecondary : FemLyraColors.textPrimary,
                    )
                  ),
                  Text('${meal.calories} kcal · ${meal.protein}g protein', style: const TextStyle(color: FemLyraColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: Icon(
                meal.isEaten ? Icons.check_circle : Icons.radio_button_unchecked,
                color: meal.isEaten ? Colors.green : FemLyraColors.textMuted,
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
                Text(score?.explanation ?? 'Log meals to see your score.', style: const TextStyle(color: FemLyraColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFemAITipCard() {
    return AppCard(
      color: FemLyraColors.aiWellness.withValues(alpha: 0.05),
      border: BorderSide(color: FemLyraColors.aiWellness.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(width: 8),
              Text('FemAI Food Tip', style: TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.aiWellness)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_plan?.femaiTip ?? 'Focus on balanced hydration and consistent protein today.', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
