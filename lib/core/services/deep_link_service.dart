import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/navigator_service.dart';
import '../../features/partner_mode/accept_invite_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  String? _pendingReferralCode;

  Uri? _pendingUri;

  String? get pendingReferralCode => _pendingReferralCode;

  Future<void> init() async {
    // 1. Handle links when app is in background or foreground
    _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });

    // 2. Handle link that opened the app
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _pendingUri = initialUri;
    }
  }

  void checkPendingDynamicLink() {
    if (_pendingUri != null) {
      final uri = _pendingUri!;
      _pendingUri = null;
      _handleUri(uri);
    }
  }

  void _handleUri(Uri uri) async {
    debugPrint('Received Deep Link: $uri');
    
    // Referral Pattern: https://femflow.app/ref/CODE
    if (uri.path.startsWith('/ref/')) {
      final code = uri.pathSegments.last;
      if (code.isNotEmpty) {
        _pendingReferralCode = code;
        debugPrint('Found referral code in deep link: $code');
        
        // Persist it in case they close the app before signing up
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_referral_code', code);
      }
    }

    // Partner Invite Pattern: 
    // - femflow://partner/accept?token=TOKEN&email=EMAIL
    // - https://femflow.in/partner/accept?token=TOKEN&email=EMAIL
    // - https://femflow.app/partner/accept?token=TOKEN&email=EMAIL
    final isCustomSchemePartner = uri.scheme == 'femflow' && uri.host == 'partner' && uri.path == '/accept';
    final isWebSchemePartner = (uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host == 'femflow.in' || uri.host == 'femflow.app') &&
        uri.path == '/partner/accept';

    if (isCustomSchemePartner || isWebSchemePartner) {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];

      if (token != null && email != null) {
        debugPrint('Navigating to AcceptInviteScreen with token: $token');
        NavigatorService.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => AcceptInviteScreen(token: token, email: email),
          ),
        );
      }
    }
  }

  Future<void> clearPendingReferral() async {
    _pendingReferralCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_referral_code');
  }

  Future<String?> getPersistedReferral() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_referral_code');
  }
}
