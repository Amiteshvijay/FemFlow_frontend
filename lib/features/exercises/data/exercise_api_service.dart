import '../../../core/network/api_client.dart';
import '../models/exercise_models.dart';

class ExerciseApiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ExerciseRecommendation>> getRecommended({DateTime? date}) async {
    final Map<String, String> queryParams = {};
    if (date != null) queryParams['date'] = date.toIso8601String().split('T')[0];
    
    final response = await _apiClient.get('/exercises/recommended/', queryParams: queryParams);
    return (response as List).map((r) => ExerciseRecommendation.fromJson(r)).toList();
  }

  Future<List<ExerciseCategory>> getCategories() async {
    final response = await _apiClient.get('/exercises/categories/');
    return (response as List).map((c) => ExerciseCategory.fromJson(c)).toList();
  }

  Future<List<Exercise>> getExercises({
    String? category,
    String? intensity,
    String? cyclePhase,
    String? search,
    bool? mine,
  }) async {
    final Map<String, String> queryParams = {};
    if (category != null) queryParams['category'] = category;
    if (intensity != null) queryParams['intensity'] = intensity;
    if (cyclePhase != null) queryParams['cycle_phase'] = cyclePhase;
    if (search != null) queryParams['search'] = search;
    if (mine != null) queryParams['mine'] = mine.toString();

    final response = await _apiClient.get('/exercises/', queryParams: queryParams);
    
    if (response is Map && response.containsKey('results')) {
      return (response['results'] as List).map((e) => Exercise.fromJson(e)).toList();
    }
    return (response as List).map((e) => Exercise.fromJson(e)).toList();
  }

  Future<Exercise> getExerciseDetail(int id) async {
    final response = await _apiClient.get('/exercises/$id/');
    return Exercise.fromJson(response);
  }

  // New ExerciseLog methods
  Future<ExerciseLog> startExerciseLog({
    required int exerciseId,
    required DateTime date,
    required String source,
  }) async {
    final response = await _apiClient.post('/exercises/logs/start/', body: {
      'exercise_id': exerciseId,
      'date': date.toIso8601String().split('T')[0],
      'source': source,
    });
    return ExerciseLog.fromJson(response);
  }

  Future<ExerciseLog> updateExerciseProgress({
    required int logId,
    required int progressSeconds,
    required int currentStepIndex,
    required String completionStatus,
  }) async {
    final response = await _apiClient.patch('/exercises/logs/$logId/progress/', body: {
      'progress_seconds': progressSeconds,
      'current_step_index': currentStepIndex,
      'completion_status': completionStatus,
    });
    return ExerciseLog.fromJson(response);
  }

  Future<Map<String, dynamic>> completeExerciseLog({
    required int logId,
    required int durationCompletedMinutes,
    required Map<String, dynamic> feedback,
    String? notes,
  }) async {
    return await _apiClient.post('/exercises/logs/$logId/complete/', body: {
      'duration_completed_minutes': durationCompletedMinutes,
      'feedback': feedback,
      'notes': notes,
    });
  }

  Future<List<ExerciseLog>> getExerciseLogs({DateTime? date}) async {
    final Map<String, String> queryParams = {};
    if (date != null) queryParams['date'] = date.toIso8601String().split('T')[0];
    
    final response = await _apiClient.get('/exercises/logs/', queryParams: queryParams);
    return (response as List).map((l) => ExerciseLog.fromJson(l)).toList();
  }

  Future<Map<String, dynamic>> getHistorySummary() async {
    return await _apiClient.get('/exercises/history/summary/');
  }

  Future<Map<String, dynamic>> getDaySummary(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await _apiClient.get('/exercises/day-summary/?date=$dateStr');
  }

  Future<Exercise> createExercise(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/exercises/', body: data);
    return Exercise.fromJson(response);
  }

  Future<Exercise> updateExercise(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/exercises/$id/', body: data);
    return Exercise.fromJson(response);
  }

  Future<void> deleteExercise(int id) async {
    await _apiClient.delete('/exercises/$id/');
  }

  Future<void> toggleSave(int exerciseId, bool save) async {
    if (save) {
      await _apiClient.post('/exercises/$exerciseId/save_exercise/');
    } else {
      await _apiClient.delete('/exercises/$exerciseId/unsave_exercise/');
    }
  }
}
