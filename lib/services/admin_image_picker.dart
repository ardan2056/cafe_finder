// Conditional import dispatcher for image picker implementations.
import 'admin_image_picker_stub.dart'
    if (dart.library.html) 'admin_image_picker_web.dart'
    if (dart.library.io) 'admin_image_picker_mobile.dart';

/// Picks image files and returns a list of data URLs or remote URLs.
/// The actual implementation is provided by the conditional import.
Future<List<String>> pickImages() => pickImagesImpl();
