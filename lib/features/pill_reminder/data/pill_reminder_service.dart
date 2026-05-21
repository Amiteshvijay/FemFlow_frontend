import '../../../core/network/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../models/pill_reminder_models.dart';

class PillReminderService {
  final ApiClient _apiClient = ApiClient();
  final NotificationService _notificationService = NotificationService();

  Future<List<Medication>> getMedications({bool? active, String? search, String? medicineType}) async {
    final Map<String, String> queryParams = {};
    if (active != null) queryParams['active'] = active.toString();
    if (search != null) queryParams['search'] = search;
    if (medicineType != null) queryParams['medicine_type'] = medicineType;

    String endpoint = '/reminders/medications/';
    if (queryParams.isNotEmpty) {
      final uri = Uri(path: '', queryParameters: queryParams);
      endpoint = '$endpoint${uri.toString()}';
    }

    final response = await _apiClient.get(endpoint);
    final List<dynamic> data = response;
    return data.map((json) => Medication.fromJson(json)).toList();
  }

  Future<Medication> createMedication(Medication medication) async {
    final response = await _apiClient.post('/reminders/medications/', body: medication.toJson());
    final saved = Medication.fromJson(response);
    if (saved.isActive && saved.notificationEnabled) {
      await scheduleMedicationNotifications(saved);
    }
    return saved;
  }

  Future<Medication> getMedication(int id) async {
    final response = await _apiClient.get('/reminders/medications/$id/');
    return Medication.fromJson(response);
  }

  Future<Medication> updateMedication(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/reminders/medications/$id/', body: data);
    final updated = Medication.fromJson(response);
    
    if (updated.isActive && updated.notificationEnabled) {
      await scheduleMedicationNotifications(updated);
    } else {
      await cancelMedicationNotifications(id);
    }
    return updated;
  }

  Future<void> deleteMedication(int id) async {
    await cancelMedicationNotifications(id);
    await _apiClient.delete('/reminders/medications/$id/');
  }

  Future<void> cancelMedicationNotifications(int medId) async {
    // Cancel IDs from medId * 100 to medId * 100 + 20 (assuming max 20 timings)
    for (int i = 0; i < 20; i++) {
      await _notificationService.cancelNotification(medId * 100 + i);
    }
  }

  Future<void> scheduleMedicationNotifications(Medication med) async {
    if (!med.isActive || !med.notificationEnabled) return;
    
    // First clear any existing ones
    await cancelMedicationNotifications(med.id);

    for (var timing in med.timings) {
      final parts = timing.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final now = DateTime.now();
      final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // Use a unique ID for each timing: med.id * 100 + timing_index
      final int baseId = med.id * 100 + med.timings.indexOf(timing);
      
      if (med.repeatType == 'daily') {
        await _notificationService.scheduleNotification(
          id: baseId,
          title: 'Medication Reminder',
          body: 'Time to take ${med.name} (${med.dosageValue ?? ''})',
          scheduledDate: scheduledTime,
          repeatDaily: true,
          isMedication: true,
          payload: med.id.toString(),
        );
      } else if (med.repeatType == 'weekly') {
        final List<int> days = List<int>.from(med.repeatPattern['days'] ?? [])
            .map((d) => d + 1) // Map 0-6 to 1-7
            .toList();
            
        await _notificationService.scheduleNotification(
          id: baseId,
          title: 'Medication Reminder',
          body: 'Time to take ${med.name} (${med.dosageValue ?? ''})',
          scheduledDate: scheduledTime,
          weekdays: days,
          isMedication: true,
          payload: med.id.toString(),
        );
      } else if (med.repeatType == 'once') {
        final startDateTime = DateTime(
          med.startDate.year,
          med.startDate.month,
          med.startDate.day,
          hour,
          minute,
        );
        if (startDateTime.isAfter(DateTime.now())) {
          await _notificationService.scheduleNotification(
            id: baseId,
            title: 'Medication Reminder',
            body: 'Time to take ${med.name} (${med.dosageValue ?? ''})',
            scheduledDate: startDateTime,
            isMedication: true,
            payload: med.id.toString(),
          );
        }
      }
    }
  }

  Future<void> scheduleAllActiveMedications() async {
    final medications = await getMedications(active: true);
    for (var med in medications) {
      if (med.isActive && med.notificationEnabled) {
        await scheduleMedicationNotifications(med);
      }
    }
  }

  Future<List<MedicationDose>> getTimeline({DateTime? date}) async {
    String endpoint = '/reminders/medications/timeline/';
    if (date != null) {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      endpoint = '$endpoint?date=$dateStr';
    }
    final response = await _apiClient.get(endpoint);
    final List<dynamic> data = response;
    return data.map((json) => MedicationDose.fromJson(json)).toList();
  }

  Future<void> takeDose(int doseId, {String? notes}) async {
    final Map<String, dynamic> body = {};
    if (notes != null) body['notes'] = notes;
    await _apiClient.post('/reminders/doses/$doseId/take/', body: body);
  }

  Future<void> skipDose(int doseId, {String? notes}) async {
    final Map<String, dynamic> body = {};
    if (notes != null) body['notes'] = notes;
    await _apiClient.post('/reminders/doses/$doseId/skip/', body: body);
  }

  Future<void> logPrn(int medicationId, {String? notes}) async {
    final Map<String, dynamic> body = {};
    if (notes != null) body['notes'] = notes;
    await _apiClient.post('/reminders/medications/$medicationId/log-prn/', body: body);
  }

  // --- LEGACY FALLBACKS ---
  Future<List<MedicationReminder>> getReminders() => getMedications();
  Future<MedicationReminder> createReminder(MedicationReminder r) => createMedication(r);
  Future<MedicationReminder> updateReminder(int id, Map<String, dynamic> d) => updateMedication(id, d);
  Future<void> markAsTaken(int id, {String? scheduledFor, String? notes}) async {
    // This is problematic with new architecture, but we'll try to find the dose
    final timeline = await getTimeline();
    final dose = timeline.firstWhere((element) => element.medicationId == id, orElse: () => throw Exception('Dose not found'));
    await takeDose(dose.id, notes: notes);
  }
}
