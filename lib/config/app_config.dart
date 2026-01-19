class AppConfig {
  static const String priorityAiBaseUrl = String.fromEnvironment(
    'PRIORITY_AI_BASE_URL',
    defaultValue: '',
  );

  static const String priorityAiApiKey = String.fromEnvironment(
    'PRIORITY_AI_API_KEY',
    defaultValue: '',
  );

  static bool get isPriorityAiEnabled => priorityAiBaseUrl.trim().isNotEmpty;
}
