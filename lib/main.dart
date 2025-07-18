import 'package:flutter/material.dart';
import 'package:mboistats/route-manager.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

LocalhostServer localhostServer = LocalhostServer();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await localhostServer.start(port: 0);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ConnectivityWrapper(
        child: MaterialApp(
          initialRoute: '/splash',
          routes: RouteManager.routes,
        ),
      ),
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _ConnectivityWrapperState createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  var connectivityResult;
  bool showConnectivityBanner = false;

  @override
  void initState() {
    super.initState();
    // Langsung panggil fungsi untuk memeriksa status koneksi saat widget diinisialisasi
    checkConnectivity();
    // Langsung lakukan pemantauan koneksi
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        connectivityResult = result;
        showConnectivityBanner = false;
        showToastMessage(); // Tampilkan pesan toast berdasarkan status koneksi
        // Menutup banner setelah beberapa detik (misalnya, 3 detik)
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            showConnectivityBanner = false;
          });
        });
      });
    });
  }

  // Fungsi untuk memeriksa status koneksi
  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      this.connectivityResult = connectivityResult;
    });
  }

  // Fungsi untuk menampilkan pesan toast berdasarkan status koneksi
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
    return Stack(
      children: [
        widget.child,
        if (showConnectivityBanner) buildConnectivityBanner(),
      ],
    );
  }
}
