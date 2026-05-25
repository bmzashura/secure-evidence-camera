import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../core/crypto/encryption_service.dart';
import '../models/photo_model.dart';

class SecureLocalDatasource {
  final EncryptionService _encryptionService;
  static const String _photoDir = 'encrypted_photos';
  static const String _metadataFile = 'photo_metadata.json';

  SecureLocalDatasource({required EncryptionService encryptionService})
      : _encryptionService = encryptionService;

  Future<Directory> get _photoDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(path.join(appDir.path, _photoDir));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  Future<File> get _metadataFilePath async {
    final dir = await _photoDirectory;
    return File(path.join(dir.path, _metadataFile));
  }

  /// Save encrypted photo with description
  Future<PhotoModel> saveEncryptedPhoto(Uint8List imageBytes, {String description = ''}) async {
    final id = const Uuid().v4();
    final timestamp = DateTime.now();
    final filename = 'enc_${timestamp.millisecondsSinceEpoch}.bin';

    // Encrypt the image
    final encryptedBytes = await _encryptionService.encryptBytes(imageBytes);

    // Save encrypted file
    final dir = await _photoDirectory;
    final file = File(path.join(dir.path, filename));
    await file.writeAsBytes(encryptedBytes);

    // Save metadata
    final photo = PhotoModel(
      id: id,
      filename: filename,
      createdAt: timestamp,
      description: description,
    );
    await _appendMetadata(photo);

    return photo;
  }

  /// Load and decrypt photo
  Future<Uint8List> loadDecryptedPhoto(PhotoModel photo) async {
    final dir = await _photoDirectory;
    final file = File(path.join(dir.path, photo.filename));
    final encryptedBytes = await file.readAsBytes();
    return await _encryptionService.decryptBytes(encryptedBytes);
  }

  /// Get all photos metadata
  Future<List<PhotoModel>> getAllPhotos() async {
    final file = await _metadataFilePath;
    if (!await file.exists()) {
      return [];
    }
    final content = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(content);
    final dir = await _photoDirectory;
    final result = <PhotoModel>[];

    for (final json in jsonList) {
      final photoFile = File(path.join(dir.path, json['filename'] as String));
      // Skip metadata entry if the actual file no longer exists
      if (!await photoFile.exists()) continue;

      result.add(PhotoModel(
        id: json['id'],
        filename: json['filename'],
        createdAt: DateTime.parse(json['createdAt']),
        description: json['description'] ?? '',
      ));
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Update photo description
  Future<void> updateDescription(PhotoModel photo, String newDescription) async {
    final file = await _metadataFilePath;
    if (!await file.exists()) return;
    final content = await file.readAsString();
    if (content.isEmpty) return;
    List<dynamic> metadata = jsonDecode(content);
    
    final index = metadata.indexWhere((item) => item['id'] == photo.id);
    if (index >= 0) {
      metadata[index]['description'] = newDescription;
      await file.writeAsString(jsonEncode(metadata));
    }
  }

  /// Delete photo
  Future<void> deletePhoto(PhotoModel photo) async {
    final dir = await _photoDirectory;
    final file = File(path.join(dir.path, photo.filename));
    if (await file.exists()) {
      await file.delete();
    }
    await _removeFromMetadata(photo.id);
  }

  /// Append to metadata file
  Future<void> _appendMetadata(PhotoModel photo) async {
    final file = await _metadataFilePath;
    List<dynamic> metadata = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        metadata = jsonDecode(content);
      }
    }
    metadata.add({
      'id': photo.id,
      'filename': photo.filename,
      'createdAt': photo.createdAt.toIso8601String(),
      'description': photo.description,
    });
    await file.writeAsString(jsonEncode(metadata));
  }

  /// Remove from metadata
  Future<void> _removeFromMetadata(String photoId) async {
    final file = await _metadataFilePath;
    if (!await file.exists()) return;
    final content = await file.readAsString();
    if (content.isEmpty) return;
    List<dynamic> metadata = jsonDecode(content);
    metadata.removeWhere((item) => item['id'] == photoId);
    await file.writeAsString(jsonEncode(metadata));
  }

  /// Check if photo file exists
  Future<bool> photoExists(PhotoModel photo) async {
    final dir = await _photoDirectory;
    final file = File(path.join(dir.path, photo.filename));
    return await file.exists();
  }
}