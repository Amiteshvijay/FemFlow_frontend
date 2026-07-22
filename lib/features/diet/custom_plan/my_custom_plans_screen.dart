import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import 'custom_plan_models.dart';
import 'custom_plan_service.dart';
import 'custom_plan_result_screen.dart';

class MyCustomPlansScreen extends StatefulWidget {
  const MyCustomPlansScreen({super.key});

  @override
  State<MyCustomPlansScreen> createState() => _MyCustomPlansScreenState();
}

class _MyCustomPlansScreenState extends State<MyCustomPlansScreen> {
  final CustomPlanService _service = CustomPlanService();
  List<CustomNutritionPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    try {
      final plans = await _service.getCustomPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content: const Text('Are you sure you want to delete this custom nutrition plan? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteCustomPlan(id);
        _fetchPlans();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan deleted successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('My Custom Plans', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchPlans,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) => _buildPlanCard(_plans[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 64, color: FemLyraColors.primary.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text(
              'No custom plans yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate your first personalized nutrition plan to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FemLyraColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(CustomNutritionPlan plan) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${plan.targetCalories} kcal · ${plan.mealFrequency.replaceAll('_', ' ')}', style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
                    ],
                  ),
                ),
                _buildStatusBadge(plan.status),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CustomPlanResultScreen(plan: plan)),
                      ).then((_) => _fetchPlans());
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: FemLyraColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View', style: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (plan.status == 'active') {
                          await _service.deactivatePlan(plan.id!);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan deactivated')));
                        } else {
                          await _service.activatePlan(plan.id!);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan activated')));
                        }
                        _fetchPlans();
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: plan.status == 'active' ? Colors.red.shade600 : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(plan.status == 'active' ? 'Deactivate' : 'Activate', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _deletePlan(plan.id!),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'ACTIVE';
        break;
      case 'archived':
        color = Colors.grey;
        label = 'ARCHIVED';
        break;
      default:
        color = FemLyraColors.primary;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
