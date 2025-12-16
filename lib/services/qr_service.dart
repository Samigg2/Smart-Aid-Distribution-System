import 'dart:convert';

/// Service for generating and parsing beneficiary QR codes.
class QRService {
  /// Build QR payload as JSON string.
  static String generateBeneficiaryQRData({
    required String beneficiaryId,
    required String nationalId,
    required String fullName,
  }) {
    final data = <String, dynamic>{
      'type': 'beneficiary',
      'beneficiaryId': beneficiaryId,
      'nationalId': nationalId,
      'fullName': fullName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  /// Parse QR payload. Returns map if valid, otherwise null.
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      if (data['type'] != 'beneficiary') {
        return null;
      }
      if (data['beneficiaryId'] == null ||
          data['nationalId'] == null ||
          data['fullName'] == null) {
        return null;
      }
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Validate payload shape.
  static bool isValidBeneficiaryQR(String qrData) {
    return parseQRData(qrData) != null;
  }

  /// Convenience helper to extract beneficiaryId.
  static String? getBeneficiaryId(String qrData) {
    final parsed = parseQRData(qrData);
    return parsed?['beneficiaryId'] as String?;
  }
}
