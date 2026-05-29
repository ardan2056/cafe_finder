// Shim used for non-web platforms during testing.
// Provides a minimal `window.localStorage` API used by CafeService for fallback.
class WindowStub {
  final Map<String, String> localStorage = <String, String>{};
}

final WindowStub window = WindowStub();
