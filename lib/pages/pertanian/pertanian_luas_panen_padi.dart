import 'package:flutter/material.dart';
import 'package:mboistats/main.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

class LuasPanenPadiPage extends StatefulWidget {
  const LuasPanenPadiPage({Key? key}) : super(key: key);

  @override
  State<LuasPanenPadiPage> createState() => _LuasPanenPadiPageState();
}

class _LuasPanenPadiPageState extends State<LuasPanenPadiPage> {
  // 1. Deklarasikan controller di sini
  late WebViewControllerPlus controller;
  bool _isLoading = true; // Tambahkan state loading

  // 2. Pindahkan semua logika inisialisasi ke dalam initState
  @override
  void initState() {
    super.initState();
    
    controller = WebViewControllerPlus()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
            onProgress: (int progress) {},
            onPageStarted: (String url) {},
            onWebResourceError: (WebResourceError error) {},
            onPageFinished: (String url) {
              // Panggil fungsi untuk mengambil data dari PHP
              print("WebView Selesai Dimuat. Mengambil data dari server...");
              _loadDataFromRemote(); 
            },
        ),
    )
    // Muat template HTML BARU Anda
    ..loadFlutterAssetWithServer('assets/web/pertanian_luas_panen_padi.html', localhostServer.port!);
  }


  // 3. Fungsi baru untuk mengambil data dari server PHP
  Future<void> _loadDataFromRemote() async {
    // String fallback jika terjadi error
    String jsCall = "loadChartData('{\"error\": \"Gagal terhubung ke server.\"}');"; 
    
    try {
      // Panggil endpoint yang Anda buat di proxy.php
      
      // --- PENTING: GANTI IP DI BAWAH INI ---
      // GANTI "192.168.X.X" DENGAN IP WIFI LAPTOP ANDA
      const String proxyHost = "10.135.73.114"; 
      
      const String proxyPort = "80"; // Port default XAMPP/Apache
      const String proxyPath = "/mboistats/proxy.php";
      
      // --- PERBAIKAN ENDPOINT & PARAMETER ---
      final uri = Uri.http("$proxyHost:$proxyPort", proxyPath, {
        'get': 'chart_data', // Endpoint yang benar
        'var_id': '492',     // ID Variabel untuk "Luas Panen Padi"
      });
      
      print("Flutter memanggil PHP di: $uri");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print("PHP merespons dengan data.");
        
        // Pastikan untuk "membersihkan" JSON string dari karakter yang bisa merusak JS
        String rawJsonData = response.body.replaceAll("'", "\\'").replaceAll("\n", "\\n");

        jsCall = "loadChartData('$rawJsonData');";
        
      } else {
        throw Exception('Gagal memuat data dari server PHP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Gagal mengambil data chart: $e");
      // Kirim JSON error ke JavaScript
      String errorMsg = e.toString().replaceAll("'", "\\'").replaceAll("\n", "\\n");
      jsCall = "loadChartData('{\"error\": \"Gagal memuat data: $errorMsg\"}');";
    }
    
    // Suntikkan data (baik data sukses atau data error) ke JavaScript
    if (mounted) {
       await controller.runJavaScript(jsCall);
       setState(() {
         _isLoading = false; // Sembunyikan loading
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luas Panen Padi'),
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
                image: AssetImage('assets/images/back_pertanian.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // WebView
          WebViewWidget(controller: controller),
          
          // Tampilkan loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}