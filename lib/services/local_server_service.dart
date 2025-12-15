import 'package:webview_flutter_plus/webview_flutter_plus.dart';


class LocalServerService {
  final LocalhostServer _server = LocalhostServer();

  int? get port => _server.port;

  Future<void> start() async {
    await _server.start(port: 0); // port: 0 = biarkan OS memilih port
  }
}