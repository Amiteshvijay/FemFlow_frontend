import '../../../core/network/api_client.dart';
import '../models/journal_entry.dart';

class JournalService {
  final ApiClient _apiClient = ApiClient();

  Future<List<JournalEntry>> getEntries({String? type, String? search}) async {
    String endpoint = '/notes/';
    Map<String, String> params = {};
    if (type != null && type != 'all') {
      params['note_type'] = type;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    if (params.isNotEmpty) {
      final queryString = Uri(queryParameters: params).query;
      endpoint += '?$queryString';
    }

    final response = await _apiClient.get(endpoint);
    if (response is List) {
      return response.map((json) => JournalEntry.fromJson(json)).toList();
    }
    return [];
  }

  Future<JournalEntry> getEntryDetail(int id) async {
    final response = await _apiClient.get('/notes/$id/');
    return JournalEntry.fromJson(response);
  }

  Future<JournalEntry> createEntry(JournalEntry entry) async {
    final response = await _apiClient.post('/notes/', body: entry.toJson());
    return JournalEntry.fromJson(response);
  }

  Future<JournalEntry> updateEntry(int id, JournalEntry entry) async {
    final response = await _apiClient.patch('/notes/$id/', body: entry.toJson());
    return JournalEntry.fromJson(response);
  }

  Future<void> deleteEntry(int id) async {
    await _apiClient.delete('/notes/$id/');
  }

  Future<void> togglePin(int id, bool isPinned) async {
    await _apiClient.patch('/notes/$id/', body: {'is_pinned': isPinned});
  }
}
