class HealthDocument {
  final int id;
  final String title;
  final String documentType;
  final String documentTypeLabel;
  final String fileUrl;
  final String originalFileName;
  final String fileType;
  final int fileSize;
  final String? notes;
  final DateTime? documentDate;
  final DateTime uploadedAt;

  HealthDocument({
    required this.id,
    required this.title,
    required this.documentType,
    required this.documentTypeLabel,
    required this.fileUrl,
    required this.originalFileName,
    required this.fileType,
    required this.fileSize,
    this.notes,
    this.documentDate,
    required this.uploadedAt,
  });

  factory HealthDocument.fromJson(Map<String, dynamic> json) {
    return HealthDocument(
      id: json['id'],
      title: json['title'],
      documentType: json['document_type'],
      documentTypeLabel: json['document_type_label'],
      fileUrl: json['file_url'],
      originalFileName: json['original_file_name'],
      fileType: json['file_type'],
      fileSize: json['file_size'],
      notes: json['notes'],
      documentDate: json['document_date'] != null 
          ? DateTime.parse(json['document_date']) 
          : null,
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}

class DocumentType {
  final String value;
  final String label;

  DocumentType({required this.value, required this.label});

  factory DocumentType.fromJson(Map<String, dynamic> json) {
    return DocumentType(
      value: json['value'],
      label: json['label'],
    );
  }
}
