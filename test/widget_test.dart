import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/photo_item.dart';
import 'package:myapp/models/classification.dart';
import 'package:myapp/models/app_settings.dart';

void main() {
  group('PhotoItem', () {
    test('creates photo with correct properties', () {
      final photo = PhotoItem(
        filePath: '/photos/test.jpg',
        fileName: 'test.jpg',
        extension: 'jpg',
      );

      expect(photo.filePath, '/photos/test.jpg');
      expect(photo.fileName, 'test.jpg');
      expect(photo.extension, 'jpg');
      expect(photo.isLivePhoto, false);
      expect(photo.hasGps, false);
    });

    test('detects live photo', () {
      final photo = PhotoItem(
        filePath: '/photos/test.heic',
        fileName: 'test.heic',
        extension: 'heic',
        livePhotoVideoPath: '/photos/test.mov',
      );

      expect(photo.isLivePhoto, true);
    });

    test('reports GPS availability', () {
      final photo = PhotoItem(
        filePath: '/photos/test.jpg',
        fileName: 'test.jpg',
        extension: 'jpg',
      );
      photo.latitude = 40.7128;
      photo.longitude = -74.0060;

      expect(photo.hasGps, true);
    });

    test('fileNameWithoutExtension returns stem', () {
      final photo = PhotoItem(
        filePath: '/photos/test.jpg',
        fileName: 'test.jpg',
        extension: 'jpg',
      );
      expect(photo.fileNameWithoutExtension, 'test');
    });
  });

  group('PhotoCategory', () {
    test('all categories have display names', () {
      for (final cat in PhotoCategory.values) {
        expect(cat.displayName.isNotEmpty, true);
      }
    });
  });

  group('AppSettings', () {
    test('hasHomeLocation returns true when set', () {
      final settings = AppSettings(homeLatitude: 40.71, homeLongitude: -74.0);
      expect(settings.hasHomeLocation, true);
    });

    test('hasHomeLocation returns false when zero', () {
      final settings = AppSettings();
      expect(settings.hasHomeLocation, false);
    });

    test('copyWith preserves unset fields', () {
      final original = AppSettings(
        homeLatitude: 40.71,
        homeLongitude: -74.0,
        llmApiKey: 'sk-test',
      );
      final copy = original.copyWith(copyFiles: false);
      expect(copy.homeLatitude, 40.71);
      expect(copy.homeLongitude, -74.0);
      expect(copy.llmApiKey, 'sk-test');
      expect(copy.copyFiles, false);
    });
  });
}
