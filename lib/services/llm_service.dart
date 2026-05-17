import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/classification.dart';

class LlmService {
  final String apiKey;
  final String model;
  final String baseUrl;
  final double confidenceThreshold;

  LlmService({
    required this.apiKey,
    this.model = 'gpt-4o',
    this.baseUrl = 'https://api.openai.com/v1',
    this.confidenceThreshold = 0.5,
  });

  Future<PhotoCategory?> classifyImage(String imagePath) async {
    if (apiKey.isEmpty) return null;

    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = imagePath.split('.').last.toLowerCase();
      final mimeType = _mimeTypeFor(ext);

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Analyze this photo and classify it into exactly one category. '
                      'Respond with ONLY the category name in lowercase, nothing else.\n'
                      'Categories: food, pet, family, portrait, landscape, architecture, '
                      'document, receipt, art, event, other',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:$mimeType;base64,$base64Image',
                    'detail': 'low',
                  },
                },
              ],
            },
          ],
          'max_tokens': 50,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          (body['choices'] as List?)?.firstOrNull?['message']?['content']
              ?.toString()
              .trim()
              .toLowerCase();

      if (content == null) return null;

      return PhotoCategory.values.firstWhere(
        (c) => c.name == content && c != PhotoCategory.trip &&
            c != PhotoCategory.dailyLife && c != PhotoCategory.uncategorized,
        orElse: () => PhotoCategory.other,
      );
    } catch (_) {
      return null;
    }
  }

  String _mimeTypeFor(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
