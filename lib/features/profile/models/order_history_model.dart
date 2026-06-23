class OrderHistoryItem {
  final int id;
  final String uuid;
  final String orderId;
  final String type; // 'Subscription' or 'Consultation'
  final String displayName;
  final double amount;
  final String currency;
  final String status; // pending, success, failed, verification_pending, rejected
  final DateTime createdAt;
  final String? utrNumber;
  final String? paymentScreenshot;
  final Map<String, dynamic> details;
  final String? upiLink;
  final String? qrCodeUrl;

  OrderHistoryItem({
    required this.id,
    required this.uuid,
    required this.orderId,
    required this.type,
    required this.displayName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.utrNumber,
    this.paymentScreenshot,
    required this.details,
    this.upiLink,
    this.qrCodeUrl,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    double parsedAmount = 0.0;
    if (json['amount'] != null) {
      parsedAmount = (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount'].toString()) ?? 0.0;
    }

    DateTime parsedDate = DateTime.now();
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now();
    }

    return OrderHistoryItem(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      orderId: json['order_id'] ?? json['booking_number'] ?? '',
      type: json['type'] ?? '',
      displayName: json['display_name'] ?? json['plan_name'] ?? 'Order',
      amount: parsedAmount,
      currency: json['currency'] ?? 'INR',
      status: json['status'] ?? 'pending',
      createdAt: parsedDate,
      utrNumber: json['utr_number'],
      paymentScreenshot: json['payment_screenshot'],
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      upiLink: json['upi_link'],
      qrCodeUrl: json['qr_code_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'order_id': orderId,
      'type': type,
      'display_name': displayName,
      'amount': amount,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'utr_number': utrNumber,
      'payment_screenshot': paymentScreenshot,
      'details': details,
      'upi_link': upiLink,
      'qr_code_url': qrCodeUrl,
    };
  }
}
