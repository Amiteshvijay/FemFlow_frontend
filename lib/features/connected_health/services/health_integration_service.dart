import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../../../core/network/api_client.dart';

class HealthIntegrationService {
  final Health _health = Health();
  final ApiClient _apiClient = ApiClient();

  // MVP Focus: Steps, Calories, Distance, Heart Rate, Sleep
  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
  ];

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Health Connect configuration
        await _health.configure();
      }
      
      return await _health.requestAuthorization(_types);
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      return false;
    }
  }

  Future<void> syncData({String? platform}) async {
    if (kIsWeb) return;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Ensure Health Connect is configured before sync
      await _health.configure();
    }

    final String targetPlatform = platform ?? (defaultTargetPlatform == TargetPlatform.android ? 'health_connect' : 'apple_health');
    
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(days: 1));

    // 1. Fetch data
    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
      startTime: startTime,
      endTime: now,
      types: _types,
    ).timeout(const Duration(seconds: 20), onTimeout: () {
      throw Exception('Timed out fetching health data.');
    });

    if (healthData.isEmpty) {
      debugPrint('No health data found for $targetPlatform');
      // Still notify backend to mark as active even if no data yet
      await _apiClient.post('/health/sync/', body: {
        'platform': targetPlatform,
        'records': [],
        'is_active': true,
      });
      return;
    }

    // 2. Normalize data into daily buckets
    Map<String, Map<String, dynamic>> dailyBuckets = {};

    for (var p in healthData) {
      final dateKey = p.dateFrom.toIso8601String().substring(0, 10);
      dailyBuckets.putIfAbsent(dateKey, () => {'date': dateKey});
      
      final bucket = dailyBuckets[dateKey]!;
      
      if (p.type == HealthDataType.STEPS) {
        bucket['steps'] = (bucket['steps'] ?? 0) + (p.value as num).toInt();
      } else if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        bucket['calories'] = (bucket['calories'] ?? 0.0) + (p.value as num).toDouble();
      } else if (p.type == HealthDataType.DISTANCE_DELTA) {
        bucket['distance'] = (bucket['distance'] ?? 0.0) + (p.value as num).toDouble();
      } else if (p.type == HealthDataType.HEART_RATE || p.type == HealthDataType.RESTING_HEART_RATE) {
        bucket['heart_rate'] = (p.value as num).toInt();
      } else if (p.type == HealthDataType.SLEEP_ASLEEP) {
        bucket['sleep_minutes'] = (bucket['sleep_minutes'] ?? 0) + (p.value as num).toInt();
      }
    }

    // 3. Send to backend with correct platform key
    await _apiClient.post('/health/sync/', body: {
      'platform': targetPlatform,
      'records': dailyBuckets.values.toList(),
      'is_active': true,
    });

    debugPrint('Successfully synced $targetPlatform data to FemFlow backend');
  }

  Future<bool> isHealthConnectAvailable() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await _health.isHealthConnectAvailable();
    }
    return false;
  }
}
