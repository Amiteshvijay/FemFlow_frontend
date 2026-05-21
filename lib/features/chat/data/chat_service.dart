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

  Future<Map<String, dynamic>> getChatHistory() async {
    return await _apiClient.get('/chat/message/');
  }
}
