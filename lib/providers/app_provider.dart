import 'package:flutter/foundation.dart';
import '../models/photo_item.dart';
import '../models/classification.dart';
import '../models/app_settings.dart';
import '../services/file_scanner.dart';
import '../services/organizer_service.dart';
import '../services/file_operator.dart';

enum AppState {
  idle,
  scanning,
  processing,
  organizing,
  done,
  error,
}

class AppProvider extends ChangeNotifier {
  AppState _state = AppState.idle;
  AppSettings _settings = AppSettings();
  String _sourcePath = '';
  String _destinationPath = '';
  List<PhotoItem> _photos = [];
  String _statusMessage = '';
  double _progress = 0.0;
  String? _errorMessage;

  // Getters
  AppState get state => _state;
  AppSettings get settings => _settings;
  String get sourcePath => _sourcePath;
  String get destinationPath => _destinationPath;
  List<PhotoItem> get photos => _photos;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;

  int get totalPhotos => _photos.length;

  int get tripCount =>
      _photos.where((p) => p.category == PhotoCategory.trip).length;

  Map<PhotoCategory, int> get categoryCounts {
    final counts = <PhotoCategory, int>{};
    for (final photo in _photos) {
      if (photo.category != null) {
        counts[photo.category!] = (counts[photo.category!] ?? 0) + 1;
      }
    }
    return counts;
  }

  int get unprocessedCount =>
      _photos.where((p) => !p.isProcessed).length;

  void setSourcePath(String path) {
    _sourcePath = path;
    notifyListeners();
  }

  void setDestinationPath(String path) {
    _destinationPath = path;
    notifyListeners();
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  Future<void> scanPhotos() async {
    if (_sourcePath.isEmpty) {
      _errorMessage = 'Please select a source folder first.';
      _state = AppState.error;
      notifyListeners();
      return;
    }

    _state = AppState.scanning;
    _statusMessage = 'Scanning for photos...';
    _progress = 0.0;
    _errorMessage = null;
    _photos = [];
    notifyListeners();

    try {
      final scanner = FileScanner();
      _photos = await scanner.scanDirectory(_sourcePath);

      if (_photos.isEmpty) {
        _errorMessage = 'No photos found in the selected folder.';
        _state = AppState.error;
        notifyListeners();
        return;
      }

      _state = AppState.idle;
      _statusMessage = 'Found ${_photos.length} photos.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error scanning: $e';
      _state = AppState.error;
      notifyListeners();
    }
  }

  Future<void> processPhotos() async {
    if (_photos.isEmpty) {
      _errorMessage = 'No photos to process. Scan a folder first.';
      _state = AppState.error;
      notifyListeners();
      return;
    }

    _state = AppState.processing;
    _statusMessage = 'Processing photos...';
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final organizer = OrganizerService(_settings);

      // Reset classifications
      for (final photo in _photos) {
        photo.category = null;
        photo.tripName = null;
        photo.destinationPath = null;
        photo.isProcessed = false;
      }

      await organizer.processPhotos(
        _photos,
        onProgress: (message, progress) {
          _statusMessage = message;
          _progress = progress;
          notifyListeners();
        },
        onPhotoProcessed: (photo) {
          // Individual photo processed notification
        },
      );

      _state = AppState.idle;
      _statusMessage = 'Classification complete. ${_photos.length} photos organized.';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error processing: $e';
      _state = AppState.error;
      notifyListeners();
    }
  }

  Future<void> organizeFiles() async {
    if (_destinationPath.isEmpty) {
      _errorMessage = 'Please select a destination folder first.';
      _state = AppState.error;
      notifyListeners();
      return;
    }

    final toOrganize = _photos.where((p) => p.destinationPath != null).toList();
    if (toOrganize.isEmpty) {
      _errorMessage = 'No classified photos to organize. Process photos first.';
      _state = AppState.error;
      notifyListeners();
      return;
    }

    _state = AppState.organizing;
    _statusMessage = 'Organizing files...';
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      final operator = FileOperator(copyFiles: _settings.copyFiles);
      await operator.organizePhotos(
        toOrganize,
        _destinationPath,
        onProgress: (message, progress) {
          _statusMessage = message;
          _progress = progress;
          notifyListeners();
        },
      );

      _state = AppState.done;
      _statusMessage =
          'Done! ${toOrganize.length} photos organized to $_destinationPath';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error organizing: $e';
      _state = AppState.error;
      notifyListeners();
    }
  }

  void reset() {
    _state = AppState.idle;
    _photos = [];
    _statusMessage = '';
    _progress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
