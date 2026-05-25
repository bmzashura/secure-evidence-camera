import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encryption service using AES-256-CBC
class EncryptionService {
  static const String _masterKeyKey = 'master_key';
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  // Parameters for isolate-based encryption (1MB threshold)
  // ignore: unused_field
  static const int isolateThreshold = 1024 * 1024;

  final FlutterSecureStorage _secureStorage;
  encrypt.Key? _masterKey;

  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize / load master key from secure storage
  Future<void> initialize() async {
    String? storedKey = await _secureStorage.read(key: _masterKeyKey);
    if (storedKey == null) {
      // Generate new key
      final keyBytes = _generateRandomBytes(_keyLength);
      storedKey = base64Encode(keyBytes);
      await _secureStorage.write(key: _masterKeyKey, value: storedKey);
    }
    _masterKey = encrypt.Key.fromBase64(storedKey);
  }

  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => random.nextInt(256)));
  }

  /// Encrypt data (returns IV + ciphertext combined)
  Future<Uint8List> encryptBytes(Uint8List plaintext) async {
    if (_masterKey == null) await initialize();

    final iv = encrypt.IV.fromSecureRandom(_ivLength);
    final keyBase64 = _masterKey!.base64;

    // Always use compute isolate to avoid blocking UI
    return compute(_encryptInIsolate, _EncryptParams(
      plaintext: plaintext,
      iv: iv.bytes,
      key: keyBase64,
    ));
  }

  static Uint8List _encryptInIsolate(_EncryptParams params) {
    final key = encrypt.Key.fromBase64(params.key);
    final iv = encrypt.IV(Uint8List.fromList(params.iv));
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(params.plaintext, iv: iv);
    final result = Uint8List(16 + encrypted.bytes.length);
    result.setRange(0, 16, params.iv);
    result.setRange(16, result.length, encrypted.bytes);
    return result;
  }

  /// Decrypt data (IV is prepended to ciphertext)
  Future<Uint8List> decryptBytes(Uint8List encryptedData) async {
    if (_masterKey == null) await initialize();

    // Extract IV
    final iv = encrypt.IV(encryptedData.sublist(0, _ivLength));
    final ciphertext = encryptedData.sublist(_ivLength);

    final encrypter = encrypt.Encrypter(
        encrypt.AES(_masterKey!, mode: encrypt.AESMode.cbc));

    final decrypted =
        encrypter.decryptBytes(encrypt.Encrypted(ciphertext), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  /// Encrypt string (returns base64 encoded IV + ciphertext)
  Future<String> encryptString(String plaintext) async {
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
    final encrypted = await encryptBytes(plaintextBytes);
    return base64Encode(encrypted);
  }

  /// Decrypt string (from base64 encoded IV + ciphertext)
  Future<String> decryptString(String encryptedBase64) async {
    final encryptedBytes = base64Decode(encryptedBase64);
    final decrypted = await decryptBytes(Uint8List.fromList(encryptedBytes));
    return utf8.decode(decrypted);
  }

  /// Get master key hex (for demo/storage inspector)
  String? getMasterKeyHex() {
    return _masterKey?.base64;
  }

  /// Check if key is initialized
  bool get isInitialized => _masterKey != null;
}

/// Parameters class for isolate-based encryption
class _EncryptParams {
  final Uint8List plaintext;
  final List<int> iv;
  final String key;

  _EncryptParams({
    required this.plaintext,
    required this.iv,
    required this.key,
  });
}