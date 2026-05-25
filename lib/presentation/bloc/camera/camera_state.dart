import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

enum CameraStatus { initial, initializing, ready, capturing, preview, saving, saved, discarded, error }

enum AspectRatioMode { portrait4v3, landscape3v4 }

class CameraState extends Equatable {
  final CameraStatus status;
  final CameraController? controller;
  final bool isFlashOn;
  final String? errorMessage;
  final bool showEncryptionOverlay;
  final Uint8List? previewBytes;
  final AspectRatioMode aspectRatioMode;

  const CameraState({
    this.status = CameraStatus.initial,
    this.controller,
    this.isFlashOn = false,
    this.errorMessage,
    this.showEncryptionOverlay = false,
    this.previewBytes,
    this.aspectRatioMode = AspectRatioMode.portrait4v3,
  });

  CameraState copyWith({
    CameraStatus? status,
    CameraController? controller,
    bool? isFlashOn,
    String? errorMessage,
    bool? showEncryptionOverlay,
    Uint8List? previewBytes,
    AspectRatioMode? aspectRatioMode,
  }) {
    return CameraState(
      status: status ?? this.status,
      controller: controller ?? this.controller,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      errorMessage: errorMessage,
      showEncryptionOverlay: showEncryptionOverlay ?? this.showEncryptionOverlay,
      previewBytes: previewBytes ?? this.previewBytes,
      aspectRatioMode: aspectRatioMode ?? this.aspectRatioMode,
    );
  }

  double get aspectRatioValue {
    switch (aspectRatioMode) {
      case AspectRatioMode.portrait4v3:
        return 4 / 3;
      case AspectRatioMode.landscape3v4:
        return 3 / 4;
    }
  }

  @override
  List<Object?> get props =>
      [status, isFlashOn, errorMessage, showEncryptionOverlay, previewBytes, aspectRatioMode];
}