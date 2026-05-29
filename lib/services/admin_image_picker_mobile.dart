import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

/// Mobile/native implementation using `image_picker`.
/// Returns a list of local file paths so the native uploader can read & upload files.
Future<List<String>> pickImagesImpl() async {
  final picker = ImagePicker();
  try {
    // On desktop platforms, `image_picker` may be unreliable. Use `file_picker` as a fallback.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result == null) return <String>[];
      return result.paths.whereType<String>().toList();
    }

    final images = await picker.pickMultiImage(imageQuality: 100);
    if (images.isEmpty) return <String>[];

    final results = <String>[];
    for (final xfile in images) {
      try {
        final originalPath = xfile.path;
        // read bytes and attempt to resize/compress to a reasonable size
        final bytes = await xfile.readAsBytes();
        final decode = img.decodeImage(bytes);

        if (decode == null) {
          // fallback: return original path if present
          if (originalPath.isNotEmpty) results.add(originalPath);
          continue;
        }

        // Auto-crop a centered square, then resize if larger than maxDim
        final maxDim = 1600;
        final minSide =
            decode.width < decode.height ? decode.width : decode.height;
        final cropX = (decode.width - minSide) ~/ 2;
        final cropY = (decode.height - minSide) ~/ 2;
        img.Image processed = img.copyCrop(decode,
            x: cropX, y: cropY, width: minSide, height: minSide);
        if (processed.width > maxDim || processed.height > maxDim) {
          processed = img.copyResize(processed, width: maxDim, height: maxDim);
        }

        // Determine extension and encode accordingly
        final origLower = originalPath.toLowerCase();
        final isPng = origLower.endsWith('.png');
        final outExt = isPng ? 'png' : 'jpg';
        final encoded = isPng
            ? img.encodePng(processed)
            : img.encodeJpg(processed, quality: 85);

        final tmpFile = File(
            '${Directory.systemTemp.path}/cafe_upload_${DateTime.now().millisecondsSinceEpoch}.$outExt');
        await tmpFile.writeAsBytes(encoded, flush: true);
        results.add(tmpFile.path);
      } catch (_) {
        if (xfile.path.isNotEmpty) results.add(xfile.path);
      }
    }
    return results;
  } catch (e) {
    return <String>[];
  }
}
