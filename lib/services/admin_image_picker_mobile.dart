import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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

    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return <String>[];

    final results = <String>[];
    for (final xfile in images) {
      if (xfile.path.isNotEmpty) results.add(xfile.path);
    }
    return results;
  } catch (e) {
    return <String>[];
  }
}
