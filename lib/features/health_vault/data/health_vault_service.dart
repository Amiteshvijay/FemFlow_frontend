import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/health_document.dart';
import 'package:intl/intl.dart';

class HealthVaultService {
  final ApiClient _apiClient = ApiClient();

  Future<List<HealthDocument>> getDocuments({
    String? documentType,
    String? search,
  }) async {
    String endpoint = '/health-vault/documents/';
    Map<String, String> params = {};
    if (documentType != null && documentType != 'all') {
      params['document_type'] = documentType;
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
      return response.map((json) => HealthDocument.fromJson(json)).toList();
    }
    return [];
  }

  Future<HealthDocument> getDocumentDetail(int id) async {
    final response = await _apiClient.get('/health-vault/documents/$id/');
    return HealthDocument.fromJson(response);
  }

  Future<void> uploadDocument({
    required String title,
    required String documentType,
    File? file,
    Uint8List? bytes,
    String? fileName,
    String? notes,
    DateTime? documentDate,
  }) async {
    Map<String, String> fields = {
      'title': title,
      'document_type': documentType,
    };
    if (notes != null) fields['notes'] = notes;
    if (documentDate != null) {
      fields['document_date'] = DateFormat('yyyy-MM-dd').format(documentDate);
    }

    await _apiClient.multipartPost(
      '/health-vault/documents/',
      fields: fields,
      fileFieldName: 'file',
      file: file,
      bytes: bytes,
      fileName: fileName,
    );
  }

  Future<void> updateDocument({
    required int id,
    String? title,
    String? documentType,
    String? notes,
    DateTime? documentDate,
  }) async {
    Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (documentType != null) body['document_type'] = documentType;
    if (notes != null) body['notes'] = notes;
    if (documentDate != null) {
      body['document_date'] = DateFormat('yyyy-MM-dd').format(documentDate);
    }

    await _apiClient.patch('/health-vault/documents/$id/', body: body);
  }

  Future<void> deleteDocument(int id) async {
    await _apiClient.delete('/health-vault/documents/$id/');
  }

  Future<List<DocumentType>> getDocumentTypes() async {
    final response = await _apiClient.get('/health-vault/document-types/');
    if (response is List) {
      return response.map((json) => DocumentType.fromJson(json)).toList();
    }
    return [];
  }
}
