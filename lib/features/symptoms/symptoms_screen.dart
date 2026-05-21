import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../cycles/data/cycle_service.dart';
import '../../core/network/api_client.dart';
import '../mood/data/mood_service.dart';
import '../mood/models/mood_models.dart' as mood_models;
import 'models/symptom_models.dart';
import 'data/symptom_service.dart';
import 'widgets/compact_chip_section.dart';
import 'full_symptoms_picker_screen.dart';
import 'full_mood_picker_screen.dart';

class SymptomsScreen extends StatefulWidget {
  final DateTime? initialDate;
  final SymptomLog? existingLog;

  const SymptomsScreen({
    super.key,
    this.initialDate,
    this.existingLog,
  });

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  late DateTime _selectedDate;
  final Set<String> _selectedSymptoms = {};
  final Set<String> _selectedMoodKeys = {};
  double _painLevel = 0.0;
  String _selectedEnergy = 'Medium';
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  
  final SymptomService _symptomService = SymptomService();
  final MoodService _moodService = MoodService();
  
  mood_models.MoodCatalog? _moodCatalog;

  final List<String> _energyLevels = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingLog?.date ?? widget.initialDate ?? DateTime.now();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load Mood Catalog for labels
      _moodCatalog = await _moodService.getMoodCatalog();

      // 2. Load Day Details for unified sync
      final cycleService = CycleService();
      final dayDetails = await cycleService.getDayDetails(_selectedDate);
      
      if (mounted) {
        setState(() {
          // Load Symptoms
          final symptomsData = dayDetails['symptoms'];
          if (symptomsData != null) {
            _selectedSymptoms.addAll(List<String>.from(symptomsData['selected'] ?? []));
            _painLevel = (symptomsData['pain_level'] ?? 0).toDouble();
            _selectedEnergy = symptomsData['energy_level'] ?? 'Medium';
            _notesController.text = symptomsData['notes'] ?? '';
          }

          // Load Moods
          final moodsData = dayDetails['moods'];
          if (moodsData != null) {
            _selectedMoodKeys.addAll(List<String>.from(moodsData['selected'] ?? []));
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    try {
      await _symptomService.saveSymptoms(
        date: _selectedDate,
        symptoms: _selectedSymptoms.toList(),
        moods: _selectedMoodKeys.toList(),
        primaryMood: _selectedMoodKeys.isNotEmpty ? _selectedMoodKeys.first : null,
        painLevel: _painLevel.toInt(),
        energyLevel: _selectedEnergy,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms and mood saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.statusCode == 401 ? 'Please login again' : e.message),
            backgroundColor: FemFlowColors.period,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: FemFlowColors.period,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Log Symptoms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, d MMMM').format(_selectedDate),
              style: const TextStyle(
                fontSize: 12,
                color: FemFlowColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading && _moodCatalog == null
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Symptoms Section
                  CompactChipSection(
                    title: 'Symptoms',
                    defaultItems: SymptomConstants.defaultCompactSymptoms,
                    selectedItems: _selectedSymptoms,
                    onViewAll: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullSymptomsPickerScreen(
                            initialSelected: _selectedSymptoms,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedSymptoms.clear();
                          _selectedSymptoms.addAll(result as Set<String>);
                        });
                      }
                    },
                    onToggle: (item, isSelected) {
                      setState(() {
                        if (isSelected) {
                          _selectedSymptoms.add(item);
                        } else {
                          _selectedSymptoms.remove(item);
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Mood Section
                  CompactChipSection(
                    title: 'Mood',
                    defaultItems: const ['happy', 'normal', 'sleepy', 'sad', 'anxious', 'irritated'],
                    selectedItems: _selectedMoodKeys,
                    labelProvider: (key) {
                      if (_moodCatalog == null) return key;
                      final allMoods = _moodCatalog!.getAllMoods();
                      try {
                        final mood = allMoods.firstWhere((m) => m.key == key);
                        return '${mood.emoji} ${mood.label}';
                      } catch (e) {
                        return key;
                      }
                    },
                    onViewAll: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullMoodPickerScreen(
                            initialSelected: _selectedMoodKeys,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedMoodKeys.clear();
                          _selectedMoodKeys.addAll(result as Set<String>);
                        });
                      }
                    },
                    onToggle: (key, isSelected) {
                      setState(() {
                        if (isSelected) {
                          _selectedMoodKeys.add(key);
                        } else {
                          _selectedMoodKeys.remove(key);
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Pain Level
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Pain Level'),
                      Text(
                        '${_painLevel.toInt()}/10',
                        style: const TextStyle(
                          color: FemFlowColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: FemFlowColors.primary,
                      inactiveTrackColor: FemFlowColors.border,
                      thumbColor: FemFlowColors.primary,
                      overlayColor: FemFlowColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: _painLevel,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() => _painLevel = value);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Energy Level
                  _buildSectionTitle('Energy Level'),
                  const SizedBox(height: 12),
                  Row(
                    children: _energyLevels.map((level) {
                      final isSelected = _selectedEnergy == level;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedEnergy = level),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? FemFlowColors.blushMist : FemFlowColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? FemFlowColors.primary : FemFlowColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  level,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? FemFlowColors.primary : FemFlowColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Notes
                  _buildSectionTitle('Notes'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add any notes about how you feel today...',
                      hintStyle: const TextStyle(color: FemFlowColors.textMuted),
                      filled: true,
                      fillColor: FemFlowColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FemFlowColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FemFlowColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FemFlowColors.primary),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  PrimaryButton(
                    label: 'Save Symptoms',
                    onPressed: _onSave,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: FemFlowColors.textPrimary,
      ),
    );
  }
}
