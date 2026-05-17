enum PhotoCategory {
  food,
  pet,
  family,
  portrait,
  landscape,
  architecture,
  document,
  receipt,
  art,
  event,
  other,
  trip,
  dailyLife,
  uncategorized;

  String get displayName {
    switch (this) {
      case PhotoCategory.food:
        return 'Food';
      case PhotoCategory.pet:
        return 'Pet';
      case PhotoCategory.family:
        return 'Family';
      case PhotoCategory.portrait:
        return 'Portrait';
      case PhotoCategory.landscape:
        return 'Landscape';
      case PhotoCategory.architecture:
        return 'Architecture';
      case PhotoCategory.document:
        return 'Document';
      case PhotoCategory.receipt:
        return 'Receipt';
      case PhotoCategory.art:
        return 'Art';
      case PhotoCategory.event:
        return 'Event';
      case PhotoCategory.other:
        return 'Other';
      case PhotoCategory.trip:
        return 'Trip';
      case PhotoCategory.dailyLife:
        return 'Daily Life';
      case PhotoCategory.uncategorized:
        return 'Uncategorized';
    }
  }
}

class ClassificationResult {
  final PhotoCategory category;
  final String? tripName;
  final double confidence;
  final String source; // 'exif', 'llm', 'date'

  const ClassificationResult({
    required this.category,
    this.tripName,
    this.confidence = 1.0,
    required this.source,
  });
}
