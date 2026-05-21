import '../../../core/network/api_client.dart';

class CycleLog {
  final int? id;
  final DateTime periodStartDate;
  final DateTime? periodEndDate;
  final DateTime? predictedEndDate;
  final int? averagePeriodLengthUsed;
  final String status;
  final String? flow;
  final String? notes;
  final List<PeriodDailyLog>? dailyLogs;

  CycleLog({
    this.id,
    required this.periodStartDate,
    this.periodEndDate,
    this.predictedEndDate,
    this.averagePeriodLengthUsed,
    required this.status,
    this.flow,
    this.notes,
    this.dailyLogs,
  });

  factory CycleLog.fromJson(Map<String, dynamic> json) {
    return CycleLog(
      id: json['id'],
      periodStartDate: DateTime.parse(json['period_start_date']),
      periodEndDate: json['period_end_date'] != null
          ? DateTime.parse(json['period_end_date'])
          : null,
      predictedEndDate: json['predicted_end_date'] != null
          ? DateTime.parse(json['predicted_end_date'])
          : null,
      averagePeriodLengthUsed: json['average_period_length_used'],
      status: json['status'] ?? 'completed',
      flow: json['flow'],
      notes: json['notes'],
      dailyLogs: json['daily_logs'] != null
          ? (json['daily_logs'] as List).map((l) => PeriodDailyLog.fromJson(l)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_start_date': periodStartDate.toIso8601String().split('T')[0],
      'period_end_date': periodEndDate?.toIso8601String().split('T')[0],
      'predicted_end_date': predictedEndDate?.toIso8601String().split('T')[0],
      'status': status,
      'flow': flow,
      'notes': notes,
    };
  }
}

class PeriodDailyLog {
  final int? id;
  final DateTime date;
  final String flow;
  final String? notes;

  PeriodDailyLog({
    this.id,
    required this.date,
    required this.flow,
    this.notes,
  });

  factory PeriodDailyLog.fromJson(Map<String, dynamic> json) {
    return PeriodDailyLog(
      id: json['id'],
      date: DateTime.parse(json['date']),
      flow: json['flow'] ?? 'medium',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'flow': flow,
      'notes': notes,
    };
  }
}

class SymptomLog {
  final int? id;
  final DateTime date;
  final List<String> symptoms;
  final String? mood;
  final int? painLevel;
  final String? energyLevel;
  final String? notes;

  SymptomLog({
    this.id,
    required this.date,
    required this.symptoms,
    this.mood,
    this.painLevel,
    this.energyLevel,
    this.notes,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'],
      date: DateTime.parse(json['date']),
      symptoms: List<String>.from(json['symptoms'] ?? []),
      mood: json['mood'],
      painLevel: json['pain_level'],
      energyLevel: json['energy_level'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'symptoms': symptoms,
      'mood': mood,
      'pain_level': painLevel,
      'energy_level': energyLevel,
      'notes': notes,
    };
  }
}

class SexualActivityLog {
  final int? id;
  final DateTime date;
  final String activityType;
  final String? activityTypeDisplay;
  final String? notes;

  SexualActivityLog({
    this.id,
    required this.date,
    required this.activityType,
    this.activityTypeDisplay,
    this.notes,
  });

  factory SexualActivityLog.fromJson(Map<String, dynamic> json) {
    return SexualActivityLog(
      id: json['id'],
      date: DateTime.parse(json['date']),
      activityType: json['activity_type'],
      activityTypeDisplay: json['activity_type_display'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'activity_type': activityType,
      'notes': notes,
    };
  }
}

class CycleService {
  final ApiClient _apiClient = ApiClient();

  Future<List<CycleLog>> getCycleLogs() async {
    final response = await _apiClient.get('/cycles/logs/');
    if (response is List) {
      return response.map((json) => CycleLog.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<SymptomLog>> getSymptomLogs() async {
    final response = await _apiClient.get('/cycles/symptoms/');
    if (response is List) {
      return response.map((json) => SymptomLog.fromJson(json)).toList();
    }
    return [];
  }

  Future<CycleLog> createCycleLog(CycleLog log) async {
    final response = await _apiClient.post('/cycles/logs/', body: log.toJson());
    return CycleLog.fromJson(response);
  }

  Future<Map<String, dynamic>> startPeriod({
    required DateTime periodStartDate,
    String? flow,
    String? notes,
  }) async {
    final response = await _apiClient.post('/cycles/period/start/', body: {
      'period_start_date': periodStartDate.toIso8601String().split('T')[0],
      'flow': flow ?? 'medium',
      'notes': notes ?? '',
    });
    return response;
  }

  Future<Map<String, dynamic>> logDailyPeriodFlow({
    required DateTime date,
    required String flow,
    String? notes,
  }) async {
    final response = await _apiClient.post('/cycles/period/daily-log/', body: {
      'date': date.toIso8601String().split('T')[0],
      'flow': flow,
      'notes': notes ?? '',
    });
    return response;
  }

  Future<Map<String, dynamic>> endPeriod({
    required DateTime periodEndDate,
  }) async {
    final response = await _apiClient.post('/cycles/period/end/', body: {
      'period_end_date': periodEndDate.toIso8601String().split('T')[0],
    });
    return response;
  }

  Future<SymptomLog> createSymptomLog(SymptomLog log) async {
    final response = await _apiClient.post('/cycles/symptoms/', body: log.toJson());
    return SymptomLog.fromJson(response);
  }

  Future<Map<String, dynamic>> getDashboard() async {
    return await _apiClient.get('/cycles/dashboard/');
  }

  Future<Map<String, dynamic>> getCalendarMonth(int year, int month) async {
    return await _apiClient.get('/cycles/calendar/?year=$year&month=$month');
  }

  Future<Map<String, dynamic>> getDayDetails(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await _apiClient.get('/cycles/day/?date=$dateStr');
  }

  Future<void> logPeriodEnd(int periodLogId, DateTime endDate) async {
    final dateStr = endDate.toIso8601String().split('T')[0];
    await _apiClient.post('/cycles/period/end/', body: {
      'period_end_date': dateStr,
    });
  }

  Future<CycleLog> updateCycleLog(int id, CycleLog log) async {
    final response = await _apiClient.patch('/cycles/logs/$id/', body: log.toJson());
    return CycleLog.fromJson(response);
  }

  Future<void> deleteCycleLog(int id) async {
    await _apiClient.delete('/cycles/logs/$id/');
  }

  Future<List<SexualActivityLog>> getSexualActivity(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await _apiClient.get('/cycles/sexual-activity/?date=$dateStr');
    if (response is List) {
      return response.map((json) => SexualActivityLog.fromJson(json)).toList();
    }
    return [];
  }

  Future<SexualActivityLog> createSexualActivityLog(SexualActivityLog log) async {
    final response = await _apiClient.post('/cycles/sexual-activity/', body: log.toJson());
    return SexualActivityLog.fromJson(response);
  }

  Future<void> deleteSexualActivityLog(int id) async {
    await _apiClient.delete('/cycles/sexual-activity/$id/');
  }

  Future<YearCalendarData> getYearCalendar(int year) async {
    final response = await _apiClient.get('/cycles/calendar/year/?year=$year');
    return YearCalendarData.fromJson(response);
  }
}

class YearCalendarData {
  final int year;
  final List<YearMonthSummary> months;

  YearCalendarData({required this.year, required this.months});

  factory YearCalendarData.fromJson(Map<String, dynamic> json) {
    return YearCalendarData(
      year: json['year'],
      months: (json['months'] as List).map((m) => YearMonthSummary.fromJson(m)).toList(),
    );
  }
}

class YearMonthSummary {
  final int month;
  final List<YearDaySummary> days;

  YearMonthSummary({required this.month, required this.days});

  factory YearMonthSummary.fromJson(Map<String, dynamic> json) {
    return YearMonthSummary(
      month: json['month'],
      days: (json['days'] as List).map((d) => YearDaySummary.fromJson(d)).toList(),
    );
  }
}

class YearDaySummary {
  final String date;
  final int day;
  final List<String> statuses;

  YearDaySummary({required this.date, required this.day, required this.statuses});

  factory YearDaySummary.fromJson(Map<String, dynamic> json) {
    return YearDaySummary(
      date: json['date'],
      day: json['day'],
      statuses: List<String>.from(json['statuses'] ?? []),
    );
  }
}
