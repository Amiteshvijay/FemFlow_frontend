import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'custom_plan_models.dart';
import 'custom_plan_service.dart';
import '../screens/diet_home_screen.dart';

class CustomPlanResultScreen extends StatefulWidget {
  final CustomNutritionPlan plan;

  const CustomPlanResultScreen({super.key, required this.plan});

  @override
  State<CustomPlanResultScreen> createState() => _CustomPlanResultScreenState();
}

class _CustomPlanResultScreenState extends State<CustomPlanResultScreen> {
  final CustomPlanService _service = CustomPlanService();
  bool _isActivating = false;
  bool _isDeactivating = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.plan.status;
  }

  Future<void> _activatePlan() async {
    if (widget.plan.id == null) return;
    
    setState(() => _isActivating = true);
    try {
      await _service.activatePlan(widget.plan.id!);
      setState(() {
        _status = 'active';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom plan activated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error activating plan: $e')),
        );
      }
    } finally {
      setState(() => _isActivating = false);
    }
  }

  Future<void> _deactivatePlan() async {
    if (widget.plan.id == null) return;
    
    setState(() => _isDeactivating = true);
    try {
      await _service.deactivatePlan(widget.plan.id!);
      setState(() {
        _status = 'draft';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom plan deactivated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deactivating plan: $e')),
        );
      }
    } finally {
      setState(() => _isDeactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMacroTargets(),
                  const SizedBox(height: 32),
                  const Text('Your Personalized Meals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...widget.plan.meals.map((meal) => _mealCard(meal)),
                  const SizedBox(height: 32),
                  if (widget.plan.doctorAdviceEnabled && widget.plan.doctorAdviceNotes != null)
                    _buildAdviceAppliedCard(),
                  const SizedBox(height: 40),
                  if (_status == 'active')
                    PrimaryButton(
                      label: 'Deactivate This Plan',
                      isLoading: _isDeactivating,
                      backgroundColor: Colors.red.shade600,
                      onPressed: _deactivatePlan,
                    )
                  else
                    PrimaryButton(
                      label: 'Activate This Plan',
                      isLoading: _isActivating,
                      onPressed: _activatePlan,
                    ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Edit Plan Settings', style: TextStyle(color: FemFlowColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Custom Plan Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(color: FemFlowColors.primary),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DietHomeScreen()),
            (route) => route.isFirst,
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      color: FemFlowColors.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.plan.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${widget.plan.targetCalories} kcal/day',
            style: const TextStyle(color: FemFlowColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on your ${widget.plan.goal.replaceAll('_', ' ')} goal and ${widget.plan.cyclePhaseAtGeneration ?? "current"} cycle phase.',
            style: const TextStyle(fontSize: 13, color: FemFlowColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroTargets() {
    final macros = widget.plan.macroTargets;
    return Row(
      children: [
        _macroItem('Protein', '${macros['protein_g'] ?? 0}g', Colors.orange),
        _macroItem('Carbs', '${macros['carbs_g'] ?? 0}g', Colors.blue),
        _macroItem('Fats', '${macros['fats_g'] ?? 0}g', Colors.green),
        _macroItem('Fiber', '${macros['fiber_g'] ?? 25}g', Colors.purple),
      ],
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10, color: FemFlowColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _mealCard(CustomPlanMeal meal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: FemFlowColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(_getMealIcon(meal.mealType), color: FemFlowColors.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.mealType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
                      Text(meal.mealName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                Text('${meal.calories} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(meal.reason, style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary)),
            if (meal.doctorAdviceApplied) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  const Text('Matches doctor advice', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
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

  Widget _buildAdviceAppliedCard() {
    return AppCard(
      color: Colors.green.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Doctor Advice Applied', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.plan.doctorAdviceNotes!,
            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
