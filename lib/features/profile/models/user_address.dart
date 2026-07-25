class UserAddress {
  final int? id;
  final String label; // 'home', 'office', 'other'
  final String? customLabel;
  final String? fullName;
  final String? phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String city;
  final String? state;
  final String pincode;
  final bool isDefault;
  final String? createdAt;
  final String? updatedAt;

  UserAddress({
    this.id,
    required this.label,
    this.customLabel,
    this.fullName,
    this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    this.landmark,
    required this.city,
    this.state,
    required this.pincode,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'] as int?,
      label: json['label'] as String? ?? 'home',
      customLabel: json['custom_label'] as String?,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      addressLine1: json['address_line_1'] as String? ?? '',
      addressLine2: json['address_line_2'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      pincode: json['pincode'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'label': label,
      if (customLabel != null && customLabel!.isNotEmpty) 'custom_label': customLabel,
      if (fullName != null && fullName!.isNotEmpty) 'full_name': fullName,
      if (phoneNumber != null && phoneNumber!.isNotEmpty) 'phone_number': phoneNumber,
      'address_line_1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) 'address_line_2': addressLine2,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      'city': city,
      if (state != null && state!.isNotEmpty) 'state': state,
      'pincode': pincode,
      'is_default': isDefault,
    };
  }

  String get displayTitle {
    if (label == 'other' && customLabel != null && customLabel!.isNotEmpty) {
      return customLabel!;
    }
    if (label == 'office') return 'Office';
    if (label == 'other') return 'Other';
    return 'Home';
  }

  String get formattedAddress {
    final parts = <String>[];
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2 != null && addressLine2!.isNotEmpty) parts.add(addressLine2!);
    if (landmark != null && landmark!.isNotEmpty) parts.add('Near $landmark');
    if (city.isNotEmpty) parts.add(city);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }

  UserAddress copyWith({
    int? id,
    String? label,
    String? customLabel,
    String? fullName,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
