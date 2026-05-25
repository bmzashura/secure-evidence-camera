import 'dart:typed_data';

class PhotoModel {
  final String id;
  final String filename;
  final DateTime createdAt;
  final String description;
  final Uint8List? decryptedBytes; // Only in memory when viewing

  const PhotoModel({
    required this.id,
    required this.filename,
    required this.createdAt,
    this.description = '',
    this.decryptedBytes,
  });

  PhotoModel copyWith({
    String? id,
    String? filename,
    DateTime? createdAt,
    String? description,
    Uint8List? decryptedBytes,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      decryptedBytes: decryptedBytes ?? this.decryptedBytes,
    );
  }
}