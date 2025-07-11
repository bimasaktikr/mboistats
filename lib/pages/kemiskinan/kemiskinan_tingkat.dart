import 'package:flutter/material.dart';
import 'package:mboistats/main.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class TingkatKemiskinanPage extends StatefulWidget {
  const TingkatKemiskinanPage({Key? key}) : super(key: key);


  @override
  State<TingkatKemiskinanPage> createState() => _TingkatKemiskinanPageState();
}

class _TingkatKemiskinanPageState extends State<TingkatKemiskinanPage> {
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
    ..loadFlutterAssetWithServer('assets/web/kemiskinan_tingkat.html', localhostServer.port!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tingkat Kemiskinan'),
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
                image: AssetImage('assets/images/back_kemiskinan.png'),
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