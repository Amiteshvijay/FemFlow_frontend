import '../../../core/network/api_client.dart';

class SupportSection {
  final String heading;
  final String content;

  SupportSection({required this.heading, required this.content});

  factory SupportSection.fromJson(Map<String, dynamic> json) {
    return SupportSection(
      heading: json['heading'],
      content: json['content'],
    );
  }
}

class SupportData {
  final String title;
  final List<SupportSection>? sections;
  final String? appName;
  final String? tagline;
  final String? version;
  final String? description;

  SupportData({
    required this.title,
    this.sections,
    this.appName,
    this.tagline,
    this.version,
    this.description,
  });

  factory SupportData.fromJson(Map<String, dynamic> json) {
    return SupportData(
      title: json['title'],
      sections: json['sections'] != null
          ? (json['sections'] as List).map((s) => SupportSection.fromJson(s)).toList()
          : null,
      appName: json['app_name'],
      tagline: json['tagline'],
      version: json['version'],
      description: json['description'],
    );
  }
}

class SupportService {
  final ApiClient _apiClient = ApiClient();

  Future<SupportData> getPrivacy() async {
    final response = await _apiClient.get('/support/privacy/');
    return SupportData.fromJson(response);
  }

  Future<SupportData> getHelp() async {
    final response = await _apiClient.get('/support/help/');
    return SupportData.fromJson(response);
  }

  Future<SupportData> getAbout() async {
    final response = await _apiClient.get('/support/about/');
    return SupportData.fromJson(response);
  }

  Future<void> submitContactForm(Map<String, dynamic> data) async {
    await _apiClient.post('/support/contact/', body: data);
  }
}
