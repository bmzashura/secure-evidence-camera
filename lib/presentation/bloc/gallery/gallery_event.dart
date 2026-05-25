import 'package:equatable/equatable.dart';

abstract class GalleryEvent extends Equatable {
  const GalleryEvent();
  @override
  List<Object?> get props => [];
}

class GalleryLoad extends GalleryEvent {}

class GalleryDeletePhoto extends GalleryEvent {
  final String photoId;
  const GalleryDeletePhoto(this.photoId);
  @override
  List<Object?> get props => [photoId];
}

class GalleryRefresh extends GalleryEvent {}