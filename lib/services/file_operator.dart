import 'dart:io';
import '../models/photo_item.dart';

class FileOperator {
  final bool copyFiles;

  FileOperator({this.copyFiles = true});

  Future<void> organizePhotos(
    List<PhotoItem> photos,
    String destinationRoot, {
    required void Function(String message, double progress) onProgress,
  }) async {
    final destDir = Directory(destinationRoot);
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo.destinationPath == null) continue;

      // Convert forward-slash paths to platform-appropriate paths
      final relativePath = photo.destinationPath!.replaceAll('/', Platform.pathSeparator);
      final fullDestPath = '${destinationRoot}${Platform.pathSeparator}$relativePath';
      final destDirForPhoto = Directory(fullDestPath);
      if (!await destDirForPhoto.exists()) {
        await destDirForPhoto.create(recursive: true);
      }

      // Copy/move the photo file
      final destFile = File('$fullDestPath${Platform.pathSeparator}${photo.fileName}');
      try {
        if (copyFiles) {
          await File(photo.filePath).copy(destFile.path);
        } else {
          await File(photo.filePath).rename(destFile.path);
        }
      } catch (e) {
        // Fallback: try copy if move fails
        try {
          await File(photo.filePath).copy(destFile.path);
        } catch (_) {}
      }

      // Copy/move the Live Photo video if present
      if (photo.livePhotoVideoPath != null) {
        final videoFile = File(photo.livePhotoVideoPath!);
        if (await videoFile.exists()) {
          final videoName = photo.livePhotoVideoPath!.split(Platform.pathSeparator).last;
          final destVideo = File('$fullDestPath${Platform.pathSeparator}$videoName');
          try {
            if (copyFiles) {
              await videoFile.copy(destVideo.path);
            } else {
              await videoFile.rename(destVideo.path);
            }
          } catch (_) {}
        }
      }

      onProgress(
        'Organizing (${i + 1}/${photos.length})...',
        (i + 1) / photos.length,
      );
    }
  }
}
