import '../../../core/network/api_client.dart';

class SettingsService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiClient.get('/settings/');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> payload) async {
    final response = await _apiClient.patch('/settings/', body: payload);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBackupStatus() async {
    final response = await _apiClient.get('/settings/backup/status/');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startBackup() async {
    final response = await _apiClient.post('/settings/backup/start/');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> exportData() async {
    final response = await _apiClient.get('/settings/export/');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> importData(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/settings/import/', body: data);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post('/auth/change-password/', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
    return response as Map<String, dynamic>;
  }
}

// Keeping UserSettings for other parts of the app if they use it, 
// but it wasn't requested in the "REQUIRED IMPLEMENTATION" section.
class UserSettings {
  final String appearance;
  final String language;
  final String weightUnit;
  final String heightUnit;
  final String temperatureUnit;
  final bool fertilityPredictions;
  final bool pmsReminders;
  final bool periodReminders;

  UserSettings({
    required this.appearance,
    required this.language,
    required this.weightUnit,
    required this.heightUnit,
    required this.temperatureUnit,
    required this.fertilityPredictions,
    required this.pmsReminders,
    required this.periodReminders,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      appearance: json['appearance'] ?? 'light',
      language: json['language'] ?? 'english',
      weightUnit: json['weight_unit'] ?? 'kg',
      heightUnit: json['height_unit'] ?? 'cm',
      temperatureUnit: json['temperature_unit'] ?? 'celsius',
      fertilityPredictions: json['fertility_predictions'] ?? true,
      pmsReminders: json['pms_reminders'] ?? true,
      periodReminders: json['period_reminders'] ?? true,
    );
  }
}
