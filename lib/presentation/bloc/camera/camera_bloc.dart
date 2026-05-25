import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../../../data/datasources/secure_local_datasource.dart';
import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final SecureLocalDatasource _datasource;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  Timer? _discardReinitTimer;

  CameraBloc({required SecureLocalDatasource datasource})
      : _datasource = datasource,
        super(const CameraState()) {
    on<CameraInitialize>(_onInitialize);
    on<CameraCapture>(_onCapture);
    on<CameraCapturePreview>(_onCapturePreview);
    on<CameraSavePhoto>(_onSavePhoto);
    on<CameraDiscardPhoto>(_onDiscardPhoto);
    on<CameraDispose>(_onDispose);
    on<CameraFlashToggle>(_onFlashToggle);
    on<CameraSwitch>(_onSwitch);
  }

  Future<void> _onInitialize(
      CameraInitialize event, Emitter<CameraState> emit) async {
    // Cancel any pending re-init timer from discard
    _discardReinitTimer?.cancel();
    _discardReinitTimer = null;

    emit(state.copyWith(status: CameraStatus.initializing));
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        emit(state.copyWith(
          status: CameraStatus.error,
          errorMessage: 'No cameras available',
        ));
        return;
      }

      // Prefer back camera
      _currentCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_currentCameraIndex < 0) _currentCameraIndex = 0;

      await _initCamera(emit);
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to initialize camera: $e',
      ));
    }
  }

  Future<void> _initCamera(Emitter<CameraState> emit) async {
    if (_cameras.isEmpty) return;

    final controller = CameraController(
      _cameras[_currentCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      emit(state.copyWith(
        status: CameraStatus.ready,
        controller: controller,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to initialize camera controller: $e',
      ));
    }
  }

  Future<void> _onCapture(
      CameraCapture event, Emitter<CameraState> emit) async {
    if (state.controller == null || !state.controller!.value.isInitialized) {
      return;
    }

    emit(state.copyWith(status: CameraStatus.capturing));

    try {
      final xFile = await state.controller!.takePicture();
      final bytes = await xFile.readAsBytes();

      emit(state.copyWith(
        status: CameraStatus.preview,
        previewBytes: bytes,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to capture: $e',
      ));
    }
  }

  void _onCapturePreview(CameraCapturePreview event, Emitter<CameraState> emit) {
    emit(state.copyWith(status: CameraStatus.preview, previewBytes: event.imageBytes));
  }

  Future<void> _onSavePhoto(CameraSavePhoto event, Emitter<CameraState> emit) async {
    if (state.previewBytes == null) return;

    emit(state.copyWith(status: CameraStatus.saving));

    try {
      // Encrypt and save with description
      await _datasource.saveEncryptedPhoto(
        state.previewBytes!,
        description: event.description,
      );

      // Show saved status with overlay
      emit(state.copyWith(
        status: CameraStatus.saved,
        showEncryptionOverlay: true,
        previewBytes: null,
      ));

      // Wait for UI to navigate to gallery
      await Future.delayed(const Duration(milliseconds: 600));
      emit(state.copyWith(
        status: CameraStatus.ready,
        showEncryptionOverlay: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CameraStatus.error,
        errorMessage: 'Failed to save: $e',
      ));
    }
  }

  void _onDiscardPhoto(CameraDiscardPhoto event, Emitter<CameraState> emit) {
    // Cancel any pending re-init timer first
    _discardReinitTimer?.cancel();
    _discardReinitTimer = null;

    emit(state.copyWith(
      status: CameraStatus.discarded,
      previewBytes: null,
    ));

    // Reset to camera ready after brief delay
    _discardReinitTimer = Timer(const Duration(milliseconds: 600), () {
      if (!isClosed) {
        add(CameraInitialize());
      }
    });
  }

  Future<void> _onDispose(
      CameraDispose event, Emitter<CameraState> emit) async {
    _discardReinitTimer?.cancel();
    _discardReinitTimer = null;
    await state.controller?.dispose();
    emit(const CameraState());
  }

  void _onFlashToggle(CameraFlashToggle event, Emitter<CameraState> emit) {
    final newFlashState = !state.isFlashOn;
    state.controller?.setFlashMode(
      newFlashState ? FlashMode.torch : FlashMode.off,
    );
    emit(state.copyWith(isFlashOn: newFlashState));
  }

  Future<void> _onSwitch(CameraSwitch event, Emitter<CameraState> emit) async {
    if (_cameras.length < 2) return;

    _discardReinitTimer?.cancel();
    _discardReinitTimer = null;

    await state.controller?.dispose();
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initCamera(emit);
  }

  @override
  Future<void> close() {
    _discardReinitTimer?.cancel();
    _discardReinitTimer = null;
    state.controller?.dispose();
    return super.close();
  }
}