import 'classification.dart';

class PhotoItem {
  final String filePath;
  final String fileName;
  final String extension;
  final String? livePhotoVideoPath;

  DateTime? dateTaken;
  double? latitude;
  double? longitude;
  String? cameraModel;
  PhotoCategory? category;
  String? tripName;
  String? destinationPath;
  bool exifReadFailed = false;
  bool isProcessed = false;

  PhotoItem({
    required this.filePath,
    required this.fileName,
    required this.extension,
    this.livePhotoVideoPath,
  });

  String get fileNameWithoutExtension {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  bool get hasGps => latitude != null && longitude != null;

  bool get isLivePhoto => livePhotoVideoPath != null;

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'fileName': fileName,
        'extension': extension,
        'livePhotoVideoPath': livePhotoVideoPath,
        'dateTaken': dateTaken?.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'cameraModel': cameraModel,
        'category': category?.name,
        'tripName': tripName,
        'destinationPath': destinationPath,
        'isProcessed': isProcessed,
        'exifReadFailed': exifReadFailed,
      };
}
