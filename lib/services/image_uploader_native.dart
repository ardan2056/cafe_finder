import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as imgpkg;
import 'package:pool/pool.dart';

/// Native implementation: upload `data:` URIs to Firebase Storage and return download URLs.
Future<List<String>> uploadImagesImpl(List<String> images,
    {required String cafeId,
    String pathPrefix = 'cafes',
    void Function(int index, double progress)? onProgress,
    Map<int, dynamic>? outUploadTasks}) async {
  final storage = FirebaseStorage.instance;
  // Upload in parallel with a small concurrency limit
  final pool = Pool(4);
  final futures = <Future<String>>[];

  for (var i = 0; i < images.length; i++) {
    final img = images[i];
    final f = pool.withResource(() async {
      try {
        if (img.startsWith('data:')) {
          final comma = img.indexOf(',');
          if (comma == -1) return '';
          final meta = img.substring(5, comma);
          final isBase64 = meta.contains('base64');
          final payload = img.substring(comma + 1);
          Uint8List bytes = isBase64
              ? base64Decode(payload)
              : Uint8List.fromList(utf8.encode(Uri.decodeComponent(payload)));

          // try to decode and resize if large
          try {
            final decoded = imgpkg.decodeImage(bytes);
            if (decoded != null) {
              final maxDim = 1600;
              imgpkg.Image processed = decoded;
              if (processed.width > maxDim || processed.height > maxDim) {
                processed =
                    imgpkg.copyResize(processed, width: maxDim, height: maxDim);
              }
              final isPng = meta.contains('image/png');
              bytes = isPng
                  ? Uint8List.fromList(imgpkg.encodePng(processed))
                  : Uint8List.fromList(
                      imgpkg.encodeJpg(processed, quality: 85));
            }
          } catch (_) {}

          final ext = meta.contains('image/png') ? 'png' : 'jpg';
          final ref = storage
              .ref()
              .child(pathPrefix)
              .child(cafeId)
              .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
          final uploadTask = ref.putData(bytes);
          outUploadTasks?.putIfAbsent(i, () => uploadTask);

          // report progress
          final sub = uploadTask.snapshotEvents.listen((snap) {
            final total = snap.totalBytes;
            final sent = snap.bytesTransferred;
            if (total > 0) {
              onProgress?.call(i, sent / total);
            }
          });

          final snapshot = await uploadTask.whenComplete(() {});
          await sub.cancel();
          outUploadTasks?.remove(i);
          final url = await snapshot.ref.getDownloadURL();
          onProgress?.call(i, 1.0);
          return url;
        } else {
          try {
            final file = File(img);
            if (file.existsSync()) {
              Uint8List bytes = await file.readAsBytes();
              // attempt to decode & resize like picker
              try {
                final decoded = imgpkg.decodeImage(bytes);
                if (decoded != null) {
                  final maxDim = 1600;
                  imgpkg.Image processed = decoded;
                  if (processed.width > maxDim || processed.height > maxDim) {
                    processed = imgpkg.copyResize(processed,
                        width: maxDim, height: maxDim);
                  }
                  final isPng = img.toLowerCase().endsWith('.png');
                  bytes = isPng
                      ? Uint8List.fromList(imgpkg.encodePng(processed))
                      : Uint8List.fromList(
                          imgpkg.encodeJpg(processed, quality: 85));
                }
              } catch (_) {}

              final ext = img.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
              final ref = storage
                  .ref()
                  .child(pathPrefix)
                  .child(cafeId)
                  .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
              final uploadTask = ref.putData(bytes);
              outUploadTasks?.putIfAbsent(i, () => uploadTask);

              final sub = uploadTask.snapshotEvents.listen((snap) {
                final total = snap.totalBytes;
                final sent = snap.bytesTransferred;
                if (total > 0) {
                  onProgress?.call(i, sent / total);
                }
              });

              final snapshot = await uploadTask.whenComplete(() {});
              await sub.cancel();
              outUploadTasks?.remove(i);
              final url = await snapshot.ref.getDownloadURL();
              try {
                if (img.startsWith(Directory.systemTemp.path)) {
                  await file.delete();
                }
              } catch (_) {}
              onProgress?.call(i, 1.0);
              return url;
            } else if (img.startsWith('http')) {
              onProgress?.call(i, 1.0);
              return img;
            }
          } catch (_) {}
        }
      } catch (_) {}
      return '';
    });

    futures.add(f);
  }

  final results = await Future.wait(futures);
  await pool.close();

  // Replace empty results with original input when possible
  final out = <String>[];
  for (var i = 0; i < images.length; i++) {
    final r = results[i];
    if (r.isEmpty) {
      final img = images[i];
      if (img.startsWith('http')) out.add(img);
      // otherwise skip
    } else {
      out.add(r);
    }
  }

  return out;
}
