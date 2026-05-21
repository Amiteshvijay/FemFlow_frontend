import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/profile_service.dart';
import 'sections/basic_information_section.dart';
import 'sections/body_fitness_section.dart';
import 'sections/health_wellness_section.dart';
import 'sections/hormonal_health_section.dart';
import 'sections/lifestyle_factors_section.dart';
import 'sections/connected_health_section.dart';
import 'sections/privacy_ai_consent_section.dart';
import '../onboarding/cycle_history_section.dart';
import '../cycles/data/cycle_service.dart';

class WellnessOnboardingFlow extends StatefulWidget {
  final UserProfile? initialProfile;
  final VoidCallback? onComplete;
  final int initialPage;
  const WellnessOnboardingFlow({super.key, this.initialProfile, this.onComplete, this.initialPage = 0});

  @override
  State<WellnessOnboardingFlow> createState() => _WellnessOnboardingFlowState();
}

class _WellnessOnboardingFlowState extends State<WellnessOnboardingFlow> {
  late PageController _pageController;
  late int _currentPage;
  final int _totalSteps = 8;
  bool _isSaving = false;

  late Map<String, dynamic> _formData;
  List<CycleLog> _historyData = [];
  final ProfileService _profileService = ProfileService();
  final CycleService _cycleService = CycleService();

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage);
    _formData = widget.initialProfile?.toJson() ?? {};
    
    // Ensure default values for critical fields
    _formData.putIfAbsent('goal', () => 'track_cycle');
    _formData.putIfAbsent('stress_level', () => 'low');
    _formData.putIfAbsent('energy_level', () => 'moderate');
    _formData.putIfAbsent('anxiety_frequency', () => 'never');
    _formData.putIfAbsent('preferred_language', () => 'English');
    _formData.putIfAbsent('usual_cycle_length', () => 28);
    _formData.putIfAbsent('avg_period_length', () => 5);
    _formData.putIfAbsent('pms_severity', () => 'low');
    _formData.putIfAbsent('pain_severity', () => 'low');
    _formData.putIfAbsent('sleep_quality', () => 'moderate');
    _formData.putIfAbsent('alcohol_consumption', () => 'never');
    _formData.putIfAbsent('caffeine_intake', () => 'sometimes');
    _formData.putIfAbsent('travel_frequency', () => 'never');
    _formData.putIfAbsent('fast_food_frequency', () => 'sometimes');
    _formData.putIfAbsent('anonymous_wellness_insights', () => true);
    _formData.putIfAbsent('ai_recommendations_consent', () => true);
    _formData.putIfAbsent('symptom_prediction_consent', () => true);

    if (_formData['height_cm'] != null) _formData['height_cm'] = (_formData['height_cm'] as num).toDouble();
    if (_formData['weight_kg'] != null) _formData['weight_kg'] = (_formData['weight_kg'] as num).toDouble();
  }

  bool _isPageValid() {
    if (_currentPage == 0) {
      final name = _formData['full_name']?.toString() ?? '';
      final dob = _formData['dob'];
      return name.trim().isNotEmpty && dob != null;
    }
    return true;
  }

  void _nextPage() {
    if (!_isPageValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_currentPage < _totalSteps - 1) {
      _saveCurrentSection().then((success) {
        if (success) {
          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      });
    } else {
      // Last page: save it first, then complete
      _saveCurrentSection().then((success) {
        if (success) {
          _saveProfile(isComplete: true);
        }
      });
    }
  }

  Future<bool> _saveCurrentSection() async {
    setState(() => _isSaving = true);
    try {
      final sectionKeys = [
        'basic_information',
        'body_fitness',
        'health_wellness',
        'hormonal_health',
        'lifestyle_factors',
        'connected_health',
        'privacy_consent',
        'cycle_history'
      ];

      final key = sectionKeys[_currentPage];
      
      if (key == 'cycle_history') {
        for (var log in _historyData) {
          await _cycleService.createCycleLog(log);
        }
      } else {
        await _profileService.saveOnboardingSection(key, _formData);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _saveProfile({bool isComplete = false}) async {
    setState(() => _isSaving = true);
    try {
      if (isComplete) {
        await _profileService.completeOnboarding();
      } else {
        await _profileService.updateProfile(_formData);
      }
      if (mounted) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onComplete != null 
          ? null 
          : IconButton(
              icon: const Icon(Icons.close, color: FemFlowColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
        title: Column(
          children: [
            const Text('Wellness Profile', style: TextStyle(color: FemFlowColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Step ${_currentPage + 1} of $_totalSteps', style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildSectionPage('Let\'s get to know you', 'Starting with the basics to personalize your experience.', BasicInformationSection(initialData: _formData, onChanged: (data) => _formData = data)),
                _buildSectionPage('Body & Fitness', 'Height and weight help us calculate patterns.', BodyFitnessSection(initialData: _formData, onChanged: (data) => _formData = data)),
                _buildSectionPage('Health & Wellness', 'Understanding your goals and daily energy.', HealthWellnessSection(initialData: _formData, onChanged: (data) => _formData = data)),
                _buildSectionPage('Cycle & Hormones', 'Critical for predicting your next period.', HormonalHealthSection(initialData: _formData, onChanged: (data) => _formData = data)),
                _buildSectionPage('Lifestyle Factors', 'Habits that affect your cycle.', LifestyleFactorsSection(initialData: _formData, onChanged: (data) => _formData = data)),
                _buildSectionPage('Connected Health', 'Sync with your favorite devices.', ConnectedHealthSection(initialData: _formData, onChanged: (data) => _formData = data)),
                _buildSectionPage('Privacy & AI', 'Your data security is our top priority.', PrivacyAISection(initialData: _formData, onChanged: (data) => _formData = data)),
                _buildSectionPage('Cycle History', 'Improve predictions by adding recent periods.', CycleHistorySection(onHistoryChanged: (history) => _historyData = history)),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionPage(String title, String subtitle, Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Stack(
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(color: FemFlowColors.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 6,
            width: MediaQuery.of(context).size.width * ((_currentPage + 1) / _totalSteps),
            decoration: BoxDecoration(color: FemFlowColors.primary, borderRadius: BorderRadius.circular(3)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: FemFlowColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: _currentPage == _totalSteps - 1 ? (_isSaving ? 'Saving...' : 'Complete Profile') : 'Next Step',
              onPressed: _isSaving ? null : _nextPage,
            ),
          ),
        ],
      ),
    );
  }
}
