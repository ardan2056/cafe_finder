import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StitchExplorerScreen extends StatefulWidget {
  const StitchExplorerScreen({super.key});

  @override
  State<StitchExplorerScreen> createState() => _StitchExplorerScreenState();
}

class _StitchExplorerScreenState extends State<StitchExplorerScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0C10))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadFlutterAsset('assets/stitch/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        title: const Text('Stitch UI Prototype'),
        backgroundColor: const Color(0xFF0B0C10),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
