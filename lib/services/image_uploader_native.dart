import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Native implementation: upload `data:` URIs to Firebase Storage and return download URLs.
Future<List<String>> uploadImagesImpl(List<String> images, {required String cafeId}) async {
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

        final ext = meta.contains('image/png') ? 'png' : 'jpg';
        final ref = storage.ref().child('cafes').child(cafeId).child('${DateTime.now().millisecondsSinceEpoch}.$ext');
        final uploadTask = ref.putData(bytes);
        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();
        results.add(url);
      } else {
        // maybe a local file path
        try {
          final file = File(img);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            final ext = img.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
            final ref = storage.ref().child('cafes').child(cafeId).child('${DateTime.now().millisecondsSinceEpoch}.$ext');
            final snapshot = await ref.putData(bytes).whenComplete(() {});
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
