import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../errors/app_exception.dart';

/// Uploads binary media to Cloudinary using unsigned upload presets.
///
/// Firebase is used only for authentication and text data; all images, videos
/// and documents are stored on Cloudinary.
final cloudinaryUploadServiceProvider = Provider<CloudinaryUploadService>(
  (ref) => CloudinaryUploadService(),
);

final class CloudinaryUploadService {
  CloudinaryUploadService({String? cloudName})
    : _cloudName = cloudName ?? Env.cloudinaryCloudName;

  final String _cloudName;

  /// Uploads an image and returns its secure HTTPS URL.
  Future<String> uploadImage(
    Uint8List bytes, {
    required String uploadPreset,
    String fileName = 'image.jpg',
  }) {
    return _upload(bytes, resourceType: 'image', uploadPreset: uploadPreset, fileName: fileName);
  }

  /// Uploads a video and returns its secure HTTPS URL.
  Future<String> uploadVideo(
    Uint8List bytes, {
    required String uploadPreset,
    String fileName = 'video.mp4',
  }) {
    return _upload(bytes, resourceType: 'video', uploadPreset: uploadPreset, fileName: fileName);
  }

  /// Uploads a document and returns its secure HTTPS URL.
  Future<String> uploadDocument(
    Uint8List bytes, {
    required String uploadPreset,
    String fileName = 'document.pdf',
  }) {
    return _upload(bytes, resourceType: 'raw', uploadPreset: uploadPreset, fileName: fileName);
  }

  Future<String> _upload(
    Uint8List bytes, {
    required String resourceType,
    required String uploadPreset,
    required String fileName,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const NetworkException('Upload failed. Please try again.');
      }

      final decoded = jsonDecode(response.body);
      final url = decoded is Map<String, dynamic>
          ? decoded['secure_url'] as String?
          : null;
      if (url == null || url.isEmpty) {
        throw const NetworkException('Upload failed. Please try again.');
      }
      return url;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const NetworkException(
        'Could not upload the file. Check your connection and try again.',
      );
    }
  }
}
