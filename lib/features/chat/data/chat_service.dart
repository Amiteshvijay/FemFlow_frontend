import '../../../core/network/api_client.dart';

class ChatMessageModel {
  final String content;
  final String role;
  final DateTime timestamp;
  bool isLiked;

  ChatMessageModel({
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLiked = false,
  });

  bool get isUser => role == 'user';
}

class ChatService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> sendMessage(String content, {int? sessionId, Map<String, dynamic>? dayContext}) async {
    return await _apiClient.post('/chat/message/', body: {
      'content': content,
      'session_id': sessionId,
      'day_context': dayContext,
    }..removeWhere((key, value) => value == null));
  }

  Future<Map<String, dynamic>> getChatHistory({int? sessionId}) async {
    final Map<String, String>? queryParams = sessionId != null
        ? {'session_id': sessionId.toString()}
        : null;
    return await _apiClient.get('/chat/message/', queryParams: queryParams);
  }

  Future<List<dynamic>> getChatSessions() async {
    final response = await _apiClient.get('/chat/sessions/');
    if (response is List) {
      return response;
    }
    return [];
  }

  Future<Map<String, dynamic>> deleteChatSession(int sessionId) async {
    final response = await _apiClient.delete('/chat/sessions/$sessionId/');
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'status': 'success'};
  }
}
