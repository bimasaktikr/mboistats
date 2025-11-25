import 'package:flutter/material.dart';
import 'package:mboistats/services/local_server_service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

/// Ini adalah pengganti untuk SEMUA file WebView duplikat.
/// File ini menerima judul, path HTML, dan path gambar latar.
class GenericWebViewPage extends StatefulWidget {
  final String title;
  final String htmlAssetPath;
  final String backgroundImagePath;

  const GenericWebViewPage({
    Key? key,
    required this.title,
    required this.htmlAssetPath,
    required this.backgroundImagePath,
  }) : super(key: key);

  @override
  _GenericWebViewPageState createState() => _GenericWebViewPageState();
}

class _GenericWebViewPageState extends State<GenericWebViewPage> {
  WebViewControllerPlus? controller;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    // Tunda inisialisasi hingga build pertama selesai
    // agar context.read() aman digunakan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebView();
    });
  }

  void _initializeWebView() {
    if (!mounted) return;

    try {
      // 1. Baca port dari Provider, BUKAN dari global main.dart
      final serverPort = context.read<LocalServerService>().port;
      
      if (serverPort == null) {
        throw Exception("LocalServerService not running or port is null.");
      }

      controller = WebViewControllerPlus()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {
              if (mounted) setState(() => isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              print("WebView Error: ${error.description}");
              if (mounted) setState(() {
                isLoading = false;
                isError = true;
              });
            },
          ),
        )
        ..loadFlutterAssetWithServer(widget.htmlAssetPath, serverPort);

      // Memicu build ulang untuk menampilkan WebView setelah controller dibuat
      setState(() {});

    } catch (e) {
      print("Failed to initialize WebView: $e");
      if (mounted) setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Gunakan title dari widget
        leading: IconButton(
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                // Gunakan backgroundImagePath dari widget
                image: AssetImage(widget.backgroundImagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // WebView, Loading, atau Error
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isError) {
      return const Center(
        child: Text(
          'Gagal memuat halaman.\nSilakan coba lagi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, backgroundColor: Colors.black54),
        ),
      );
    }

    if (controller == null || isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Hanya tampilkan WebView jika controller sudah siap dan halaman selesai dimuat
    return WebViewWidget(controller: controller!);
  }
}