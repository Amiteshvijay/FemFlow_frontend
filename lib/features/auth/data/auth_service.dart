import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<dynamic> updateAvatar(Uint8List imageBytes, String fileName) async {
    final multipartFile = http.MultipartFile.fromBytes(
      'avatar',
      imageBytes,
      filename: fileName,
    );
    return await _apiClient.patch('/auth/me/', files: [multipartFile]);
  }

  Future<void> register({
    required String mobileNo,
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    debugPrint('Attempting registration for: $mobileNo ($email), Name: $fullName');
    await _apiClient.post('/auth/register/', body: {
      'mobile_no': mobileNo,
      'email': email,
      'password': password,
      'full_name': fullName,
      'referral_code': referralCode,
    });
  }

  Future<Map<String, dynamic>> requestSignupOtp({
    required String mobileNo,
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    debugPrint('Attempting signup OTP request for: $mobileNo ($email)');
    final response = await _apiClient.post('/auth/signup/request-otp/', body: {
      'phone': mobileNo,
      'email': email,
      'password': password,
      'full_name': fullName,
      'referral_code': referralCode,
    });
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> verifySignupOtp({
    required String verificationId,
    String? emailOtp,
    String? phoneOtp,
  }) async {
    debugPrint('Attempting signup OTP verification for: $verificationId');
    final Map<String, dynamic> body = {
      'verification_id': verificationId,
    };
    if (emailOtp != null && emailOtp.isNotEmpty) {
      body['email_otp'] = emailOtp;
    }
    if (phoneOtp != null && phoneOtp.isNotEmpty) {
      body['phone_otp'] = phoneOtp;
    }

    final response = await _apiClient.post('/auth/signup/verify-otp/', body: body);

    if (response['success'] == true && response['access'] != null && response['refresh'] != null) {
      await _tokenStorage.saveTokens(
        access: response['access'],
        refresh: response['refresh'],
      );
    }
    return Map<String, dynamic>.from(response);
  }

  Future<void> resendSignupOtp({
    required String verificationId,
    required String channel,
  }) async {
    debugPrint('Attempting signup OTP resend for channel: $channel');
    await _apiClient.post('/auth/signup/resend-otp/', body: {
      'verification_id': verificationId,
      'channel': channel,
    });
  }


  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    debugPrint('Attempting login for: $username');
    final response = await _apiClient.post('/auth/login/', body: {
      'username': username,
      'password': password,
    });

    final result = LoginResult.fromJson(response);
    
    if (!result.requires2fa && result.access != null && result.refresh != null) {
      await _tokenStorage.saveTokens(access: result.access!, refresh: result.refresh!);
    }

    return result;
  }

  Future<LoginResult> verify2fa({
    required String twoFactorToken,
    required String otp,
  }) async {
    final response = await _apiClient.post('/auth/2fa/verify/', body: {
      'two_factor_token': twoFactorToken,
      'otp': otp,
    });

    final result = LoginResult.fromJson(response);
    if (result.access != null && result.refresh != null) {
      await _tokenStorage.saveTokens(access: result.access!, refresh: result.refresh!);
    }
    return result;
  }

  Future<void> resend2fa(String twoFactorToken) async {
    await _apiClient.post('/auth/2fa/resend/', body: {
      'two_factor_token': twoFactorToken,
    });
  }

  Future<void> enable2fa() async {
    await _apiClient.post('/auth/2fa/enable/');
  }

  Future<void> disable2fa(String password) async {
    await _apiClient.post('/auth/2fa/disable/', body: {
      'password': password,
    });
  }

  Future<dynamic> me() async {
    return await _apiClient.get('/auth/me/');
  }

  Future<void> refresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token available');

    final response = await _apiClient.post('/auth/refresh/', body: {
      'refresh': refreshToken,
    });

    final String access = response['access'];
    final String? newRefresh = response['refresh'];

    await _tokenStorage.saveTokens(
      access: access,
      refresh: newRefresh ?? refreshToken,
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null;
  }

  Future<void> sendForgotPasswordOtp({required String email}) async {
    debugPrint('Attempting send OTP for: $email');
    await _apiClient.post('/auth/password/forgot/', body: {
      'email_or_username': email,
    });
  }

  Future<String> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    debugPrint('Attempting verify OTP for: $email');
    final response = await _apiClient.post('/auth/password/verify-otp/', body: {
      'email_or_username': email,
      'otp': otp,
    });
    return response['reset_token'];
  }

  Future<PasswordResetResult> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post('/auth/password/reset/', body: {
      'reset_token': resetToken,
      'new_password': newPassword,
      'confirm_password': confirmPassword,
    });
    return PasswordResetResult.fromJson(response);
  }

  Future<void> sendPinResetOtp({required String email}) async {
    await _apiClient.post('/auth/send-pin-reset-otp/', body: {
      'email': email,
    });
  }

  Future<void> verifyPinResetOtp({
    required String email,
    required String otp,
  }) async {
    await _apiClient.post('/auth/verify-pin-reset-otp/', body: {
      'email': email,
      'otp': otp,
    });
  }

  Future<void> verifyDeletionPassword(String password) async {
    await _apiClient.post('/auth/account-deletion/verify-password/', body: {
      'password': password,
    });
  }

  Future<void> sendDeletionOtp(String email) async {
    await _apiClient.post('/auth/account-deletion/send-otp/', body: {
      'email': email,
    });
  }

  Future<void> verifyDeletionOtp(String email, String otp) async {
    await _apiClient.post('/auth/account-deletion/verify-otp/', body: {
      'email': email,
      'otp': otp,
    });
  }

  Future<Map<String, dynamic>> submitDeletionRequest(String email, String reason) async {
    return await _apiClient.post('/auth/account-deletion/submit/', body: {
      'email': email,
      'reason': reason,
    });
  }
}
