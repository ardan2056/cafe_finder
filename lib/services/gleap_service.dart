import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_status.dart' as fb_status;

/// Lightweight wrapper for feedback integration (Gleap or fallback).
class GleapService {
  GleapService._();
  static final GleapService instance = GleapService._();

  bool _enabled = false;
  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('gleap_enabled') ?? false;
    // If integration with Gleap SDK is added, initialize it here when _enabled==true.
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gleap_enabled', enabled);
    _enabled = enabled;
    // Initialize or teardown native Gleap SDK here if available.
  }

  /// Show in-app feedback UI. If Gleap SDK isn't available, fall back to
  /// collecting a message via dialog and submitting it to Firestore or queueing.
  Future<void> showFeedback(BuildContext context) async {
    if (!_enabled) {
      // Fallback to simple dialog
      await _collectAndSubmit(context);
      return;
    }

    // Placeholder: if Gleap SDK is added, call its 'open' method here.
    // For now, fallback to dialog so feature works even without the SDK.
    await _collectAndSubmit(context);
  }

  Future<void> _collectAndSubmit(BuildContext context) async {
    final controller = TextEditingController();
    // Capture navigator before any async gaps to safely check mounted state later
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kirim Feedback'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
              hintText: 'Tuliskan masukan atau laporkan bug'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kirim')),
        ],
      ),
    );

    if (ok != true) return;
    final msg = controller.text.trim();
    if (msg.isEmpty) {
      if (!navigator.mounted) return;
      ScaffoldMessenger.of(navigator.context)
          .showSnackBar(const SnackBar(content: Text('Pesan kosong')));
      return;
    }

    try {
      if (fb_status.isFirebaseReady) {
        await FirebaseFirestore.instance.collection('feedback').add({
          'uid': 'gleap',
          'message': msg,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (navigator.mounted) {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
              const SnackBar(content: Text('Terima kasih, feedback terkirim')));
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final existing = prefs.getStringList('queued_feedback') ?? [];
        existing.add(msg);
        await prefs.setStringList('queued_feedback', existing);
        if (navigator.mounted) {
          ScaffoldMessenger.of(navigator.context).showSnackBar(const SnackBar(
              content: Text(
                  'Firebase tidak tersedia — feedback disimpan sementara')));
        }
      }
    } catch (e) {
      if (navigator.mounted) {
        ScaffoldMessenger.of(navigator.context)
            .showSnackBar(SnackBar(content: Text('Gagal kirim feedback: $e')));
      }
    }
  }
}
