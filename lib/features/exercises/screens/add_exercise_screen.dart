import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/exercise_api_service.dart';
import '../models/exercise_models.dart';
import '../providers/exercise_provider.dart';

class AddExerciseScreen extends StatefulWidget {
  final Exercise? exerciseToEdit;

  const AddExerciseScreen({super.key, this.exerciseToEdit});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final ExerciseApiService _apiService = ExerciseApiService();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructionsController;
  late TextEditingController _safetyNoteController;
  
  String? _selectedCategory;
  String _selectedIntensity = 'medium';
  String _selectedDifficulty = 'beginner';
  int _duration = 15;
  
  final List<String> _selectedPhases = [];
  final List<String> _selectedBenefits = [];
  
  bool _isLoading = false;
  List<ExerciseCategory> _categories = [];

  final List<String> _phases = [
    'period', 'follicular', 'ovulation', 'fertile_window', 'luteal', 'pms', 'any_day'
  ];

  final List<String> _benefitOptions = [
    'Reduces cramps', 'Improves mood', 'Boosts energy', 'Supports sleep',
    'Reduces stress', 'Improves circulation', 'Relieves back pain',
    'Supports digestion', 'Improves flexibility'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exerciseToEdit?.name);
    _descriptionController = TextEditingController(text: widget.exerciseToEdit?.description);
    _instructionsController = TextEditingController(text: widget.exerciseToEdit?.instructions);
    _safetyNoteController = TextEditingController(text: widget.exerciseToEdit?.safetyNote);
    
    if (widget.exerciseToEdit != null) {
      _selectedCategory = widget.exerciseToEdit!.category;
      _selectedIntensity = widget.exerciseToEdit!.intensity;
      _selectedDifficulty = widget.exerciseToEdit!.difficulty;
      _duration = widget.exerciseToEdit!.durationMinutes;
      _selectedPhases.addAll(widget.exerciseToEdit!.cyclePhases);
      _selectedBenefits.addAll(widget.exerciseToEdit!.benefits);
    }
    
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _apiService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _safetyNoteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameController.text,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'duration_minutes': _duration,
        'intensity': _selectedIntensity,
        'difficulty': _selectedDifficulty,
        'cycle_phases': _selectedPhases,
        'benefits': _selectedBenefits,
        'instructions': _instructionsController.text,
        'safety_note': _safetyNoteController.text,
      };

      if (widget.exerciseToEdit != null) {
        await _apiService.updateExercise(widget.exerciseToEdit!.id, data);
      } else {
        await _apiService.createExercise(data);
      }

      if (mounted) {
        context.read<ExerciseProvider>().loadExercises();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.exerciseToEdit != null ? 'Exercise updated' : 'Exercise created'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: Text(widget.exerciseToEdit != null ? 'Edit Exercise' : 'Add Exercise', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 32),
              _sectionTitle('Basic Details'),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Exercise Name', 'e.g. Gentle Evening Stretch', required: true),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description', 'Describe how this exercise helps you', maxLines: 3),
              
              const SizedBox(height: 32),
              _sectionTitle('Exercise Setup'),
              const SizedBox(height: 16),
              _buildDurationPicker(),
              const SizedBox(height: 24),
              _buildIntensityPicker(),
              const SizedBox(height: 24),
              _buildDifficultyPicker(),
              
              const SizedBox(height: 32),
              _sectionTitle('Cycle Phase Suitability'),
              const SizedBox(height: 12),
              _buildMultiSelectChips(_phases, _selectedPhases, (val) => val.replaceAll('_', ' ').toUpperCase()),
              
              const SizedBox(height: 32),
              _sectionTitle('Benefits'),
              const SizedBox(height: 12),
              _buildMultiSelectChips(_benefitOptions, _selectedBenefits, (val) => val),
              
              const SizedBox(height: 32),
              _sectionTitle('Instructions'),
              const SizedBox(height: 16),
              _buildTextField(_instructionsController, 'Step-by-step instructions', '1. Sit comfortably...\n2. Breathe...', maxLines: 5),
              
              const SizedBox(height: 32),
              _sectionTitle('Safety Note'),
              const SizedBox(height: 16),
              _buildTextField(_safetyNoteController, 'Avoid if...', 'e.g. Avoid if pain is severe or unusual', maxLines: 2),
              
              const SizedBox(height: 40),
              PrimaryButton(
                label: widget.exerciseToEdit != null ? 'Update Exercise' : 'Save Exercise',
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return AppCard(
      color: FemLyraColors.primary.withValues(alpha: 0.05),
      border: BorderSide(color: FemLyraColors.primary.withValues(alpha: 0.1)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: FemLyraColors.blushMist, shape: BoxShape.circle),
            child: const Icon(Icons.fitness_center, color: FemLyraColors.primary),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create your custom routine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Build a plan that works with your cycle, energy, and comfort.', style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary));
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FemLyraColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: FemLyraColors.primary)),
          ),
          validator: required ? (val) => val == null || val.isEmpty ? 'Please enter $label' : null : null,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FemLyraColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              hint: const Text('Select Category', style: TextStyle(color: Colors.grey, fontSize: 14)),
              items: _categories.map((cat) => DropdownMenuItem(value: cat.key, child: Text(cat.label))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    final durations = [5, 10, 15, 20, 30, 45, 60];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration (Minutes)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FemLyraColors.textSecondary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: durations.map((d) {
            final isSelected = _duration == d;
            return ChoiceChip(
              label: Text('$d min'),
              selected: isSelected,
              onSelected: (_) => setState(() => _duration = d),
              selectedColor: FemLyraColors.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : FemLyraColors.textPrimary, fontSize: 12),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntensityPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Intensity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FemLyraColors.textSecondary)),
        const SizedBox(height: 12),
        Row(
          children: ['low', 'medium', 'high'].map((level) {
            final isSelected = _selectedIntensity == level;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Center(child: Text(level.toUpperCase())),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedIntensity = level),
                  selectedColor: FemLyraColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : FemLyraColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultyPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Difficulty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FemLyraColors.textSecondary)),
        const SizedBox(height: 12),
        Row(
          children: ['beginner', 'intermediate', 'advanced'].map((level) {
            final isSelected = _selectedDifficulty == level;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Center(child: Text(level.toUpperCase())),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDifficulty = level),
                  selectedColor: FemLyraColors.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : FemLyraColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips(List<String> options, List<String> selectedList, String Function(String) labelFormatter) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selectedList.contains(opt);
        return FilterChip(
          label: Text(labelFormatter(opt)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedList.add(opt);
              } else {
                selectedList.remove(opt);
              }
            });
          },
          selectedColor: FemLyraColors.primary.withValues(alpha: 0.2),
          checkmarkColor: FemLyraColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? FemLyraColors.primary : FemLyraColors.textPrimary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? FemLyraColors.primary : Colors.grey[300]!)
          ),
        );
      }).toList(),
    );
  }
}
