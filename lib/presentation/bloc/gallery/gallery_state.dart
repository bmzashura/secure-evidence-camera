import 'package:equatable/equatable.dart';
import '../../../data/models/photo_model.dart';

enum GalleryStatus { initial, loading, loaded, error }

class GalleryState extends Equatable {
  final GalleryStatus status;
  final List<PhotoModel> photos;
  final String? errorMessage;

  const GalleryState({
    this.status = GalleryStatus.initial,
    this.photos = const [],
    this.errorMessage,
  });

  GalleryState copyWith({
    GalleryStatus? status,
    List<PhotoModel>? photos,
    String? errorMessage,
  }) {
    return GalleryState(
      status: status ?? this.status,
      photos: photos ?? this.photos,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, photos, errorMessage];
}