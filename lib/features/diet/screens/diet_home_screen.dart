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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
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
                      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
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
        await _dietService.logWater(ml);
        _fetchData();
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: FemFlowColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_getMealIcon(meal.mealType), color: FemFlowColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.mealType.toUpperCase(), style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${meal.calories} kcal · ${meal.protein}g protein', style: const TextStyle(color: FemFlowColors.textMuted, fontSize: 12)),
                ],
              ),
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
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: FemFlowColors.aiWellness, size: 18),
              const SizedBox(width: 8),
              const Text('FemAI Food Tip', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_plan?.femaiTip ?? 'Focus on balanced hydration and consistent protein today.', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
