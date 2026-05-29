// Dispatcher: use native implementation when `dart.library.io` is available.
import 'image_uploader_web.dart'
    if (dart.library.io) 'image_uploader_native.dart';

/// Uploads images when needed and returns a list of usable URLs.
///
/// Behavior:
/// - Native: detects `data:` URIs and uploads them to Firebase Storage, returning public URLs when possible. Other URLs are passed through.
/// - Web: no-op — returns the original list.
/// Optional `onProgress` reports per-image progress as a value 0.0..1.0
Future<List<String>> uploadImagesIfNeeded(List<String> images,
        {required String cafeId,
        String pathPrefix = 'cafes',
        void Function(int index, double progress)? onProgress,
        Map<int, dynamic>? outUploadTasks}) =>
    uploadImagesImpl(images,
        cafeId: cafeId,
        pathPrefix: pathPrefix,
        onProgress: onProgress,
        outUploadTasks: outUploadTasks);
