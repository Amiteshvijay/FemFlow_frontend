class SubscriptionPlan {
  final int id;
  final String name;
  final String planType;
  final String? planKey;
  final String? durationLabel;
  final double price; // Original price
  final double? offerPrice;
  final String currency;
  final String billingCycle;
  final int? durationDays;
  final int? durationMonths;
  final bool isLifetime;
  final String? badge;
  final String? secondaryLabel;
  final bool highlight;
  final bool primaryRecommended;
  final List<String> benefits;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    this.planKey,
    this.durationLabel,
    required this.price,
    this.offerPrice,
    required this.currency,
    required this.billingCycle,
    this.durationDays,
    this.durationMonths,
    this.isLifetime = false,
    this.badge,
    this.secondaryLabel,
    this.highlight = false,
    this.primaryRecommended = false,
    required this.benefits,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      planType: json['plan_type'],
      planKey: json['plan_key'],
      durationLabel: json['duration_label'],
      price: double.parse(json['price'].toString()),
      offerPrice: json['offer_price'] != null ? double.parse(json['offer_price'].toString()) : null,
      currency: json['currency'],
      billingCycle: json['billing_cycle'],
      durationDays: json['duration_days'],
      durationMonths: json['duration_months'],
      isLifetime: json['is_lifetime'] ?? false,
      badge: json['badge'],
      secondaryLabel: json['secondary_label'],
      highlight: json['highlight'] ?? false,
      primaryRecommended: json['primary_recommended'] ?? false,
      benefits: List<String>.from(json['benefits'] ?? []),
    );
  }
}

class UserSubscriptionStatus {
  final String status;
  final DateTime? trialEndDate;
  final DateTime? subscriptionEndDate;
  final bool autoRenew;
  final int trialDaysLeft;
  final bool hasPremiumAccess;
  final String? planName;
  final String? planKey;
  final bool isLifetime;
  final String? baseUrl;
  final bool hasUsedTrial;

  UserSubscriptionStatus({
    required this.status,
    this.trialEndDate,
    this.subscriptionEndDate,
    required this.autoRenew,
    required this.trialDaysLeft,
    required this.hasPremiumAccess,
    this.planName,
    this.planKey,
    this.isLifetime = false,
    this.baseUrl,
    required this.hasUsedTrial,
  });

  factory UserSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionStatus(
      status: json['status'],
      trialEndDate: json['trial_end_date'] != null ? DateTime.parse(json['trial_end_date']) : null,
      subscriptionEndDate: json['subscription_end_date'] != null ? DateTime.parse(json['subscription_end_date']) : null,
      autoRenew: json['auto_renew'] ?? true,
      trialDaysLeft: json['trial_days_left'] ?? 0,
      hasPremiumAccess: json['has_premium_access'] ?? false,
      planName: json['plan_name'],
      planKey: json['plan_key'],
      isLifetime: json['is_lifetime'] ?? false,
      baseUrl: json['base_url'],
      hasUsedTrial: json['has_used_trial'] ?? false,
    );
  }

  bool get isTrialActive => status == 'trial_active';
  bool get isPremiumActive => status == 'active';
}

class InvoiceModel {
  final int id;
  final String invoiceNumber;
  final String? invoicePdf;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String? planName;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    this.invoicePdf,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.planName,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      invoicePdf: json['invoice_pdf'],
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      planName: json['plan_name'],
    );
  }
}
