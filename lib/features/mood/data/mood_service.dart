import '../../../core/network/api_client.dart';
import '../models/mood_models.dart';

class MoodService {
  final ApiClient _apiClient = ApiClient();

  Future<MoodCatalog> getMoodCatalog() async {
    final response = await _apiClient.get('/moods/catalog/');
    return MoodCatalog.fromJson(response);
  }

  Future<MoodLog> getMoodForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _apiClient.get('/moods/?date=$dateStr');
    return MoodLog.fromJson(response);
  }

  Future<MoodLog> saveMoods({
    required DateTime date,
    required List<String> moods,
    String? primaryMood,
    String? notes,
  }) async {
    final log = MoodLog(
      date: date,
      moods: moods,
      primaryMood: primaryMood,
      notes: notes,
    );
    final response = await _apiClient.post('/moods/', body: log.toJson());
    return MoodLog.fromJson(response);
  }

  Future<MoodPreference> getMoodPreferences() async {
    final response = await _apiClient.get('/moods/preferences/');
    return MoodPreference.fromJson(response);
  }

  Future<MoodPreference> updateMoodPreferences(List<String> enabledMoods) async {
    final response = await _apiClient.patch(
      '/moods/preferences/',
      body: {'enabled_moods': enabledMoods},
    );
    return MoodPreference.fromJson(response);
  }
}
