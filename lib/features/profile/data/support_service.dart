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

class SupportTicket {
  final int id;
  final String ticketId;
  final String subject;
  final String message;
  final String status;
  final String statusDisplay;
  final String? assignedToName;
  final String? resolutionNotes;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;
  final List<TicketHistory>? history;

  SupportTicket({
    required this.id,
    required this.ticketId,
    required this.subject,
    required this.message,
    required this.status,
    required this.statusDisplay,
    this.assignedToName,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.history,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      ticketId: json['ticket_id'] ?? 'N/A',
      subject: json['subject'],
      message: json['message'],
      status: json['status'],
      statusDisplay: json['status_display'],
      assignedToName: json['assigned_to_name'],
      resolutionNotes: json['resolution_notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      closedAt: json['closed_at'],
      history: json['history'] != null
          ? (json['history'] as List).map((h) => TicketHistory.fromJson(h)).toList()
          : null,
    );
  }
}

class TicketHistory {
  final String status;
  final String statusDisplay;
  final String? notes;
  final String createdAt;

  TicketHistory({
    required this.status,
    required this.statusDisplay,
    this.notes,
    required this.createdAt,
  });

  factory TicketHistory.fromJson(Map<String, dynamic> json) {
    return TicketHistory(
      status: json['status'],
      statusDisplay: json['status_display'],
      notes: json['notes'],
      createdAt: json['created_at'],
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

  Future<Map<String, dynamic>?> submitContactForm(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/support/contact/', body: data);
    return response as Map<String, dynamic>?;
  }

  Future<List<SupportTicket>> getMyTickets() async {
    final response = await _apiClient.get('/support/my-tickets/');
    return (response as List).map((t) => SupportTicket.fromJson(t)).toList();
  }

  Future<SupportTicket> getTicketDetail(String ticketId) async {
    final response = await _apiClient.get('/support/tickets/$ticketId/');
    return SupportTicket.fromJson(response);
  }
}
