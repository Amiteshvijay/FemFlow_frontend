import '../../../core/network/api_client.dart';
import '../models/insight_models.dart';

class ExpertInsightsService {
  final ApiClient _apiClient = ApiClient();

  Future<List<InsightCategory>> getCategories() async {
    final response = await _apiClient.get('/expert-insights/categories/');
    return (response as List).map((c) => InsightCategory.fromJson(c)).toList();
  }

  Future<List<ExpertInsight>> getInsights({String? categorySlug, String? search}) async {
    final Map<String, String> queryParams = {};
    if (categorySlug != null) queryParams['category'] = categorySlug;
    if (search != null) queryParams['search'] = search;

    final response = await _apiClient.get('/expert-insights/insights/', queryParams: queryParams);
    return (response as List).map((i) => ExpertInsight.fromJson(i)).toList();
  }

  Future<ExpertInsight> getInsightDetail(String slug) async {
    final response = await _apiClient.get('/expert-insights/insights/$slug/');
    return ExpertInsight.fromJson(response);
  }

  Future<Map<String, dynamic>> engage(int insightId, String slug, String action) async {
    final response = await _apiClient.post('/expert-insights/insights/$slug/engage/', body: {'action': action});
    return response as Map<String, dynamic>;
  }

  Future<AIInteraction> askAI(String slug, String question) async {
    final response = await _apiClient.post('/expert-insights/insights/$slug/ask_ai/', body: {'question': question});
    return AIInteraction.fromJson(response);
  }
}
