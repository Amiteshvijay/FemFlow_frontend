import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CloudSyncException implements Exception {
  final String message;
  CloudSyncException(this.message);

  @override
  String toString() => message;
}

class GoogleDriveService {
  static const List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);
  GoogleSignInAccount? _currentUser;

  /// Signs in the user to Google and ensures Drive scopes are granted.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      debugPrint('Sync: google_sign_in_start');
      await _googleSignIn.signOut(); // Ensure fresh login picker
      _currentUser = await _googleSignIn.signIn();
      
      if (_currentUser == null) {
        debugPrint('Sync: google_sign_in_cancelled');
        throw CloudSyncException('Google sign-in was cancelled by the user.');
      }

      debugPrint('Sync: google_sign_in_success - Account: ${_currentUser!.email}');
      final authHeaders = await _currentUser!.authHeaders;
      if (authHeaders.isEmpty) {
        debugPrint('Sync: auth_headers_empty');
        throw CloudSyncException('Failed to retrieve authentication headers from Google.');
      }
      debugPrint('Sync: auth_headers_received');
      return _currentUser;
    } on PlatformException catch (e) {
      debugPrint('Sync: PlatformException caught during Google Sign-In: code=${e.code}, message=${e.message}');
      final errStr = '${e.code} ${e.message} $e';
      if (errStr.contains('ApiException: 10') || e.code == 'sign_in_failed') {
        throw CloudSyncException(
          'Google Drive connection failed.\nPlease check your Google Sign-In / OAuth configuration (SHA-1/package name) or try again.'
        );
      }
      throw CloudSyncException('Google Drive connection failed.\n${e.message ?? e.toString()}');
    } catch (e) {
      debugPrint('Sync: Google Sign-In Error: $e');
      if (e is CloudSyncException) rethrow;
      
      final errStr = e.toString();
      if (errStr.contains('ApiException: 10') || errStr.contains('sign_in_failed')) {
        throw CloudSyncException(
          'Google Drive connection failed.\nPlease check your Google Sign-In / OAuth configuration (SHA-1/package name) or try again.'
        );
      }
      throw CloudSyncException('Google Drive connection failed. ${e.toString()}');
    }
  }

  /// Signs in silently if possible.
  Future<GoogleSignInAccount?> signInSilently() async {
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser;
  }

  /// Signs out the user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Returns the current signed-in account.
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser;
  }

  /// Gets an authenticated HTTP client for Google APIs.
  Future<http.Client?> _getAuthenticatedClient() async {
    final account = await getCurrentAccount();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    return _AuthenticatedClient(authHeaders, http.Client());
  }

  /// Uploads an encrypted backup file to the appDataFolder.
  Future<String> uploadBackup(String encryptedData, {String? existingFileId}) async {
    final client = await _getAuthenticatedClient();
    if (client == null) throw Exception('Google account not connected');

    final driveApi = drive.DriveApi(client);
    final fileName = 'femflow_backup.enc';

    final bytes = utf8.encode(encryptedData);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
    );

    if (existingFileId != null) {
      try {
        // Update existing file
        final updatedFile = await driveApi.files.update(
          drive.File()..name = fileName,
          existingFileId,
          uploadMedia: media,
        );
        return updatedFile.id!;
      } catch (e) {
        debugPrint('Sync: Update failed, falling back to create: $e');
        // If update fails (e.g. file deleted), fall through to create
      }
    }

    // Create new file in appDataFolder
    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];
    
    final uploadedFile = await driveApi.files.create(
      fileMetadata,
      uploadMedia: media,
    );
    return uploadedFile.id!;
  }

  /// Downloads the latest backup file from the appDataFolder.
  Future<String?> downloadBackup(String fileId) async {
    final client = await _getAuthenticatedClient();
    if (client == null) throw Exception('Google account not connected');

    final driveApi = drive.DriveApi(client);
    
    await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.metadata,
    );

    // We need to download the actual content
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> data = [];
    await for (final chunk in media.stream) {
      data.addAll(chunk);
    }
    return utf8.decode(data);
  }

  /// Finds the backup file in appDataFolder if the ID is unknown.
  Future<String?> findBackupFileId() async {
    final client = await _getAuthenticatedClient();
    if (client == null) return null;

    final driveApi = drive.DriveApi(client);
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = 'femflow_backup.enc'",
      pageSize: 1,
    );

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id;
    }
    return null;
  }

  /// Deletes the backup file from Google Drive.
  Future<void> deleteBackup(String fileId) async {
    final client = await _getAuthenticatedClient();
    if (client == null) return;

    final driveApi = drive.DriveApi(client);
    await driveApi.files.delete(fileId);
  }
}

class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner;

  _AuthenticatedClient(this._headers, this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
