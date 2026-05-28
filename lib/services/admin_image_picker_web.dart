// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;

/// Web implementation: open an `<input type="file" multiple accept="image/*">` and
/// read selected files as data URLs.
Future<List<String>> pickImagesImpl() async {
  final completer = Completer<List<String>>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = true;
  input.click();
  // Listen for selection
  input.onChange.listen((_) async {
    try {
      final files = input.files ?? [];
      final results = <String>[];
      for (final file in files) {
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        await reader.onLoad.first;
        final res = reader.result;
        if (res is String) results.add(res);
      }
      if (!completer.isCompleted) completer.complete(results);
    } catch (e) {
      if (!completer.isCompleted) completer.complete(<String>[]);
    }
  });

  // If user cancels or doesn't pick files, complete with empty list after timeout
  Future.delayed(const Duration(seconds: 60)).then((_) {
    if (!completer.isCompleted) completer.complete(<String>[]);
  });

  return completer.future;
}
