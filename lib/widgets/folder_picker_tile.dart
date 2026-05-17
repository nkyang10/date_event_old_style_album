import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FolderPickerTile extends StatelessWidget {
  final String label;
  final String? path;
  final VoidCallback onPick;

  const FolderPickerTile({
    super.key,
    required this.label,
    this.path,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder_open, size: 32),
        title: Text(label),
        subtitle: Text(
          path?.isNotEmpty == true ? path! : 'Not selected',
          style: TextStyle(
            color: path?.isNotEmpty == true ? null : Colors.grey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: onPick,
          icon: const Icon(Icons.folder, size: 18),
          label: const Text('Browse'),
        ),
      ),
    );
  }
}

Future<String?> pickDirectory() async {
  final result = await FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Select Folder',
  );
  return result;
}
