class AppSettings {
  double homeLatitude;
  double homeLongitude;
  bool copyFiles; // false = move
  String llmApiKey;
  String llmModel;
  String llmBaseUrl;
  double confidenceThreshold;
  bool enableLlmClassification;

  AppSettings({
    this.homeLatitude = 0.0,
    this.homeLongitude = 0.0,
    this.copyFiles = true,
    this.llmApiKey = '',
    this.llmModel = 'gpt-4o',
    this.llmBaseUrl = 'https://api.openai.com/v1',
    this.confidenceThreshold = 0.5,
    this.enableLlmClassification = true,
  });

  bool get hasHomeLocation => homeLatitude != 0.0 || homeLongitude != 0.0;

  bool get hasLlmKey => llmApiKey.isNotEmpty;

  AppSettings copyWith({
    double? homeLatitude,
    double? homeLongitude,
    bool? copyFiles,
    String? llmApiKey,
    String? llmModel,
    String? llmBaseUrl,
    double? confidenceThreshold,
    bool? enableLlmClassification,
  }) =>
      AppSettings(
        homeLatitude: homeLatitude ?? this.homeLatitude,
        homeLongitude: homeLongitude ?? this.homeLongitude,
        copyFiles: copyFiles ?? this.copyFiles,
        llmApiKey: llmApiKey ?? this.llmApiKey,
        llmModel: llmModel ?? this.llmModel,
        llmBaseUrl: llmBaseUrl ?? this.llmBaseUrl,
        confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
        enableLlmClassification:
            enableLlmClassification ?? this.enableLlmClassification,
      );
}
