class FemLyraEvent {
  final int id;
  final String title;
  final String slug;
  final String shortDescription;
  final String fullDescription;
  final String category;
  final String bannerImage;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final String mode;
  final String? location;
  final String? meetingLink;
  final String? guestSpeakerName;
  final String? guestSpeakerDesignation;
  final String? guestSpeakerPhoto;
  final String? guestSpeakerBio;
  final int maxSeats;
  final DateTime registrationDeadline;
  final String status;
  final int registeredCount;
  final bool isRegistered;

  FemLyraEvent({
    required this.id,
    required this.title,
    required this.slug,
    required this.shortDescription,
    required this.fullDescription,
    required this.category,
    required this.bannerImage,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.mode,
    this.location,
    this.meetingLink,
    this.guestSpeakerName,
    this.guestSpeakerDesignation,
    this.guestSpeakerPhoto,
    this.guestSpeakerBio,
    required this.maxSeats,
    required this.registrationDeadline,
    required this.status,
    required this.registeredCount,
    required this.isRegistered,
  });

  factory FemLyraEvent.fromJson(Map<String, dynamic> json) {
    return FemLyraEvent(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      shortDescription: json['short_description'],
      fullDescription: json['full_description'],
      category: json['category'],
      bannerImage: json['banner_image'],
      eventDate: DateTime.parse(json['event_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      mode: json['mode'],
      location: json['location'],
      meetingLink: json['meeting_link'],
      guestSpeakerName: json['guest_speaker_name'],
      guestSpeakerDesignation: json['guest_speaker_designation'],
      guestSpeakerPhoto: json['guest_speaker_photo'],
      guestSpeakerBio: json['guest_speaker_bio'],
      maxSeats: json['max_seats'],
      registrationDeadline: DateTime.parse(json['registration_deadline']),
      status: json['status'],
      registeredCount: json['registered_count'] ?? 0,
      isRegistered: json['is_registered'] ?? false,
    );
  }
}

class EventRegistrationRequest {
  final String name;
  final String email;
  final String mobile;
  final int? age;
  final String? city;
  final String? profession;
  final String? question;
  final bool consent;

  EventRegistrationRequest({
    required this.name,
    required this.email,
    required this.mobile,
    this.age,
    this.city,
    this.profession,
    this.question,
    required this.consent,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'age': age,
      'city': city,
      'profession': profession,
      'question': question,
      'consent': consent,
    };
  }
}
