import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/photo_item.dart';
import '../widgets/folder_picker_tile.dart';
import '../widgets/summary_card.dart';
import '../widgets/progress_widget.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DateEvent Style Album'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Folder selection
            FolderPickerTile(
              label: 'Source Folder',
              path: provider.sourcePath,
              onPick: () async {
                final path = await pickDirectory();
                if (path != null) {
                  provider.setSourcePath(path);
                }
              },
            ),
            const SizedBox(height: 8),
            FolderPickerTile(
              label: 'Destination Folder',
              path: provider.destinationPath,
              onPick: () async {
                final path = await pickDirectory();
                if (path != null) {
                  provider.setDestinationPath(path);
                }
              },
            ),

            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: provider.state == AppState.scanning
                      ? null
                      : () => provider.scanPhotos(),
                  icon: const Icon(Icons.search),
                  label: const Text('Scan Photos'),
                ),
                if (provider.photos.isNotEmpty &&
                    provider.state != AppState.processing) ...[
                  FilledButton.icon(
                    onPressed: provider.state == AppState.processing
                        ? null
                        : () => provider.processPhotos(),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Classify Photos'),
                  ),
                  FilledButton.icon(
                    onPressed: provider.state == AppState.organizing ||
                            provider.photos
                                .every((p) => p.destinationPath == null)
                        ? null
                        : () => provider.organizeFiles(),
                    icon: const Icon(Icons.drive_folder_upload),
                    label: const Text('Organize Files'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => provider.reset(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Error message
            if (provider.errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Progress
            if (provider.state == AppState.scanning ||
                provider.state == AppState.processing ||
                provider.state == AppState.organizing) ...[
              const SizedBox(height: 16),
              ProgressWidget(
                progress: provider.progress,
                message: provider.statusMessage,
              ),
            ],

            // Summary
            if (provider.photos.isNotEmpty &&
                provider.state != AppState.scanning) ...[
              const SizedBox(height: 16),
              SummaryCard(
                totalPhotos: provider.totalPhotos,
                categoryCounts: provider.categoryCounts,
                tripCount: provider.tripCount,
              ),
            ],

            // Folder tree preview
            if (provider.photos.any((p) => p.destinationPath != null)) ...[
              const SizedBox(height: 16),
              _FolderPreview(photos: provider.photos),
            ],

            // Done message
            if (provider.state == AppState.done) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.statusMessage,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FolderPreview extends StatelessWidget {
  final List<PhotoItem> photos;
  const _FolderPreview({required this.photos});

  @override
  Widget build(BuildContext context) {
    // Group by destination path
    final Map<String, List<PhotoItem>> grouped = {};
    for (final photo in photos) {
      if (photo.destinationPath != null) {
        grouped.putIfAbsent(photo.destinationPath!, () => []).add(photo);
      }
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: ListView(
                children: sortedKeys.map((dest) {
                  final count = grouped[dest]!.length;
                  final parts = dest.split('/');
                  final indent = '  ' * (parts.length - 1);
                  final folderName = parts.last;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: '$indent\u{1F4C1} $folderName',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: ' ($count files)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
