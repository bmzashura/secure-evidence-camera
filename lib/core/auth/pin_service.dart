import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// PIN Service using bcrypt-like approach with salt
/// Since Flutter doesn't have native bcrypt, we use PBKDF2 with salt
class PinService {
  static const String _pinHashKey = 'pin_hash';
  static const String _saltKey = 'pin_salt';
  static const String _appWasInBackgroundKey = 'app_was_in_background';
  static const int _iterations = 10000;
  static const int _keyLength = 32;

  final FlutterSecureStorage _secureStorage;

  PinService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Generate random salt
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Hash PIN using PBKDF2 (bcrypt-like approach)
  String _hashPin(String pin, String salt) {
    final codec = utf8;
    final saltBytes = base64Decode(salt);
    final pinBytes = codec.encode(pin);

    // PBKDF2 implementation using HMAC-SHA256
    final hmac = Hmac(sha256, pinBytes);
    var block = saltBytes + [0, 0, 0, 1]; // Block index = 1
    var result = hmac.convert(block).bytes;
    var previous = result;

    for (var i = 1; i < _iterations; i++) {
      final current = hmac.convert(previous).bytes;
      // XOR
      for (var j = 0; j < result.length; j++) {
        result[j] ^= current[j];
      }
      previous = current;
    }

    // Truncate or pad to _keyLength bytes
    final truncated = result.sublist(0, _keyLength.clamp(0, result.length));
    return base64Encode(truncated);
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Setup new PIN
  Future<void> setupPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _saltKey, value: salt);
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _secureStorage.read(key: _saltKey);

    if (storedHash == null || salt == null) return false;

    final inputHash = _hashPin(pin, salt);
    return inputHash == storedHash;
  }

  /// Change PIN (requires old PIN verification first)
  Future<bool> changePin(String oldPin, String newPin) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;
    await setupPin(newPin);
    return true;
  }

  /// Get stored hash (for storage inspector demo)
  Future<String?> getStoredHash() async {
    return await _secureStorage.read(key: _pinHashKey);
  }

  /// Get stored salt (for storage inspector demo)
  Future<String?> getStoredSalt() async {
    return await _secureStorage.read(key: _saltKey);
  }

  /// Track app going to background (for onboarding logic)
  Future<void> setAppWasInBackground() async {
    await _secureStorage.write(key: _appWasInBackgroundKey, value: 'true');
  }

  /// Check and clear the background flag atomically
  Future<bool> checkAndClearAppWasInBackground() async {
    final value = await _secureStorage.read(key: _appWasInBackgroundKey);
    if (value == 'true') {
      await _secureStorage.delete(key: _appWasInBackgroundKey);
      return true;
    }
    return false;
  }
}