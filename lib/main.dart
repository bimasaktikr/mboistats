import 'package:flutter/material.dart';
import 'package:mboistats/route-manager.dart';
// import 'package:connectivity/connectivity.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/services/activity_observer.dart';
import 'package:mboistats/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mboistats/config/supabase_config.dart';

LocalhostServer localhostServer = LocalhostServer();

// Global theme notifier for dark mode
final AppThemeNotifier appThemeNotifier = AppThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoggerService.init();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await localhostServer.start(port: 0);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appThemeNotifier,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appThemeNotifier.currentTheme,
          home: ConnectivityWrapper(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: appThemeNotifier.currentTheme,
              initialRoute: '/splash',
              onGenerateRoute: (settings) {
                final builder = RouteManager.routes[settings.name];
                if (builder != null) {
                  return PageRouteBuilder(
                    settings: settings,
                    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 200),
                  );
                }
                return null;
              },
              navigatorObservers: [
                ActivityLoggingObserver(),
                routeObserver,
              ],
            ),
          ),
        );
      },
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
