import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firs_app/config/app_config.dart';

void main() {
  group('AppConfig', () {
    setUp(() async {
      // Initialize dotenv with empty map for testing
      dotenv.testLoad(fileInput: '');
    });

    test('priorityAiBaseUrl returns empty string when not set', () {
      expect(AppConfig.priorityAiBaseUrl, equals(''));
    });

    test('priorityAiBaseUrl returns value from env', () async {
      dotenv.testLoad(fileInput: 'PRIORITY_AI_BASE_URL=https://test-api.com');
      expect(AppConfig.priorityAiBaseUrl, equals('https://test-api.com'));
    });

    test('priorityAiApiKey returns empty string when not set', () {
      expect(AppConfig.priorityAiApiKey, equals(''));
    });

    test('priorityAiApiKey returns value from env', () {
      dotenv.testLoad(fileInput: 'PRIORITY_AI_API_KEY=test-api-key');
      expect(AppConfig.priorityAiApiKey, equals('test-api-key'));
    });

    test('isPriorityAiEnabled returns false when baseUrl is empty', () {
      dotenv.testLoad(fileInput: 'PRIORITY_AI_BASE_URL=');
      expect(AppConfig.isPriorityAiEnabled, isFalse);
    });

    test('isPriorityAiEnabled returns false when baseUrl is whitespace', () {
      dotenv.testLoad(fileInput: 'PRIORITY_AI_BASE_URL=   ');
      expect(AppConfig.isPriorityAiEnabled, isFalse);
    });

    test('isPriorityAiEnabled returns true when baseUrl is set', () {
      dotenv.testLoad(fileInput: 'PRIORITY_AI_BASE_URL=https://test-api.com');
      expect(AppConfig.isPriorityAiEnabled, isTrue);
    });
  });
}

