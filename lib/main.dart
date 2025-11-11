import 'package:flutter/material.dart';
import 'package:mboistats/route-manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:mboistats/services/auth_service_custom.dart';

// Variabel global untuk server lokal (digunakan oleh WebView)
LocalhostServer localhostServer = LocalhostServer();

void main() async {
  // Pastikan binding Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi service autentikasi kustom kita
  // Ini akan menyiapkan listener auth state global
  await AuthServiceCustom.instance.init();

  // Mulai server lokal untuk aset web
  await localhostServer.start(port: 0);

  // Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN ARSITEKTUR DI SINI ---
    // 1. MaterialApp sekarang adalah widget root/paling luar.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: RouteManager.routes,

      // 2. Gunakan properti 'builder' untuk membungkus aplikasi Anda.
      // 'builder' memastikan widget di dalamnya (ConnectivityWrapper)
      // adalah turunan dari MaterialApp dan memiliki akses
      // ke Directionality, Theme, Navigator, dll.
      builder: (context, child) {
        // 'child' di sini mewakili halaman apa pun yang
        // sedang ditampilkan oleh Navigator (Splash, Home, Login, dll.)
        
        // 3. Bungkus 'child' (halaman Anda) dengan ConnectivityWrapper.
        // Sekarang, saat ConnectivityWrapper memanggil Fluttertoast,
        // ia akan menggunakan 'context' yang valid.
        return ConnectivityWrapper(
          // 'child' tidak boleh null, tanda '!' aman di sini.
          child: child!, 
        );
      },
    );
    // --- AKHIR PERBAIKAN ARSITEKTUR ---
  }
}

/// Widget wrapper untuk memantau konektivitas internet
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _ConnectivityWrapperState createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  var connectivityResult;
  bool showConnectivityBanner = false; // Status untuk banner (saat ini tdk dipakai)

  @override
  void initState() {
    super.initState();
    // Cek koneksi saat aplikasi pertama kali dimulai
    checkConnectivity();
    // Dengarkan perubahan koneksi
    Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return; // Tambahkan pengecekan 'mounted'
      setState(() {
        connectivityResult = result;
        showConnectivityBanner =
            false; // Set false agar banner tdk muncul permanen
        showToastMessage(); // Tampilkan Toast
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              showConnectivityBanner = false;
            });
          }
        });
      });
    });
  }

  /// Cek status koneksi awal
  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (mounted) {
      setState(() {
        this.connectivityResult = connectivityResult;
      });
    }
  }

  /// Tampilkan Toast (pop-up kecil) status koneksi
  void showToastMessage() {
    String message = connectivityResult == ConnectivityResult.none
        ? "Tidak terhubung ke internet"
        : "Terkoneksi ke internet";

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: connectivityResult == ConnectivityResult.none
          ? Colors.red
          : Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// (Tidak terpakai saat ini) Membangun banner di atas layar
  Widget buildConnectivityBanner() {
    return Container(
      height: 40,
      color: connectivityResult == ConnectivityResult.none
          ? Colors.red
          : Colors.green,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              connectivityResult == ConnectivityResult.none
                  ? "Tidak Terhubung"
                  : "Terkoneksi",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              connectivityResult == ConnectivityResult.none
                  ? "Tidak terhubung ke internet"
                  : "Terkoneksi ke internet",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stack untuk menampilkan aplikasi dan (jika aktif) banner koneksi
    return Stack(
      children: [
        // widget.child di sini adalah halaman aktual Anda (misal: LoginPage)
        widget.child, 
        
        // Tampilkan banner jika showConnectivityBanner adalah true
        if (showConnectivityBanner) buildConnectivityBanner(),
      ],
    );
  }
}