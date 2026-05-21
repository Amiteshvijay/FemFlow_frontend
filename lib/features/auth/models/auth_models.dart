class LoginResult {
  final bool requires2fa;
  final String? access;
  final String? refresh;
  final String? twoFactorToken;
  final String? maskedEmail;
  final String? message;
  final Map<String, dynamic>? user;

  LoginResult({
    required this.requires2fa,
    this.access,
    this.refresh,
    this.twoFactorToken,
    this.maskedEmail,
    this.message,
    this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      requires2fa: json['requires_2fa'] ?? false,
      access: json['access'],
      refresh: json['refresh'],
      twoFactorToken: json['two_factor_token'],
      maskedEmail: json['masked_email'],
      message: json['message'],
      user: json['user'],
    );
  }
}

class PasswordResetResult {
  final String message;
  final bool twoFactorDisabled;

  PasswordResetResult({required this.message, required this.twoFactorDisabled});

  factory PasswordResetResult.fromJson(Map<String, dynamic> json) {
    return PasswordResetResult(
      message: json['message'] ?? 'Success',
      twoFactorDisabled: json['two_factor_disabled'] ?? false,
    );
  }
}
