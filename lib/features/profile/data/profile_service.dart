import 'dart:io';
import '../../../core/network/api_client.dart';
import '../models/order_history_model.dart';

class UserProfile {
  final int? id;
  final String username;
  final String email;
  final String? fullName;
  final String? displayName;
  final DateTime? dob;
  final int? age;
  final String? country;
  final String? city;
  final String? profession;
  final String preferredLanguage;
  final String? avatarUrl;
  final String? mobileNumber;
  final bool isMobileVerified;
  final String goal;
  final bool isProfileComplete;
  final bool onboardingCompleted;
  final int onboardingCurrentStep;
  final Map<String, double> sectionProgress;
  final bool twoFactorEnabled;
  final bool isCommunityCareEnrolled;

  // Body & Fitness
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? bodyType;
  final String? fitnessLevel;
  final String? activityLevel;
  final double? avgSleepHours;
  final double? waterIntakeLiters;
  final String? workoutFrequency;
  final String? yogaMeditationFrequency;

  // Health & Wellness
  final String stressLevel;
  final String? moodPattern;
  final String energyLevel;
  final String anxietyFrequency;
  final String? digestiveHealth;
  final bool skinConditionTracking;
  final bool hairFallTracking;
  final String? cravingsPattern;
  final String fatigueLevel;

  // Menstrual & Hormonal
  final int usualCycleLength;
  final int avgPeriodLength;
  final bool irregularCycles;
  final String pmsSeverity;
  final String painSeverity;
  final bool heavyFlow;
  final bool spotting;
  final String? ovulationSymptoms;
  final bool pcosDiagnosis;
  final bool thyroidIssues;
  final String? hormonalMedication;
  final String? birthControlUsage;

  // Lifestyle
  final bool smoking;
  final String alcoholConsumption;
  final String caffeineIntake;
  final String sleepQuality;
  final bool nightShiftWork;
  final String travelFrequency;
  final bool stressfulWorkEnvironment;
  final String? dietaryPreference;
  final String fastFoodFrequency;

  // Smart Data & Privacy
  final bool googleFitSync;
  final bool appleHealthSync;
  final bool fitbitSync;
  final bool stepCountIntegration;
  final bool anonymousWellnessInsights;
  final bool aiRecommendationsConsent;
  final bool symptomPredictionConsent;

  UserProfile({
    this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.displayName,
    this.dob,
    this.age,
    this.country,
    this.city,
    this.profession,
    this.preferredLanguage = 'English',
    this.avatarUrl,
    this.mobileNumber,
    this.isMobileVerified = false,
    this.goal = 'track_cycle',
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.bodyType,
    this.fitnessLevel,
    this.activityLevel,
    this.avgSleepHours,
    this.waterIntakeLiters,
    this.workoutFrequency,
    this.yogaMeditationFrequency,
    this.stressLevel = 'low',
    this.moodPattern,
    this.energyLevel = 'moderate',
    this.anxietyFrequency = 'never',
    this.digestiveHealth,
    this.skinConditionTracking = false,
    this.hairFallTracking = false,
    this.cravingsPattern,
    this.fatigueLevel = 'low',
    this.usualCycleLength = 28,
    this.avgPeriodLength = 5,
    this.irregularCycles = false,
    this.pmsSeverity = 'low',
    this.painSeverity = 'low',
    this.heavyFlow = false,
    this.spotting = false,
    this.ovulationSymptoms,
    this.pcosDiagnosis = false,
    this.thyroidIssues = false,
    this.hormonalMedication,
    this.birthControlUsage,
    this.smoking = false,
    this.alcoholConsumption = 'never',
    this.caffeineIntake = 'sometimes',
    this.sleepQuality = 'moderate',
    this.nightShiftWork = false,
    this.travelFrequency = 'never',
    this.stressfulWorkEnvironment = false,
    this.dietaryPreference,
    this.fastFoodFrequency = 'sometimes',
    this.googleFitSync = false,
    this.appleHealthSync = false,
    this.fitbitSync = false,
    this.stepCountIntegration = false,
    this.anonymousWellnessInsights = true,
    this.aiRecommendationsConsent = true,
    this.symptomPredictionConsent = true,
    required this.isProfileComplete,
    this.onboardingCompleted = false,
    this.onboardingCurrentStep = 0,
    this.sectionProgress = const {},
    this.twoFactorEnabled = false,
    this.isCommunityCareEnrolled = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final p = json['profile'] as Map<String, dynamic>? ?? json;
    
    return UserProfile(
      id: json['id'],
      username: json['username'] ?? 'User',
      email: json['email'] ?? 'Not available',
      fullName: p['full_name'],
      displayName: p['display_name'],
      dob: p['dob'] != null ? DateTime.parse(p['dob']) : null,
      age: p['age'],
      country: p['country'],
      city: p['city'],
      profession: p['profession'],
      preferredLanguage: p['preferred_language'] ?? 'English',
      avatarUrl: p['avatar_url'],
      mobileNumber: p['mobile_number'] ?? json['mobile_no'],
      isMobileVerified: p['is_mobile_verified'] ?? false,
      goal: p['goal'] ?? 'track_cycle',
      isProfileComplete: p['is_profile_complete'] ?? false,
      heightCm: _toDouble(p['height_cm']),
      weightKg: _toDouble(p['weight_kg']),
      bmi: _toDouble(p['bmi']),
      bodyType: p['body_type'],
      fitnessLevel: p['fitness_level'],
      activityLevel: p['activity_level'],
      avgSleepHours: _toDouble(p['avg_sleep_hours']),
      waterIntakeLiters: _toDouble(p['water_intake_liters']),
      workoutFrequency: p['workout_frequency'],
      yogaMeditationFrequency: p['yoga_meditation_frequency'],
      stressLevel: p['stress_level'] ?? 'low',
      moodPattern: p['mood_pattern'],
      energyLevel: p['energy_level'] ?? 'moderate',
      anxietyFrequency: p['anxiety_frequency'] ?? 'never',
      digestiveHealth: p['digestive_health'],
      skinConditionTracking: p['skin_condition_tracking'] ?? false,
      hairFallTracking: p['hair_fall_tracking'] ?? false,
      cravingsPattern: p['cravings_pattern'],
      fatigueLevel: p['fatigue_level'] ?? 'low',
      usualCycleLength: p['usual_cycle_length'] ?? 28,
      avgPeriodLength: p['avg_period_length'] ?? 5,
      irregularCycles: p['irregular_cycles'] ?? false,
      pmsSeverity: p['pms_severity'] ?? 'low',
      painSeverity: p['pain_severity'] ?? 'low',
      heavyFlow: p['heavy_flow'] ?? false,
      spotting: p['spotting'] ?? false,
      ovulationSymptoms: p['ovulation_symptoms'],
      pcosDiagnosis: p['pcos_diagnosis'] ?? false,
      thyroidIssues: p['thyroid_issues'] ?? false,
      hormonalMedication: p['hormonal_medication'],
      birthControlUsage: p['birth_control_usage'],
      smoking: p['smoking'] ?? false,
      alcoholConsumption: p['alcohol_consumption'] ?? 'never',
      caffeineIntake: p['caffeine_intake'] ?? 'sometimes',
      sleepQuality: p['sleep_quality'] ?? 'moderate',
      nightShiftWork: p['night_shift_work'] ?? false,
      travelFrequency: p['travel_frequency'] ?? 'never',
      stressfulWorkEnvironment: p['stressful_work_environment'] ?? false,
      dietaryPreference: p['dietary_preference'],
      fastFoodFrequency: p['fast_food_frequency'] ?? 'sometimes',
      googleFitSync: p['google_fit_sync'] ?? false,
      appleHealthSync: p['apple_health_sync'] ?? false,
      fitbitSync: p['fitbit_sync'] ?? false,
      stepCountIntegration: p['step_count_integration'] ?? false,
      anonymousWellnessInsights: p['anonymous_wellness_insights'] ?? true,
      aiRecommendationsConsent: p['ai_recommendations_consent'] ?? true,
      symptomPredictionConsent: p['symptom_prediction_consent'] ?? true,
      onboardingCompleted: p['onboarding_completed'] ?? false,
      onboardingCurrentStep: p['onboarding_current_step'] ?? 0,
      sectionProgress: (p['section_progress'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, _toDouble(value) ?? 0.0),
      ) ?? {},
      twoFactorEnabled: p['two_factor_enabled'] ?? false,
      isCommunityCareEnrolled: p['is_community_care_enrolled'] ?? false,
    );
  }

  static double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'display_name': displayName,
      'dob': dob?.toIso8601String().substring(0, 10),
      'age': age,
      'country': country,
      'city': city,
      'profession': profession,
      'preferred_language': preferredLanguage,
      'goal': goal,
      'mobile_number': mobileNumber,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'body_type': bodyType,
      'fitness_level': fitnessLevel,
      'activity_level': activityLevel,
      'avg_sleep_hours': avgSleepHours,
      'water_intake_liters': waterIntakeLiters,
      'workout_frequency': workoutFrequency,
      'yoga_meditation_frequency': yogaMeditationFrequency,
      'stress_level': stressLevel,
      'mood_pattern': moodPattern,
      'energy_level': energyLevel,
      'anxiety_frequency': anxietyFrequency,
      'digestive_health': digestiveHealth,
      'skin_condition_tracking': skinConditionTracking,
      'hair_fall_tracking': hairFallTracking,
      'cravings_pattern': cravingsPattern,
      'fatigue_level': fatigueLevel,
      'usual_cycle_length': usualCycleLength,
      'avg_period_length': avgPeriodLength,
      'irregular_cycles': irregularCycles,
      'pms_severity': pmsSeverity,
      'pain_severity': painSeverity,
      'heavy_flow': heavyFlow,
      'spotting': spotting,
      'ovulation_symptoms': ovulationSymptoms,
      'pcos_diagnosis': pcosDiagnosis,
      'thyroid_issues': thyroidIssues,
      'hormonal_medication': hormonalMedication,
      'birth_control_usage': birthControlUsage,
      'smoking': smoking,
      'alcohol_consumption': alcoholConsumption,
      'caffeine_intake': caffeineIntake,
      'sleep_quality': sleepQuality,
      'night_shift_work': nightShiftWork,
      'travel_frequency': travelFrequency,
      'stressful_work_environment': stressfulWorkEnvironment,
      'dietary_preference': dietaryPreference,
      'fast_food_frequency': fastFoodFrequency,
      'google_fit_sync': googleFitSync,
      'apple_health_sync': appleHealthSync,
      'fitbit_sync': fitbitSync,
      'step_count_integration': stepCountIntegration,
      'anonymous_wellness_insights': anonymousWellnessInsights,
      'ai_recommendations_consent': aiRecommendationsConsent,
      'symptom_prediction_consent': symptomPredictionConsent,
      'two_factor_enabled': twoFactorEnabled,
      'is_community_care_enrolled': isCommunityCareEnrolled,
    };
  }

  String get safeDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!;
    }
    return username;
  }
}

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  Future<UserProfile> getProfile() async {
    final response = await _apiClient.get('/auth/me/');
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _apiClient.patch('/auth/me/', body: profileData);
    return UserProfile.fromJson(response);
  }

  Future<Map<String, dynamic>> saveOnboardingSection(String section, Map<String, dynamic> data) async {
    return await _apiClient.post('/auth/onboarding/section/', body: {
      'section': section,
      'data': data,
    });
  }

  Future<void> completeOnboarding() async {
    await _apiClient.post('/auth/onboarding/complete/');
  }

  Future<void> sendMobileOtp(String mobileNumber) async {
    await _apiClient.post('/auth/mobile/send-otp/', body: {
      'mobile_number': mobileNumber,
    });
  }

  Future<Map<String, dynamic>> verifyMobileOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    return await _apiClient.post('/auth/mobile/verify-otp/', body: {
      'mobile_number': mobileNumber,
      'otp': otp,
    });
  }

  Future<void> sendEmailChangeOtp(String email) async {
    await _apiClient.post('/auth/email/send-otp/', body: {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> verifyEmailChangeOtp({
    required String email,
    required String otp,
  }) async {
    return await _apiClient.post('/auth/email/verify-otp/', body: {
      'email': email,
      'otp': otp,
    });
  }

  Future<List<VoucherModel>> getVouchers() async {
    final response = await _apiClient.get('/doctor-consultation/vouchers/');
    if (response is List) {
      return response.map((item) => VoucherModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<OrderHistoryItem>> getOrderHistory() async {
    final response = await _apiClient.get('/auth/orders/');
    if (response != null && response['orders'] != null) {
      final List ordersJson = response['orders'];
      return ordersJson.map((item) => OrderHistoryItem.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> submitSubscriptionUtr({
    required String orderId,
    required String utrNumber,
    File? screenshotFile,
  }) async {
    await _apiClient.multipartPost(
      '/subscriptions/payment/submit-utr/',
      fields: {
        'order_id': orderId,
        'utr_number': utrNumber,
      },
      fileFieldName: 'payment_screenshot',
      file: screenshotFile,
    );
  }

  Future<void> submitConsultationUtr({
    required int bookingId,
    required String utrNumber,
    File? screenshotFile,
  }) async {
    await _apiClient.multipartPost(
      '/doctor-consultation/bookings/$bookingId/submit-utr/',
      fields: {
        'utr_number': utrNumber,
      },
      fileFieldName: 'payment_screenshot',
      file: screenshotFile,
    );
  }
}

class VoucherModel {
  final int id;
  final String code;
  final double value;
  final bool isActive;
  final bool isSpent;
  final DateTime? spentAt;
  final DateTime createdAt;
  final DateTime? expiryDate;

  VoucherModel({
    required this.id,
    required this.code,
    required this.value,
    required this.isActive,
    required this.isSpent,
    this.spentAt,
    required this.createdAt,
    this.expiryDate,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'],
      code: json['code'] ?? '',
      value: (json['value'] as num).toDouble(),
      isActive: json['is_active'] ?? false,
      isSpent: json['is_spent'] ?? false,
      spentAt: json['spent_at'] != null ? DateTime.parse(json['spent_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
    );
  }
}
