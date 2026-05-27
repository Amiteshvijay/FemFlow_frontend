import '../../../core/network/api_client.dart';
import '../models/event_models.dart';

class EventService {
  final ApiClient _apiClient = ApiClient();

  Future<List<FemFlowEvent>> getEvents() async {
    final response = await _apiClient.get('/events/public/');
    if (response is List) {
      return response.map((json) => FemFlowEvent.fromJson(json)).toList();
    }
    return [];
  }

  Future<FemFlowEvent> getEventDetail(String slug) async {
    final response = await _apiClient.get('/events/public/$slug/');
    return FemFlowEvent.fromJson(response);
  }

  Future<Map<String, dynamic>> registerForEvent(String slug, EventRegistrationRequest request) async {
    return await _apiClient.post('/events/public/$slug/register/', body: request.toJson());
  }

  Future<List<FemFlowEvent>> getMyEvents() async {
    final response = await _apiClient.get('/events/my-events/');
    if (response is List) {
      return response.map((json) => FemFlowEvent.fromJson(json)).toList();
    }
    return [];
  }
}
