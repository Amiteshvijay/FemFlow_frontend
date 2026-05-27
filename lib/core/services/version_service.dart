import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_client.dart';

class AppUpdateInfo {
  final bool updateAvailable;
  final String updateType; // 'optional' | 'mandatory'
  final String latestVersion;
  final String title;
  final String message;
  final String storeUrl;

  AppUpdateInfo({
    required this.updateAvailable,
    required this.updateType,
    required this.latestVersion,
    required this.title,
    required this.message,
    required this.storeUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      updateAvailable: json['update_available'] ?? false,
      updateType: json['update_type'] ?? 'optional',
      latestVersion: json['latest_version'] ?? '',
      title: json['title'] ?? 'New Update Available',
      message: json['message'] ?? '',
      storeUrl: json['store_url'] ?? '',
    );
  }
}

class VersionService {
  final ApiClient _apiClient = ApiClient();

  Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String platform = Platform.isAndroid ? 'android' : 'ios';
      
      final response = await _apiClient.get('/app-version/check/', queryParams: {
        'platform': platform,
        'current_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      });

      return AppUpdateInfo.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
