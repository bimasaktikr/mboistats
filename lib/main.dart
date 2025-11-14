import 'package:flutter/material.dart';
import 'package:mboistats/route-manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- TAMBAHAN BARU UNTUK STATE MANAGEMENT ---
import 'package:provider/provider.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:mboistats/services/supabase_db_service.dart';

LocalhostServer localhostServer = LocalhostServer();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await localhostServer.start(port: 0);
  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseAuthService>(
          create: (_) => SupabaseAuthService(),
        ),
        ChangeNotifierProvider<SupabaseDbService>(
          create: (context) => SupabaseDbService(
            context.read<SupabaseAuthService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: RouteManager.routes,
      builder: (context, child) {
        return ConnectivityWrapper(
          child: child!,
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
    checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        connectivityResult = result;
        showConnectivityBanner = false;
        showToastMessage();
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
  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (mounted) {
      setState(() {
        this.connectivityResult = connectivityResult;
      });
    }
  }
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