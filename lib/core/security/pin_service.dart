import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_keys.dart';

class PinService {
  final _storage = const FlutterSecureStorage();

  // Create a 32-character random salt
  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    // SHA-256 for production-grade security
    return sha256.convert(bytes).toString();
  }

  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: SecureStorageKeys.pinSalt, value: salt);
    await _storage.write(key: SecureStorageKeys.pinHash, value: hash);
  }

  Future<bool> verifyPin(String inputPin) async {
    final salt = await _storage.read(key: SecureStorageKeys.pinSalt);
    final storedHash = await _storage.read(key: SecureStorageKeys.pinHash);
    
    if (salt == null || storedHash == null) return false;
    
    final inputHash = _hashPin(inputPin, salt);
    return inputHash == storedHash;
  }

  Future<bool> isPinSet() async {
    final storedHash = await _storage.read(key: SecureStorageKeys.pinHash);
    return storedHash != null;
  }

  Future<void> clearPinData() async {
    await _storage.delete(key: SecureStorageKeys.pinHash);
    await _storage.delete(key: SecureStorageKeys.pinSalt);
    await _storage.write(key: SecureStorageKeys.isAppLockEnabled, value: 'false');
    await _storage.write(key: SecureStorageKeys.isBiometricEnabled, value: 'false');
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: SecureStorageKeys.isAppLockEnabled, value: enabled.toString());
  }

  Future<bool> isAppLockEnabled() async {
    final val = await _storage.read(key: SecureStorageKeys.isAppLockEnabled);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: SecureStorageKeys.isBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: SecureStorageKeys.isBiometricEnabled);
    return val == 'true';
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    await _storage.write(key: SecureStorageKeys.autoLockTimeout, value: seconds.toString());
  }

  Future<int> getAutoLockTimeout() async {
    final val = await _storage.read(key: SecureStorageKeys.autoLockTimeout);
    return int.tryParse(val ?? '0') ?? 0;
  }
}
