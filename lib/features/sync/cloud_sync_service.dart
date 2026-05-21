import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import 'backup_encryption_service.dart';
import 'google_drive_service.dart';
import 'models/cloud_sync_models.dart';
import '../../core/security/app_lock_service.dart';

class CloudSyncService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final BackupEncryptionService _encryptionService = BackupEncryptionService();
  final GoogleDriveService _driveService = GoogleDriveService();

  AppLockService? _appLock;

  void setAppLock(AppLockService appLock) {
    _appLock = appLock;
  }

  CloudSyncStatus? _status;
  CloudSyncStatus? get status => _status;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Fetches the current sync status from the backend.
  Future<void> fetchStatus() async {
    try {
      final data = await _apiClient.get('/sync/status/');
      _status = CloudSyncStatus.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching sync status: $e');
    }
  }

  /// Links a Google Account to the app.
  Future<void> connectAccount() async {
    _isSyncing = true;
    notifyListeners();
    _appLock?.setTrustedExternalFlowActive(true);

    try {
      final account = await _driveService.signIn();
      if (account == null) throw Exception('Google sign-in cancelled or scopes denied.');

      await _apiClient.post('/sync/status/', body: {
        "google_account_email": account.email,
      });

      await fetchStatus();
    } finally {
      _appLock?.setTrustedExternalFlowActive(false);
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Unlinks the Google Account and disables sync.
  Future<void> disconnectAccount() async {
    try {
      await _apiClient.post('/sync/status/', body: {
        "enabled": false,
        "google_account_email": null,
        "drive_file_id": null,
      });
      await _driveService.signOut();
      await fetchStatus();
    } catch (e) {
      rethrow;
    }
  }

  /// Enables Cloud Sync and performs initial backup.
  Future<void> enableSync() async {
    if (_status?.googleAccountEmail == null) {
      await connectAccount();
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // Perform initial backup
      final fileId = await performBackup(isInternal: true);

      // Update Backend Status
      await _apiClient.post('/sync/status/', body: {
        "enabled": true,
        "drive_file_id": fileId,
      });

      await fetchStatus();
    } catch (e) {
      debugPrint('Sync: Error during enablement: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Disables Cloud Sync.
  Future<void> disableSync({bool deleteRemote = false}) async {
    try {
      if (deleteRemote && _status?.driveFileId != null) {
        await _driveService.deleteBackup(_status!.driveFileId!);
      }
      
      await _apiClient.post('/sync/status/', body: {"enabled": false});
      await _driveService.signOut();
      await fetchStatus();
    } catch (e) {
      rethrow;
    }
  }

  /// Performs a manual backup: Export -> Encrypt -> Upload.
  Future<String> performBackup({bool isInternal = false}) async {
    debugPrint('Sync: Manual backup started');
    if (!isInternal) {
      _isSyncing = true;
      notifyListeners();
    }

    try {
      // 1. Export from Backend
      debugPrint('Sync: Exporting from backend...');
      final backupJson = await _apiClient.get('/sync/export/');
      final jsonString = jsonEncode(backupJson);
      debugPrint('Sync: Data exported, size: ${jsonString.length} bytes');

      // 2. Encrypt
      debugPrint('Sync: Encrypting backup...');
      final encryptedData = await _encryptionService.encryptBackup(jsonString);
      debugPrint('Sync: Data encrypted');

      // 3. Upload to Drive
      debugPrint('Sync: Uploading to Google Drive...');
      final fileId = await _driveService.uploadBackup(
        encryptedData,
        existingFileId: _status?.driveFileId,
      );
      debugPrint('Sync: Upload successful, File ID: $fileId');

      // 4. Update Backend with last sync info
      debugPrint('Sync: Logging sync status to backend...');
      await _apiClient.post('/sync/status/', body: {
        "last_sync_at": DateTime.now().toIso8601String(),
        "last_backup_size": encryptedData.length,
        "drive_file_id": fileId,
      });

      await fetchStatus();
      return fileId;
    } catch (e) {
      debugPrint('Sync: Manual backup failed: $e');
      rethrow;
    } finally {
      if (!isInternal) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  /// Restores data from the latest backup in Google Drive.
  Future<void> restoreBackup() async {
    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Find/Get File ID
      String? fileId = _status?.driveFileId ?? await _driveService.findBackupFileId();
      if (fileId == null) throw Exception('No backup found in Google Drive');

      // 2. Download from Drive
      final encryptedData = await _driveService.downloadBackup(fileId);
      if (encryptedData == null) throw Exception('Failed to download backup');

      // 3. Decrypt
      final jsonString = await _encryptionService.decryptBackup(encryptedData);
      final backupData = jsonDecode(jsonString);

      // 4. Import to Backend
      await _apiClient.post('/sync/import/', body: {
        "backup_data": backupData,
        "mode": "merge"
      });

      // 5. Update local status
      await _apiClient.post('/sync/status/', body: {
        "last_restore_at": DateTime.now().toIso8601String(),
      });

      await fetchStatus();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Updates auto-sync preference.
  Future<void> updateAutoSync(bool enabled) async {
    try {
      await _apiClient.post('/sync/status/', body: {"auto_sync_enabled": enabled});
      await fetchStatus();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches sync logs.
  Future<List<SyncLog>> fetchLogs() async {
    try {
      final List data = await _apiClient.get('/sync/logs/');
      return data.map((l) => SyncLog.fromJson(l)).toList();
    } catch (e) {
      return [];
    }
  }
}
