class DoctorCategory {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? iconName;

  DoctorCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.iconName,
  });

  factory DoctorCategory.fromJson(Map<String, dynamic> json) {
    return DoctorCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      iconName: json['icon_name'],
    );
  }
}

class DoctorProfile {
  final int id;
  final String? doctorId;
  final String fullName;
  final String category;
  final String speciality;
  final String qualification;
  final int experienceYears;
  final String? about;
  final List<String> languages;
  final double consultationFee;
  final String currency;
  final double? rating;
  final int totalReviews;
  final bool isVerified;
  final bool isAvailable;
  final String? nextAvailableText;
  final List<String> consultationModes;
  final List<String> availableDays;
  final List<String> availableSlots;
  final String? profileImage;
  final List<DoctorReview> recentReviews;

  // Additional Profile Details
  final String? dob;
  final String? gender;
  final String? registrationNumber;
  final String? medicalCouncil;
  final List<dynamic> workHistory;
  final List<dynamic> awards;
  final List<dynamic> memberships;
  final List<dynamic> educationHistory;

  // Bank Details (for doctor portal/payout info)
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? accountHolderName;

  DoctorProfile({
    required this.id,
    this.doctorId,
    required this.fullName,
    required this.category,
    required this.speciality,
    required this.qualification,
    required this.experienceYears,
    this.about,
    required this.languages,
    required this.consultationFee,
    required this.currency,
    this.rating,
    required this.totalReviews,
    required this.isVerified,
    required this.isAvailable,
    this.nextAvailableText,
    required this.consultationModes,
    required this.availableDays,
    required this.availableSlots,
    this.profileImage,
    this.recentReviews = const [],
    this.dob,
    this.gender,
    this.registrationNumber,
    this.medicalCouncil,
    this.workHistory = const [],
    this.awards = const [],
    this.memberships = const [],
    this.educationHistory = const [],
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.accountHolderName,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'],
      doctorId: json['doctor_id'],
      fullName: json['full_name'],
      category: json['category'],
      speciality: json['speciality'],
      qualification: json['qualification'],
      experienceYears: json['experience_years'],
      about: json['about'],
      languages: List<String>.from(json['languages'] ?? []),
      consultationFee: double.parse(json['consultation_fee'].toString()),
      currency: json['currency'] ?? 'INR',
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : null,
      totalReviews: json['total_reviews'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isAvailable: json['is_available'] ?? false,
      nextAvailableText: json['next_available_text'],
      consultationModes: List<String>.from(json['consultation_modes'] ?? []),
      availableDays: List<String>.from(json['available_days'] ?? []),
      availableSlots: List<String>.from(json['available_slots'] ?? []),
      profileImage: json['profile_image'],
      recentReviews: (json['recent_reviews'] as List?)
              ?.map((r) {
                try {
                  return DoctorReview.fromJson(r);
                } catch (e) {
                  return null;
                }
              })
              .whereType<DoctorReview>()
              .toList() ??
          [],
      dob: json['dob'],
      gender: json['gender'],
      registrationNumber: json['registration_number'],
      medicalCouncil: json['medical_council'],
      workHistory: List<dynamic>.from(json['work_history'] ?? []),
      awards: List<dynamic>.from(json['awards'] ?? []),
      memberships: List<dynamic>.from(json['memberships'] ?? []),
      educationHistory: List<dynamic>.from(json['education_history'] ?? []),
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
      accountHolderName: json['account_holder_name'],
    );
  }
}

class Invoice {
  final String invoiceNumber;
  final String invoiceDate;
  final double amount;
  final double taxAmount;
  final String status;

  Invoice({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.amount,
    required this.taxAmount,
    required this.status,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNumber: json['invoice_number'],
      invoiceDate: json['invoice_date'],
      amount: double.parse(json['amount'].toString()),
      taxAmount: double.parse(json['tax_amount'].toString()),
      status: json['status'],
    );
  }
}

class DoctorBooking {
  final int id;
  final String bookingIdDisplay;
  final int doctorId;
  final String doctorName;
  final String? doctorSpecialty;
  final String consultationMode;
  final String appointmentDate;
  final String appointmentTime;
  final double consultationFee;
  final String currency;
  final String status;
  final String paymentStatus;
  final String? razorpayPaymentId;
  final String? userNotes;
  final String createdAt;
  final Invoice? invoice;
  final String? meetLink;
  final bool hasReview;
  final bool hasPrescription;

  DoctorBooking({
    required this.id,
    required this.bookingIdDisplay,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialty,
    required this.consultationMode,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.consultationFee,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    this.razorpayPaymentId,
    this.userNotes,
    required this.createdAt,
    this.invoice,
    this.meetLink,
    this.hasReview = false,
    this.hasPrescription = false,
  });

  factory DoctorBooking.fromJson(Map<String, dynamic> json) {
    return DoctorBooking(
      id: json['id'],
      bookingIdDisplay: json['booking_id_display'] ?? 'FF-CD-${json['id']}',
      doctorId: json['doctor'],
      doctorName: json['doctor_name'] ?? '',
      doctorSpecialty: json['doctor_specialty'],
      consultationMode: json['consultation_mode'],
      appointmentDate: json['appointment_date'],
      appointmentTime: json['appointment_time'],
      consultationFee: double.parse(json['consultation_fee'].toString()),
      currency: json['currency'] ?? 'INR',
      status: json['status'],
      paymentStatus: json['payment_status'],
      razorpayPaymentId: json['razorpay_payment_id'],
      userNotes: json['user_notes'],
      createdAt: json['created_at'],
      invoice: json['invoice'] != null ? Invoice.fromJson(json['invoice']) : null,
      meetLink: json['meet_link'],
      hasReview: json['has_review'] ?? false,
      hasPrescription: json['has_prescription'] ?? false,
    );
  }
}

class DoctorReview {
  final int id;
  final int bookingId;
  final String? bookingIdDisplay;
  final String userName;
  final String doctorName;
  final int rating;
  final List<String> quickTags;
  final String? reviewText;
  final String moderationStatus;
  final String? doctorResponse;
  final String createdAt;

  DoctorReview({
    required this.id,
    required this.bookingId,
    this.bookingIdDisplay,
    required this.userName,
    required this.doctorName,
    required this.rating,
    required this.quickTags,
    this.reviewText,
    required this.moderationStatus,
    this.doctorResponse,
    required this.createdAt,
  });

  factory DoctorReview.fromJson(Map<String, dynamic> json) {
    return DoctorReview(
      id: json['id'],
      bookingId: json['booking'] ?? 0,
      bookingIdDisplay: json['booking_id_display'],
      userName: json['user_name'] ?? 'User',
      doctorName: json['doctor_name'] ?? '',
      rating: json['rating'] ?? 5,
      quickTags: List<String>.from(json['quick_tags'] ?? []),
      reviewText: json['review_text'],
      moderationStatus: json['moderation_status'] ?? 'pending',
      doctorResponse: json['doctor_response'],
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class Prescription {
  final int id;
  final int bookingId;
  final String doctorName;
  final String diagnosis;
  final List<dynamic> medicines;
  final String? instructions;
  final String? followUpNotes;
  final String? precautions;
  final String? lifestyleRecommendations;
  final String? internalNotes;
  final String? nextConsultationRecommendation;
  final String? fileUrl;
  final String createdAt;

  Prescription({
    required this.id,
    required this.bookingId,
    required this.doctorName,
    required this.diagnosis,
    required this.medicines,
    this.instructions,
    this.followUpNotes,
    this.precautions,
    this.lifestyleRecommendations,
    this.internalNotes,
    this.nextConsultationRecommendation,
    this.fileUrl,
    required this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      bookingId: json['booking'],
      doctorName: json['doctor_name'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      medicines: json['medicines'] ?? [],
      instructions: json['instructions'],
      followUpNotes: json['follow_up_notes'],
      precautions: json['precautions'],
      lifestyleRecommendations: json['lifestyle_recommendations'],
      internalNotes: json['internal_notes'],
      nextConsultationRecommendation: json['next_consultation_recommendation'],
      fileUrl: json['file'],
      createdAt: json['created_at'],
    );
  }
}
