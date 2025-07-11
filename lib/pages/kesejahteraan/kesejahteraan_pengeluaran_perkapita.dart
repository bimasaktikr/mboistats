import 'package:flutter/material.dart';
import 'package:mboistats/main.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class PengeluaranPerkapitaPage extends StatefulWidget {
  const PengeluaranPerkapitaPage({Key? key}) : super(key: key);


  @override
  State<PengeluaranPerkapitaPage> createState() => _PengeluaranPerkapitaPageState();
}

class _PengeluaranPerkapitaPageState extends State<PengeluaranPerkapitaPage> {
  WebViewControllerPlus controller = WebViewControllerPlus()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
      ),
    )
    ..loadFlutterAssetWithServer('assets/web/kesejahteraan_pengeluaran_perkapita.html', localhostServer.port!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran Perkapita'),
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/left-arrow.png',
            height: 25,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back_kesejahteraan.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // WebView
          WebViewWidget(controller: controller),
        ],
      ),
    );
  }
}