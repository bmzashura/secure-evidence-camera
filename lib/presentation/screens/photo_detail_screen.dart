import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/crypto/encryption_service.dart';
import '../../data/datasources/secure_local_datasource.dart';
import '../../data/models/photo_model.dart';

class PhotoDetailScreen extends StatefulWidget {
  final PhotoModel photo;
  final EncryptionService encryptionService;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
    required this.encryptionService,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decryptPhoto();
  }

  @override
  void dispose() {
    // Clear decrypted data from memory
    _decryptedBytes = null;
    super.dispose();
  }

  Future<void> _decryptPhoto() async {
    try {
      final datasource = SecureLocalDatasource(encryptionService: widget.encryptionService);
      final bytes = await datasource.loadDecryptedPhoto(widget.photo);
      if (mounted) {
        setState(() {
          _decryptedBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to decrypt: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onBack() {
    _decryptedBytes = null;
    Navigator.pop(context, false);
  }

  void _onDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Hapus Foto?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Foto akan dihapus permanen. Tidak dapat dikembalikan.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final datasource = SecureLocalDatasource(encryptionService: widget.encryptionService);
              await datasource.deletePhoto(widget.photo);
              _decryptedBytes = null;
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo / Loading / Error
          Positioned.fill(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      )
                    : _decryptedBytes != null
                        ? InteractiveViewer(
                            child: Center(
                              child: Image.memory(
                                _decryptedBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : const SizedBox(),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: _onBack,
                  ),
                  Text(
                    dateFormat.format(widget.photo.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _onDelete(context),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Description
                  if (widget.photo.description.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes, color: AppColors.textSecondary, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Deskripsi',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.photo.description,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.shield, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Dekripsi di memori saja',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Foto tidak pernah disimpan sebagai file tidak terenkripsi.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}