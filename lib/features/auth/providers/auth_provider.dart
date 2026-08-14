import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_service.dart';
import '../../profile/data/profile_service.dart' as profile_data;
import '../../reminders/data/reminder_service.dart' as reminders;
import '../../pill_reminder/data/pill_reminder_service.dart' as pills;
import '../../../core/network/api_client.dart';

import '../../subscriptions/providers/subscription_provider.dart';

enum AuthStatus { authenticated, unauthenticated, maintenance, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final profile_data.ProfileService _profileService = profile_data.ProfileService();
  SubscriptionProvider? _subscriptionProvider;

  AuthStatus _status = AuthStatus.loading;
  bool _onboardingCompleted = false;
  bool _showSignupScreen = false;
  profile_data.UserProfile? _profile;

  AuthStatus get status => _status;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get showSignupScreen => _showSignupScreen;
  profile_data.UserProfile? get profile => _profile;

  void updateSubscriptionProvider(SubscriptionProvider provider) {
    _subscriptionProvider = provider;
  }

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // 1. Check Onboarding Status
      final prefs = await SharedPreferences.getInstance();
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      // 2. Check Auth Status
      final authenticated = await _authService.isAuthenticated();
      if (authenticated) {
        try {
          _profile = await _profileService.getProfile();
          // Initialize user-specific stuff
          reminders.ReminderService().scheduleAllActiveReminders();
          pills.PillReminderService().scheduleAllActiveMedications();
          
          if (_subscriptionProvider != null) {
            _subscriptionProvider!.loadStatus();
          }

          _status = AuthStatus.authenticated;
        } on ApiException catch (e) {
          if (e.statusCode == 401) {
            _status = AuthStatus.unauthenticated;
          } else if (e.statusCode == 503) {
             _status = AuthStatus.maintenance;
          } else {
             _status = AuthStatus.unauthenticated;
          }
        } catch (e) {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void notifyLogin() {
    checkAuth();
  }

  Future<void> logout() async {
    await _authService.logout();
    _profile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> completeOnboarding({bool showSignup = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    _onboardingCompleted = true;
    _showSignupScreen = showSignup;
    notifyListeners();
  }

  void setMaintenance() {
    _status = AuthStatus.maintenance;
    notifyListeners();
  }
}
