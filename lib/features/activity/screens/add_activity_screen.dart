import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/activity_service.dart';
import '../models/calorie_burn_models.dart';
import 'dart:developer' as dev;

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final ActivityService _service = ActivityService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  final DateTime _selectedDate = DateTime.now();
  ActivityMET? _selectedMET;
  List<ActivityMET> _catalog = [];
  int _durationMinutes = 20;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    setState(() => _isLoading = true);
    try {
      final catalog = await _service.getMETCatalog();
      if (mounted) {
        setState(() {
          _catalog = catalog;
          if (_catalog.isNotEmpty) {
             _selectedMET = _catalog.first;
          }
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      dev.log('Error fetching activity catalog', error: e, stackTrace: stack);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (_selectedMET == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Please select an activity type')),
       );
       return;
    }
    
    setState(() => _isSaving = true);
    try {
      await _service.addManualActivity(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        activityType: _selectedMET!.activityKey,
        durationMinutes: _durationMinutes,
        activityName: _nameController.text.isNotEmpty ? _nameController.text : _selectedMET!.label,
        notes: _notesController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Activity Type'),
                  if (_catalog.isEmpty)
                     const Text('No activities found. Please check your connection.', style: TextStyle(color: Colors.red, fontSize: 12))
                  else
                    _buildActivityDropdown(),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Custom Name (Optional)'),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: _selectedMET?.label ?? 'e.g. My Evening Walk',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Duration (minutes)'),
                  _buildDurationSlider(),
                  const SizedBox(height: 24),
                  
                  _buildLabel('Notes'),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'How did you feel?',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  PrimaryButton(
                    label: 'Save Activity',
                    isLoading: _isSaving,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary)),
    );
  }

  Widget _buildActivityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FemLyraColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ActivityMET>(
          isExpanded: true,
          value: _selectedMET,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: _catalog.map((m) => DropdownMenuItem(
            value: m,
            child: Text(m.label, style: const TextStyle(color: FemLyraColors.textPrimary)),
          )).toList(),
          onChanged: (val) {
            setState(() {
              _selectedMET = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('5 min', style: TextStyle(fontSize: 12)),
            Text('$_durationMinutes min', style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 18)),
            const Text('120 min', style: TextStyle(fontSize: 12)),
          ],
        ),
        Slider(
          value: _durationMinutes.toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          activeColor: FemLyraColors.primary,
          inactiveColor: FemLyraColors.primary.withValues(alpha: 0.1),
          onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
        ),
      ],
    );
  }
}
