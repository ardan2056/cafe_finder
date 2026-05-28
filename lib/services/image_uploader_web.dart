import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Web implementation: upload `data:` URIs to Firebase Storage and return https URLs.
Future<List<String>> uploadImagesImpl(List<String> images, {required String cafeId}) async {
  final storage = FirebaseStorage.instance;
  final results = <String>[];

  for (final img in images) {
    try {
      if (img.startsWith('data:')) {
        final comma = img.indexOf(',');
        if (comma == -1) continue;
        final meta = img.substring(5, comma);
        final isBase64 = meta.contains('base64');
        final payload = img.substring(comma + 1);
        Uint8List bytes;
        if (isBase64) {
          bytes = base64Decode(payload);
        } else {
          bytes = Uint8List.fromList(utf8.encode(Uri.decodeComponent(payload)));
        }

        final ext = meta.contains('image/png') ? 'png' : 'jpg';
        final ref = storage.ref().child('cafes').child(cafeId).child('${DateTime.now().millisecondsSinceEpoch}.$ext');
        final snapshot = await ref.putData(bytes).whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();
        results.add(url);
      } else {
        // keep existing http(s) URLs
        results.add(img);
      }
    } catch (_) {
      if (img.startsWith('http')) results.add(img);
    }
  }

  return results;
}
