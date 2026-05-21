import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BackupEncryptionService {
  static const String _keyAlias = 'femflow_backup_key';
  final _storage = const FlutterSecureStorage();

  /// Generates or retrieves the backup encryption key.
  Future<Key> _getOrGenerateKey() async {
    String? storedKey = await _storage.read(key: _keyAlias);
    if (storedKey == null) {
      final newKey = Key.fromSecureRandom(32); // 256-bit key
      await _storage.write(key: _keyAlias, value: newKey.base64);
      return newKey;
    }
    return Key.fromBase64(storedKey);
  }

  /// Encrypts the backup JSON string.
  /// Returns a Base64 string containing [IV (12 bytes) + Encrypted Data + Tag].
  /// Note: AES-GCM in 'encrypt' package appends the tag to the cipher text.
  Future<String> encryptBackup(String jsonString) async {
    final key = await _getOrGenerateKey();
    final iv = IV.fromSecureRandom(12); // GCM standard IV size is 12 bytes
    
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm, padding: null));
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    
    // Combine IV and CipherText (which includes the tag in GCM mode for this package)
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    return base64.encode(combined);
  }

  /// Decrypts the Base64 encrypted backup string.
  Future<String> decryptBackup(String encryptedBase64, {String? manualKey}) async {
    try {
      final combined = base64.decode(encryptedBase64);
      if (combined.length < 12) throw Exception('Invalid backup file');

      final key = manualKey != null ? Key.fromBase64(manualKey) : await _getOrGenerateKey();
      
      final iv = IV(combined.sublist(0, 12));
      final cipherText = combined.sublist(12);
      
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm, padding: null));
      return encrypter.decrypt(Encrypted(cipherText), iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: Check recovery key');
    }
  }

  /// Exports the recovery key as a Base64 string for the user to save.
  Future<String> exportRecoveryKey() async {
    final key = await _getOrGenerateKey();
    return key.base64;
  }

  /// Imports a recovery key (e.g., when restoring on a new device).
  Future<void> importRecoveryKey(String base64Key) async {
    // Validate key length (should be 32 bytes decoded)
    final bytes = base64.decode(base64Key);
    if (bytes.length != 32) throw Exception('Invalid recovery key length');
    
    await _storage.write(key: _keyAlias, value: base64Key);
  }
  
  /// Checks if a key already exists.
  Future<bool> hasKey() async {
    return await _storage.containsKey(key: _keyAlias);
  }
}
