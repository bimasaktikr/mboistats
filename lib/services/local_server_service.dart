import 'package:webview_flutter_plus/webview_flutter_plus.dart';

/// Membungkus instance LocalhostServer agar bisa disediakan
/// oleh Provider dan tidak menjadi variabel global di main.dart
class LocalServerService {
  final LocalhostServer _server = LocalhostServer();

  /// Mengembalikan port yang sedang berjalan
  int? get port => _server.port;

  /// Memulai server pada port yang tersedia
  Future<void> start() async {
    await _server.start(port: 0); // port: 0 = biarkan OS memilih port
  }
}