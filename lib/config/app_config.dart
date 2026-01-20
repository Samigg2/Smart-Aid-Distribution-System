import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from .env file
class AppConfig {
  static String get priorityAiBaseUrl {
    return dotenv.env['PRIORITY_AI_BASE_URL'] ?? '';
  }

  static String get priorityAiApiKey {
    return dotenv.env['PRIORITY_AI_API_KEY'] ?? '';
  }

  static bool get isPriorityAiEnabled => priorityAiBaseUrl.trim().isNotEmpty;
}
