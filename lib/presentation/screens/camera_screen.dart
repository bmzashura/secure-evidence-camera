import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../../core/constants/colors.dart';
import '../../core/crypto/encryption_service.dart';
import '../../data/datasources/secure_local_datasource.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../widgets/capture_button.dart';
import 'gallery_screen.dart';
import 'save_description_screen.dart';

class CameraScreen extends StatefulWidget {
  final EncryptionService encryptionService;

  const CameraScreen({super.key, required this.encryptionService});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraBloc _cameraBloc;

  @override
  void initState() {
    super.initState();
    final datasource = SecureLocalDatasource(encryptionService: widget.encryptionService);
    _cameraBloc = CameraBloc(datasource: datasource)..add(CameraInitialize());
  }

  @override
  void dispose() {
    _cameraBloc.add(CameraDispose());
    _cameraBloc.close();
    super.dispose();
  }

  void _onLock() {
    context.read<AuthBloc>().add(AuthLock());
  }

  void _openGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryScreen(encryptionService: widget.encryptionService),
      ),
    );
  }

  void _onCapture() {
    _cameraBloc.add(CameraCapture());
  }

  void _onSavePhoto(String description) {
    _cameraBloc.add(CameraSavePhoto(description));
  }

  void _onDiscardPhoto() {
    _cameraBloc.add(CameraDiscardPhoto());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cameraBloc,
      child: BlocConsumer<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state.status == CameraStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
          // Navigate to save screen when in preview state
          bool didSave = false;
          bool didCancel = false;
          if (state.status == CameraStatus.preview && state.previewBytes != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SaveDescriptionScreen(
                  imageBytes: state.previewBytes!,
                  onSave: (desc) {
                    didSave = true;
                    _onSavePhoto(desc);
                  },
                  onCancel: () {
                    didCancel = true;
                    _onDiscardPhoto();
                  },
                ),
              ),
            ).then((_) {
              // Only discard if user backed out without saving or canceling
              if (!didSave && !didCancel) {
                _cameraBloc.add(CameraDiscardPhoto());
              }
            });
          }
          // Success feedback - navigate to gallery
          if (state.status == CameraStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Foto tersimpan dengan aman'),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 1),
              ),
            );
            // Navigate to gallery after brief delay
            final nav = Navigator.of(context);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                nav.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GalleryScreen(encryptionService: widget.encryptionService),
                  ),
                );
              }
            });
          }
          // Discarded feedback - pop back to camera
          if (state.status == CameraStatus.discarded) {
            Navigator.of(context).pop(); // Close SaveDescriptionScreen
          }
        },
        builder: (context, state) {
          // Show camera preview when ready
          if (state.status == CameraStatus.ready ||
              state.status == CameraStatus.capturing) {
            return _buildCameraView(state);
          }

          // Show loading when initializing
          if (state.status == CameraStatus.initializing ||
              state.status == CameraStatus.initial) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          // For other states (preview, saving, captured), camera view is shown
          // The actual navigation to SaveDescriptionScreen happens in listener
          return _buildCameraView(state);
        },
      ),
    );
  }

  Widget _buildCameraView(CameraState state) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Camera preview - fill available space with correct aspect ratio crop
          if (state.controller != null && state.controller!.value.isInitialized)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(state.controller!),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Kamera tidak tersedia',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.lock_outline,
                        color: AppColors.textPrimary, size: 28),
                    onPressed: _onLock,
                  ),
                  Row(
                    children: [
                      if (state.controller != null &&
                          state.controller!.value.isInitialized)
                        IconButton(
                          icon: Icon(
                            state.isFlashOn
                                ? Icons.flash_on
                                : Icons.flash_off,
                            color: AppColors.textPrimary,
                            size: 28,
                          ),
                          onPressed: () =>
                              _cameraBloc.add(CameraFlashToggle()),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _openGallery,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.textSecondary, width: 1),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                  CaptureButton(
                    onPressed: state.status == CameraStatus.ready
                        ? _onCapture
                        : () {},
                    isProcessing: state.status == CameraStatus.capturing,
                  ),
                  const SizedBox(width: 52, height: 52),
                ],
              ),
            ),
          ),

          // Encryption overlay
          if (state.showEncryptionOverlay)
            const Positioned.fill(child: EncryptionOverlay()),
        ],
      ),
    );
  }
}