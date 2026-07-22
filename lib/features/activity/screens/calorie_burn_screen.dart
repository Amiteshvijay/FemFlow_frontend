import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/activity_service.dart';
import '../models/calorie_burn_models.dart';
import 'add_activity_screen.dart';

class CalorieBurnScreen extends StatefulWidget {
  const CalorieBurnScreen({super.key});

  @override
  State<CalorieBurnScreen> createState() => _CalorieBurnScreenState();
}

class _CalorieBurnScreenState extends State<CalorieBurnScreen> {
  final ActivityService _service = ActivityService();
  DailyActivitySummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _service.getTodaySummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Activity & Calories', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    _buildTodaySummary(),
                    const SizedBox(height: 24),
                    _buildSourceBreakdown(),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Add Manual Activity',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddActivityScreen()),
                      ).then((_) => _fetchData()),
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 32),
                    _buildSafetyNote(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodaySummary() {
    return AppCard(
      color: FemLyraColors.primary.withValues(alpha: 0.05),
      border: BorderSide(color: FemLyraColors.primary.withValues(alpha: 0.1)),
      child: Column(
        children: [
          const Text('Total Calories Burned', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${_summary?.totalCaloriesBurned ?? 0} kcal',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
          ),
          const SizedBox(height: 8),
          Text(_summary?.message ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: FemLyraColors.textMuted)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(Icons.timer_outlined, '${_summary?.activeMinutes ?? 0} min', 'Active Time'),
              _statItem(Icons.directions_walk, '${_summary?.steps ?? 0}', 'Steps'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: FemLyraColors.textSecondary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: FemLyraColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildSourceBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Source Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _sourceRow(Icons.fitness_center, 'Exercises', '${_summary?.exerciseCalories ?? 0} kcal'),
        _sourceRow(Icons.directions_walk, 'Walking', '${_summary?.walkingCalories ?? 0} kcal'),
        _sourceRow(Icons.edit_note, 'Manual Logs', '${_summary?.manualActivityCalories ?? 0} kcal'),
      ],
    );
  }

  Widget _sourceRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: FemLyraColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Calories are estimates. Your body’s needs can vary by cycle phase, energy, and overall health status. Focus on how you feel.',
              style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
