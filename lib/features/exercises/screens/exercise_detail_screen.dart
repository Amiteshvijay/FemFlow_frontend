import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/exercise_models.dart';
import '../data/exercise_api_service.dart';
import '../providers/exercise_provider.dart';
import 'start_exercise_screen.dart';
import 'add_exercise_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int exerciseId;
  final DateTime? selectedDate;
  final String source;

  const ExerciseDetailScreen({
    super.key, 
    required this.exerciseId,
    this.selectedDate,
    this.source = 'library',
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late Future<Exercise> _exerciseFuture;
  final ExerciseApiService _apiService = ExerciseApiService();
  List<ExerciseLog> _todayLogs = [];

  @override
  void initState() {
    super.initState();
    _exerciseFuture = _apiService.getExerciseDetail(widget.exerciseId);
    _loadTodayLogs();
  }

  Future<void> _loadTodayLogs() async {
    try {
      final date = widget.selectedDate ?? DateTime.now();
      final logs = await _apiService.getExerciseLogs(date: date);
      if (mounted) {
        setState(() {
          _todayLogs = logs.where((l) => l.exerciseId == widget.exerciseId && l.completionStatus == 'completed').toList();
        });
      }
    } catch (e) {
      // Error handled silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: FutureBuilder<Exercise>(
        future: _exerciseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FemFlowColors.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final exercise = snapshot.data!;
          final primaryPhase = exercise.cyclePhases.isNotEmpty ? exercise.cyclePhases.first : 'any_day';
          final phaseColor = _getPhaseColor(primaryPhase);

          return Scaffold(
            backgroundColor: FemFlowColors.warmWhite,
            appBar: AppBar(
              backgroundColor: phaseColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (exercise.isCustom) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddExerciseScreen(exerciseToEdit: exercise)));
                      if (result == true) setState(() { _exerciseFuture = _apiService.getExerciseDetail(widget.exerciseId); });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _confirmDelete(exercise),
                  ),
                ],
              ],
            ),
            body: _buildContent(exercise),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Exercise exercise) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise?'),
        content: const Text('This will remove it from your Exercise Library.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<ExerciseProvider>().deleteExercise(exercise.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exercise deleted')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildContent(Exercise exercise) {
    final primaryPhase = exercise.cyclePhases.isNotEmpty ? exercise.cyclePhases.first : 'any_day';
    final phaseColor = _getPhaseColor(primaryPhase);
    final displayDate = widget.selectedDate ?? DateTime.now();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [phaseColor, phaseColor.withValues(alpha: 0.7)],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(_getCategoryIcon(exercise.category), size: 100, color: Colors.white.withValues(alpha: 0.2)),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(exercise.categoryLabel.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                      const SizedBox(height: 8),
                      Text(exercise.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStats(exercise),
                const SizedBox(height: 32),
                if (_todayLogs.isNotEmpty)
                  _buildSection('Completed today ✓', 'You did this workout on ${DateFormat('MMM dd').format(displayDate)}', Icons.check_circle, Colors.green),
                const SizedBox(height: 24),
                if (exercise.isCustom) ...[
                   _buildSection('My Custom Exercise', 'Created on ${DateFormat('MMM dd, yyyy').format(exercise.createdAt)}', Icons.person_outline, FemFlowColors.primary),
                   const SizedBox(height: 24),
                ],
                const Text('About this movement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                const SizedBox(height: 12),
                Text(exercise.description, style: const TextStyle(fontSize: 15, color: FemFlowColors.textSecondary, height: 1.6)),
                const SizedBox(height: 32),
                if (exercise.benefits.isNotEmpty) ...[
                  _buildSection('Benefits', exercise.benefits.join(', '), Icons.auto_awesome, FemFlowColors.aiWellness),
                  const SizedBox(height: 32),
                ],
                if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
                  const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                  const SizedBox(height: 16),
                  Text(exercise.instructions!, style: const TextStyle(fontSize: 15, color: FemFlowColors.textSecondary, height: 1.6)),
                  const SizedBox(height: 32),
                ],
                if (exercise.safetyNote != null && exercise.safetyNote!.isNotEmpty) _buildSafetyBox(exercise.safetyNote!),
                const SizedBox(height: 40),
                PrimaryButton(
                  label: _todayLogs.isNotEmpty ? 'Restart Session' : 'Start Exercise',
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StartExerciseScreen(
                          exercise: exercise,
                          selectedDate: displayDate,
                          source: widget.source,
                        ),
                      ),
                    );
                    if (result == true) _loadTodayLogs();
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(Exercise exercise) {
    final primaryPhase = exercise.cyclePhases.isNotEmpty ? exercise.cyclePhases.first : 'any_day';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem(Icons.timer_outlined, '${exercise.durationMinutes} min', 'Duration'),
        _statItem(Icons.bolt, exercise.intensity.toUpperCase(), 'Intensity'),
        _statItem(Icons.calendar_today_outlined, primaryPhase.replaceAll('_', ' ').toUpperCase(), 'Best Phase'),
      ],
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: FemFlowColors.textSecondary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: FemFlowColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return AppCard(
      color: color.withValues(alpha: 0.05),
      border: BorderSide(color: color.withValues(alpha: 0.1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 8),
                Text(content, style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBox(String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withValues(alpha: 0.1))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Safety Note', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
                const SizedBox(height: 4),
                Text(note, style: const TextStyle(fontSize: 13, color: FemFlowColors.textPrimary, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual': case 'period': return FemFlowColors.period;
      case 'follicular': return FemFlowColors.primary;
      case 'ovulatory': case 'ovulation': return FemFlowColors.ovulation;
      case 'luteal': return Colors.orange;
      case 'pms': return Colors.deepPurple;
      case 'fertile_window': return FemFlowColors.fertileWindow;
      default: return FemFlowColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'gentle_yoga': case 'gentle yoga': return Icons.self_improvement;
      case 'stretching': return Icons.accessibility;
      case 'walking': return Icons.directions_walk;
      case 'strength': case 'strength training': return Icons.fitness_center;
      case 'pilates': return Icons.grid_view;
      case 'meditation': return Icons.spa;
      case 'breathing': return Icons.air;
      case 'cardio': return Icons.speed;
      case 'mobility': return Icons.motion_photos_on;
      default: return Icons.play_circle_outline;
    }
  }
}
