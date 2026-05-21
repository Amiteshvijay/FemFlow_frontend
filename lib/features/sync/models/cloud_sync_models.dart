class CloudSyncStatus {
  final bool enabled;
  final String provider;
  final String? googleAccountEmail;
  final String? driveFileId;
  final String? driveFolderId;
  final DateTime? lastSyncAt;
  final DateTime? lastRestoreAt;
  final int? lastBackupSize;
  final bool autoSyncEnabled;

  CloudSyncStatus({
    required this.enabled,
    required this.provider,
    this.googleAccountEmail,
    this.driveFileId,
    this.driveFolderId,
    this.lastSyncAt,
    this.lastRestoreAt,
    this.lastBackupSize,
    required this.autoSyncEnabled,
  });

  factory CloudSyncStatus.fromJson(Map<String, dynamic> json) {
    return CloudSyncStatus(
      enabled: json['enabled'] ?? false,
      provider: json['provider'] ?? 'google_drive',
      googleAccountEmail: json['google_account_email'],
      driveFileId: json['drive_file_id'],
      driveFolderId: json['drive_folder_id'],
      lastSyncAt: json['last_sync_at'] != null ? DateTime.parse(json['last_sync_at']) : null,
      lastRestoreAt: json['last_restore_at'] != null ? DateTime.parse(json['last_restore_at']) : null,
      lastBackupSize: json['last_backup_size'],
      autoSyncEnabled: json['auto_sync_enabled'] ?? true,
    );
  }
}

class SyncLog {
  final String action;
  final String status;
  final String? message;
  final DateTime createdAt;

  SyncLog({
    required this.action,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory SyncLog.fromJson(Map<String, dynamic> json) {
    return SyncLog(
      action: json['action'],
      status: json['status'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
