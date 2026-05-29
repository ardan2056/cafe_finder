import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase_status.dart' as fb_status;

class DiagnosticReportService {
  DiagnosticReportService._();

  static final DiagnosticReportService instance = DiagnosticReportService._();

  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('crashlytics_enabled') ?? false;
    await _syncNativeCollectionSetting();
    await flushQueuedReports();
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('crashlytics_enabled', enabled);
    _enabled = enabled;
    await _syncNativeCollectionSetting();
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String source = 'app',
    Map<String, dynamic>? extra,
  }) async {
    if (!_enabled) return;

    await _recordNativeCrashlytics(error, stackTrace,
        source: source, extra: extra);

    final report = <String, dynamic>{
      'message': error.toString(),
      'stackTrace': stackTrace.toString(),
      'source': source,
      'extra': extra ?? const {},
      'createdAt': FieldValue.serverTimestamp(),
      'uid': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
    };

    if (fb_status.isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('crash_reports')
            .add(report);
        return;
      } catch (_) {
        // fall through to local queue
      }
    }

    await _queueLocalReport(report);
  }

  Future<void> flushQueuedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final queued = prefs.getStringList('queued_crash_reports') ?? [];
    if (queued.isEmpty || !fb_status.isFirebaseReady) return;

    final remaining = <String>[];
    for (final encoded in queued) {
      try {
        final report = _decodeReport(encoded);
        await FirebaseFirestore.instance
            .collection('crash_reports')
            .add(report);
      } catch (_) {
        remaining.add(encoded);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove('queued_crash_reports');
    } else {
      await prefs.setStringList('queued_crash_reports', remaining);
    }
  }

  Future<void> _queueLocalReport(Map<String, dynamic> report) async {
    final prefs = await SharedPreferences.getInstance();
    final queued = prefs.getStringList('queued_crash_reports') ?? [];
    queued.add(_encodeReport(report));
    await prefs.setStringList('queued_crash_reports', queued);
  }

  Future<void> _syncNativeCollectionSetting() async {
    if (!_supportsNativeCrashlytics) return;
    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(_enabled);
    } catch (_) {}
  }

  Future<void> _recordNativeCrashlytics(
    Object error,
    StackTrace stackTrace, {
    String source = 'app',
    Map<String, dynamic>? extra,
  }) async {
    if (!_supportsNativeCrashlytics) return;

    try {
      await FirebaseCrashlytics.instance.setCustomKey('source', source);
      if (extra != null) {
        for (final entry in extra.entries) {
          final value = entry.value;
          await FirebaseCrashlytics.instance.setCustomKey(
            entry.key,
            value is int || value is num || value is String || value is bool
                ? value
                : value.toString(),
          );
        }
      }
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: source,
        fatal: false,
      );
    } catch (_) {}
  }

  bool get _supportsNativeCrashlytics {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _encodeReport(Map<String, dynamic> report) {
    return jsonEncode(report);
  }

  Map<String, dynamic> _decodeReport(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{'message': decoded.toString()};
  }
}
