import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/exercise_models.dart';
import '../data/exercise_api_service.dart';
import '../providers/exercise_provider.dart';

class ExerciseCompletionScreen extends StatefulWidget {
  final int exerciseLogId;
  final Exercise exercise;
  final DateTime selectedDate;
  final int durationCompleted;

  const ExerciseCompletionScreen({
    super.key,
    required this.exerciseLogId,
    required this.exercise,
    required this.selectedDate,
    required this.durationCompleted,
  });

  @override
  State<ExerciseCompletionScreen> createState() => _ExerciseCompletionScreenState();
}

class _ExerciseCompletionScreenState extends State<ExerciseCompletionScreen> {
  final ExerciseApiService _apiService = ExerciseApiService();
  final List<String> _feelings = [];
  double _painLevel = 0.0;
  String _energyAfter = 'medium';
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  final List<String> _feelingOptions = [
    'Better', 'Same', 'Tired', 'Energized', 'Pain reduced', 'More relaxed'
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final feedback = {
        'feeling_after': _feelings,
        'pain_after': _painLevel.toInt(),
        'energy_after': _energyAfter,
      };

      await _apiService.completeExerciseLog(
        logId: widget.exerciseLogId,
        durationCompletedMinutes: widget.durationCompleted,
        feedback: feedback,
        notes: _notesController.text,
      );

      if (mounted) {
        context.read<ExerciseProvider>().loadHistorySummary();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Great job! Workout saved.')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildCelebrationHeader(),
            const SizedBox(height: 32),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildFeedbackSection(),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Save Completion',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: FemFlowColors.blushMist, shape: BoxShape.circle),
          child: const Icon(Icons.auto_awesome, color: FemFlowColors.primary, size: 40),
        ),
        const SizedBox(height: 24),
        const Text(
          'Great job! 🌸',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'You completed ${widget.exercise.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: FemFlowColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _summaryItem('${widget.durationCompleted} min', 'Completed'),
          _summaryItem('${widget.exercise.durationMinutes} min', 'Target'),
          _summaryItem(widget.exercise.intensity.toUpperCase(), 'Intensity'),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: FemFlowColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How do you feel after this?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _feelingOptions.map((f) {
            final isSelected = _feelings.contains(f);
            return FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _feelings.add(f);
                  } else {
                    _feelings.remove(f);
                  }
                });
              },
              selectedColor: FemFlowColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : FemFlowColors.textPrimary, fontSize: 13),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[300]!)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Pain Level after', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Slider(
          value: _painLevel,
          min: 0,
          max: 10,
          divisions: 10,
          label: _painLevel.toInt().toString(),
          activeColor: FemFlowColors.primary,
          onChanged: (val) => setState(() => _painLevel = val),
        ),
        const SizedBox(height: 24),
        const Text('Energy after', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: ['low', 'medium', 'high'].map((e) {
            final isSelected = _energyAfter == e;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Center(child: Text(e.toUpperCase())),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _energyAfter = e),
                  selectedColor: FemFlowColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : FemFlowColors.textPrimary, fontSize: 12),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Any thoughts? (Optional)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
        ),
      ],
    );
  }
}
