import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/wellness_score_service.dart';
import 'models/wellness_score_models.dart';
import 'wellness_score_dashboard_screen.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  
  String? _selectedMood;
  double _stressLevel = 0;
  double _anxietyLevel = 0;
  double _painLevel = 0;
  String? _energyLevel;
  String? _sleepQuality;
  String? _focusLevel;
  double _symptomSeverity = 0;
  final List<String> _selectedSymptoms = [];
  final _notesController = TextEditingController();
  bool _isSaving = false;

  final List<String> _moods = ['Happy', 'Okay', 'Tired', 'Sad', 'Anxious', 'Irritated', 'Calm', 'Emotional'];
  final List<String> _energyLevels = ['Low', 'Medium', 'High'];
  final List<String> _sleepQualities = ['Poor', 'Okay', 'Good', 'Excellent'];
  final List<String> _focusLevels = ['Clear', 'Distracted', 'Foggy', 'Forgetful'];
  final List<String> _commonSymptoms = ['Cramps', 'Fatigue', 'Headache', 'Bloating', 'Back Pain', 'Mood Swings', 'Sleep Trouble', 'Acne', 'Nausea', 'Food Cravings'];

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    
    final checkIn = WellnessCheckIn(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      mood: _selectedMood,
      moodScore: _selectedMood != null ? (_moods.indexOf(_selectedMood!) + 1) : null,
      stressScore: _stressLevel.toInt(),
      anxietyScore: _anxietyLevel.toInt(),
      painScore: _painLevel.toInt(),
      energyScore: _energyLevel != null ? (_energyLevels.indexOf(_energyLevel!) + 1) : null,
      sleepScore: _sleepQuality != null ? (_sleepQualities.indexOf(_sleepQuality!) + 1) : null,
      focusScore: _focusLevel != null ? (_focusLevels.indexOf(_focusLevel!) + 1) : null,
      symptomSeverity: _symptomSeverity.toInt(),
      symptoms: _selectedSymptoms,
      notes: _notesController.text,
    );

    try {
      final result = await _service.saveCheckIn(checkIn);
      if (mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save check-in: $e')));
      }
    }
  }

  void _showResultDialog(WellnessCheckIn result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Check-in Saved!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Today\'s Wellness Score',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              '${result.wellnessScore ?? "--"}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
            ),
            Text(
              result.status ?? 'Stay consistent!',
              style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Great!',
              onPressed: () {
                Navigator.pop(context); // Dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WellnessScoreDashboardScreen()),
                  (route) => route.isFirst,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: const [
            Text('Daily Check-in', style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('How are you feeling today?', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('How is your mood?'),
            _buildChips(_moods, _selectedMood, (val) => setState(() => _selectedMood = val)),
            const SizedBox(height: 24),
            _buildSliderSection('Stress Level', _stressLevel, (val) => setState(() => _stressLevel = val)),
            _buildSliderSection('Anxiety Level', _anxietyLevel, (val) => setState(() => _anxietyLevel = val)),
            _buildSliderSection('Pain Level', _painLevel, (val) => setState(() => _painLevel = val)),
            const SizedBox(height: 24),
            _buildSectionTitle('Energy Level'),
            _buildChips(_energyLevels, _energyLevel, (val) => setState(() => _energyLevel = val)),
            const SizedBox(height: 24),
            _buildSectionTitle('Sleep Quality'),
            _buildChips(_sleepQualities, _sleepQuality, (val) => setState(() => _sleepQuality = val)),
            const SizedBox(height: 24),
            _buildSectionTitle('Focus / Memory'),
            _buildChips(_focusLevels, _focusLevel, (val) => setState(() => _focusLevel = val)),
            const SizedBox(height: 24),
            _buildSliderSection('Symptom Severity', _symptomSeverity, (val) => setState(() => _symptomSeverity = val)),
            const SizedBox(height: 24),
            _buildSectionTitle('Symptoms'),
            _buildMultiSelectChips(_commonSymptoms, _selectedSymptoms, (val) {
              setState(() {
                if (_selectedSymptoms.contains(val)) {
                  _selectedSymptoms.remove(val);
                } else {
                  _selectedSymptoms.add(val);
                }
              });
            }),
            const SizedBox(height: 24),
            _buildSectionTitle('Notes (Optional)'),
            _buildNotesField(),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Save Check-in',
              onPressed: _handleSave,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary, fontSize: 16),
      ),
    );
  }

  Widget _buildChips(List<String> options, String? selected, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return FilterChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onSelect(opt),
          backgroundColor: Colors.white,
          selectedColor: FemLyraColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : FemLyraColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? Colors.transparent : FemLyraColors.border),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectChips(List<String> options, List<String> selected, Function(String) onToggle) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return FilterChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onToggle(opt),
          backgroundColor: Colors.white,
          selectedColor: FemLyraColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : FemLyraColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? Colors.transparent : FemLyraColors.border),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildSliderSection(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(label),
            Text('${value.toInt()}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: FemLyraColors.primary,
          inactiveColor: FemLyraColors.border,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add notes about your day...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemLyraColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemLyraColors.border)),
      ),
    );
  }
}
