class HealthReportMeta {
  final String generatedAt;
  final String reportRange;
  final String dataCompleteness;

  HealthReportMeta({
    required this.generatedAt,
    required this.reportRange,
    required this.dataCompleteness,
  });

  factory HealthReportMeta.fromJson(Map<String, dynamic> json) {
    return HealthReportMeta(
      generatedAt: json['generated_at'],
      reportRange: json['report_range'],
      dataCompleteness: json['data_completeness'],
    );
  }
}

class PersonalInformation {
  final String fullName;
  final String age;
  final String dob;
  final String email;
  final String mobile;
  final String location;
  final String bmi;
  final String weight;

  PersonalInformation({
    required this.fullName,
    required this.age,
    required this.dob,
    required this.email,
    required this.mobile,
    required this.location,
    required this.bmi,
    required this.weight,
  });

  factory PersonalInformation.fromJson(Map<String, dynamic> json) {
    return PersonalInformation(
      fullName: json['full_name'] ?? 'Not provided',
      age: json['age']?.toString() ?? 'Not provided',
      dob: json['dob'] ?? 'Not provided',
      email: json['email'] ?? 'Not provided',
      mobile: json['mobile'] ?? 'Not provided',
      location: json['location'] ?? 'Not provided',
      bmi: json['bmi']?.toString() ?? 'Not provided',
      weight: json['weight'] ?? 'Not provided',
    );
  }
}

class CycleSummary {
  final int totalCycles;
  final String avgCycleLength;
  final String avgPeriodLength;
  final String currentPhase;

  CycleSummary({
    required this.totalCycles,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.currentPhase,
  });

  factory CycleSummary.fromJson(Map<String, dynamic> json) {
    return CycleSummary(
      totalCycles: json['total_cycles'] ?? 0,
      avgCycleLength: json['avg_cycle_length'] ?? 'N/A',
      avgPeriodLength: json['avg_period_length'] ?? 'N/A',
      currentPhase: json['current_phase'] ?? 'Unknown',
    );
  }
}

class HealthReport {
  final HealthReportMeta meta;
  final PersonalInformation personalInfo;
  final CycleSummary cycleSummary;
  final String doctorSummary;

  HealthReport({
    required this.meta,
    required this.personalInfo,
    required this.cycleSummary,
    required this.doctorSummary,
  });

  factory HealthReport.fromJson(Map<String, dynamic> json) {
    return HealthReport(
      meta: HealthReportMeta.fromJson(json['meta']),
      personalInfo: PersonalInformation.fromJson(json['personal_information']),
      cycleSummary: CycleSummary.fromJson(json['cycle_summary']),
      doctorSummary: json['doctor_summary'] ?? '',
    );
  }
}
