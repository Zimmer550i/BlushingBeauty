// import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:intl/intl.dart';

// Future<String?> _mergeVideos(String bgPath, String overlayPath) async {
//   try {
//     final dir = await getTemporaryDirectory();
//     final outputPath =
//         '${dir.path}/merged_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.mp4';

//     // Overlay video (PiP) on top of camera background
//     final ffmpegCmd =
//         '-i "$bgPath" -i "$overlayPath" -filter_complex "[1:v]scale=200:250[ov];[0:v][ov]overlay=W-w-20:20" -c:a copy "$outputPath"';

//     await FFmpegKit.execute(ffmpegCmd);

//     final outputFile = File(outputPath);
//     if (await outputFile.exists()) {
//       debugPrint('✅ Merged video saved at: $outputPath');
//       return outputPath;
//     } else {
//       debugPrint('❌ Merged video not created');
//       return null;
//     }
//   } catch (e) {
//     debugPrint('❌ Merge failed: $e');
//     return null;
//   }
// }
