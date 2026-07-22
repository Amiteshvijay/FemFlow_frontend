import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import '../navigation/navigator_service.dart';
import '../../features/partner_mode/accept_invite_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  String? _pendingReferralCode;
  final _uriController = StreamController<Uri>.broadcast();
  Stream<Uri> get uriStream => _uriController.stream;

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
    } else {
      _checkInstallReferrer();
    }
  }

  Future<void> _checkInstallReferrer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyProcessed = prefs.getBool('processed_install_referrer') ?? false;
      if (alreadyProcessed) {
        return;
      }

      final details = await PlayInstallReferrer.installReferrer;
      final referrer = details.installReferrer;
      debugPrint('Retrieved Google Play Install Referrer: $referrer');

      if (referrer != null && referrer.isNotEmpty) {
        if (referrer.contains('token=') && referrer.contains('email=')) {
          // Mark it as processed immediately to avoid repeat redirects on subsequent launches
          await prefs.setBool('processed_install_referrer', true);

          String sanitizedReferrer = referrer;
          if (referrer.startsWith('referrer=')) {
            sanitizedReferrer = referrer.replaceFirst('referrer=', '');
          }

          try {
            sanitizedReferrer = Uri.decodeFull(sanitizedReferrer);
          } catch (_) {}

          final uri = Uri.parse('FemLyra://partner/accept?$sanitizedReferrer');
          debugPrint('Redirecting parsed install referrer URI: $uri');
          _handleUri(uri);
        }
      }
    } catch (e) {
      debugPrint('Error retrieving install referrer: $e');
    }
  }

  void _handleUri(Uri uri) async {
    debugPrint('Received Deep Link: $uri');
    _uriController.add(uri);
    
    // Referral Pattern: https://FemLyra.app/ref/CODE
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

    final path = uri.path;
    final isPartnerPath = path == '/partner/accept' || path == '/partner/accept/';
    final isCustomPartnerPath = path == '/accept' || path == '/accept/';

    final isCustomSchemePartner = uri.scheme == 'FemLyra' && uri.host == 'partner' && isCustomPartnerPath;
    final isWebSchemePartner = (uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host == 'femlyra.com' || uri.host == 'FemLyra.app') &&
        isPartnerPath;

    if (isCustomSchemePartner || isWebSchemePartner) {
      final token = uri.queryParameters['token'];
      final email = uri.queryParameters['email'];
      final code = uri.queryParameters['code'];

      if (token != null && email != null) {
        debugPrint('Navigating to AcceptInviteScreen with token: $token, code: $code');
        
        void performPush() {
          final state = NavigatorService.navigatorKey.currentState;
          if (state != null) {
            state.push(
              MaterialPageRoute(
                builder: (_) => AcceptInviteScreen(
                  token: token,
                  email: email,
                  pairingCode: code,
                ),
              ),
            );
          } else {
            debugPrint('Navigator state not ready yet. Retrying deep link navigation in 200ms...');
            Future.delayed(const Duration(milliseconds: 200), performPush);
          }
        }
        
        performPush();
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
