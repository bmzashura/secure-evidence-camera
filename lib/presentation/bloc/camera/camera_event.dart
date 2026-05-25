import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();
  @override
  List<Object?> get props => [];
}

class CameraInitialize extends CameraEvent {}

class CameraCapture extends CameraEvent {}

class CameraCapturePreview extends CameraEvent {
  final Uint8List imageBytes;
  const CameraCapturePreview(this.imageBytes);
  @override
  List<Object?> get props => [imageBytes];
}

class CameraSavePhoto extends CameraEvent {
  final String description;
  const CameraSavePhoto(this.description);
  @override
  List<Object?> get props => [description];
}

class CameraDiscardPhoto extends CameraEvent {}

class CameraDispose extends CameraEvent {}

class CameraFlashToggle extends CameraEvent {}

class CameraSwitch extends CameraEvent {}

class CameraReset extends CameraEvent {}