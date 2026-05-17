import 'dart:io';
import 'dart:math' as math;
import '../models/photo_item.dart';
import '../models/classification.dart';
import '../models/app_settings.dart';
import 'exif_service.dart';
import 'geocoding_service.dart';
import 'llm_service.dart';

class OrganizerService {
  final ExifService _exifService = ExifService();
  final GeocodingService _geocodingService = GeocodingService();
  final AppSettings _settings;

  OrganizerService(this._settings);

  Future<void> processPhotos(
    List<PhotoItem> photos, {
    required void Function(String message, double progress) onProgress,
    required void Function(PhotoItem item) onPhotoProcessed,
  }) async {
    if (photos.isEmpty) return;

    onProgress('Reading EXIF data...', 0.0);

    // Step 1: Read EXIF data for all photos
    for (int i = 0; i < photos.length; i++) {
      final exif = await _exifService.readExif(photos[i].filePath);
      if (exif != null) {
        photos[i].dateTaken = exif.dateTaken;
        photos[i].latitude = exif.latitude;
        photos[i].longitude = exif.longitude;
        photos[i].cameraModel = exif.cameraModel;
      } else {
        // Fallback to file creation date
        try {
          final file = File(photos[i].filePath); // dart:io
          final stat = await file.stat();
          photos[i].dateTaken = stat.modified;
          photos[i].exifReadFailed = true;
        } catch (_) {}
      }
      onProgress('Reading EXIF data...', (i + 1) / photos.length * 0.2);
    }

    // Step 2: Pass 1 - Trip Detection
    onProgress('Detecting trips...', 0.2);
    await _detectTrips(photos, onProgress: onProgress);

    // Step 3: Pass 2 - LLM Content Classification (for non-trip photos)
    if (_settings.enableLlmClassification && _settings.hasLlmKey) {
      onProgress('Classifying content with AI...', 0.5);
      await _classifyContent(photos, onProgress: onProgress);
    }

    // Step 4: Pass 3 - Daily Life organization for remaining
    onProgress('Organizing by date...', 0.8);
    _classifyByDate(photos);

    // Step 5: Assign destination paths
    onProgress('Assigning destinations...', 0.9);
    _assignDestinations(photos);

    for (final photo in photos) {
      photo.isProcessed = true;
      onPhotoProcessed(photo);
    }

    onProgress('Done!', 1.0);
  }

  Future<void> _detectTrips(
    List<PhotoItem> photos, {
    required void Function(String message, double progress) onProgress,
  }) async {
    if (!_settings.hasHomeLocation) return;

    // Sort by date
    final withDate = photos
        .where((p) => p.dateTaken != null)
        .toList()
      ..sort((a, b) => a.dateTaken!.compareTo(b.dateTaken!));

    if (withDate.isEmpty) return;

    // Group by consecutive days
    final List<List<PhotoItem>> dayGroups = [];
    List<PhotoItem> currentGroup = [withDate.first];

    for (int i = 1; i < withDate.length; i++) {
      final diff = withDate[i].dateTaken!
          .difference(withDate[i - 1].dateTaken!);
      if (diff.inDays <= 1) {
        currentGroup.add(withDate[i]);
      } else {
        dayGroups.add(currentGroup);
        currentGroup = [withDate[i]];
      }
    }
    dayGroups.add(currentGroup);

    // Check each group for trip conditions (2+ consecutive days, non-home GPS)
    for (final group in dayGroups) {
      final days = group
          .map((p) => DateTime(p.dateTaken!.year, p.dateTaken!.month,
              p.dateTaken!.day))
          .toSet()
          .toList()
        ..sort();

      if (days.length < 2) continue;

      // Check if all photos with GPS are from a non-home location
      final photosWithGps = group.where((p) => p.hasGps).toList();
      if (photosWithGps.isEmpty) continue;

      // Calculate average location of the group
      double avgLat = 0, avgLon = 0;
      for (final p in photosWithGps) {
        avgLat += p.latitude!;
        avgLon += p.longitude!;
      }
      avgLat /= photosWithGps.length;
      avgLon /= photosWithGps.length;

      // Check if this is significantly different from home
      final distance = _haversineDistance(
        _settings.homeLatitude,
        _settings.homeLongitude,
        avgLat,
        avgLon,
      );

      if (distance > 50) {
        // More than 50km from home
        // Get location name
        final locationName = await _geocodingService
            .reverseGeocode(avgLat, avgLon);
        final tripName = locationName ?? 'Unknown Location';
        final month = days.first.month.toString().padLeft(2, '0');
        final year = days.first.year.toString();

        for (final photo in group) {
          photo.category = PhotoCategory.trip;
          photo.tripName = '${tripName}_$year-$month';
        }
      }
    }
  }

  Future<void> _classifyContent(
    List<PhotoItem> photos, {
    required void Function(String message, double progress) onProgress,
  }) async {
    final unclassified = photos
        .where((p) => p.category == null && p.dateTaken != null)
        .toList();

    if (unclassified.isEmpty) return;

    final llm = LlmService(
      apiKey: _settings.llmApiKey,
      model: _settings.llmModel,
      baseUrl: _settings.llmBaseUrl,
      confidenceThreshold: _settings.confidenceThreshold,
    );

    for (int i = 0; i < unclassified.length; i++) {
      final category = await llm.classifyImage(unclassified[i].filePath);
      if (category != null) {
        unclassified[i].category = category;
      }
      onProgress(
        'Classifying with AI (${i + 1}/${unclassified.length})...',
        0.5 + (i + 1) / unclassified.length * 0.3,
      );
    }
  }

  void _classifyByDate(List<PhotoItem> photos) {
    for (final photo in photos) {
      if (photo.category == null && photo.dateTaken != null) {
        photo.category = PhotoCategory.dailyLife;
      } else if (photo.category == null) {
        photo.category = PhotoCategory.uncategorized;
      }
    }
  }

  void _assignDestinations(List<PhotoItem> photos) {
    for (final photo in photos) {
      final dateStr = photo.dateTaken != null
          ? '${photo.dateTaken!.year.toString().padLeft(4, '0')}-'
              '${photo.dateTaken!.month.toString().padLeft(2, '0')}-'
              '${photo.dateTaken!.day.toString().padLeft(2, '0')}'
          : 'unknown_date';

      switch (photo.category) {
        case PhotoCategory.trip:
          photo.destinationPath = 'Trips${separator}${photo.tripName ?? "Unknown_Trip"}';
        case PhotoCategory.dailyLife:
          final year = dateStr.substring(0, 4);
          photo.destinationPath =
              'By_Date${separator}$year${separator}$dateStr';
        case PhotoCategory.uncategorized:
          photo.destinationPath = 'Uncategorized';
        default:
          photo.destinationPath =
              'By_Content${separator}${photo.category!.displayName}';
      }
    }
  }

  String get separator => '/'; // Use forward slash consistently for output paths

  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sinSquared(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            _sinSquared(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
  double _sinSquared(double x) {
    final s = math.sin(x);
    return s * s;
  }
}
