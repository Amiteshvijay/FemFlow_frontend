import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import 'custom_plan_models.dart';
import 'custom_plan_service.dart';
import 'widgets/calorie_requirement_card.dart';
import 'widgets/doctor_advice_card.dart';
import 'widgets/meal_distribution_selector.dart';
import 'custom_plan_review_screen.dart';
import '../../premium/premium_feature_preview_screen.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import 'package:provider/provider.dart';
import '../../health_vault/data/health_vault_service.dart';

class CreateCustomPlanScreen extends StatefulWidget {
  const CreateCustomPlanScreen({super.key});

  @override
  State<CreateCustomPlanScreen> createState() => _CreateCustomPlanScreenState();
}

class _CreateCustomPlanScreenState extends State<CreateCustomPlanScreen> {
  final PageController _pageController = PageController();
  final CustomPlanService _service = CustomPlanService();
  
  int _currentStep = 0;
  final int _totalSteps = 7;

  // Form State
  String _selectedGoal = 'weight_maintenance';
  int _targetCalories = 2000;
  String _calculationMethod = 'auto';
  String _mealFrequency = '3_meals';
  final Map<String, int> _mealDistribution = {'breakfast': 30, 'lunch': 40, 'dinner': 30};
  String _dietType = 'vegetarian';
  final List<String> _allergies = [];
  bool _doctorAdviceEnabled = false;
  String? _doctorName;
  String? _doctorAdviceNotes;
  int? _linkedDocumentId;
  String? _linkedDocumentTitle;
  final List<String> _medicalConditions = [];
  bool _exerciseLinkEnabled = true;

  String _calcExplanation = 'Calculated based on your profile.';
  int _existingPlanCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAutoCalories();
    _fetchPlanCount();
  }

  Future<void> _fetchPlanCount() async {
    try {
      final plans = await _service.getCustomPlans();
      setState(() => _existingPlanCount = plans.length);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _fetchAutoCalories() async {
    try {
      // In a real app, we'd fetch profile data first. 
      // For now, using defaults for calculation
      final result = await _service.calculateCalories(
        goal: _selectedGoal,
        heightCm: 165,
        weightKg: 60,
        age: 28,
        activityLevel: 'moderate',
      );
      setState(() {
        _targetCalories = result.targetCalories;
        _calcExplanation = result.explanation;
      });
    } catch (e) {
      // Fallback
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToReview();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToReview() {
    final plan = CustomNutritionPlan(
      title: 'My Custom ${_selectedGoal.replaceAll('_', ' ')} Plan',
      goal: _selectedGoal,
      targetCalories: _targetCalories,
      calorieCalculationMethod: _calculationMethod,
      mealFrequency: _mealFrequency,
      mealDistribution: _mealDistribution,
      dietType: _dietType,
      cuisinePreferences: [],
      allergies: _allergies,
      excludedFoods: [],
      doctorAdviceEnabled: _doctorAdviceEnabled,
      doctorName: _doctorName,
      doctorAdviceNotes: _doctorAdviceNotes,
      medicalConditionTags: _medicalConditions,
      linkedDocumentId: _linkedDocumentId,
      exerciseLinkEnabled: _exerciseLinkEnabled,
      generatedPlanSummary: {},
      macroTargets: {},
      hydrationTargetMl: 2000,
      status: 'draft',
      meals: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomPlanReviewScreen(plan: plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Create Custom Diet Plan', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildGoalStep(),
                _buildCalorieStep(),
                _buildMealStep(),
                _buildPreferenceStep(),
                _buildDoctorAdviceStep(),
                _buildExerciseStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
            color: FemFlowColors.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentStep + 1} of $_totalSteps', 
                style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, fontWeight: FontWeight.bold)),
              Text(_getStepTitle(), 
                style: const TextStyle(fontSize: 12, color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Plan Goal';
      case 1: return 'Calories';
      case 2: return 'Meals';
      case 3: return 'Preferences';
      case 4: return 'Doctor Advice';
      case 5: return 'Exercise Link';
      case 6: return 'Review';
      default: return '';
    }
  }

  Widget _buildBottomNav() {
    final isPremium = context.read<SubscriptionProvider>().isPremium;
    final isLocked = !isPremium && _existingPlanCount >= 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: PrimaryButton(
        label: isLocked && _currentStep == _totalSteps - 1 ? 'Upgrade to Generate' : (_currentStep == _totalSteps - 1 ? 'Review Plan' : 'Continue'),
        onPressed: () {
          if (isLocked && _currentStep == _totalSteps - 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'custom_plan_unlimited'),
              ),
            );
            return;
          }
          _nextStep();
        },
      ),
    );
  }

  // --- STEPS ---

  Widget _buildGoalStep() {
    final goals = [
      {'id': 'weight_loss', 'title': 'Weight Loss', 'icon': Icons.trending_down, 'premium': false},
      {'id': 'weight_maintenance', 'title': 'Weight Maintenance', 'icon': Icons.horizontal_rule, 'premium': false},
      {'id': 'weight_gain', 'title': 'Weight Gain', 'icon': Icons.trending_up, 'premium': false},
      {'id': 'energy_improvement', 'title': 'Energy Improvement', 'icon': Icons.bolt, 'premium': true},
      {'id': 'cramps_relief', 'title': 'Cramps Relief', 'icon': Icons.favorite_border, 'premium': true},
      {'id': 'fertility_support', 'title': 'Fertility Support', 'icon': Icons.child_care, 'premium': true},
      {'id': 'doctor_recommended', 'title': 'Doctor Recommended', 'icon': Icons.medical_services_outlined, 'premium': true},
    ];

    return _stepContainer(
      title: 'What is your primary goal?',
      subtitle: 'We will tailor your calorie and macro targets based on this.',
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final g = goals[index];
          final isSelected = _selectedGoal == g['id'];
          final isPremiumOnly = g['premium'] as bool;
          final isPremium = context.read<SubscriptionProvider>().isPremium;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                if (isPremiumOnly && !isPremium) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'custom_plan_goals'),
                    ),
                  );
                  return;
                }
                setState(() => _selectedGoal = g['id'] as String);
                _fetchAutoCalories();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? FemFlowColors.primary.withValues(alpha: 0.05) : Colors.white,
                  border: Border.all(color: isSelected ? FemFlowColors.primary : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(g['icon'] as IconData, color: isSelected ? FemFlowColors.primary : Colors.grey),
                    const SizedBox(width: 16),
                    Text(g['title'] as String, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    const Spacer(),
                    if (isPremiumOnly && !isPremium)
                      const Icon(Icons.lock_outline, color: FemFlowColors.textMuted, size: 18),
                    if (isSelected) const Icon(Icons.check_circle, color: FemFlowColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalorieStep() {
    return _stepContainer(
      title: 'Daily Calorie Requirement',
      subtitle: 'Estimated calories to reach your goal safely.',
      child: Column(
        children: [
          CalorieRequirementCard(
            calories: _targetCalories,
            explanation: _calcExplanation,
            onEdit: () {
               _showCalorieEditDialog();
            },
          ),
          const SizedBox(height: 24),
          _choiceCard(
            title: 'Auto-calculate calories',
            subtitle: 'Recommended based on your profile & goal.',
            isSelected: _calculationMethod == 'auto',
            onTap: () {
              setState(() => _calculationMethod = 'auto');
              _fetchAutoCalories();
            },
          ),
          const SizedBox(height: 12),
          _choiceCard(
            title: 'Enter calories manually',
            subtitle: 'Use a specific target from your professional.',
            isSelected: _calculationMethod == 'manual',
            onTap: () {
              setState(() => _calculationMethod = 'manual');
              _showCalorieEditDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showCalorieEditDialog() {
    final controller = TextEditingController(text: _targetCalories.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Target Calories'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'kcal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _targetCalories = int.tryParse(controller.text) ?? _targetCalories;
                _calculationMethod = 'manual';
                _calcExplanation = 'Manually set by you.';
              });
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildMealStep() {
    final frequencies = [
      {'id': '2_meals', 'title': '2 Meals'},
      {'id': '3_meals', 'title': '3 Meals'},
      {'id': '3_meals_snack', 'title': '3 Meals + 1 Snack'},
      {'id': '4_meals', 'title': '4 Meals'},
    ];

    return _stepContainer(
      title: 'Meal Structure',
      subtitle: 'How many times do you prefer to eat in a day?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...frequencies.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _choiceCard(
              title: f['title']!,
              isSelected: _mealFrequency == f['id'],
              onTap: () => setState(() => _mealFrequency = f['id']!),
            ),
          )),
          const SizedBox(height: 32),
          MealDistributionSelector(
            distribution: _mealDistribution,
            onChanged: (val) => setState(() {
              _mealDistribution.clear();
              _mealDistribution.addAll(val);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceStep() {
    final diets = ['Vegetarian', 'Vegan', 'Non-Vegetarian', 'Pescetarian', 'Keto'];
    return _stepContainer(
      title: 'Dietary Preferences',
      subtitle: 'Choose your diet type and mention any allergies.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diet Type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: diets.map((d) {
              final isSelected = _dietType.toLowerCase().replaceAll('-', '_') == d.toLowerCase().replaceAll('-', '_');
              return ChoiceChip(
                label: Text(d),
                selected: isSelected,
                onSelected: (val) => setState(() => _dietType = d.toLowerCase().replaceAll('-', '_')),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Allergies', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Simple multi-select chips for demo
          Wrap(
            spacing: 8,
            children: ['Dairy', 'Gluten', 'Nuts', 'Soy', 'Shellfish'].map((a) {
              final isSelected = _allergies.contains(a.toLowerCase());
              return FilterChip(
                label: Text(a),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _allergies.add(a.toLowerCase());
                    } else {
                      _allergies.remove(a.toLowerCase());
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAdviceStep() {
    final isPremium = context.read<SubscriptionProvider>().isPremium;

    return _stepContainer(
      title: 'Doctor Advice',
      subtitle: 'Add specific instructions from your health professional.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DoctorAdviceCard(
            isEnabled: _doctorAdviceEnabled,
            doctorName: _doctorName,
            adviceNotes: _doctorAdviceNotes,
            medicalConditions: _medicalConditions,
            onToggle: (val) {
              if (val && !isPremium) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'doctor_advice_nutrition'),
                  ),
                );
                return;
              }
              setState(() => _doctorAdviceEnabled = val);
            },
            onEdit: () => _showDoctorAdviceDialog(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Important: FemFlow uses your entered advice to personalize your plan, but it does not replace medical care.',
            style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  void _showDoctorAdviceDialog() {
    final nameController = TextEditingController(text: _doctorName);
    final notesController = TextEditingController(text: _doctorAdviceNotes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doctor Advice Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Doctor / Dietitian Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Advice / Notes',
                hintText: 'e.g. Low salt diet, high protein, iron-rich foods...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Medical Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['PCOS', 'Thyroid', 'Diabetes', 'Anemia', 'IBS'].map((c) {
                final isSelected = _medicalConditions.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _medicalConditions.add(c);
                      } else {
                        _medicalConditions.remove(c);
                      }
                    });
                    // Re-render bottom sheet (simple way)
                    Navigator.pop(context);
                    _showDoctorAdviceDialog();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Linked Medical Document', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_linkedDocumentId != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_linkedDocumentTitle ?? 'Document Attached', style: const TextStyle(fontSize: 14))),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() { _linkedDocumentId = null; _linkedDocumentTitle = null; })),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _showDocumentPicker,
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach from Health Vault'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Save Advice',
              onPressed: () {
                setState(() {
                  _doctorName = nameController.text;
                  _doctorAdviceNotes = notesController.text;
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStep() {
    return _stepContainer(
      title: 'Exercise Link',
      subtitle: 'Should this plan adjust based on your daily activity?',
      child: Column(
        children: [
          _choiceCard(
            title: 'Link with Exercise Module',
            subtitle: 'Activity burn will adjust recovery suggestions and meal timing.',
            isSelected: _exerciseLinkEnabled,
            onTap: () => setState(() => _exerciseLinkEnabled = true),
          ),
          const SizedBox(height: 12),
          _choiceCard(
            title: 'Diet Only',
            subtitle: 'Focus strictly on your calorie targets without activity adjustment.',
            isSelected: !_exerciseLinkEnabled,
            onTap: () => setState(() => _exerciseLinkEnabled = false),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _stepContainer(
      title: 'Ready to Generate?',
      subtitle: 'Review your settings before creating your personalized plan.',
      child: Column(
        children: [
          _summaryRow('Goal', _selectedGoal.replaceAll('_', ' ').toUpperCase()),
          _summaryRow('Calories', '$_targetCalories kcal/day'),
          _summaryRow('Meals', _mealFrequency.replaceAll('_', ' ')),
          _summaryRow('Diet', _dietType),
          _summaryRow('Allergies', _allergies.isEmpty ? 'None' : _allergies.join(', ')),
          _summaryRow('Doctor Advice', _doctorAdviceEnabled ? 'Included' : 'None'),
          _summaryRow('Exercise Link', _exerciseLinkEnabled ? 'Enabled' : 'Disabled'),
          const SizedBox(height: 40),
          const Text(
            'Our AI engine will now generate a balanced plan specifically for you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FemFlowColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _stepContainer({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _choiceCard({required String title, String? subtitle, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? FemFlowColors.primary.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(color: isSelected ? FemFlowColors.primary : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: FemFlowColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDocumentPicker() async {
    final healthService = HealthVaultService();
    final docs = await healthService.getDocuments();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Medical Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No documents found in Health Vault.')),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(doc.title),
                      subtitle: Text(doc.documentTypeLabel),
                      onTap: () {
                        setState(() {
                          _linkedDocumentId = doc.id;
                          _linkedDocumentTitle = doc.title;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
