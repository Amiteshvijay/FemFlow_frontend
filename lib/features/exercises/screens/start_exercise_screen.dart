import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../models/exercise_models.dart';
import '../data/exercise_api_service.dart';
import 'exercise_completion_screen.dart';
import 'exercise_home_screen.dart';

class StartExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final DateTime selectedDate;
  final String source;

  const StartExerciseScreen({
    super.key,
    required this.exercise,
    required this.selectedDate,
    required this.source,
  });

  @override
  State<StartExerciseScreen> createState() => _StartExerciseScreenState();
}

class _StartExerciseScreenState extends State<StartExerciseScreen> {
  late int _timeLeft; // in seconds
  Timer? _timer;
  bool _isPaused = true;
  final ExerciseApiService _apiService = ExerciseApiService();
  ExerciseLog? _currentLog;
  int _lastSavedProgress = 0;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.exercise.durationMinutes * 60;
  }

  Future<void> _startSession() async {
    setState(() => _isPaused = false);
    
    if (_currentLog == null) {
      try {
        final log = await _apiService.startExerciseLog(
          exerciseId: widget.exercise.id,
          date: widget.selectedDate,
          source: widget.source,
        );
        setState(() => _currentLog = log);
      } catch (e) {
        debugPrint('Error starting session: $e');
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isPaused) {
        setState(() => _timeLeft--);
        
        // Auto-save progress every 30 seconds
        final elapsed = (widget.exercise.durationMinutes * 60) - _timeLeft;
        if (elapsed - _lastSavedProgress >= 30) {
          _saveProgress();
          _lastSavedProgress = elapsed;
        }
      } else if (_timeLeft == 0) {
        timer.cancel();
        _finish();
      }
    });
  }

  void _pauseSession() {
    setState(() => _isPaused = true);
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    if (_currentLog == null) return;
    final elapsed = (widget.exercise.durationMinutes * 60) - _timeLeft;
    try {
      await _apiService.updateExerciseProgress(
        logId: _currentLog!.id,
        progressSeconds: elapsed,
        currentStepIndex: 0, // Simplified for now
        completionStatus: _isPaused ? 'paused' : 'started',
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final elapsed = (widget.exercise.durationMinutes * 60) - _timeLeft;
    final durationMins = (elapsed / 60).ceil();
    
    if (_currentLog == null) return;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseCompletionScreen(
            exerciseLogId: _currentLog!.id,
            exercise: widget.exercise,
            selectedDate: widget.selectedDate,
            durationCompleted: durationMins,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemFlowColors.textPrimary),
          onPressed: () => _confirmExit(),
        ),
        title: Column(
          children: [
            Text(widget.exercise.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
            Text(widget.exercise.categoryLabel, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: _timeLeft / (widget.exercise.durationMinutes * 60),
                    strokeWidth: 10,
                    color: FemFlowColors.primary,
                    backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatTime(_timeLeft),
                      style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, letterSpacing: -1),
                    ),
                    const Text('REMAINING', style: TextStyle(color: FemFlowColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlButton(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  _isPaused ? _startSession : _pauseSession,
                  isPrimary: true,
                ),
                const SizedBox(width: 40),
                _controlButton(Icons.done_rounded, _finish),
              ],
            ),
            const SizedBox(height: 60),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Breathe deeply and move at your own pace. Stop if you feel any discomfort.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FemFlowColors.textMuted, fontStyle: FontStyle.italic, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isPrimary ? FemFlowColors.primary : FemFlowColors.warmWhite,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? FemFlowColors.primary : Colors.black).withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : FemFlowColors.primary, size: 36),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Do you want to end the session now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseHomeScreen()),
                (route) => route.isFirst,
              );
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
