import 'dart:io';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

/// Ensures that a given video file has a .mp4 extension.
/// Returns the corrected file path (always .mp4).
Future<File> ensureMp4Format(String originalPath) async {
  final originalFile = File(originalPath);

  // If it already ends with .mp4 → return as is
  if (originalPath.toLowerCase().endsWith('.mp4')) {
    return originalFile;
  }

  try {
    final dir = path.dirname(originalPath);
    final newPath = path.join(dir, '${path.basenameWithoutExtension(originalPath)}.mp4');

    // copy file to new path (rename might fail on some devices)
    final newFile = await originalFile.copy(newPath);

    debugPrint('✅ Video converted to MP4 format: $newPath');
    return newFile;
  } catch (e) {
    debugPrint('❌ Failed to convert video to .mp4: $e');
    rethrow;
  }
}
