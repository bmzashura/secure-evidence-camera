import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';

class SaveDescriptionScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(String description) onSave;
  final VoidCallback onCancel;

  const SaveDescriptionScreen({
    super.key,
    required this.imageBytes,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<SaveDescriptionScreen> createState() => _SaveDescriptionScreenState();
}

class _SaveDescriptionScreenState extends State<SaveDescriptionScreen> {
  final _descController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSave() {
    final description = _descController.text.trim();
    setState(() => _isSaving = true);
    widget.onSave(description);
  }

  void _onCancel() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Batalkan?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Foto akan dihapus dan tidak disimpan.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onCancel();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _onCancel,
        ),
        title: const Text(
          'Simpan Foto',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Photo preview
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textSecondary, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Description input
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Tambahkan deskripsi untuk foto ini...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.textSecondary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.textSecondary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info text
                  const Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.success, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Foto akan Dienkripsi AES-256 sebelum disimpan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}