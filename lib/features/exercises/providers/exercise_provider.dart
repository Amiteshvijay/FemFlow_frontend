import 'package:flutter/material.dart';
import '../data/exercise_api_service.dart';
import '../models/exercise_models.dart';

class ExerciseProvider extends ChangeNotifier {
  final ExerciseApiService _apiService = ExerciseApiService();
  
  List<ExerciseRecommendation> _recommended = [];
  List<ExerciseCategory> _categories = [];
  List<Exercise> _exercises = [];
  List<ExerciseLog> _recentLogs = [];
  Map<String, dynamic>? _historySummary;
  bool _isLoading = false;
  String? _error;

  List<ExerciseRecommendation> get recommended => _recommended;
  List<ExerciseCategory> get categories => _categories;
  List<Exercise> get exercises => _exercises;
  List<ExerciseLog> get recentLogs => _recentLogs;
  Map<String, dynamic>? get historySummary => _historySummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecommended({DateTime? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _recommended = await _apiService.getRecommended(date: date);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> loadExercises({
    String? category,
    String? intensity,
    String? cyclePhase,
    String? search,
    bool? mine,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _exercises = await _apiService.getExercises(
        category: category,
        intensity: intensity,
        cyclePhase: cyclePhase,
        search: search,
        mine: mine,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistorySummary() async {
    try {
      _historySummary = await _apiService.getHistorySummary();
      _recentLogs = List<ExerciseLog>.from(
        (_historySummary!['recent_logs'] as List).map((l) => ExerciseLog.fromJson(l))
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history summary: $e');
    }
  }

  Future<Map<String, dynamic>> getDaySummary(DateTime date) async {
    return await _apiService.getDaySummary(date);
  }

  Future<void> toggleSave(int exerciseId, bool save) async {
    try {
      await _apiService.toggleSave(exerciseId, save);
      // Optional: Refresh local state or just return
    } catch (e) {
      debugPrint('Error toggling save: $e');
    }
  }

  Future<void> deleteExercise(int id) async {
    try {
      await _apiService.deleteExercise(id);
      _exercises.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting exercise: $e');
      rethrow;
    }
  }

  void reset() {
    _recommended = [];
    _categories = [];
    _exercises = [];
    _recentLogs = [];
    _historySummary = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
