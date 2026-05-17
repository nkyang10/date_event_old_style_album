import 'dart:io';
import 'dart:typed_data';
import 'package:exif/exif.dart';

class ExifService {
  Future<ExifData?> readExif(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final Uint8List bytes = await file.readAsBytes();
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) return null;
      return _parseTags(tags);
    } catch (_) {
      return null;
    }
  }

  ExifData? _parseTags(Map<String, IfdTag> tags) {
    DateTime? dateTaken;
    try {
      final dateStr = tags['EXIF DateTimeOriginal']?.printable;
      if (dateStr != null && dateStr.isNotEmpty) {
        dateTaken = _parseExifDate(dateStr);
      }
    } catch (_) {}

    if (dateTaken == null) {
      try {
        final dateStr = tags['Image DateTime']?.printable;
        if (dateStr != null && dateStr.isNotEmpty) {
          dateTaken = _parseExifDate(dateStr);
        }
      } catch (_) {}
    }

    double? latitude;
    double? longitude;

    try {
      final latTag = tags['GPS GPSLatitude'];
      final latRef = tags['GPS GPSLatitudeRef']?.printable;
      if (latTag != null && latTag.values is IfdRatios) {
        final ratios = (latTag.values as IfdRatios).ratios;
        if (ratios.length == 3) {
          latitude = ratios[0].toDouble() +
              ratios[1].toDouble() / 60.0 +
              ratios[2].toDouble() / 3600.0;
          if (latRef == 'S' || latRef == 's') {
            latitude = -latitude;
          }
        }
      }
    } catch (_) {}

    try {
      final lonTag = tags['GPS GPSLongitude'];
      final lonRef = tags['GPS GPSLongitudeRef']?.printable;
      if (lonTag != null && lonTag.values is IfdRatios) {
        final ratios = (lonTag.values as IfdRatios).ratios;
        if (ratios.length == 3) {
          longitude = ratios[0].toDouble() +
              ratios[1].toDouble() / 60.0 +
              ratios[2].toDouble() / 3600.0;
          if (lonRef == 'W' || lonRef == 'w') {
            longitude = -longitude;
          }
        }
      }
    } catch (_) {}

    String? cameraModel = tags['Image Model']?.printable;

    if (dateTaken == null && latitude == null && longitude == null) {
      return null;
    }

    return ExifData(
      dateTaken: dateTaken,
      latitude: latitude,
      longitude: longitude,
      cameraModel: cameraModel,
    );
  }

  DateTime? _parseExifDate(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length != 2) return null;
      final dateParts = parts[0].split(':');
      if (dateParts.length != 3) return null;
      final timeParts = parts[1].split(':');
      if (timeParts.length != 3) return null;
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return null;
    }
  }
}

class ExifData {
  final DateTime? dateTaken;
  final double? latitude;
  final double? longitude;
  final String? cameraModel;

  const ExifData({
    this.dateTaken,
    this.latitude,
    this.longitude,
    this.cameraModel,
  });
}
