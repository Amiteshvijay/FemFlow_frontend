class ReferralProfile {
  final String referralCode;
  final String shareLink;
  final int totalReferrals;
  final int successfulReferrals;
  final int rewardMonthsEarned;
  final DateTime? premiumUntil;

  ReferralProfile({
    required this.referralCode,
    required this.shareLink,
    required this.totalReferrals,
    required this.successfulReferrals,
    required this.rewardMonthsEarned,
    this.premiumUntil,
  });

  factory ReferralProfile.fromJson(Map<String, dynamic> json) {
    return ReferralProfile(
      referralCode: json['referral_code'],
      shareLink: json['share_link'],
      totalReferrals: json['total_referrals'],
      successfulReferrals: json['successful_referrals'],
      rewardMonthsEarned: json['reward_months_earned'],
      premiumUntil: json['premium_until'] != null ? DateTime.parse(json['premium_until']) : null,
    );
  }
}

class ReferralHistoryItem {
  final int id;
  final String status;
  final String referredUserDisplay;
  final int rewardMonths;
  final DateTime createdAt;
  final DateTime? rewardedAt;

  ReferralHistoryItem({
    required this.id,
    required this.status,
    required this.referredUserDisplay,
    required this.rewardMonths,
    required this.createdAt,
    this.rewardedAt,
  });

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryItem(
      id: json['id'],
      status: json['status'],
      referredUserDisplay: json['referred_user_display'],
      rewardMonths: json['reward_months'],
      createdAt: DateTime.parse(json['created_at']),
      rewardedAt: json['referrer_rewarded_at'] != null ? DateTime.parse(json['referrer_rewarded_at']) : null,
    );
  }
}

class ReferralShareContent {
  final String title;
  final String message;
  final String shareLink;

  ReferralShareContent({
    required this.title,
    required this.message,
    required this.shareLink,
  });

  factory ReferralShareContent.fromJson(Map<String, dynamic> json) {
    return ReferralShareContent(
      title: json['title'],
      message: json['message'],
      shareLink: json['share_link'],
    );
  }
}
