import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _homeLatCtrl;
  late TextEditingController _homeLonCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _baseUrlCtrl;
  late bool _copyFiles;
  late double _confidenceThreshold;
  late bool _enableLlm;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppProvider>().settings;
    _homeLatCtrl = TextEditingController(
        text: settings.homeLatitude.toString());
    _homeLonCtrl = TextEditingController(
        text: settings.homeLongitude.toString());
    _apiKeyCtrl =
        TextEditingController(text: settings.llmApiKey);
    _modelCtrl =
        TextEditingController(text: settings.llmModel);
    _baseUrlCtrl =
        TextEditingController(text: settings.llmBaseUrl);
    _copyFiles = settings.copyFiles;
    _confidenceThreshold = settings.confidenceThreshold;
    _enableLlm = settings.enableLlmClassification;
  }

  @override
  void dispose() {
    _homeLatCtrl.dispose();
    _homeLonCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final provider = context.read<AppProvider>();
    provider.updateSettings(provider.settings.copyWith(
      homeLatitude: double.tryParse(_homeLatCtrl.text) ?? 0.0,
      homeLongitude: double.tryParse(_homeLonCtrl.text) ?? 0.0,
      copyFiles: _copyFiles,
      llmApiKey: _apiKeyCtrl.text,
      llmModel: _modelCtrl.text.isNotEmpty ? _modelCtrl.text : 'gpt-4o',
      llmBaseUrl: _baseUrlCtrl.text.isNotEmpty
          ? _baseUrlCtrl.text
          : 'https://api.openai.com/v1',
      confidenceThreshold: _confidenceThreshold,
      enableLlmClassification: _enableLlm,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Home Location
            Text('Home Location', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _homeLatCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 40.7128',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _homeLonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. -74.0060',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // File operation
            Text('File Handling', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Copy files (vs move)'),
              subtitle: Text(
                  _copyFiles ? 'Files will be copied to destination' : 'Files will be moved'),
              value: _copyFiles,
              onChanged: (v) => setState(() => _copyFiles = v),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // LLM Settings
            Text('AI Classification', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable AI classification'),
              subtitle: const Text('Analyze photos with vision LLM'),
              value: _enableLlm,
              onChanged: (v) => setState(() => _enableLlm = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_enableLlm) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  hintText: 'sk-...',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                  hintText: 'gpt-4o',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://api.openai.com/v1',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Confidence Threshold: '),
                  Expanded(
                    child: Slider(
                      value: _confidenceThreshold,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: _confidenceThreshold.toStringAsFixed(2),
                      onChanged: (v) =>
                          setState(() => _confidenceThreshold = v),
                    ),
                  ),
                  Text(_confidenceThreshold.toStringAsFixed(2)),
                ],
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
