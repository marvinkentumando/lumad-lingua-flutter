import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Uploads an image to the 'images' bucket.
  /// Returns the public URL of the uploaded image.
  Future<String?> uploadImage(File file, String fileName) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        debugPrint('Error: Image file does not exist at ${file.path}');
        return null;
      }

      final String path = fileName;
      await _client.storage.from('images').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _client.storage.from('images').getPublicUrl(path);
      debugPrint('Successfully uploaded image: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image to Supabase: $e');
      return null;
    }
  }

  /// Uploads an audio file to the 'audio' bucket.
  /// Returns the public URL of the uploaded audio.
  Future<String?> uploadAudio(File file, String fileName) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        debugPrint('Error: Audio file does not exist at ${file.path}');
        return null;
      }

      final String path = fileName;
      await _client.storage.from('audio').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _client.storage.from('audio').getPublicUrl(path);
      debugPrint('Successfully uploaded audio: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading audio to Supabase: $e');
      return null;
    }
  }

  /// Deletes a file from a specified bucket.
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
      debugPrint('Successfully deleted file from $bucket: $path');
    } catch (e) {
      debugPrint('Error deleting file from Supabase: $e');
    }
  }

  /// Uploads a file to a specified bucket.
  /// Returns the public URL of the uploaded file.
  Future<String?> uploadFile({
    required String bucket,
    required File file,
    required String fileName,
  }) async {
    try {
      if (!await file.exists()) {
        debugPrint('Error: File does not exist at ${file.path}');
        return null;
      }

      await _client.storage.from(bucket).upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _client.storage.from(bucket).getPublicUrl(fileName);
      debugPrint('Successfully uploaded file to $bucket: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file to $bucket: $e');
      return null;
    }
  }
}

final supabaseStorageServiceProvider = Provider((ref) => SupabaseStorageService());
