import 'dart:io';

class MultipartBody {
  final String key;
  final File file;
  final File? thumbnail; // Add thumbnail field

  MultipartBody({
    required this.key,
    required this.file,
    this.thumbnail, // Make thumbnail optional
  });
}
