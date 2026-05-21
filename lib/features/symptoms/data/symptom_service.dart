import '../../../core/network/api_client.dart';

class SymptomService {
  final ApiClient _apiClient = ApiClient();

  Future<void> saveSymptoms({
    required DateTime date,
    required List<String> symptoms,
    required List<String> moods,
    String? primaryMood,
    required int painLevel,
    required String energyLevel,
    String? notes,
  }) async {
    final payload = {
      'date': date.toIso8601String().split('T')[0],
      'symptoms': symptoms,
      'moods': moods,
      'primary_mood': primaryMood,
      'pain_level': painLevel,
      'energy_level': energyLevel,
      'notes': notes,
    };

    try {
      await _apiClient.post('/cycles/symptoms/', body: payload);
    } catch (e) {
      rethrow;
    }
  }
}
