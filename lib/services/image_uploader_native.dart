import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img_lib;

/// Native implementation: upload `data:` URIs to Firebase Storage and return download URLs.
Future<List<String>> uploadImagesImpl(List<String> images,
    {required String cafeId}) async {
  final storage = FirebaseStorage.instance;
  final results = <String>[];

  for (final img in images) {
    try {
      if (img.startsWith('data:')) {
        // data:[<mediatype>][;base64],<data>
        final comma = img.indexOf(',');
        if (comma == -1) {
          continue;
        }
        final meta = img.substring(5, comma); // skip 'data:'
        final isBase64 = meta.contains('base64');
        final payload = img.substring(comma + 1);
        Uint8List bytes;
        if (isBase64) {
          bytes = base64Decode(payload);
        } else {
          bytes = Uint8List.fromList(utf8.encode(Uri.decodeComponent(payload)));
        }

        // Compress/resize the image bytes before upload
        Uint8List processed =
            await _processImageBytes(bytes, meta.contains('image/png'));
        final ext = meta.contains('image/png') ? 'png' : 'jpg';
        final ref = storage
            .ref()
            .child('cafes')
            .child(cafeId)
            .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
        final uploadTask = ref.putData(processed);
        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();
        results.add(url);
      } else {
        // maybe a local file path
        try {
          final file = File(img);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            // try to detect png by file extension
            final isPng = img.toLowerCase().endsWith('.png');
            final processed = await _processImageBytes(bytes, isPng);
            final ext = isPng ? 'png' : 'jpg';
            final ref = storage
                .ref()
                .child('cafes')
                .child(cafeId)
                .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
            final snapshot = await ref.putData(processed).whenComplete(() {});
            final url = await snapshot.ref.getDownloadURL();
            results.add(url);
          } else {
            // assume already a usable URL
            results.add(img);
          }
        } catch (_) {
          results.add(img);
        }
      }
    } catch (e) {
      // On failure, fallback to original string if it looks like a URL
      if (img.startsWith('http')) {
        results.add(img);
      }
    }
  }

  return results;
}

Future<Uint8List> _processImageBytes(Uint8List bytes, bool isPng) async {
  try {
    final image = img_lib.decodeImage(bytes);
    if (image == null) return bytes;

    // Resize if wider than 1024px
    final maxWidth = 1024;
    img_lib.Image resized = image;
    if (image.width > maxWidth) {
      resized = img_lib.copyResize(image, width: maxWidth);
    }

    if (isPng) {
      return Uint8List.fromList(img_lib.encodePng(resized));
    }

    // encode as JPEG with quality 80
    return Uint8List.fromList(img_lib.encodeJpg(resized, quality: 80));
  } catch (e) {
    return bytes;
  }
}
