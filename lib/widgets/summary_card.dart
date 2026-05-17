import 'package:flutter/material.dart';
import '../models/classification.dart';

class SummaryCard extends StatelessWidget {
  final int totalPhotos;
  final Map<PhotoCategory, int> categoryCounts;
  final int tripCount;

  const SummaryCard({
    super.key,
    required this.totalPhotos,
    required this.categoryCounts,
    required this.tripCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final entries = <Widget>[
      _summaryRow(Icons.photo_library, 'Total Photos', '$totalPhotos'),
    ];

    if (tripCount > 0) {
      entries.add(_summaryRow(Icons.flight, 'Trips Detected', '$tripCount'));
    }

    for (final entry in categoryCounts.entries) {
      if (entry.key == PhotoCategory.trip || entry.key == PhotoCategory.dailyLife) continue;
      entries.add(_summaryRow(Icons.image, entry.key.displayName, '${entry.value}'));
    }

    final dailyLife = categoryCounts[PhotoCategory.dailyLife] ?? 0;
    if (dailyLife > 0) {
      entries.add(_summaryRow(Icons.calendar_today, 'Daily Life', '$dailyLife'));
    }

    final uncategorized = categoryCounts[PhotoCategory.uncategorized] ?? 0;
    if (uncategorized > 0) {
      entries.add(_summaryRow(Icons.help_outline, 'Uncategorized', '$uncategorized'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...entries,
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
