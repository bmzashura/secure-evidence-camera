import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/crypto/encryption_service.dart';
import '../../data/datasources/secure_local_datasource.dart';
import '../../data/models/photo_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/gallery/gallery_bloc.dart';
import '../bloc/gallery/gallery_event.dart';
import '../bloc/gallery/gallery_state.dart';
import '../widgets/empty_state.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatelessWidget {
  final EncryptionService encryptionService;

  const GalleryScreen({super.key, required this.encryptionService});

  void _onLock(BuildContext context) {
    Navigator.of(context).pop();
    context.read<AuthBloc>().add(AuthLock());
  }

  void _openPhoto(BuildContext context, PhotoModel photo) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(
          photo: photo,
          encryptionService: encryptionService,
        ),
      ),
    );
    if (result == true && context.mounted) {
      context.read<GalleryBloc>().add(GalleryLoad());
    }
  }

  void _deletePhoto(BuildContext context, String photoId, GalleryBloc bloc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Hapus Foto?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Foto terenkripsi akan dihapus permanen. Tidak dapat dikembalikan.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(GalleryDeletePhoto(photoId));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('ddMMyyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final datasource = SecureLocalDatasource(encryptionService: encryptionService);

    return BlocProvider(
      create: (_) => GalleryBloc(datasource: datasource)..add(GalleryLoad()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text(
            'Gallery',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_outline, color: AppColors.textPrimary),
              onPressed: () => _onLock(context),
            ),
          ],
        ),
        body: BlocBuilder<GalleryBloc, GalleryState>(
          builder: (context, state) {
            if (state.status == GalleryStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state.status == GalleryStatus.error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'Error loading photos',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<GalleryBloc>().add(GalleryLoad()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state.photos.isEmpty) {
              return const EmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.photos.length,
              separatorBuilder: (_, index) => const Divider(
                color: AppColors.surface,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final photo = state.photos[index];
                final desc = photo.description.isNotEmpty
                    ? photo.description
                    : 'Tanpa deskripsi';
                final date = _formatDate(photo.createdAt);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    '$desc - $date',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 22,
                    ),
                    onPressed: () => _deletePhoto(
                      context,
                      photo.id,
                      context.read<GalleryBloc>(),
                    ),
                  ),
                  onTap: () => _openPhoto(context, photo),
                );
              },
            );
          },
        ),
      ),
    );
  }
}