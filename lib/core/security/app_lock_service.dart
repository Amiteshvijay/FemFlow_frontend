import 'package:flutter/material.dart';
import 'pin_service.dart';

class AppLockService extends ChangeNotifier {
  final PinService _pinService = PinService();

  bool _isLocked = false;
  bool _isEnabled = false;
  bool _biometricsEnabled = false;
  bool _isBiometricsAvailable = false;
  int _autoLockTimeout = 0;
  DateTime? _lastPausedTime;
  final bool _isLockedManuallyTriggered = false;
  bool _isInitializing = true;
  bool _trustedExternalFlowActive = false;
  bool _suppressNextLock = false;

  bool get isLocked => _isLocked;
  bool get isEnabled => _isEnabled;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get isBiometricsAvailable => _isBiometricsAvailable;
  int get autoLockTimeout => _autoLockTimeout;
  bool get isLockedManuallyTriggered => _isLockedManuallyTriggered;
  bool get isInitializing => _isInitializing;
  bool get trustedExternalFlowActive => _trustedExternalFlowActive;
  bool get suppressNextLock => _suppressNextLock;

  AppLockService() {
    _init();
  }

  Future<void> _init() async {
    _isEnabled = await _pinService.isAppLockEnabled();
    _biometricsEnabled = false; // Forced false as biometrics are removed
    _autoLockTimeout = await _pinService.getAutoLockTimeout();
    _isBiometricsAvailable = false; // Forced false as biometrics are removed
    
    // On app startup, if lock is enabled, start as locked
    if (_isEnabled) {
      _isLocked = true;
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool value) async {
    _isEnabled = value;
    await _pinService.setAppLockEnabled(value);
    if (!value) {
      _isLocked = false;
    }
    notifyListeners();
  }

  Future<void> setBiometricsEnabled(bool value) async {
    // Biometrics removed as of now
    _biometricsEnabled = false;
    await _pinService.setBiometricEnabled(false);
    notifyListeners();
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    _autoLockTimeout = seconds;
    await _pinService.setAutoLockTimeout(seconds);
    notifyListeners();
  }

  void lock() {
    if (_isEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlock() {
    _isLocked = false;
    _lastPausedTime = null;
    _suppressNextLock = false; // Reset suppression on manual unlock
    notifyListeners();
  }

  void setTrustedExternalFlowActive(bool value) {
    _trustedExternalFlowActive = value;
    if (!value) {
      // When ending a flow, update lastPausedTime to now 
      // so the timeout starts counting from the moment the user returns to the app
      _lastPausedTime = DateTime.now();
    }
    notifyListeners();
  }

  void setSuppressNextLock(bool value) {
    _suppressNextLock = value;
    notifyListeners();
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    if (!_isEnabled) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_lastPausedTime == null) {
        _lastPausedTime = DateTime.now();
        // If timeout is 0 (Immediate Lock), lock only if NO trusted flow is active
        if (_autoLockTimeout == 0 && !_trustedExternalFlowActive && !_suppressNextLock) {
          _isLocked = true;
          notifyListeners();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // 1. If we are in a trusted flow (picker, payment) or suppressed, DO NOT lock
      if (_trustedExternalFlowActive || _suppressNextLock) {
        _suppressNextLock = false; // Clear one-time suppression
        _lastPausedTime = null;
        return;
      }

      // 2. Check timeout
      if (_lastPausedTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastPausedTime!).inSeconds;
        
        if (difference >= _autoLockTimeout) {
          _isLocked = true;
        }
        _lastPausedTime = null;
        notifyListeners();
      }
    }
  }

  Future<bool> verifyPin(String pin) async {
    return await _pinService.verifyPin(pin);
  }

  Future<void> savePin(String pin) async {
    await _pinService.savePin(pin);
  }

  Future<bool> authenticateWithBiometrics() async {
    // Biometrics removed as of now
    return false;
  }

  Future<void> clearAll() async {
    await _pinService.clearPinData();
    _isEnabled = false;
    _isLocked = false;
    _biometricsEnabled = false;
    notifyListeners();
  }

  Future<void> resetAppLock() async {
    // 1. Wipe all local security data
    await _pinService.clearPinData();
    await _pinService.setAppLockEnabled(false);
    await _pinService.setBiometricEnabled(false);
    
    // 2. Update local state
    _isEnabled = false;
    _isLocked = false;
    _biometricsEnabled = false;
    _lastPausedTime = null;

    notifyListeners();
  }
}
