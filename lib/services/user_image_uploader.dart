import 'dart:io';
import 'image_uploader.dart';

/// Uploads images intended for users (avatars) to Storage under `users/{uid}`.
/// After successful upload, deletes local temp files that live in system temp.
Future<List<String>> uploadUserImageFiles(List<String> localPaths,
    {required String uid}) async {
  // Reuse generic uploader with pathPrefix 'users'
  final uploaded =
      await uploadImagesIfNeeded(localPaths, cafeId: uid, pathPrefix: 'users');

  // Attempt to delete local temp files we created (system temp)
  try {
    for (final p in localPaths) {
      try {
        if (p.startsWith(Directory.systemTemp.path)) {
          final f = File(p);
          if (await f.exists()) await f.delete();
        }
      } catch (_) {}
    }
  } catch (_) {}

  return uploaded;
}
