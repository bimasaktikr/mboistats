import 'package:flutter/material.dart';
import 'package:mboistats/services/local_server_service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class GenericWebViewPage extends StatefulWidget {
  final String title;
  final String? htmlAssetPath;
  final String? url;
  final String? backgroundImagePath;

  const GenericWebViewPage({
    Key? key,
    required this.title,
    this.htmlAssetPath,
    this.url,
    this.backgroundImagePath,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebView();
    });
  }

  void _initializeWebView() {
    if (!mounted) return;

    try {
      controller = WebViewControllerPlus()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) setState(() {
                isLoading = false;
                isError = true;
              });
            },
          ),
        );
      if (widget.url != null && widget.url!.isNotEmpty) {
        controller!.loadRequest(Uri.parse(widget.url!));
      } else if (widget.htmlAssetPath != null) {
        final serverPort = context.read<LocalServerService>().port;
        if (serverPort == null) {
          throw Exception("LocalServerService not running.");
        }
        controller!.loadFlutterAssetWithServer(widget.htmlAssetPath!, serverPort);
      }

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
        title: Text(widget.title),
        leading: IconButton(
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          if (widget.backgroundImagePath != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.backgroundImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Gagal memuat halaman.\nPeriksa koneksi internet Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    if (controller == null || isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: controller!);
  }
}