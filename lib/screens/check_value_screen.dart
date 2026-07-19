import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

/// CHECK VALUE tab — full-screen WebView of the PGA trade-in value guide.
///
/// No navigation restrictions: the clerk can move freely. If they wander off
/// the trade-in flow, Home snaps back to the tool, Back steps within the site,
/// and Reload refreshes the current page.
class CheckValueScreen extends StatefulWidget {
  const CheckValueScreen({super.key});

  @override
  State<CheckValueScreen> createState() => _CheckValueScreenState();
}

class _CheckValueScreenState extends State<CheckValueScreen> {
  static const _toolUrl = 'https://valueguide.pga.com/trade-in/';

  late final WebViewController _controller;
  bool _loading = true;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.ground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) async {
            final canBack = await _controller.canGoBack();
            if (mounted) {
              setState(() {
                _loading = false;
                _canGoBack = canBack;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_toolUrl));
  }

  Future<void> _back() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  /// Returns to the trade-in tool, wherever the clerk has navigated to.
  Future<void> _home() async {
    setState(() => _loading = true);
    await _controller.loadRequest(Uri.parse(_toolUrl));
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Check Value',
        actions: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _canGoBack ? _back : null,
            disabledColor: AppColors.border,
          ),
          IconButton(
            tooltip: 'Back to trade-in tool',
            icon: const Icon(Icons.home_outlined),
            onPressed: _home,
          ),
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: AppColors.ground,
            ),
        ],
      ),
    );
  }
}
