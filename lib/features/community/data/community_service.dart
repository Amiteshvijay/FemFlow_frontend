import '../../../core/network/api_client.dart';
import '../models/community_models.dart';

class CommunityService {
  final ApiClient _apiClient = ApiClient();

  Future<CommunityPreview> getCommunityPreview() async {
    final response = await _apiClient.get('/community/preview/');
    return CommunityPreview.fromJson(response);
  }

  Future<List<CommunityRoom>> getRooms() async {
    final response = await _apiClient.get('/community/rooms/');
    if (response is List) {
      return response.map((json) => CommunityRoom.fromJson(json)).toList();
    }
    return [];
  }

  Future<CommunityRoom> getRoomDetail(String slug) async {
    final response = await _apiClient.get('/community/rooms/$slug/');
    return CommunityRoom.fromJson(response);
  }

  Future<List<CommunityPost>> getRoomPosts(String slug) async {
    final response = await _apiClient.get('/community/rooms/$slug/posts/');
    // Handle both direct list and paginated results
    if (response is List) {
      return response.map((json) => CommunityPost.fromJson(json)).toList();
    } else if (response is Map && response.containsKey('results')) {
      return (response['results'] as List)
          .map((json) => CommunityPost.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<CommunityPost> getPostDetail(int postId) async {
    final response = await _apiClient.get('/community/posts/$postId/');
    return CommunityPost.fromJson(response);
  }

  Future<List<PostReply>> getPostReplies(int postId) async {
    final response = await _apiClient.get('/community/posts/$postId/replies/');
    if (response is List) {
      return response.map((json) => PostReply.fromJson(json)).toList();
    }
    return [];
  }

  Future<CommunityPost> createPost(String roomSlug, Map<String, dynamic> data, {dynamic imageFile}) async {
    if (imageFile != null) {
      final Map<String, String> stringFields = {};
      data.forEach((key, value) {
        stringFields[key] = value.toString();
      });

      final response = await _apiClient.multipartPost(
        '/community/rooms/$roomSlug/posts/',
        fields: stringFields,
        fileFieldName: 'image',
        file: imageFile,
      );
      return CommunityPost.fromJson(response);
    }

    final response = await _apiClient.post('/community/rooms/$roomSlug/posts/', body: data);
    return CommunityPost.fromJson(response);
  }

  Future<PostReply> createReply(int postId, Map<String, dynamic> data) async {
    final response = await _apiClient.post('/community/posts/$postId/replies/', body: data);
    return PostReply.fromJson(response);
  }

  Future<void> reactToPost(int postId, String reactionType) async {
    await _apiClient.post('/community/posts/$postId/react/', body: {'reaction_type': reactionType});
  }

  Future<void> report(Map<String, dynamic> data) async {
    await _apiClient.post('/community/report/', body: data);
  }
}
