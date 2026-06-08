import 'package:workmanager/workmanager.dart';
import '../../features/connected_health/services/health_integration_service.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background Task Executing: $task');
    
    switch (task) {
      case BackgroundSyncService.healthSyncTask:
        try {
          final healthService = HealthIntegrationService();
          // First check if we have permissions (though we can't request them in background)
          // syncData() will just fail or return empty if not authorized
          await healthService.syncData();
          return Future.value(true);
        } catch (e) {
          debugPrint('Health Sync Task Failed: $e');
          return Future.value(false);
        }
      default:
        return Future.value(true);
    }
  });
}

class BackgroundSyncService {
  static const String healthSyncTask = "com.femflow.health_sync_task";
  static const String healthSyncUniqueName = "healthSyncJob";
  

  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  Future<void> scheduleHealthSync() async {
    debugPrint('Scheduling periodic health sync task...');
    await Workmanager().registerPeriodicTask(
      healthSyncUniqueName,
      healthSyncTask,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> cancelHealthSync() async {
    debugPrint('Cancelling health sync task...');
    await Workmanager().cancelByUniqueName(healthSyncUniqueName);
  }

}
