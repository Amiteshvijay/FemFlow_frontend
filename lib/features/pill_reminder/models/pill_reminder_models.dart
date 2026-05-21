class Medication {
  final int id;
  final String name;
  final String medicineType;
  final String? dosageValue;
  final String instructions; // choices: before, after, with, empty, none
  
  final String repeatType; // choices: once, daily, weekly, custom, prn
  final Map<String, dynamic> repeatPattern;
  
  final DateTime startDate;
  final DateTime? endDate;
  final bool isOngoing;
  
  final bool isActive;
  final bool notificationEnabled;
  final bool isSecret;
  final String? notes;
  
  final List<MedicationTiming> timings;

  Medication({
    required this.id,
    required this.name,
    required this.medicineType,
    this.dosageValue,
    required this.instructions,
    required this.repeatType,
    required this.repeatPattern,
    required this.startDate,
    this.endDate,
    required this.isOngoing,
    required this.isActive,
    required this.notificationEnabled,
    required this.isSecret,
    this.notes,
    required this.timings,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'] ?? '',
      medicineType: json['medicine_type'] ?? 'pill',
      dosageValue: json['dosage_value'],
      instructions: json['instructions'] ?? 'none',
      repeatType: json['repeat_type'] ?? 'daily',
      repeatPattern: Map<String, dynamic>.from(json['repeat_pattern'] ?? {}),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isOngoing: json['is_ongoing'] ?? true,
      isActive: json['is_active'] ?? true,
      notificationEnabled: json['notification_enabled'] ?? true,
      isSecret: json['is_secret'] ?? false,
      notes: json['notes'],
      timings: (json['timings'] as List? ?? [])
          .map((t) => MedicationTiming.fromJson(t))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'medicine_type': medicineType,
      'dosage_value': dosageValue,
      'instructions': instructions,
      'repeat_type': repeatType,
      'repeat_pattern': repeatPattern,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'is_ongoing': isOngoing,
      'is_active': isActive,
      'notification_enabled': notificationEnabled,
      'is_secret': isSecret,
      'notes': notes,
      'timings': timings.map((t) => t.toJson()).toList(),
    };
    if (endDate != null) {
      data['end_date'] = endDate!.toIso8601String().substring(0, 10);
    }
    return data;
  }
}

class MedicationTiming {
  final int? id;
  final String time; // HH:mm
  final String label; // Morning, etc.
  final double doseQuantity;

  MedicationTiming({
    this.id,
    required this.time,
    required this.label,
    required this.doseQuantity,
  });

  factory MedicationTiming.fromJson(Map<String, dynamic> json) {
    return MedicationTiming(
      id: json['id'],
      time: json['time'] ?? '08:00',
      label: json['label'] ?? '',
      doseQuantity: double.parse(json['dose_quantity']?.toString() ?? '1.0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'label': label,
      'dose_quantity': doseQuantity,
    };
  }
}

class MedicationDose {
  final int id;
  final int medicationId;
  final String medicineName;
  final String medicineType;
  final String? dosageValue;
  final String instructions;
  
  final DateTime scheduledAt;
  final DateTime? actualTakenAt;
  final String status; // upcoming, taken, skipped, missed
  final String? notes;

  MedicationDose({
    required this.id,
    required this.medicationId,
    required this.medicineName,
    required this.medicineType,
    this.dosageValue,
    required this.instructions,
    required this.scheduledAt,
    this.actualTakenAt,
    required this.status,
    this.notes,
  });

  factory MedicationDose.fromJson(Map<String, dynamic> json) {
    return MedicationDose(
      id: json['id'],
      medicationId: json['medication'],
      medicineName: json['medicine_name'] ?? '',
      medicineType: json['medicine_type'] ?? 'pill',
      dosageValue: json['dosage_value'],
      instructions: json['instructions'] ?? 'none',
      scheduledAt: DateTime.parse(json['scheduled_at']),
      actualTakenAt: json['actual_taken_at'] != null 
          ? DateTime.parse(json['actual_taken_at']) 
          : null,
      status: json['status'] ?? 'upcoming',
      notes: json['notes'],
    );
  }
}

// Compatibility layer for old code during transition
typedef MedicationReminder = Medication;
typedef MedicationLog = MedicationDose;
