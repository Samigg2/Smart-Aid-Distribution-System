import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Environment configuration loader
/// Supports both .env file and direct configuration
class EnvConfig {
  static String? _cloudName;
  static String? _apiKey;
  static String? _apiSecret;

  /// Initialize configuration
  /// In production, load from .env file or Firebase Remote Config
  /// In development, can use hardcoded values (NOT RECOMMENDED)
  static Future<void> initialize() async {
    // Try to load from environment variables first
    // If using flutter_dotenv, uncomment below:
    /*
    try {
      await dotenv.load(fileName: ".env");
      _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      _apiKey = dotenv.env['CLOUDINARY_API_KEY'];
      _apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];
    } catch (e) {
      Logger.warning('Failed to load .env file, using defaults', tag: 'EnvConfig');
    }
    */

    // Fallback to hardcoded values (ONLY FOR DEVELOPMENT)
    // TODO: Remove hardcoded values in production
    if (_cloudName == null || _apiKey == null || _apiSecret == null) {
      if (kDebugMode) {
        Logger.warning(
          'Using hardcoded Cloudinary credentials. For production, use environment variables.',
          tag: 'EnvConfig',
        );
      }
      _cloudName = 'dpz0f6t0k';
      _apiKey = '147546184473829';
      _apiSecret = 'yjZNlKPPBZ-FJNg75ZqAJOtrBkA';
    }
  }

  static String get cloudName {
    if (_cloudName == null) {
      throw Exception('EnvConfig not initialized. Call EnvConfig.initialize() first.');
    }
    return _cloudName!;
  }

  static String get apiKey {
    if (_apiKey == null) {
      throw Exception('EnvConfig not initialized. Call EnvConfig.initialize() first.');
    }
    return _apiKey!;
  }

  static String get apiSecret {
    if (_apiSecret == null) {
      throw Exception('EnvConfig not initialized. Call EnvConfig.initialize() first.');
    }
    return _apiSecret!;
  }

  /// Check if using production-safe configuration
  static bool get isProductionReady {
    // Returns false if using hardcoded values
    // Returns true if loaded from environment variables
    return _cloudName != 'dpz0f6t0k';
  }
}

