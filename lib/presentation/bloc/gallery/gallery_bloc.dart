import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/secure_local_datasource.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final SecureLocalDatasource _datasource;

  GalleryBloc({required SecureLocalDatasource datasource})
      : _datasource = datasource,
        super(const GalleryState()) {
    on<GalleryLoad>(_onLoad);
    on<GalleryDeletePhoto>(_onDeletePhoto);
    on<GalleryRefresh>(_onRefresh);
  }

  Future<void> _onLoad(GalleryLoad event, Emitter<GalleryState> emit) async {
    emit(state.copyWith(status: GalleryStatus.loading));
    try {
      final photos = await _datasource.getAllPhotos();
      emit(state.copyWith(
        status: GalleryStatus.loaded,
        photos: photos,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GalleryStatus.error,
        errorMessage: 'Failed to load photos: $e',
      ));
    }
  }

  Future<void> _onDeletePhoto(
      GalleryDeletePhoto event, Emitter<GalleryState> emit) async {
    try {
      final photo = state.photos.firstWhere((p) => p.id == event.photoId);
      await _datasource.deletePhoto(photo);
      final updatedPhotos = state.photos.where((p) => p.id != event.photoId).toList();
      // Emit with status to force UI rebuild
      emit(GalleryState(
        status: GalleryStatus.loaded,
        photos: updatedPhotos,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GalleryStatus.error,
        errorMessage: 'Failed to delete photo: $e',
      ));
    }
  }

  Future<void> _onRefresh(GalleryRefresh event, Emitter<GalleryState> emit) async {
    try {
      final photos = await _datasource.getAllPhotos();
      emit(state.copyWith(
        status: GalleryStatus.loaded,
        photos: photos,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GalleryStatus.error,
        errorMessage: 'Failed to refresh: $e',
      ));
    }
  }
}