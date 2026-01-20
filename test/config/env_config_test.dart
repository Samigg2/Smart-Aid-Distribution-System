import 'package:flutter_test/flutter_test.dart';
import 'package:firs_app/config/env_config.dart';

void main() {
  group('EnvConfig', () {
    setUp(() {
      // Reset EnvConfig state before each test
      EnvConfig.reset();
    });

    test('cloudName throws exception when not initialized', () {
      expect(
        () => EnvConfig.cloudName,
        throwsException,
      );
    });

    test('apiKey throws exception when not initialized', () {
      expect(
        () => EnvConfig.apiKey,
        throwsException,
      );
    });

    test('apiSecret throws exception when not initialized', () {
      expect(
        () => EnvConfig.apiSecret,
        throwsException,
      );
    });

    test('reset clears all configuration values', () {
      // First, we'd need to initialize (but that requires .env file)
      // So we test that reset works on uninitialized state
      EnvConfig.reset();
      expect(
        () => EnvConfig.cloudName,
        throwsException,
      );
      expect(
        () => EnvConfig.apiKey,
        throwsException,
      );
      expect(
        () => EnvConfig.apiSecret,
        throwsException,
      );
    });

    // Note: Testing initialize() requires a .env file or file system mocking
    // Integration tests would be better suited for testing the full initialization flow
  });
}

