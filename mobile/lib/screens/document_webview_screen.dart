/*
---------- Tela de WebView para Documentos ----------
- Autor Principal: Felipe Nasser Coelho Moussa | RA: 25004922
*/

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfWebViewScreen extends StatefulWidget {
  final String name;
  final String url;

  const PdfWebViewScreen({
    super.key,
    required this.name,
    required this.url,
  });

  @override
  State<PdfWebViewScreen> createState() => _PdfWebViewScreenState();
}

class _PdfWebViewScreenState extends State<PdfWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            ),
        ],
      ),
    );
  }
}