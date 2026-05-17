import 'dart:io';
import '../models/photo_item.dart';

class FileScanner {
  static const _photoExtensions = {'jpg', 'jpeg', 'heic', 'heif', 'png', 'gif'};

  Future<List<PhotoItem>> scanDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw Exception('Directory not found: $path');
    }

    final Map<String, PhotoItem> photoMap = {};
    final List<FileSystemEntity> allFiles = [];

    await for (final entity in directory.list(recursive: true)) {
      allFiles.add(entity);
    }

    final Set<String> movFiles = {};
    final Map<String, FileSystemEntity> photoFiles = {};

    for (final entity in allFiles) {
      if (entity is! File) continue;
      final ext = entity.path.split('.').last.toLowerCase();
      final stem = _stem(entity.path);

      if (ext == 'mov') {
        movFiles.add(stem);
      } else if (_photoExtensions.contains(ext)) {
        photoFiles[stem] = entity;
      }
    }

    for (final entry in photoFiles.entries) {
      final file = entry.value as File;
      final ext = file.path.split('.').last.toLowerCase();
      String? livePhotoPath;
      if (movFiles.contains(entry.key)) {
        livePhotoPath = '${Directory(file.path).parent.path}${Platform.pathSeparator}${entry.key}.mov';
        if (!await File(livePhotoPath).exists()) {
          livePhotoPath = '${Directory(file.path).parent.path}${Platform.pathSeparator}${entry.key}.MOV';
          if (!await File(livePhotoPath).exists()) {
            livePhotoPath = null;
          }
        }
      }

      photoMap[file.path] = PhotoItem(
        filePath: file.path,
        fileName: file.path.split(Platform.pathSeparator).last,
        extension: ext,
        livePhotoVideoPath: livePhotoPath,
      );
    }

    return photoMap.values.toList();
  }

  String _stem(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
