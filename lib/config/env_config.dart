import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Environment configuration loader
/// Loads configuration from .env file
class EnvConfig {
  static String? _cloudName;
  static String? _apiKey;
  static String? _apiSecret;

  /// Initialize configuration from .env file
  /// Throws exception if required values are missing
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      _apiKey = dotenv.env['CLOUDINARY_API_KEY'];
      _apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];
      
      if (_cloudName == null || _apiKey == null || _apiSecret == null) {
        throw Exception(
          'Missing required Cloudinary configuration in .env file. '
          'Please check CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET',
        );
      }
      
      if (kDebugMode) {
        Logger.info('Environment configuration loaded successfully', tag: 'EnvConfig');
      }
    } catch (e) {
      Logger.error('Failed to load .env file: $e', tag: 'EnvConfig');
      rethrow;
    }
  }

  /// Reset configuration (useful for testing)
  @visibleForTesting
  static void reset() {
    _cloudName = null;
    _apiKey = null;
    _apiSecret = null;
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

