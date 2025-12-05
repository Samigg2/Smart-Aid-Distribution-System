import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

class CloudinaryService {
  // TODO: Replace with your Cloudinary credentials from https://cloudinary.com
  // Get these from your Cloudinary dashboard (FREE account)
  static const String _cloudName = 'dpz0f6t0k';
  static const String _apiKey = '147546184473829';
  static const String _apiSecret = 'yjZNlKPPBZ-FJNg75ZqAJOtrBkA';

  // Upload beneficiary photo to Cloudinary using REST API
  Future<String> uploadBeneficiaryPhoto(File imageFile) async {
    try {
      // First, ensure the file exists and copy to permanent location if needed
      File fileToProcess = await _ensureFileExists(imageFile);

      // Compress image before upload to save storage
      final compressedFile = await _compressImage(fileToProcess);

      // Verify compressed file exists
      if (!await compressedFile.exists()) {
        throw Exception('Compressed file was not created');
      }

      // Create upload URL
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

      // Create form data
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final folder = 'fairid/beneficiaries';
      final publicId =
          'beneficiary_${timestamp}_${DateTime.now().microsecondsSinceEpoch}';

      // Create signature for authentication (Cloudinary uses SHA1, not SHA256)
      final signatureString =
          'folder=$folder&public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields.addAll({
        'api_key': _apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        'public_id': publicId,
      });
      request.files.add(
        await http.MultipartFile.fromPath('file', compressedFile.path),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'] as String;
        return secureUrl;
      } else {
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      Fluttertoast.showToast(msg: 'Failed to upload photo: $e');
      rethrow;
    }
  }

  // Ensure file exists and copy to permanent location if needed
  Future<File> _ensureFileExists(File imageFile) async {
    // Check if file exists
    if (await imageFile.exists()) {
      return imageFile;
    }

    // If file doesn't exist, try to copy from the path
    // This handles cases where the file was moved or deleted
    try {
      // Try to read the file first
      await imageFile.readAsBytes();
      return imageFile;
    } catch (e) {
      // If reading fails, the file is truly missing
      throw Exception(
        'Image file not found at path: ${imageFile.path}. Please capture the photo again.',
      );
    }
  }

  // Compress image to reduce file size (saves Cloudinary storage)
  Future<File> _compressImage(File imageFile) async {
    try {
      // Verify file exists before processing
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }

      // Read image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Resize if too large (max 1200px width, maintain aspect ratio)
      img.Image resizedImage = image;
      if (image.width > 1200) {
        resizedImage = img.copyResize(image, width: 1200, maintainAspect: true);
      }

      // Compress JPEG quality (80% - good balance)
      final compressedBytes = img.encodeJpg(resizedImage, quality: 80);

      // Save to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(imageFile.path);
      final compressedFile = File(
        path.join(tempDir.path, 'compressed_$fileName'),
      );

      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      // Return original file if compression fails
      return imageFile;
    }
  }

  // Delete photo from Cloudinary (if needed)
  Future<bool> deletePhoto(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signatureString =
          'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  // Get optimized URL (for faster loading)
  String getOptimizedUrl(String originalUrl, {int width = 800}) {
    // Cloudinary URL transformation for optimization
    if (originalUrl.contains('cloudinary.com')) {
      // Insert transformation parameters
      final parts = originalUrl.split('/upload/');
      if (parts.length == 2) {
        return '${parts[0]}/upload/w_$width,q_auto,f_auto/${parts[1]}';
      }
    }
    return originalUrl;
  }
}
